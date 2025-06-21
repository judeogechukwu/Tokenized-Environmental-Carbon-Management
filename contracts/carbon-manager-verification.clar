;; Carbon Manager Verification Contract
;; Validates and manages carbon management professionals

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map verified-managers principal {
    name: (string-ascii 50),
    certification: (string-ascii 100),
    verified-at: uint,
    active: bool
})

(define-map manager-credentials principal {
    experience-years: uint,
    specialization: (string-ascii 50),
    rating: uint
})

;; Read-only functions
(define-read-only (is-verified-manager (manager principal))
    (match (map-get? verified-managers manager)
        manager-data (get active manager-data)
        false
    )
)

(define-read-only (get-manager-info (manager principal))
    (map-get? verified-managers manager)
)

(define-read-only (get-manager-credentials (manager principal))
    (map-get? manager-credentials manager)
)

;; Public functions
(define-public (verify-manager (manager principal) (name (string-ascii 50)) (certification (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? verified-managers manager)) ERR_ALREADY_VERIFIED)
        (map-set verified-managers manager {
            name: name,
            certification: certification,
            verified-at: block-height,
            active: true
        })
        (ok true)
    )
)

(define-public (update-credentials (experience-years uint) (specialization (string-ascii 50)) (rating uint))
    (begin
        (asserts! (is-verified-manager tx-sender) ERR_UNAUTHORIZED)
        (map-set manager-credentials tx-sender {
            experience-years: experience-years,
            specialization: specialization,
            rating: rating
        })
        (ok true)
    )
)

(define-public (deactivate-manager (manager principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (match (map-get? verified-managers manager)
            manager-data (begin
                (map-set verified-managers manager (merge manager-data { active: false }))
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)
