# DataLoop

A blockchain platform for sharing real-time data streams with integrated payment streaming capabilities.

## Features

- Provider registration and verification
- Stream creation and management 
- Access control and permissions
- Data publishing and retrieval
- Subscription management
- Usage tracking and analytics
- Payment streaming with automatic payments
- Revenue tracking and platform fees
- Provider earnings management

## Payment Streaming

The platform now supports continuous payment streams for data access:

- Subscribers can initialize payment streams with custom payment rates
- Automatic payment processing based on stream usage
- Platform fee handling and distribution
- Revenue tracking for providers and individual streams
- Built-in payment expiry and renewal mechanisms

## Getting Started

The contract can be deployed using Clarinet. See tests for example usage.

### Payment Stream Example

```clarity
;; Start a payment stream
(contract-call? .data-loop start-payment-stream stream-id payment-rate)

;; Process periodic payments
(contract-call? .data-loop process-payment stream-id)
```

## Revenue Tracking

Providers can monitor their earnings and stream performance:

- Total earnings per provider
- Revenue per stream
- Platform fee calculations
- Payment history and subscription analytics
