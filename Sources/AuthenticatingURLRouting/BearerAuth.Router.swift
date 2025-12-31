//
//  BearerAuth.Router.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 03/01/2025.
//

import Foundation
import RFC_6750
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension RFC_6750.Bearer {
    /// A URL router for OAuth 2.0 Bearer Token Authentication (RFC 6750).
    ///
    /// ``Router`` handles the parsing and printing of Bearer token headers
    /// in HTTP requests according to RFC 6750.
    ///
    /// ## Overview
    ///
    /// This router integrates with `swift-url-routing` to provide type-safe
    /// handling of Bearer authentication headers. It automatically encodes and
    /// decodes the `Authorization: Bearer <token>` header.
    ///
    /// ## Example
    ///
    /// ```swift
    /// import Authenticating
    /// import AuthenticatingURLRouting
    ///
    /// // Create Bearer auth token
    /// let auth = BearerAuth(token: "your-api-token")
    ///
    /// // Use the router to create a request
    /// let router = BearerAuth.Router()
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
    /// Authorization: Bearer <token>
    /// ```
    public struct Router: Parsing.ParserPrinter, Sendable {

        /// Creates a new Bearer Authentication router.
        public init() {}

        /// The router body that handles the Authorization header.
        public var body: some URLRouting.Router<RFC_6750.Bearer> {
            Headers {
                RFC_7230.Header.Field("Authorization") {
                    RFC_6750.Bearer.ParserPrinter()
                }
            }
        }
    }
}

extension RFC_6750.Bearer {
    /// A parser-printer for Bearer token header values.
    ///
    /// ``ParserPrinter`` handles the parsing and printing of the Bearer token
    /// that appears after "Bearer " in the Authorization header.
    ///
    /// ## Overview
    ///
    /// This parser-printer works with the token portion of the Bearer Authentication
    /// header, converting between the string representation and the typed
    /// `RFC_6750.Bearer` structure.
    ///
    /// ## Format
    ///
    /// - **Parsing**: Extracts token from "Bearer <token>" format
    /// - **Printing**: Outputs the raw token string
    public struct ParserPrinter: Parsing.ParserPrinter, Sendable {

        /// Creates a new Bearer token parser-printer.
        public init() {}

        /// The parser-printer body that handles token extraction/insertion.
        public var body: some Parsing.ParserPrinter<Substring, RFC_6750.Bearer> {
            "Bearer "
            Parse(.string)
                .map(
                    .convert(
                        apply: { try? RFC_6750.Bearer.parse(from: "Bearer \($0)") },
                        unapply: \.token
                    )
                )

        }
    }
}
