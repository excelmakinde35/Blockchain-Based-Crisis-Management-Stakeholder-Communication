;; Communication Coordinator Verification Contract
;; Validates and manages crisis communication coordinators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_VERIFIED (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map coordinators
  { coordinator: principal }
  {
    verified: bool,
    verification-date: uint,
    credentials-hash: (buff 32),
    reputation-score: uint,
    active: bool
  }
)

(define-map verification-requests
  { request-id: uint }
  {
    coordinator: principal,
    credentials-hash: (buff 32),
    requested-at: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-request-id uint u1)

;; Public functions
(define-public (request-verification (credentials-hash (buff 32)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        coordinator: tx-sender,
        credentials-hash: credentials-hash,
        requested-at: block-height,
        status: "pending"
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (verify-coordinator (coordinator principal) (credentials-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? coordinators { coordinator: coordinator })) ERR_ALREADY_VERIFIED)
    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: true,
        verification-date: block-height,
        credentials-hash: credentials-hash,
        reputation-score: u100,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (revoke-verification (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? coordinators { coordinator: coordinator })) ERR_NOT_VERIFIED)
    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: false,
        verification-date: u0,
        credentials-hash: 0x00,
        reputation-score: u0,
        active: false
      }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-coordinator (coordinator principal))
  (match (map-get? coordinators { coordinator: coordinator })
    coordinator-data (get verified coordinator-data)
    false
  )
)

(define-read-only (get-coordinator-info (coordinator principal))
  (map-get? coordinators { coordinator: coordinator })
)

(define-read-only (get-verification-request (request-id uint))
  (map-get? verification-requests { request-id: request-id })
)
