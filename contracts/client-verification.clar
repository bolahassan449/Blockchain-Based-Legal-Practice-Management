;; Client Verification Contract
;; This contract manages client identities on the blockchain

(define-data-var admin principal tx-sender)

;; Data structure for client information
(define-map clients
  { client-id: (string-ascii 36) }
  {
    principal: principal,
    name: (string-ascii 100),
    contact: (string-ascii 100),
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

;; Register a new client
(define-public (register-client
    (client-id (string-ascii 36))
    (name (string-ascii 100))
    (contact (string-ascii 100))
  )
  (begin
    (asserts! (is-none (map-get? clients { client-id: client-id })) (err u101))
    (map-set clients
      { client-id: client-id }
      {
        principal: tx-sender,
        name: name,
        contact: contact,
        status: "pending",
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify a client (admin or attorney can do this)
(define-public (verify-client (client-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (match (map-get? clients { client-id: client-id })
      client-data (begin
        (map-set clients
          { client-id: client-id }
          (merge client-data { status: "active", verified: true })
        )
        (ok true)
      )
      (err u102)
    )
  )
)

;; Check if a client is verified
(define-read-only (is-client-verified (client-id (string-ascii 36)))
  (match (map-get? clients { client-id: client-id })
    client-data (ok (get verified client-data))
    (err u102)
  )
)

;; Get client details
(define-read-only (get-client-details (client-id (string-ascii 36)))
  (match (map-get? clients { client-id: client-id })
    client-data (ok client-data)
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
