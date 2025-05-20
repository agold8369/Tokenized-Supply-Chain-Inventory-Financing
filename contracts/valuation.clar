;; Valuation Contract
;; Determines appropriate financing amounts for inventory

(define-data-var contract-owner principal tx-sender)

;; Map to store valuations for inventory
(define-map inventory-valuations
  { inventory-id: (string-utf8 36) }
  {
    appraised-value: uint,
    financing-rate: uint,
    max-financing-amount: uint,
    valuation-date: uint,
    appraiser: principal
  }
)

;; Authorized appraisers
(define-map authorized-appraisers principal bool)

;; Initialize contract
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Add an appraiser
(define-public (add-appraiser (appraiser-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-set authorized-appraisers appraiser-address true)
    (ok true)
  )
)

;; Remove an appraiser
(define-public (remove-appraiser (appraiser-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-delete authorized-appraisers appraiser-address)
    (ok true)
  )
)

;; Create a valuation for inventory
(define-public (value-inventory
    (inventory-id (string-utf8 36))
    (appraised-value uint)
    (financing-rate uint)
  )
  (begin
    (asserts! (default-to false (map-get? authorized-appraisers tx-sender)) (err u2))
    (asserts! (<= financing-rate u100) (err u3)) ;; Rate cannot exceed 100%

    (let (
      (max-financing (/ (* appraised-value financing-rate) u100))
    )
      (map-set inventory-valuations
        { inventory-id: inventory-id }
        {
          appraised-value: appraised-value,
          financing-rate: financing-rate,
          max-financing-amount: max-financing,
          valuation-date: block-height,
          appraiser: tx-sender
        }
      )
      (ok max-financing)
    )
  )
)

;; Get valuation details
(define-read-only (get-valuation (inventory-id (string-utf8 36)))
  (map-get? inventory-valuations { inventory-id: inventory-id })
)

;; Check if item has been valued
(define-read-only (is-inventory-valued (inventory-id (string-utf8 36)))
  (is-some (map-get? inventory-valuations { inventory-id: inventory-id }))
)

;; Get maximum financing amount
(define-read-only (get-max-financing (inventory-id (string-utf8 36)))
  (match (map-get? inventory-valuations { inventory-id: inventory-id })
    valuation (ok (get max-financing-amount valuation))
    (err u4)
  )
)
