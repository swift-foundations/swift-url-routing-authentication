# TOMBSTONE — swift-url-routing-authentication

**This package is RETIRED.** Its concerns were absorbed into
[swift-url-routing](https://github.com/swift-foundations/swift-url-routing).
Nothing here is maintained; nothing here should be depended on.

## Why

Per the ratified url-routing stack migration plan, **Batch 7 item 2**, this
package failed the one-concern-per-package test: it held no residual domain
concept of its own. Every part of it decomposed cleanly onto an existing
owner:

| Concern | New home |
|---|---|
| Credential grammars (`RFC_6750.Bearer`, `RFC_7617.Basic`) | Already at L2 — `swift-rfc-6750` / `swift-rfc-7617`, consumed as vended |
| `Authorization` header matching (`Bearer.Router`, `Basic.Router`) | **`URLRouting` core** — the Router Header mission target |
| `Authentication.Client` composition (`Foundation.URL` / `URLRequest`) | **`URL Routing Foundation Integration`** — swift-url-routing's FI leaf |

With the grammars already owned at L2, the matching belonging to the router,
and the URL bridging belonging to the Foundation Integration leaf, no concern
remained for this package to own.

## Migration

The absorbed surface landed in swift-url-routing at `5bd127ba`.

| Retired spelling | Replacement |
|---|---|
| `import Authentication_Foundation_Integration` | `import URL_Routing_Foundation_Integration` |
| `.product(name: "Authentication Foundation Integration", package: "swift-url-routing-authentication")` | `.product(name: "URL Routing Foundation Integration", package: "swift-url-routing")` |
| `BearerAuth` | `RFC_6750.Bearer` |
| `BasicAuth` | `RFC_7617.Basic` |
| `BearerAuth.Router` / `BasicAuth.Router` | `RFC_6750.Bearer.Router` / `RFC_7617.Basic.Router` (in `URLRouting`) |
| `Authenticating<Auth, AuthRouter, API, APIRouter, Client>` | `Authentication.Client<Credential, CredentialRouter, API, APIRouter, Consumer>` |
| `URLRequestData` | `RFC_3986.URI.Request.Data` |
| `init(baseURL:auth:apiRouter:authRouter:buildClient:)` (crash-early) | `init(baseURL:credential:apiRouter:credentialRouter:client:)` (typed-throwing) |

The `Authenticating` compat spelling layer was deleted with **no
replacement** — the modernization posture is final-state code, so consumers
migrated in-arc rather than through a deprecation window. The legacy
non-throwing initializers' crash-early contract became honest typed throws.

## Consumers

All consumers were migrated and published before this tombstone:

- `swift-stripe-live` — `cb8f23d`
- `swift-mailgun-live` — `2e27109`
- `swift-identities-types` — `e88d4ea`
- `swift-stripe` — `5bf73b9`

Verified dead at tombstone time: zero active consumers, corroborated by a
workspace-wide manifest census, the four published manifests, fresh
clean-room resolves across all four, and a full clean build of the
super-consumer with zero references compiled.

## Status of this repository

The source is **retained for history** — nothing was deleted. The repository
remains in place; any archival or visibility change is a separate, gated
action and has deliberately not been taken.
