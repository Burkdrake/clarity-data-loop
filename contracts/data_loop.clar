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
        total-revenue: uint
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
                    subscriber-count: u0,
                    total-revenue: u0
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
            )
            err-invalid-stream
        )
    )
)

(define-public (process-payment (stream-id uint))
    (let (
        (subscription (map-get? stream-subscriptions {stream-id: stream-id, subscriber: tx-sender}))
        (stream (map-get? data-streams stream-id))
    )
        (match subscription subscription-data
            (if (< (get expiry subscription-data) block-height)
                err-stream-expired
                (let (
                    (payment-amount (get payment-rate subscription-data))
                    (provider-amount (- payment-amount (* payment-amount (/ (var-get platform-fee-percent) u100))))
                )
                    (match stream stream-data
                        (begin
                            ;; Transfer payment to provider
                            (try! (stx-transfer? provider-amount tx-sender (get provider stream-data)))
                            
                            ;; Update provider earnings
                            (map-set providers (get provider stream-data)
                                (merge (unwrap-panic (map-get? providers (get provider stream-data)))
                                    {total-earnings: (+ (get total-earnings (unwrap-panic (map-get? providers (get provider stream-data)))) provider-amount)}
                                )
                            )
                            
                            ;; Update stream revenue
                            (map-set data-streams stream-id
                                (merge stream-data
                                    {total-revenue: (+ (get total-revenue stream-data) payment-amount)}
                                )
                            )
                            
                            ;; Update subscription
                            (map-set stream-subscriptions {stream-id: stream-id, subscriber: tx-sender}
                                (merge subscription-data
                                    {
                                        last-access: block-height,
                                        total-paid: (+ (get total-paid subscription-data) payment-amount)
                                    }
                                )
                            )
                            (ok true)
                        )
                        err-invalid-stream
                    )
                )
            )
            err-not-registered
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

(define-read-only (get-subscription-info (stream-id uint) (subscriber principal))
    (ok (map-get? stream-subscriptions {stream-id: stream-id, subscriber: subscriber}))
)
