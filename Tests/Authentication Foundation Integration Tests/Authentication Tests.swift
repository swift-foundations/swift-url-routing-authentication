//
//  Authentication Tests.swift
//  swift-url-routing-authentication — Authentication Foundation Integration Tests
//
//  Native-surface coverage for the Authentication.Client composition. The
//  Test subdomain hangs off the non-generic parent namespace because the
//  composition type is generic.
//

import Dependencies
import Foundation
import Testing
import URL_Routing_Foundation_Integration

@testable import Authentication_Foundation_Integration

extension Authentication {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        /// A trivial API router exercising the composition.
        struct EchoRouter: Parser.Bidirectional, Sendable {
            typealias Input = RFC_3986.URI.Request.Data
            typealias Buffer = Input
            typealias Output = Route
            typealias Failure = RFC_3986.URI.Routing.Error

            struct Route: Equatable, Sendable {}

            func parse(_ input: inout Input) throws(Failure) -> Output { Route() }
            func serialize(_ output: Output, into input: inout Buffer) throws(Failure) {}
        }

        /// A credential router whose serialization always refuses — drives the
        /// compose-failure paths.
        struct FailingRouter: Parser.Bidirectional {
            typealias Input = RFC_3986.URI.Request.Data
            typealias Buffer = Input
            typealias Output = RFC_6750.Bearer

            struct PrintRefused: Swift.Error {}
            typealias Failure = PrintRefused

            func parse(_ input: inout Input) throws(PrintRefused) -> RFC_6750.Bearer {
                throw PrintRefused()
            }
            func serialize(
                _ output: RFC_6750.Bearer,
                into input: inout Buffer
            ) throws(PrintRefused) {
                throw PrintRefused()
            }
        }

        /// Binding `Consumer` to the request-maker function type lets the
        /// tests drive the closure the composition hands to `client`.
        typealias MakeRequest = @Sendable (EchoRouter.Route) throws -> URLRequest
    }
}

// MARK: - EchoRouter dependency registration
// Same file as the declaration: the conformance implies Sendable, which must
// be declared in the struct's own source file.

extension Authentication.Test.EchoRouter: Dependency.Key {
    static var liveValue: Self { Self() }
}

extension Authentication.Test.Unit {
    @Test
    func `canonical init stores the composition and builds a live client`() throws {
        let credential = try RFC_6750.Bearer(token: "tok")
        let composition = try Authentication.Client(
            baseURL: URL(string: "https://api.example.com/v1")!,
            credential: credential,
            apiRouter: Authentication.Test.EchoRouter(),
            credentialRouter: RFC_6750.Bearer.Router(),
            client: { (client: URLRouting.Client<Authentication.Test.EchoRouter.Route>) in client }
        )

        #expect(composition.credential.token == "tok")
        #expect(composition.baseURL.absoluteString == "https://api.example.com/v1")
    }

    @Test
    func `request-maker init prints the Authorization header into every request`() throws {
        let credential = try RFC_7617.Basic(userID: "Aladdin", password: "open sesame")
        let composition = try Authentication.Client(
            baseURL: URL(string: "https://api.example.com/v1")!,
            credential: credential,
            apiRouter: Authentication.Test.EchoRouter(),
            credentialRouter: RFC_7617.Basic.Router(),
            client: { (makeRequest: @escaping Authentication.Test.MakeRequest) in makeRequest }
        )

        let request = try composition.client(Authentication.Test.EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        // RFC 7617 §2 example vector, printed by the credential router into
        // every request.
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
        )
    }
}

extension Authentication.Test.`Edge Case` {
    @Test
    func `compose failure throws the typed authorization error`() throws {
        let credential = try RFC_6750.Bearer(token: "tok")
        #expect(throws: Authentication.Error<Authentication.Test.FailingRouter.PrintRefused>.self) {
            _ = try Authentication.Client(
                baseURL: URL(string: "https://api.example.com/v1")!,
                credential: credential,
                apiRouter: Authentication.Test.EchoRouter(),
                credentialRouter: Authentication.Test.FailingRouter(),
                client: { (client: URLRouting.Client<Authentication.Test.EchoRouter.Route>) in
                    client
                }
            )
        }
    }
}

extension Authentication.Test.Integration {
    @Test
    func `Bearer credential composes an authenticated request end-to-end`() throws {
        let composition = try Authentication.Client(
            baseURL: URL(string: "https://api.example.com/v1")!,
            credential: try RFC_6750.Bearer(token: "tok123"),
            apiRouter: Authentication.Test.EchoRouter(),
            credentialRouter: RFC_6750.Bearer.Router(),
            client: { (makeRequest: @escaping Authentication.Test.MakeRequest) in makeRequest }
        )

        let request = try composition.client(Authentication.Test.EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok123")
    }
}
