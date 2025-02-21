;; Resource Allocation Contract

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_RESOURCES (err u402))

(define-map mission-resources
  { mission-id: uint }
  {
    fuel: uint,
    food: uint,
    equipment: uint
  }
)

(define-map resource-pool
  { resource: (string-ascii 20) }
  { amount: uint }
)

(define-public (allocate-resources (mission-id uint) (fuel uint) (food uint) (equipment uint))
  (let
    ((current-fuel (unwrap! (get amount (map-get? resource-pool { resource: "fuel" })) ERR_NOT_FOUND))
     (current-food (unwrap! (get amount (map-get? resource-pool { resource: "food" })) ERR_NOT_FOUND))
     (current-equipment (unwrap! (get amount (map-get? resource-pool { resource: "equipment" })) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= current-fuel fuel) (>= current-food food) (>= current-equipment equipment)) ERR_INSUFFICIENT_RESOURCES)
    (map-set resource-pool { resource: "fuel" } { amount: (- current-fuel fuel) })
    (map-set resource-pool { resource: "food" } { amount: (- current-food food) })
    (map-set resource-pool { resource: "equipment" } { amount: (- current-equipment equipment) })
    (ok (map-set mission-resources
      { mission-id: mission-id }
      {
        fuel: fuel,
        food: food,
        equipment: equipment
      }
    ))
  )
)

(define-public (add-to-resource-pool (resource (string-ascii 20)) (amount uint))
  (let
    ((current-amount (default-to u0 (get amount (map-get? resource-pool { resource: resource })))))
    (ok (map-set resource-pool
      { resource: resource }
      { amount: (+ current-amount amount) }
    ))
  )
)

(define-read-only (get-mission-resources (mission-id uint))
  (map-get? mission-resources { mission-id: mission-id })
)

(define-read-only (get-resource-pool-amount (resource (string-ascii 20)))
  (get amount (map-get? resource-pool { resource: resource }))
)

