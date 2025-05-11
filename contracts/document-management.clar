;; Document Management Contract
;; This contract organizes case-related materials

(define-data-var admin principal tx-sender)

;; Data structure for documents
(define-map documents
  { document-id: (string-ascii 36) }
  {
    matter-id: (string-ascii 36),
    title: (string-ascii 100),
    description: (string-ascii 500),
    file-hash: (buff 32),
    file-type: (string-ascii 20),
    uploaded-by: principal,
    uploaded-at: uint,
    status: (string-ascii 20)
  }
)

;; Data structure for document access
(define-map document-access
  { document-id: (string-ascii 36), principal: principal }
  {
    can-read: bool,
    can-write: bool,
    granted-at: uint,
    granted-by: principal
  }
)

;; Initialize the contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok true)
  )
)

;; Upload a new document
(define-public (upload-document
    (document-id (string-ascii 36))
    (matter-id (string-ascii 36))
    (title (string-ascii 100))
    (description (string-ascii 500))
    (file-hash (buff 32))
    (file-type (string-ascii 20))
  )
  (begin
    (asserts! (is-none (map-get? documents { document-id: document-id })) (err u101))
    (map-set documents
      { document-id: document-id }
      {
        matter-id: matter-id,
        title: title,
        description: description,
        file-hash: file-hash,
        file-type: file-type,
        uploaded-by: tx-sender,
        uploaded-at: block-height,
        status: "active"
      }
    )

    ;; Grant access to the uploader
    (map-set document-access
      { document-id: document-id, principal: tx-sender }
      {
        can-read: true,
        can-write: true,
        granted-at: block-height,
        granted-by: tx-sender
      }
    )

    (ok true)
  )
)

;; Grant access to a document
(define-public (grant-document-access
    (document-id (string-ascii 36))
    (user principal)
    (can-read bool)
    (can-write bool)
  )
  (begin
    (match (map-get? documents { document-id: document-id })
      document-data (begin
        (asserts! (is-eq (get uploaded-by document-data) tx-sender) (err u104))
        (map-set document-access
          { document-id: document-id, principal: user }
          {
            can-read: can-read,
            can-write: can-write,
            granted-at: block-height,
            granted-by: tx-sender
          }
        )
        (ok true)
      )
      (err u102)
    )
  )
)

;; Check if a user has access to a document
(define-read-only (check-document-access (document-id (string-ascii 36)) (user principal))
  (match (map-get? document-access { document-id: document-id, principal: user })
    access-data (ok access-data)
    (err u103)
  )
)

;; Get document details
(define-read-only (get-document-details (document-id (string-ascii 36)))
  (match (map-get? documents { document-id: document-id })
    document-data (ok document-data)
    (err u102)
  )
)

;; Archive a document
(define-public (archive-document (document-id (string-ascii 36)))
  (begin
    (match (map-get? documents { document-id: document-id })
      document-data (begin
        (asserts! (is-eq (get uploaded-by document-data) tx-sender) (err u104))
        (map-set documents
          { document-id: document-id }
          (merge document-data { status: "archived" })
        )
        (ok true)
      )
      (err u102)
    )
  )
)
