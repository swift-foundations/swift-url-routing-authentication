//
//  BasicAuth.Router.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Foundation
import RFC_7617
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension RFC_7617.Basic {
    /// A URL router for HTTP Basic Authentication (RFC 7617).
    ///
    /// ``Router`` handles the parsing and printing of Basic Authentication headers
    /// in HTTP requests according to RFC 7617.
    ///
    /// ## Overview
    ///
    /// This router integrates with `swift-url-routing` to provide type-safe
    /// handling of Basic Authentication headers. It automatically encodes and
    /// decodes the `Authorization: Basic <credentials>` header.
    ///
    /// ## Example
    ///
    /// ```swift
    /// import Authenticating
    /// import AuthenticatingURLRouting
    ///
    /// // Create Basic auth credentials
    /// let auth = try BasicAuth(username: "api", password: "secret-key")
    ///
    /// // Use the router to create a request
    /// let router = BasicAuth.Router()
    /// let request = try router.request(
    ///     for: auth,
    ///     baseURL: URL(string: "https://api.example.com")!
    /// )
    /// ```
    ///
    /// ## Header Format
    ///
    /// The router generates headers in the format:
    /// ```
    /// Authorization: Basic <base64(username:password)>
    /// ```
    public struct Router: Parsing.ParserPrinter, Sendable {

        /// Creates a new Basic Authentication router.
        public init() {}

        /// The router body that handles the Authorization header.
        public var body: some URLRouting.Router<RFC_7617.Basic> {
            Headers {
                RFC_7230.Header.Field("Authorization") {
                    RFC_7617.Basic.ParserPrinter()
                }
            }
        }
    }
}

extension RFC_7617.Basic {
    /// A parser-printer for Basic Authentication header values.
    ///
    /// ``ParserPrinter`` handles the parsing and printing of the Basic Authentication
    /// credential string that appears after "Basic " in the Authorization header.
    ///
    /// ## Overview
    ///
    /// This parser-printer works with the base64-encoded credentials portion of
    /// the Basic Authentication header, converting between the string representation
    /// and the typed `RFC_7617.Basic` structure.
    ///
    /// ## Format
    ///
    /// - **Parsing**: Extracts credentials from "Basic <base64>" format
    /// - **Printing**: Generates base64-encoded "username:password" string
    public struct ParserPrinter: Parsing.ParserPrinter, Sendable {

        /// Creates a new Basic Authentication parser-printer.
        public init() {}

        /// The parser-printer body that handles credential encoding/decoding.
        public var body: some Parsing.ParserPrinter<Substring, RFC_7617.Basic> {
            "Basic "
            Parse(.string)
                .map(
                    .convert(
                        apply: { try? RFC_7617.Basic.parse(from: "Basic \($0)") },
                        unapply: { $0.encoded() }
                    )
                )

        }
    }
}
