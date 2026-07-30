//
//  Authentication Tests+Compatibility.swift
//  swift-url-routing-authentication — Authentication Foundation Integration Tests
//
//  Coverage for the legacy `Authenticating` compat spelling layer: the
//  census call-site shapes the four migrating consumers use today, plus the
//  crash-early contract on the non-throwing legacy initializers.
//

import Dependencies
import Foundation
import Testing
import URL_Routing_Foundation_Integration

@testable import Authentication_Foundation_Integration

extension Authentication.Test.Unit {
    @Test
    func `compat aliases resolve to the durable types`() throws {
        #expect(BearerAuth.self == RFC_6750.Bearer.self)
        #expect(BasicAuth.self == RFC_7617.Basic.self)

        // Compat `username:` label forwards to the spec-mirroring `userID:`.
        let basic = try BasicAuth(username: "u", password: "p")
        #expect(basic.userID == "u")
    }

    @Test
    func `Authenticating alias resolves to the native composition`() {
        typealias Legacy = Authenticating<
            BearerAuth, BearerAuth.Router, Authentication.Test.EchoRouter.Route,
            Authentication.Test.EchoRouter, Authentication.Test.MakeRequest
        >
        typealias Native = Authentication.Client<
            RFC_6750.Bearer, RFC_6750.Bearer.Router, Authentication.Test.EchoRouter.Route,
            Authentication.Test.EchoRouter, Authentication.Test.MakeRequest
        >
        #expect(Legacy.self == Native.self)
    }
}

extension Authentication.Test.Integration {
    @Test
    func `legacy five-label init composes auth, routers, and client builder`() throws {
        let auth = try BearerAuth(token: "tok")
        let wrapper = Authenticating(
            baseURL: URL(string: "https://api.example.com/v1")!,
            auth: auth,
            apiRouter: Authentication.Test.EchoRouter(),
            authRouter: BearerAuth.Router(),
            buildClient: { (client: URLRouting.Client<Authentication.Test.EchoRouter.Route>) in
                client
            }
        )

        // Legacy accessor spellings stay live.
        #expect(wrapper.auth.token == "tok")
        #expect(wrapper.baseURL.absoluteString == "https://api.example.com/v1")
        // ClientOutput is the composed client type fed to buildClient.
        #expect(
            type(of: wrapper.client)
                == Authenticating<
                    BearerAuth, BearerAuth.Router, Authentication.Test.EchoRouter.Route,
                    Authentication.Test.EchoRouter,
                    URLRouting.Client<Authentication.Test.EchoRouter.Route>
                >.ClientOutput.self
        )
    }

    @Test
    func `legacy makeRequest-shaped init constructs authenticated requests`() throws {
        let auth = try BasicAuth(username: "Aladdin", password: "open sesame")
        let wrapper = Authenticating(
            baseURL: URL(string: "https://api.example.com/v1")!,
            auth: auth,
            apiRouter: Authentication.Test.EchoRouter(),
            authRouter: BasicAuth.Router(),
            buildClient: { (makeRequest: @escaping Authentication.Test.MakeRequest) in makeRequest }
        )

        let request = try wrapper.client(Authentication.Test.EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        // RFC 7617 §2 example vector.
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
        )
    }

    @Test
    func `legacy Bearer init resolves the API router via @Dependency`() throws {
        let wrapper = try Authenticating<
            BearerAuth, BearerAuth.Router, Authentication.Test.EchoRouter.Route,
            Authentication.Test.EchoRouter, Authentication.Test.MakeRequest
        >(
            baseURL: URL(string: "https://api.example.com/v1")!,
            token: "tok123"
        ) { makeRequest in makeRequest }

        #expect(wrapper.auth.token == "tok123")

        let request = try wrapper.client(Authentication.Test.EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok123")
    }

    @Test
    func `composition is Sendable at the Dependency.Key Value shape`() throws {
        typealias Wrapper = Authenticating<
            BearerAuth, BearerAuth.Router, Authentication.Test.EchoRouter.Route,
            Authentication.Test.EchoRouter, Authentication.Test.MakeRequest
        >

        // Compile-time proof of the consumer shape: `Dependency.Key` requires
        // `Value: Sendable`, so this local key conforms ONLY if the
        // specialization is Sendable.
        enum WrapperKey: Dependency.Key {
            typealias Value = Wrapper
            static var liveValue: Wrapper {
                // `Dependency.Key.liveValue` is non-throwing; the literal
                // baseURL/token below are fixed compile-time constants that
                // cannot fail `Wrapper.init`, so there is no error to propagate.
                // swiftlint:disable:next force_try
                try! Wrapper(
                    baseURL: URL(string: "https://api.example.com/v1")!,
                    token: "tok"
                ) { makeRequest in makeRequest }
            }
        }

        func requireSendable<T: Sendable>(_ value: T) -> T { value }

        let wrapper = requireSendable(WrapperKey.liveValue)
        #expect(wrapper.auth.token == "tok")

        // Behavioral: the stored client still produces authenticated requests.
        let request = try wrapper.client(Authentication.Test.EchoRouter.Route())
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }
}

extension Authentication.Test.`Edge Case` {
    @Test
    func `legacy Bearer init throws the typed credential error on an invalid token`() {
        #expect(throws: RFC_6750.Bearer.Error.self) {
            _ = try Authenticating<
                BearerAuth, BearerAuth.Router, Authentication.Test.EchoRouter.Route,
                Authentication.Test.EchoRouter, Authentication.Test.MakeRequest
            >(
                baseURL: URL(string: "https://api.example.com/v1")!,
                token: ""
            ) { makeRequest in makeRequest }
        }
    }

    @Test
    func `legacy five-label init stops the program when the credential fails to print`() async {
        await #expect(processExitsWith: .failure) {
            _ = Authenticating(
                baseURL: URL(string: "https://api.example.com/v1")!,
                auth: try BearerAuth(token: "tok"),
                apiRouter: Authentication.Test.EchoRouter(),
                authRouter: Authentication.Test.FailingRouter(),
                buildClient: { (client: URLRouting.Client<Authentication.Test.EchoRouter.Route>) in
                    client
                }
            )
        }
    }

    @Test
    func `legacy makeRequest init stops the program when the credential fails to print`() async {
        await #expect(processExitsWith: .failure) {
            _ = Authenticating(
                baseURL: URL(string: "https://api.example.com/v1")!,
                auth: try BearerAuth(token: "tok"),
                apiRouter: Authentication.Test.EchoRouter(),
                authRouter: Authentication.Test.FailingRouter(),
                buildClient: { (makeRequest: @escaping Authentication.Test.MakeRequest) in
                    makeRequest
                }
            )
        }
    }
}
