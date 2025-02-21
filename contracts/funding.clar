;; Funding Contract

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))

(define-fungible-token space-token)

(define-map mission-funding
  { mission-id: uint }
  { total-funds: uint }
)

(define-public (fund-mission (mission-id uint) (amount uint))
  (let
    ((current-funding (default-to { total-funds: u0 } (map-get? mission-funding { mission-id: mission-id }))))
    (try! (ft-transfer? space-token amount tx-sender (as-contract tx-sender)))
    (ok (map-set mission-funding
      { mission-id: mission-id }
      { total-funds: (+ (get total-funds current-funding) amount) }
    ))
  )
)

(define-public (allocate-funds (mission-id uint) (amount uint) (recipient principal))
  (let
    ((mission-funds (unwrap! (map-get? mission-funding { mission-id: mission-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (>= (get total-funds mission-funds) amount) ERR_INSUFFICIENT_FUNDS)
    (try! (as-contract (ft-transfer? space-token amount tx-sender recipient)))
    (ok (map-set mission-funding
      { mission-id: mission-id }
      { total-funds: (- (get total-funds mission-funds) amount) }
    ))
  )
)

(define-read-only (get-mission-funds (mission-id uint))
  (map-get? mission-funding { mission-id: mission-id })
)

(define-read-only (get-total-funds)
  (ft-get-balance space-token (as-contract tx-sender))
)

