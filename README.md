🛡️ UnderwriteIQ 🛡️
====================

A sophisticated, on-chain smart contract for automated insurance underwriting and claims management built on the Clarity smart contract language. UnderwriteIQ streamlines the entire insurance lifecycle, from dynamic premium calculation based on risk assessment to automated claims processing with integrated fraud detection. This contract serves as a decentralized, transparent, and efficient alternative to traditional insurance systems, reducing overhead and providing rapid, trustless payouts for eligible claims.

* * * * *

🚀 Key Features
---------------

UnderwriteIQ is designed to be a comprehensive insurance protocol, offering a suite of powerful features:

-   **Dynamic Underwriting:** Calculates premiums in real-time based on a multi-factor risk assessment model that considers the user's claims history, reputation, and the nature of the policy.

-   **Automated Claims Processing:** Facilitates a seamless claims submission process. Claims with a low fraud risk are automatically approved and paid out, while higher-risk claims are flagged for manual review.

-   **Integrated Fraud Detection:** Utilizes on-chain data to calculate a fraud score for each claim. It flags suspicious activities based on factors like claims frequency, claim amount relative to coverage, and user's claims history.

-   **Decentralized Policy Management:** All policies and claims are stored on the blockchain, providing a permanent and transparent record accessible to all participants.

-   **Emergency Pause Mechanism:** The contract owner can temporarily pause key functions in case of a security breach or unexpected behavior.

-   **Reputation-Based Incentives:** Users with a clean claims history are rewarded with a better reputation score, which can lead to lower premiums on future policies.

-   **Multi-Policy Support:** The contract is designed to handle various insurance types, such as "auto," "health," and "property," with different risk multipliers.

* * * * *

🛠️ Getting Started
-------------------

### Prerequisites

To interact with this contract, you will need:

-   A Stacks wallet (e.g., Leather, Xverse).

-   The `clarity-cli` for local testing.

-   A development environment set up for Stacks smart contracts.

### Deployment

This contract is written in Clarity and can be deployed to the Stacks blockchain. You will need to use a contract deployment tool like `clarity-cli` or a web-based IDE that supports Clarity.

Bash

```
# Example using clarity-cli
clarity-cli deploy <path_to_contract>/underwrite-iq.clar

```

### Integration

UnderwriteIQ is designed to be a standalone service or integrated with a front-end dApp. Here's how you can call its public functions:

#### Example: Creating a Policy

Code snippet

```
(try! (contract-call? 'SPX...UnderwriteIQ.create-policy
  u500000 ;; coverage-amount
  "property" ;; policy-type
  0x123... ;; evidence-hash
))

```

#### Example: Submitting a Claim

Code snippet

```
(try! (contract-call? 'SPX...UnderwriteIQ.submit-claim
  u1024 ;; policy-id
  u100000 ;; claim-amount
  "My car was stolen on Tuesday morning." ;; description
  0xabc... ;; evidence-hash
))

```

* * * * *

📄 API Reference
----------------

### Public Functions

#### `create-policy`

**Signature:** `(create-policy (coverage-amount uint) (policy-type (string-ascii 32)) (evidence-hash (buff 32)))` **Description:** Mints a new insurance policy for the `tx-sender`. It calculates a risk-adjusted premium, transfers the premium, and records the policy details on-chain. **Returns:** `(ok uint)` with the new policy ID on success, or an error code on failure.

#### `submit-claim`

**Signature:** `(submit-claim (policy-id uint) (claim-amount uint) (description (string-ascii 256)) (evidence-hash (buff 32)))` **Description:** Allows a policy holder to submit a claim against an active policy. The function validates eligibility, assesses a fraud score, and creates a claim record. **Returns:** `(ok uint)` with the new claim ID on success, or an error code on failure.

#### `process-claim`

**Signature:** `(process-claim (claim-id uint))` **Description:** This function processes a claim. If the claim has a low fraud score and is pre-approved, it automatically executes the STX transfer to the claimant. Otherwise, it updates the claim status for manual review. **Returns:** `(ok true)` if the claim is processed, `(ok false)` if it requires manual review, or an error code on failure.

* * * * *

### Private Functions

#### `calculate-premium`

**Signature:** `(calculate-premium (coverage-amount uint) (risk-score uint) (policy-type (string-ascii 32)))` **Description:** A core internal function that determines the premium cost. It applies a base rate based on the risk score and a multiplier based on the policy type.

#### `assess-risk-score`

**Signature:** `(assess-risk-score (user principal) (policy-type (string-ascii 32)) (coverage-amount uint))` **Description:** Computes an aggregated risk score for a user. It factors in their past claims history, reputation, and the financial risk of the new policy.

#### `detect-fraud`

**Signature:** `(detect-fraud (policy-id uint) (claim-amount uint) (claimant principal))` **Description:** This function analyzes a claim against a user's historical data and policy details to produce a fraud risk score.

* * * * *

📊 Data Structures & State
--------------------------

-   `policies` (map): Stores all active and expired policy data.

-   `claims` (map): Maintains a record of all submitted claims, including their status and fraud score.

-   `user-profiles` (map): A dynamic profile for each user, tracking their claims history, policies, and reputation score.

-   `policy-nonce` (variable): A monotonically increasing counter for policy IDs.

-   `claim-nonce` (variable): A monotonically increasing counter for claim IDs.

-   `contract-balance` (variable): The total amount of STX held by the contract.

-   `emergency-pause` (variable): A boolean flag to pause critical contract functions.

* * * * *

🚧 Error Codes
--------------

-   `u100`: `err-owner-only` - Only the contract owner can call this function.

-   `u101`: `err-not-found` - The requested record (policy or claim) was not found.

-   `u102`: `err-unauthorized` - The caller is not authorized for this action.

-   `u103`: `err-invalid-amount` - The specified amount is invalid.

-   `u104`: `err-policy-expired` - The policy has expired.

-   `u105`: `err-claim-already-processed` - The claim has already been processed.

-   `u106`: `err-insufficient-funds` - The contract balance is too low for the payout.

-   `u107`: `err-invalid-risk-score` - The calculated risk score is out of the valid range.

-   `u108`: `err-contract-paused` - The contract is currently paused.

* * * * *

📝 Contribution
---------------

We welcome and appreciate all contributions! If you have suggestions for improvements, bug fixes, or new features, please open a pull request or submit an issue on our GitHub repository. Your help makes this a more robust and secure protocol.

* * * * *

⚖️ License
----------

This project is licensed under the MIT License. See the `LICENSE` file for details.
