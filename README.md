# swift-url-routing-authentication

![Development Status](https://img.shields.io/badge/status-RETIRED-red.svg)

> # ⚰️ RETIRED — dissolved into swift-url-routing
>
> **This package is retired and unmaintained. Do not depend on it.**
>
> Its concerns were absorbed into
> [swift-url-routing](https://github.com/swift-foundations/swift-url-routing)
> per the ratified migration plan (Batch 7 item 2): the credential grammars
> stay at L2 (`swift-rfc-6750` / `swift-rfc-7617`), `Authorization` header
> matching moved to the **`URLRouting`** core, and the `Authentication.Client`
> composition moved to the **`URL Routing Foundation Integration`** leaf.
>
> See [Retirement record](#retirement-record) below for the rationale and the
> full migration table.
>
> The source below is retained for history only.

Bearer and Basic authentication routing for [swift-url-routing](https://github.com/swift-foundations/swift-url-routing).

## Overview

Two products:

- **`Authentication`** — the Foundation-free core. The `Authentication`
  namespace, its typed composition error, and bidirectional parser-printers
  for `Authorization: Bearer <token>` (RFC 6750 §2.1) and
  `Authorization: Basic <base64>` (RFC 7617 §2) over the durable
  `RFC_6750.Bearer` / `RFC_7617.Basic` credential value types. The import is
  self-contained: the routing vocabulary and the credential modules are
  re-exported.
- **`Authentication Foundation Integration`** — the client composition.
  `Authentication.Client` composes a base `Foundation.URL`, a credential, its
  Authorization-header router, and an API router into a live routing client
  or a `URLRequest` maker. Composition failures throw a typed error — an
  unparseable base URL or a credential that fails to print never silently
  produces unauthenticated requests. This product also vends the legacy
  `Authenticating` spelling (plus `BearerAuth` / `BasicAuth` and the
  non-throwing legacy initializers, which stop the program on composition
  misconfiguration) as a pure compatibility layer for existing consumers.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-url-routing-authentication.git", branch: "main")
]
```

Then add the product your target needs:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        // Credential routing only (no Foundation):
        .product(name: "Authentication", package: "swift-url-routing-authentication"),
        // Client composition + legacy Authenticating spellings:
        .product(name: "Authentication Foundation Integration", package: "swift-url-routing-authentication"),
    ]
)
```

## Quick Start

```swift
import Authentication_Foundation_Integration

let composition = try Authentication.Client(
    baseURL: URL(string: "https://api.example.com/v1")!,
    credential: try RFC_6750.Bearer(token: token),
    apiRouter: API.Router(),
    credentialRouter: RFC_6750.Bearer.Router(),
    client: { makeRequest in Client(makeRequest: makeRequest) }
)
```

Parsing and printing the `Authorization` header directly needs only the core:

```swift
import Authentication

var data = RFC_3986.URI.Request.Data()
try RFC_6750.Bearer.Router().print(credential, into: &data)
```

## Error Handling

Composing an `Authentication.Client` never degrades to a silently
unauthenticated request: both initializers throw the package's own typed
`Authentication.Error`, generic over the credential router's own failure.

```
Authentication.Error<Failure>
├── .baseURL(String)         // Base URL string failed to parse as RFC 3986 request data
└── .authorization(Failure)  // Credential failed to print into the Authorization header
```

`Failure` is the credential router's typed failure preserved through the
composition — `RFC_3986.URI.Routing.Error` for both `RFC_6750.Bearer.Router`
and `RFC_7617.Basic.Router`. The typed throw makes both failure modes
exhaustively catchable:

```swift
import Authentication_Foundation_Integration

let credential = try RFC_6750.Bearer(token: token)

do {
    let composition = try Authentication.Client(
        baseURL: URL(string: "https://api.example.com/v1")!,
        credential: credential,
        apiRouter: API.Router(),
        credentialRouter: RFC_6750.Bearer.Router(),
        client: { makeRequest in Client(makeRequest: makeRequest) }
    )
} catch .baseURL(let string) {
    // The base URL string failed RFC 3986 request-data parsing;
    // `string` is the offending absolute string.
} catch .authorization(let failure) {
    // The credential failed to print into the Authorization header;
    // `failure` is the credential router's own typed failure.
}
```

## License

Licensed under the [Apache License, Version 2.0](LICENSE.md).

## Retirement record

**This package is RETIRED.** Its concerns were absorbed into
[swift-url-routing](https://github.com/swift-foundations/swift-url-routing).
Nothing here is maintained; nothing here should be depended on.

### Why

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

### Migration

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

### Consumers

All consumers were migrated and published before this tombstone:

- `swift-stripe-live` — `cb8f23d`
- `swift-mailgun-live` — `2e27109`
- `swift-identities-types` — `e88d4ea`
- `swift-stripe` — `5bf73b9`

Verified dead at tombstone time: zero active consumers, corroborated by a
workspace-wide manifest census, the four published manifests, fresh
clean-room resolves across all four, and a full clean build of the
super-consumer with zero references compiled.

### Status of this repository

The source is **retained for history** — nothing was deleted. The repository
remains in place; any archival or visibility change is a separate, gated
action and has deliberately not been taken.
