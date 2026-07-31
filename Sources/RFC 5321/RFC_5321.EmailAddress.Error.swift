// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// RFC_5321.EmailAddress.Error.swift
// swift-rfc-5321
//
// EmailAddress-level validation errors

public import RFC_1123
import Standard_Library_Extensions

extension RFC_5321.EmailAddress {
    /// Errors that can occur during email address validation
    ///
    /// These represent compositional constraint violations at the email address level,
    /// as defined by RFC 5321.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Email address is missing @ sign
        case missingAtSign

        /// Total length exceeds maximum of 254 octets
        case totalLengthExceeded(_ length: Int)

        /// Local-part validation failed
        case invalidLocalPart(_ error: LocalPart.Error)

        /// Domain validation failed
        case invalidDomain(_ error: RFC_1123.Domain.Error)

        /// Angle-bracket format (`[display-name] <local@domain>`) has an
        /// opening `<` with no `>` after it (fable-448 F-001).
        case unterminatedAngleBracket

        /// Display name contains a byte outside the 7-bit ASCII range
        /// (fable-448 F-004). RFC 5321 mailboxes are ASCII-only; a non-ASCII
        /// display name must be RFC 2047-encoded upstream.
        case invalidDisplayName(_ name: String, byte: Byte)
    }
}

// MARK: - CustomStringConvertible

extension RFC_5321.EmailAddress.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingAtSign:
            return "Email address must contain @ sign"

        case .totalLengthExceeded(let length):
            return "Email address is too long (\(length) bytes, maximum 254)"

        case .invalidLocalPart(let error):
            return "Invalid local-part: \(error)"

        case .invalidDomain(let error):
            return "Invalid domain: \(error)"

        case .unterminatedAngleBracket:
            return "Email address has an opening '<' with no matching '>'"

        case .invalidDisplayName(let name, let byte):
            return
                "Display name '\(name)' contains non-ASCII byte 0x\(String(byte.underlying, radix: 16)) (RFC 5321 requires ASCII-only mailboxes; RFC 2047-encode non-ASCII names upstream)"
        }
    }
}
