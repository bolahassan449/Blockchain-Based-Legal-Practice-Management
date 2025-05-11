;; Attorney Verification Contract
;; This contract validates legal professionals on the blockchain

(define-data-var admin principal tx-sender)

;; Data structure for attorney information
(define-map attorneys
  { attorney-id: (string-ascii 36) }
  {
    principal: principal,
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    jurisdiction: (string-ascii 50),
    status: (string-ascii 20),
    verified: bool
  }
)

;; Initialize the contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok true)
  )
)

;; Register a new attorney
(define-public (register-attorney
    (attorney-id (string-ascii 36))
    (name (string-ascii 100))
    (license-number (string-ascii 50))
    (jurisdiction (string-ascii 50))
  )
  (begin
    (asserts! (is-none (map-get? attorneys { attorney-id: attorney-id })) (err u101))
    (map-set attorneys
      { attorney-id: attorney-id }
      {
        principal: tx-sender,
        name: name,
        license-number: license-number,
        jurisdiction: jurisdiction,
        status: "pending",
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify an attorney (admin only)
(define-public (verify-attorney (attorney-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (match (map-get? attorneys { attorney-id: attorney-id })
      attorney-data (begin
        (map-set attorneys
          { attorney-id: attorney-id }
          (merge attorney-data { status: "active", verified: true })
        )
        (ok true)
      )
      (err u102)
    )
  )
)

;; Check if an attorney is verified
(define-read-only (is-attorney-verified (attorney-id (string-ascii 36)))
  (match (map-get? attorneys { attorney-id: attorney-id })
    attorney-data (ok (get verified attorney-data))
    (err u102)
  )
)

;; Get attorney details
(define-read-only (get-attorney-details (attorney-id (string-ascii 36)))
  (match (map-get? attorneys { attorney-id: attorney-id })
    attorney-data (ok attorney-data)
    (err u102)
  )
)

;; Set a new admin (only current admin can do this)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (var-set admin new-admin)
    (ok true)
  )
)
