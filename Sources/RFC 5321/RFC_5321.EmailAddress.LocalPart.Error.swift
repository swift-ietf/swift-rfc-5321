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

// RFC_5321.EmailAddress.LocalPart.Error.swift
// swift-rfc-5321
//
// LocalPart-level validation errors

import Standard_Library_Extensions

extension RFC_5321.EmailAddress.LocalPart {
    /// Errors that can occur during local-part validation
    ///
    /// These represent atomic constraint violations at the local-part level,
    /// as defined by RFC 5321 Section 4.5.3.1.1.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Local-part is empty
        case empty

        /// Local-part exceeds maximum length of 64 octets
        case tooLong(_ length: Int)

        /// Local-part contains non-ASCII characters (RFC 5321 is ASCII-only)
        case nonASCII

        /// Invalid character in local-part
        case invalidCharacter(_ value: String, byte: Byte)

        /// Dot-atom format is invalid
        case invalidDotAtom(_ localPart: String)

        /// Quoted string format is invalid
        case invalidQuotedString(_ localPart: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_5321.EmailAddress.LocalPart.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Local-part cannot be empty"

        case .tooLong(let length):
            return "Local-part is too long (\(length) bytes, maximum 64)"

        case .nonASCII:
            return "Local-part must contain only ASCII characters (RFC 5321)"

        case .invalidCharacter(let value, let byte):
            return "Invalid byte 0x\(String(byte, radix: 16)) in local-part '\(value)'"

        case .invalidDotAtom(let localPart):
            return "Invalid dot-atom format in local-part '\(localPart)'"

        case .invalidQuotedString(let localPart):
            return "Invalid quoted string format in local-part '\(localPart)'"
        }
    }
}
