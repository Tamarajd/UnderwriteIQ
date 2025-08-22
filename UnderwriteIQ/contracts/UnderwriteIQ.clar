;; Adaptive Insurance Underwriting and Claims Automation Contract
;; This smart contract provides automated insurance underwriting based on risk assessment
;; and streamlined claims processing with built-in fraud detection and automated payouts.
;; The system supports multiple insurance types and dynamic premium calculations.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-policy-expired (err u104))
(define-constant err-claim-already-processed (err u105))
(define-constant err-insufficient-funds (err u106))
(define-constant err-invalid-risk-score (err u107))

;; Risk assessment thresholds
(define-constant low-risk-threshold u30)
(define-constant medium-risk-threshold u70)
(define-constant max-coverage-amount u1000000) ;; Maximum coverage in STX
(define-constant min-premium-rate u100) ;; Minimum premium rate (basis points)
(define-constant max-premium-rate u2000) ;; Maximum premium rate (basis points)

;; Data maps and vars
;; Policy storage with comprehensive policy details
(define-map policies
  { policy-id: uint }
  {
    holder: principal,
    coverage-amount: uint,
    premium-amount: uint,
    risk-score: uint,
    policy-type: (string-ascii 32),
    start-block: uint,
    end-block: uint,
    active: bool,
    claims-count: uint
  }
)

;; Claims tracking with detailed claim information
(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    claimant: principal,
    amount: uint,
    description: (string-ascii 256),
    submitted-block: uint,
    processed: bool,
    approved: bool,
    fraud-score: uint,
    evidence-hash: (buff 32)
  }
)

;; User risk profiles for dynamic underwriting
(define-map user-profiles
  { user: principal }
  {
    total-policies: uint,
    claims-history: uint,
    reputation-score: uint,
    last-claim-block: uint,
    blacklisted: bool
  }
)

;; Contract state variables
(define-data-var policy-nonce uint u0)
(define-data-var claim-nonce uint u0)
(define-data-var contract-balance uint u0)
(define-data-var emergency-pause bool false)

;; Private functions
;; Calculate risk-adjusted premium based on multiple factors
(define-private (calculate-premium (coverage-amount uint) (risk-score uint) (policy-type (string-ascii 32)))
  (let (
    (base-rate (if (< risk-score low-risk-threshold) min-premium-rate
                  (if (< risk-score medium-risk-threshold) u500 max-premium-rate)))
    (type-multiplier (if (is-eq policy-type "auto") u120
                        (if (is-eq policy-type "health") u150
                           (if (is-eq policy-type "property") u100 u130))))
  )
  (/ (* (* coverage-amount base-rate) type-multiplier) u1000000))
)

;; Assess risk score based on user profile and policy details
(define-private (assess-risk-score (user principal) (policy-type (string-ascii 32)) (coverage-amount uint))
  (let (
    (profile (default-to 
      { total-policies: u0, claims-history: u0, reputation-score: u50, last-claim-block: u0, blacklisted: false }
      (map-get? user-profiles { user: user })))
    (base-score u50)
    (history-penalty (* (get claims-history profile) u5))
    (coverage-risk (/ coverage-amount u10000))
    (reputation-bonus (- u50 (get reputation-score profile)))
  )
  (+ (+ (+ base-score history-penalty) coverage-risk) reputation-bonus))
)

;; Validate claim against fraud indicators
(define-private (detect-fraud (policy-id uint) (claim-amount uint) (claimant principal))
  (let (
    (policy (unwrap! (map-get? policies { policy-id: policy-id }) u100))
    (user-profile (default-to 
      { total-policies: u0, claims-history: u0, reputation-score: u50, last-claim-block: u0, blacklisted: false }
      (map-get? user-profiles { user: claimant })))
    (fraud-score u0)
  )
  ;; Check for suspicious patterns
  (let (
    (amount-score (if (> claim-amount (/ (get coverage-amount policy) u2)) u25 u0))
    (frequency-score (if (< (- block-height (get last-claim-block user-profile)) u144) u30 u0))
    (history-score (if (> (get claims-history user-profile) u3) u20 u0))
    (blacklist-score (if (get blacklisted user-profile) u100 u0))
  )
  (+ (+ (+ fraud-score amount-score) frequency-score) (+ history-score blacklist-score))))
)

;; Public functions
;; Create a new insurance policy with automated underwriting
(define-public (create-policy (coverage-amount uint) (policy-type (string-ascii 32)) (evidence-hash (buff 32)))
  (let (
    (policy-id (+ (var-get policy-nonce) u1))
    (risk-score (assess-risk-score tx-sender policy-type coverage-amount))
    (premium (calculate-premium coverage-amount risk-score policy-type))
  )
  ;; Validate inputs and risk assessment
  (asserts! (not (var-get emergency-pause)) (err u108))
  (asserts! (and (> coverage-amount u0) (<= coverage-amount max-coverage-amount)) err-invalid-amount)
  (asserts! (<= risk-score u100) err-invalid-risk-score)
  
  ;; Process premium payment
  (try! (stx-transfer? premium tx-sender (as-contract tx-sender)))
  
  ;; Create policy record
  (map-set policies 
    { policy-id: policy-id }
    {
      holder: tx-sender,
      coverage-amount: coverage-amount,
      premium-amount: premium,
      risk-score: risk-score,
      policy-type: policy-type,
      start-block: block-height,
      end-block: (+ block-height u52560), ;; ~1 year assuming 10min blocks
      active: true,
      claims-count: u0
    }
  )
  
  ;; Update user profile
  (map-set user-profiles
    { user: tx-sender }
    (merge 
      (default-to { total-policies: u0, claims-history: u0, reputation-score: u50, last-claim-block: u0, blacklisted: false }
                  (map-get? user-profiles { user: tx-sender }))
      { total-policies: (+ (get total-policies (default-to { total-policies: u0, claims-history: u0, reputation-score: u50, last-claim-block: u0, blacklisted: false }
                                                           (map-get? user-profiles { user: tx-sender }))) u1) }
    )
  )
  
  ;; Update contract state
  (var-set policy-nonce policy-id)
  (var-set contract-balance (+ (var-get contract-balance) premium))
  
  (ok policy-id))
)

;; Submit an insurance claim with automated processing
(define-public (submit-claim (policy-id uint) (claim-amount uint) (description (string-ascii 256)) (evidence-hash (buff 32)))
  (let (
    (policy (unwrap! (map-get? policies { policy-id: policy-id }) err-not-found))
    (claim-id (+ (var-get claim-nonce) u1))
    (fraud-score (detect-fraud policy-id claim-amount tx-sender))
  )
  ;; Validate claim eligibility
  (asserts! (not (var-get emergency-pause)) (err u108))
  (asserts! (is-eq (get holder policy) tx-sender) err-unauthorized)
  (asserts! (get active policy) err-policy-expired)
  (asserts! (<= block-height (get end-block policy)) err-policy-expired)
  (asserts! (and (> claim-amount u0) (<= claim-amount (get coverage-amount policy))) err-invalid-amount)
  
  ;; Create claim record
  (map-set claims
    { claim-id: claim-id }
    {
      policy-id: policy-id,
      claimant: tx-sender,
      amount: claim-amount,
      description: description,
      submitted-block: block-height,
      processed: false,
      approved: (< fraud-score u50), ;; Auto-approve low fraud risk claims
      fraud-score: fraud-score,
      evidence-hash: evidence-hash
    }
  )
  
  ;; Update policy claims count
  (map-set policies
    { policy-id: policy-id }
    (merge policy { claims-count: (+ (get claims-count policy) u1) })
  )
  
  (var-set claim-nonce claim-id)
  (ok claim-id))
)


