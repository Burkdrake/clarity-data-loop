;; DataLoop Contract
;; Enables decentralized real-time data sharing

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-registered (err u101)) 
(define-constant err-already-registered (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-stream (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-stream-expired (err u106))
(define-constant err-zero-payment-rate (err u107))

;; Data Maps
(define-map providers
    principal
    {
        name: (string-ascii 64),
        verified: bool,
        rating: uint,
        stream-count: uint,
        total-earnings: uint
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
        subscriber-count: uint,
        total-revenue: uint,
        min-payment-rate: uint
    }
)

(define-map stream-subscriptions
    {stream-id: uint, subscriber: principal}
    {
        active: bool,
        expiry: uint,
        last-access: uint,
        total-paid: uint,
        payment-rate: uint
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
(define-data-var platform-fee-percent uint u5)

;; Provider Management
(define-public (register-provider (name (string-ascii 64)))
    (let ((provider-exists (map-get? providers tx-sender)))
        (if (is-some provider-exists)
            err-already-registered
            (ok (map-set providers tx-sender {
                name: name,
                verified: false,
                rating: u0,
                stream-count: u0,
                total-earnings: u0
            }))
        )
    )
)

;; Stream Management
(define-public (create-stream (name (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (price uint) (min-payment-rate uint))
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
                    subscriber-count: u0,
                    total-revenue: u0,
                    min-payment-rate: min-payment-rate
                })
                (var-set next-stream-id (+ stream-id u1))
                (ok stream-id)
            )
        )
    )
)

;; Payment Streaming
(define-public (start-payment-stream (stream-id uint) (payment-rate uint))
    (let (
        (stream (map-get? data-streams stream-id))
        (subscription-key {stream-id: stream-id, subscriber: tx-sender})
    )
        (match stream
            stream-data
            (if (< payment-rate (get min-payment-rate stream-data))
                err-zero-payment-rate
                (begin
                    (map-set stream-subscriptions subscription-key
                        {
                            active: true,
                            expiry: (+ block-height u1440),
                            last-access: block-height,
                            total-paid: u0,
                            payment-rate: payment-rate
                        }
                    )
                    (ok true)
                ))
            err-invalid-stream
        )
    )
)

[Rest of contract remains unchanged]
