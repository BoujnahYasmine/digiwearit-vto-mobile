# Experience backend contract

The app currently uses real Firebase AI generation and explicitly simulated payment.
Build with --dart-define=DIGIWEARIT_API_URL=https://your-api.example to enable partner sign-in and email delivery. No endpoint is configured by default. Missing services never grant partner access or report delivery success.

POST /partner/sessions
Request: {"token":"professional token"}
Success: {"sessionToken":"short-lived opaque session credential","subscriptionActive":true,"expiresAt":"2026-12-01T12:00:00Z"}
Reject invalid, revoked, expired or unsubscribed accounts server-side. Rate-limit attempts. Never log professional tokens. The returned credential stays only in memory; restarting the app requires sign-in again.

POST /deliveries
Authorization: Bearer <partner session credential> when a shop session is active.
Request: {"email":"customer@example.com","resultId":"result identifier","imageBase64":"..."}
Success: {"status":"sent"} only after the email provider accepts the message. Enforce image size/type limits, address validation, authorization and idempotency by resultId plus email. Do not log photos, addresses or credentials. Define retention and deletion policies before deployment. No emails are sent by development tests.

## Production payment and generation

RevealGate tracks generation and payment independently in the demo UI. This client-side gate is NOT a production paywall. Do not enable real payments against this demo flow.

Before charging users, move AI execution and image storage to backend jobs. Create an authenticated job after photo acceptance, with separate generation_status and payment_status fields. Validate shop entitlement server-side for each job. Start hosted checkout for personal jobs and update payment_status only from a signature-verified, idempotent payment webhook. Release a short-lived result download URL only when generation is completed and payment is paid, or a shop entitlement is valid. Never send unpaid final image bytes to a personal client. Define failed-generation refund handling and job cancellation semantics.

Suggested endpoints: POST /jobs, GET /jobs/:id, POST /jobs/:id/checkout, POST /payment-webhooks, GET /jobs/:id/result, POST /jobs/:id/delivery. Use server-controlled prices; 29 DH in the UI is a demo price, not configured commerce pricing.

## Customer privacy

Terminer removes every customer route, clears Flutter's image cache, and returns to the home screen with no customer photo/result routes. A validated shop credential may remain for the next customer. Customer photos are not persisted by this flow. This clears visible app state; it does not guarantee forensic memory erasure or delete provider-held images. Backend retention/deletion must be implemented separately.

## Mobile sheets and feedback

Result delivery is email-only. No direct download or favorites are exposed. The result remains behind the email bottom sheet. After confirmed delivery, Continue opens the optional rating sheet. Passer permits completion without a rating. Terminer removes the entire customer navigation stack.

POST /feedback
Request: {"rating": 1, "comment": "optional, at most 150 characters"}
Validate integer rating 1–5 and comment length on the server. Authenticate/rate-limit submissions. No photo or email is included. Without DIGIWEARIT_API_URL, the UI explicitly labels feedback as a demonstration and does not transmit it. Configured-service failures keep the rating and comment available for retry.