//
//  Authentication.swift
//  swift-url-routing-authentication — Authentication
//

/// The namespace for HTTP-authentication routing compositions.
///
/// `Authentication` composes the RFC credential value types
/// (``RFC_6750/Bearer``, ``RFC_7617/Basic``) with `URLRouting`
/// parser-printers: the credential routers parse and print the
/// `Authorization` request header, and ``Authentication/Error`` types the
/// composition failures. The `Authentication Foundation Integration` product
/// adds the client composition over `Foundation.URL` / `URLRequest`.
public enum Authentication {}
