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
> See **[TOMBSTONE.md](TOMBSTONE.md)** for the rationale and the full
> migration table (`BearerAuth` → `RFC_6750.Bearer`, `Authenticating<…>` →
> `Authentication.Client<…>`, `URLRequestData` → `RFC_3986.URI.Request.Data`,
> and the typed-throwing initializers).
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
