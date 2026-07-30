//
//  Authenticating.Compatibility.swift
//  swift-url-routing-authentication — Authentication Foundation Integration
//
//  Compat spellings for the legacy `Authenticating` product surface
//  (swift-url-routing) and the retired `swift-authenticating` lineage.
//  A pure spelling layer over the native `Authentication.Client`
//  composition — no semantics of its own beyond the deliberate crash-early
//  contract on the non-throwing legacy initializers: a compose failure on
//  those is a configuration programmer error and stops the program instead
//  of silently producing unauthenticated requests.
//

public import Authentication
public import Dependencies
public import Foundation
public import RFC_6750
public import RFC_7617
public import URLRouting
public import URL_Routing_Foundation_Integration

#if canImport(FoundationNetworking)
    public import FoundationNetworking
#endif

/// Legacy gerund spelling of the native ``Authentication/Client``
/// composition. New code spells the native name.
public typealias Authenticating<Auth, AuthRouter, API, APIRouter, Client> =
    Authentication.Client<Auth, AuthRouter, API, APIRouter, Client>
where
    AuthRouter: Parser.Bidirectional,
    AuthRouter.Input == RFC_3986.URI.Request.Data,
    AuthRouter.Output == Auth,
    APIRouter: Parser.Bidirectional,
    APIRouter.Input == RFC_3986.URI.Request.Data,
    APIRouter.Output == API

/// Compat spelling for RFC 6750 Bearer credentials.
///
/// The durable type is ``RFC_6750/Bearer``; `BearerAuth` (and
/// `BearerAuth.Router`) is the drop-in name for legacy consumers.
public typealias BearerAuth = RFC_6750.Bearer

/// Compat spelling for RFC 7617 Basic credentials.
///
/// The durable type is ``RFC_7617/Basic``; `BasicAuth` (and
/// `BasicAuth.Router`) is the drop-in name for legacy consumers.
public typealias BasicAuth = RFC_7617.Basic

extension RFC_7617.Basic {
    /// Compat initializer mirroring the legacy `BasicAuth(username:password:)`
    /// label.
    ///
    /// Forwards to the spec-mirroring ``RFC_7617/Basic/init(userID:password:)``
    /// — the durable RFC 7617 surface uses `userID`; `username` is the compat
    /// spelling only.
    public init(username: String, password: String) throws(RFC_7617.Basic.Error) {
        try self.init(userID: username, password: password)
    }
}

extension Authentication.Client {
    /// Legacy spelling of ``Live``.
    public typealias ClientOutput = Live

    /// Legacy accessor spelling of ``credential``.
    public var auth: Credential { credential }

    /// Legacy accessor spelling of ``credentialRouter``.
    public var authRouter: CredentialRouter { credentialRouter }

    /// Legacy non-throwing composition — the drop-in `Authenticating` shape.
    ///
    /// A compose failure here is a configuration programmer error: the
    /// initializer stops the program with a descriptive message rather than
    /// silently degrading to an unauthenticated client. Prefer the native
    /// typed-throwing
    /// ``init(baseURL:credential:apiRouter:credentialRouter:client:)``.
    public init(
        baseURL: Foundation.URL,
        auth: Credential,
        apiRouter: APIRouter,
        authRouter: CredentialRouter,
        buildClient: (Live) -> Consumer
    ) {
        do {
            try self.init(
                baseURL: baseURL,
                credential: auth,
                apiRouter: apiRouter,
                credentialRouter: authRouter,
                client: buildClient
            )
        } catch {
            preconditionFailure(
                "Authenticating: composition failed for base URL '\(baseURL.absoluteString)': \(error)"
            )
        }
    }
}

// MARK: - makeRequest-shaped buildClient (legacy five-label overload)

extension Authentication.Client where APIRouter: Sendable {
    /// Legacy non-throwing request-maker composition — hands `buildClient` a
    /// `makeRequest` closure instead of a live client.
    ///
    /// Same crash-early contract as the legacy five-label initializer; prefer
    /// the native typed-throwing request-maker
    /// ``init(baseURL:credential:apiRouter:credentialRouter:client:)``.
    public init(
        baseURL: Foundation.URL,
        auth: Credential,
        apiRouter: APIRouter,
        authRouter: CredentialRouter,
        buildClient: ((@escaping @Sendable (API) throws -> URLRequest)) -> Consumer
    ) {
        do {
            try self.init(
                baseURL: baseURL,
                credential: auth,
                apiRouter: apiRouter,
                credentialRouter: authRouter,
                client: buildClient
            )
        } catch {
            preconditionFailure(
                "Authenticating: composition failed for base URL '\(baseURL.absoluteString)': \(error)"
            )
        }
    }
}

// MARK: - Bearer token convenience

extension Authentication.Client
where
    Credential == RFC_6750.Bearer,
    CredentialRouter == RFC_6750.Bearer.Router,
    APIRouter: Sendable,
    APIRouter: Dependency.Key,
    APIRouter.Value == APIRouter
{
    /// Composes a Bearer-authenticated wrapper from a base URL and a token
    /// string.
    ///
    /// The token constructs the ``RFC_6750/Bearer`` credential (throwing its
    /// typed error on an invalid token), the credential router defaults to
    /// ``RFC_6750/Bearer/Router``, and the API router resolves via
    /// `@Dependency(APIRouter.self)` — consumers declare their
    /// `API.Router: Dependency.Key` conformance to supply it.
    ///
    /// A composition failure past a valid credential is a configuration
    /// programmer error and stops the program.
    public init(
        baseURL: Foundation.URL,
        token: String,
        buildClient: ((@escaping @Sendable (API) throws -> URLRequest)) -> Consumer
    ) throws(RFC_6750.Bearer.Error) {
        @Dependency(APIRouter.self) var apiRouter
        let credential = try RFC_6750.Bearer(token: token)
        do {
            try self.init(
                baseURL: baseURL,
                credential: credential,
                apiRouter: apiRouter,
                credentialRouter: RFC_6750.Bearer.Router(),
                client: buildClient
            )
        } catch {
            preconditionFailure(
                "Authenticating: composition failed for base URL '\(baseURL.absoluteString)': \(error)"
            )
        }
    }
}
