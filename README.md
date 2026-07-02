# Swift RFC 5321

[![CI](https://github.com/swift-ietf/swift-rfc-5321/workflows/CI/badge.svg)](https://github.com/swift-ietf/swift-rfc-5321/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 5321: Simple Mail Transfer Protocol (SMTP) - email address validation and formatting standard.

## Overview

RFC 5321 defines the SMTP protocol and email address format used for electronic mail transmission. This package provides a pure Swift implementation of RFC 5321-compliant email address validation, parsing, and formatting, supporting both simple addresses and addresses with display names.

The package handles email address components including local-parts (before @), domains (after @), and optional display names, with full validation according to RFC 5321 specifications including length limits and character restrictions.

## Features

- **RFC 5321 Compliant**: Full validation of email addresses per SMTP specification
- **Display Name Support**: Parse and format addresses like "John Doe <john@example.com>"
- **Local Part Validation**: Support for both dot-atom and quoted-string formats
- **Domain Integration**: Built on RFC 1123 domain validation
- **Length Validation**: Enforces RFC 5321 length limits (64 chars for local-part, 254 total)
- **Type-Safe API**: Structured components with compile-time safety
- **Codable Support**: Seamless JSON encoding/decoding

## Installation

Add swift-rfc-5321 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-5321.git", from: "0.3.4")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 5321", package: "swift-rfc-5321")
    ]
)
```

## Quick Start

### Parsing Email Addresses

```swift
import RFC_5321

// Parse simple email address
let email = try EmailAddress("user@example.com")
print(email.localPart.stringValue) // "user"
print(email.domain.name) // "example.com"

// Parse with display name
let namedEmail = try EmailAddress("John Doe <john@example.com>")
print(namedEmail.displayName) // "John Doe"
print(namedEmail.address) // "john@example.com"

// Parse with quoted display name
let quotedEmail = try EmailAddress("\"Doe, John\" <john@example.com>")
print(quotedEmail.displayName) // "Doe, John"
```

### Creating Email Addresses

```swift
// Create from components
let localPart = try EmailAddress.LocalPart("support")
let domain = try Domain("example.com")
let email = EmailAddress(
    displayName: "Support Team",
    localPart: localPart,
    domain: domain
)

print(email.stringValue) // "Support Team <support@example.com>"
print(email.address) // "support@example.com"
```

### Validation

```swift
// Valid addresses
let valid1 = try EmailAddress("simple@example.com")
let valid2 = try EmailAddress("user.name@example.com")
let valid3 = try EmailAddress("\"user name\"@example.com")

// Invalid addresses throw errors
do {
    let invalid = try EmailAddress("no-at-sign")
} catch EmailAddress.Error.missingAtSign {
    print("Missing @ symbol")
}

do {
    let tooLong = try EmailAddress("verylonglocalpartthatexceedssixtyfourcharactersshouldnotbeallowed@example.com")
} catch EmailAddress.Error.localPartTooLong(let length) {
    print("Local part too long: \(length) characters")
}
```

## Usage

### EmailAddress Type

The core `EmailAddress` type provides structured access to email components:

```swift
public struct EmailAddress: Hashable, Sendable {
    public let displayName: String?
    public let localPart: LocalPart
    public let domain: Domain

    public init(displayName: String?, localPart: LocalPart, domain: Domain)
    public init(_ string: String) throws

    public var stringValue: String      // Full format with display name
    public var address: String     // Just the email address part
}
```

### LocalPart Type

The local-part (before @) supports both dot-atom and quoted formats:

```swift
public struct LocalPart: Hashable, Sendable {
    public init(_ string: String) throws
    public var stringValue: String
}
```

Valid local-part formats:
- **Dot-atom**: `user`, `user.name`, `first.last`
- **Quoted**: `"user name"`, `"user@name"`, `"special!chars"`

### Domain Type

Uses RFC 1123 domain validation (re-exported from swift-rfc-1123):

```swift
let domain = try Domain("mail.example.com")
```

### Validation Errors

```swift
public enum Error: Swift.Error {
    case missingAtSign
    case invalidDotAtom
    case invalidQuotedString
    case localPartTooLong(Int)
    case totalLengthExceeded(Int)
}
```

## Related Packages

### Dependencies
- [swift-rfc-1123](https://github.com/swift-ietf/swift-rfc-1123) - Domain name validation per RFC 1123

### Used By
- [swift-rfc-5322](https://github.com/swift-ietf/swift-rfc-5322) - Extended email address format (Internet Message Format)
- [swift-rfc-6531](https://github.com/swift-ietf/swift-rfc-6531) - Internationalized email addresses (SMTPUTF8)

## Requirements

- Swift 6.0+
- macOS 13.0+ / iOS 16.0+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
