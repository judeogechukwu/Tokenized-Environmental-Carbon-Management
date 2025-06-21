;; Emissions Tracking Contract
;; Tracks carbon emissions for organizations

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_AMOUNT (err u201))
(define-constant ERR_NOT_FOUND (err u202))

;; Data structures
(define-map organization-emissions principal {
    total-emissions: uint,
    last-updated: uint,
    reporting-period: uint
})

(define-map emission-records { org: principal, period: uint } {
    scope1: uint,
    scope2: uint,
    scope3: uint,
    verified: bool,
    verifier: (optional principal)
})

(define-data-var next-record-id uint u1)

;; Read-only functions
(define-read-only (get-organization-emissions (org principal))
    (map-get? organization-emissions org)
)

(define-read-only (get-emission-record (org principal) (period uint))
    (map-get? emission-records { org: org, period: period })
)

(define-read-only (calculate-total-emissions (scope1 uint) (scope2 uint) (scope3 uint))
    (+ scope1 (+ scope2 scope3))
)

;; Public functions
(define-public (record-emissions (scope1 uint) (scope2 uint) (scope3 uint) (period uint))
    (let ((total (calculate-total-emissions scope1 scope2 scope3)))
        (begin
            (asserts! (> total u0) ERR_INVALID_AMOUNT)
            (map-set emission-records
                { org: tx-sender, period: period }
                {
                    scope1: scope1,
                    scope2: scope2,
                    scope3: scope3,
                    verified: false,
                    verifier: none
                }
            )
            (map-set organization-emissions tx-sender {
                total-emissions: total,
                last-updated: block-height,
                reporting-period: period
            })
            (ok true)
        )
    )
)

(define-public (verify-emissions (org principal) (period uint))
    (begin
        ;; In a real implementation, would check if tx-sender is a verified manager
        (match (map-get? emission-records { org: org, period: period })
            record (begin
                (map-set emission-records
                    { org: org, period: period }
                    (merge record { verified: true, verifier: (some tx-sender) })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (update-emissions (scope1 uint) (scope2 uint) (scope3 uint) (period uint))
    (let ((total (calculate-total-emissions scope1 scope2 scope3)))
        (begin
            (asserts! (> total u0) ERR_INVALID_AMOUNT)
            (match (map-get? emission-records { org: tx-sender, period: period })
                existing-record (begin
                    (map-set emission-records
                        { org: tx-sender, period: period }
                        (merge existing-record {
                            scope1: scope1,
                            scope2: scope2,
                            scope3: scope3,
                            verified: false,
                            verifier: none
                        })
                    )
                    (map-set organization-emissions tx-sender {
                        total-emissions: total,
                        last-updated: block-height,
                        reporting-period: period
                    })
                    (ok true)
                )
                ERR_NOT_FOUND
            )
        )
    )
)
