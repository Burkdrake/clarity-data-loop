;; DataLoop Contract
;; Enables decentralized real-time data sharing

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-stream (err u104))

;; Data Maps
(define-map providers
    principal
    {
        name: (string-ascii 64),
        verified: bool,
        rating: uint,
        stream-count: uint
    }
)

(define-map data-streams
    uint
    {
        provider: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        category: (string-ascii 32),
        price: uint,
        active: bool,
        subscriber-count: uint
    }
)

(define-map stream-subscriptions
    {stream-id: uint, subscriber: principal}
    {
        active: bool,
        expiry: uint,
        last-access: uint
    }
)

(define-map stream-data
    {stream-id: uint, timestamp: uint}
    {
        data-point: (string-utf8 256),
        verified: bool
    }
)

;; Data Variables 
(define-data-var next-stream-id uint u0)

;; Provider Management
(define-public (register-provider (name (string-ascii 64)))
    (let ((provider-exists (map-get? providers tx-sender)))
        (if (is-some provider-exists)
            err-already-registered
            (ok (map-set providers tx-sender {
                name: name,
                verified: false,
                rating: u0,
                stream-count: u0
            }))
        )
    )
)

;; Stream Management
(define-public (create-stream (name (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (price uint))
    (let (
        (provider (map-get? providers tx-sender))
        (stream-id (var-get next-stream-id))
    )
        (if (is-none provider)
            err-not-registered
            (begin
                (map-set data-streams stream-id {
                    provider: tx-sender,
                    name: name,
                    description: description,
                    category: category,
                    price: price,
                    active: true,
                    subscriber-count: u0
                })
                (var-set next-stream-id (+ stream-id u1))
                (ok stream-id)
            )
        )
    )
)

;; Data Publishing
(define-public (publish-data (stream-id uint) (data-point (string-utf8 256)))
    (let ((stream (map-get? data-streams stream-id)))
        (if (and
            (is-some stream)
            (is-eq (get provider (unwrap-panic stream)) tx-sender)
        )
            (ok (map-set stream-data 
                {stream-id: stream-id, timestamp: block-height}
                {data-point: data-point, verified: true}
            ))
            err-unauthorized
        )
    )
)

;; Subscription Management
(define-public (subscribe-to-stream (stream-id uint))
    (let ((stream (map-get? data-streams stream-id)))
        (if (is-some stream)
            (ok (map-set stream-subscriptions 
                {stream-id: stream-id, subscriber: tx-sender}
                {active: true, expiry: (+ block-height u1440), last-access: block-height}
            ))
            err-invalid-stream
        )
    )
)

;; Read Functions
(define-read-only (get-provider-info (provider principal))
    (ok (map-get? providers provider))
)

(define-read-only (get-stream-info (stream-id uint))
    (ok (map-get? data-streams stream-id))
)

(define-read-only (get-stream-data (stream-id uint) (timestamp uint))
    (ok (map-get? stream-data {stream-id: stream-id, timestamp: timestamp}))
)