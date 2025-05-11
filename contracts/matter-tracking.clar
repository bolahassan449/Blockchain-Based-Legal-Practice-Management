;; Matter Tracking Contract
;; This contract records case details and progress

(define-data-var admin principal tx-sender)

;; Data structure for matter information
(define-map matters
  { matter-id: (string-ascii 36) }
  {
    attorney-id: (string-ascii 36),
    client-id: (string-ascii 36),
    title: (string-ascii 100),
    description: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint
  }
)

;; Data structure for matter updates
(define-map matter-updates
  { matter-id: (string-ascii 36), update-id: (string-ascii 36) }
  {
    description: (string-ascii 500),
    timestamp: uint,
    updated-by: principal
  }
)

;; Initialize the contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok true)
  )
)

;; Create a new matter
(define-public (create-matter
    (matter-id (string-ascii 36))
    (attorney-id (string-ascii 36))
    (client-id (string-ascii 36))
    (title (string-ascii 100))
    (description (string-ascii 500))
  )
  (begin
    (asserts! (is-none (map-get? matters { matter-id: matter-id })) (err u101))
    (map-set matters
      { matter-id: matter-id }
      {
        attorney-id: attorney-id,
        client-id: client-id,
        title: title,
        description: description,
        status: "open",
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Update matter status
(define-public (update-matter-status
    (matter-id (string-ascii 36))
    (new-status (string-ascii 20))
  )
  (begin
    (match (map-get? matters { matter-id: matter-id })
      matter-data (begin
        (map-set matters
          { matter-id: matter-id }
          (merge matter-data {
            status: new-status,
            updated-at: block-height
          })
        )
        (ok true)
      )
      (err u102)
    )
  )
)

;; Add an update to a matter
(define-public (add-matter-update
    (matter-id (string-ascii 36))
    (update-id (string-ascii 36))
    (description (string-ascii 500))
  )
  (begin
    (asserts! (is-some (map-get? matters { matter-id: matter-id })) (err u102))
    (asserts! (is-none (map-get? matter-updates { matter-id: matter-id, update-id: update-id })) (err u103))

    (map-set matter-updates
      { matter-id: matter-id, update-id: update-id }
      {
        description: description,
        timestamp: block-height,
        updated-by: tx-sender
      }
    )

    (match (map-get? matters { matter-id: matter-id })
      matter-data (begin
        (map-set matters
          { matter-id: matter-id }
          (merge matter-data { updated-at: block-height })
        )
        (ok true)
      )
      (err u102)
    )
  )
)

;; Get matter details
(define-read-only (get-matter-details (matter-id (string-ascii 36)))
  (match (map-get? matters { matter-id: matter-id })
    matter-data (ok matter-data)
    (err u102)
  )
)

;; Get matter update
(define-read-only (get-matter-update (matter-id (string-ascii 36)) (update-id (string-ascii 36)))
  (match (map-get? matter-updates { matter-id: matter-id, update-id: update-id })
    update-data (ok update-data)
    (err u103)
  )
)
