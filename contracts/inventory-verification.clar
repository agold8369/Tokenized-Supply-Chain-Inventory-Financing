;; Inventory Verification Contract
;; Validates the existence of goods in the supply chain

(define-data-var contract-owner principal tx-sender)

;; Structure to represent inventory items
(define-map inventory-records
  { inventory-id: (string-utf8 36) }
  {
    owner: principal,
    description: (string-utf8 100),
    quantity: uint,
    location: (string-utf8 50),
    verified: bool,
    timestamp: uint
  }
)

;; List of authorized verifiers
(define-map authorized-verifiers principal bool)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Add a verifier
(define-public (add-verifier (verifier-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-set authorized-verifiers verifier-address true)
    (ok true)
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-delete authorized-verifiers verifier-address)
    (ok true)
  )
)

;; Register new inventory
(define-public (register-inventory
    (inventory-id (string-utf8 36))
    (description (string-utf8 100))
    (quantity uint)
    (location (string-utf8 50))
  )
  (begin
    (asserts! (is-none (map-get? inventory-records { inventory-id: inventory-id })) (err u2))
    (map-set inventory-records
      { inventory-id: inventory-id }
      {
        owner: tx-sender,
        description: description,
        quantity: quantity,
        location: location,
        verified: false,
        timestamp: block-height
      }
    )
    (ok true)
  )
)

;; Verify inventory existence
(define-public (verify-inventory (inventory-id (string-utf8 36)))
  (let (
    (inventory-info (unwrap! (map-get? inventory-records { inventory-id: inventory-id }) (err u3)))
  )
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) (err u4))
    (map-set inventory-records
      { inventory-id: inventory-id }
      (merge inventory-info { verified: true, timestamp: block-height })
    )
    (ok true)
  )
)

;; Check if inventory is verified
(define-read-only (is-inventory-verified (inventory-id (string-utf8 36)))
  (match (map-get? inventory-records { inventory-id: inventory-id })
    inventory-info (ok (get verified inventory-info))
    (err u3)
  )
)

;; Get inventory details
(define-read-only (get-inventory-details (inventory-id (string-utf8 36)))
  (map-get? inventory-records { inventory-id: inventory-id })
)
