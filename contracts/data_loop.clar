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
(define-constant err-invalid-price (err u108))

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
        paused: bool,
        subscriber-count: uint,
        total-revenue: uint,
        min-payment-rate: uint,
        created-at: uint,
        last-updated: uint
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
            (begin
                (print {event: "provider-registered", provider: tx-sender, name: name})
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
)

;; Stream Management
(define-public (create-stream (name (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (price uint) (min-payment-rate uint))
    (let (
        (provider (map-get? providers tx-sender))
        (stream-id (var-get next-stream-id))
    )
        (asserts! (is-some provider) err-not-registered)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (>= min-payment-rate u1) err-zero-payment-rate)
        
        (map-set data-streams stream-id {
            provider: tx-sender,
            name: name,
            description: description,
            category: category,
            price: price,
            active: true,
            paused: false,
            subscriber-count: u0,
            total-revenue: u0,
            min-payment-rate: min-payment-rate,
            created-at: block-height,
            last-updated: block-height
        })
        (print {event: "stream-created", stream-id: stream-id, provider: tx-sender})
        (var-set next-stream-id (+ stream-id u1))
        (ok stream-id)
    )
)

;; Stream Control Functions
(define-public (pause-stream (stream-id uint))
    (let ((stream (map-get? data-streams stream-id)))
        (match stream
            stream-data
            (begin
                (asserts! (is-eq tx-sender (get provider stream-data)) err-unauthorized)
                (map-set data-streams stream-id 
                    (merge stream-data {
                        paused: true,
                        last-updated: block-height
                    })
                )
                (print {event: "stream-paused", stream-id: stream-id})
                (ok true)
            )
            err-invalid-stream
        )
    )
)

(define-public (resume-stream (stream-id uint))
    (let ((stream (map-get? data-streams stream-id)))
        (match stream
            stream-data
            (begin
                (asserts! (is-eq tx-sender (get provider stream-data)) err-unauthorized)
                (map-set data-streams stream-id 
                    (merge stream-data {
                        paused: false,
                        last-updated: block-height
                    })
                )
                (print {event: "stream-resumed", stream-id: stream-id})
                (ok true)
            )
            err-invalid-stream
        )
    )
)

[Previous payment streaming functions remain unchanged]
