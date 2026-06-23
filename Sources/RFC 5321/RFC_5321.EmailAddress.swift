//
//  RFC_5321.EmailAddress.swift
//  swift-rfc-5321
//
//  EmailAddress implementation
//

import ASCII_Serializer_Primitives
import INCITS_4_1986
public import RFC_1123
import Standard_Library_Extensions

extension RFC_5321 {
    /// RFC 5321 compliant email address (basic SMTP format)
    ///
    /// An email address consists of a local-part, @ sign, and domain.
    /// Optionally includes a display name in angle-bracket format.
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321:
    /// - Maximum total length: 254 octets (local-part + @ + domain)
    /// - Local-part maximum: 64 octets
    /// - Domain maximum: 255 octets
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try RFC_5321.EmailAddress(ascii: "user@example.com".utf8)
    /// ```
    public struct EmailAddress: Hashable, Sendable, Codable {
        /// The display name, if present
        public let displayName: String?

        /// The local part (before @)
        public let localPart: LocalPart

        /// The domain part (after @)
        public let domain: RFC_1123.Domain

        /// Creates email address WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(
            __unchecked: Void,
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) {
            self.displayName = displayName
            self.localPart = localPart
            self.domain = domain
        }

        /// Initialize with validated components
        ///
        /// This is the canonical initializer. Components are already validated.
        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) throws(Error) {
            self.displayName = displayName?.trimming(.ascii.whitespaces)
            self.localPart = localPart
            self.domain = domain

            // Check total length
            let addressLength = localPart.value.count + 1 + domain.name.count  // +1 for @
            guard addressLength <= Limits.maxTotalLength else {
                throw Error.totalLengthExceeded(addressLength)
            }
        }
    }
}

// MARK: - Byte-Level Parsing (Binary.ASCII.Serializable)

extension RFC_5321.EmailAddress: Binary.ASCII.Serializable {
    /// Initialize from ASCII bytes, validating RFC 5321 rules
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5321.EmailAddress (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [UInt8] (UTF-8) → EmailAddress
    /// ```
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321:
    /// - Must contain @ sign separating local-part and domain
    /// - Maximum total length: 254 octets
    /// - Supports display name in angle brackets
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try RFC_5321.EmailAddress(ascii: "user@example.com".utf8)
    /// ```
    public init<Bytes: Collection>(ascii bytes: Bytes, in _: Void = ()) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        // Check for angle bracket format: [display-name] <local@domain>
        if let openAngle = bytes.firstIndex(of: ASCII.Code.lessThanSign.byte),
            let closeAngle = bytes.firstIndex(of: ASCII.Code.greaterThanSign.byte) {

            // Extract display name if present
            let displayName: String?
            if openAngle > bytes.startIndex {
                let nameBytes = bytes[bytes.startIndex..<openAngle]
                var name = String(decoding: nameBytes, as: UTF8.self).trimming(.ascii.whitespaces)

                // Remove quotes and unescape if present
                if name.hasPrefix("\"") && name.hasSuffix("\"") {
                    let withoutQuotes = String(name.dropFirst().dropLast())
                    name = withoutQuotes.replacing("\\\"", with: "\"")
                        .replacing("\\\\", with: "\\")
                }

                displayName = name.isEmpty ? nil : name
            } else {
                displayName = nil
            }

            // Extract email address between angle brackets
            let emailBytes = bytes[bytes.index(after: openAngle)..<closeAngle]

            // Find @ sign
            guard let atIndex = emailBytes.firstIndex(of: ASCII.Code.commercialAt.byte) else {
                throw Error.missingAtSign
            }

            // Extract local-part
            let localBytes = emailBytes[emailBytes.startIndex..<atIndex]
            let localPart: LocalPart
            do {
                localPart = try LocalPart(ascii: localBytes)
            } catch let error {
                throw Error.invalidLocalPart(error)
            }

            // Extract domain
            let domainBytes = emailBytes[emailBytes.index(after: atIndex)...]
            let domain: RFC_1123.Domain
            do {
                domain = try RFC_1123.Domain(ascii: domainBytes)
            } catch let error {
                throw Error.invalidDomain(error)
            }

            try self.init(displayName: displayName, localPart: localPart, domain: domain)
        } else {
            // Parse as bare email address: local@domain
            guard let atIndex = bytes.firstIndex(of: ASCII.Code.commercialAt.byte) else {
                throw Error.missingAtSign
            }

            // Extract local-part
            let localBytes = bytes[bytes.startIndex..<atIndex]
            let localPart: LocalPart
            do {
                localPart = try LocalPart(ascii: localBytes)
            } catch let error {
                throw Error.invalidLocalPart(error)
            }

            // Extract domain
            let domainBytes = bytes[bytes.index(after: atIndex)...]
            let domain: RFC_1123.Domain
            do {
                domain = try RFC_1123.Domain(ascii: domainBytes)
            } catch let error {
                throw Error.invalidDomain(error)
            }

            try self.init(displayName: nil, localPart: localPart, domain: domain)
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

// MARK: - ASCII Serialization

extension RFC_5321.EmailAddress {
    /// Serialize email address to ASCII bytes
    ///
    /// Required implementation for `Binary.ASCII.RawRepresentable` to avoid
    /// infinite recursion (since `rawValue` is synthesized from serialization).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii email: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if let displayName = email.displayName {
            // Check if display name needs quoting (RFC 5322 specials)
            let needsQuoting = displayName.utf8.contains { byte in
                // Non-ASCII, or any non-alphanumeric/whitespace char, forces quoting.
                guard let code = try? ASCII.Code(Byte(byte)) else { return true }
                return !code.isLetter && !code.isDigit && !code.isWhitespace
            }

            if needsQuoting {
                buffer.append(ASCII.Code.quotationMark)
                for char in displayName.utf8 {
                    let byte = Byte(char)
                    if byte == ASCII.Code.quotationMark.byte || byte == ASCII.Code.reverseSolidus.byte {
                        buffer.append(ASCII.Code.reverseSolidus)
                    }
                    buffer.append(byte)
                }
                buffer.append(ASCII.Code.quotationMark)
            } else {
                buffer.append(contentsOf: Array<Byte>(displayName.utf8))
            }

            buffer.append(ASCII.Code.space)
            buffer.append(ASCII.Code.lessThanSign)
        }

        // local-part@domain
        buffer.append(ascii: email.localPart)
        buffer.append(ASCII.Code.commercialAt)
        buffer.append(ascii: email.domain)

        if email.displayName != nil {
            buffer.append(ASCII.Code.greaterThanSign)
        }
    }
}

// MARK: - Properties

extension RFC_5321.EmailAddress {
    /// Just the email address part without display name
    public var address: String {
        "\(localPart)@\(domain.name)"
    }
}

// MARK: - Constants

extension RFC_5321.EmailAddress {
    package enum Limits {
        static let maxTotalLength = 254  // Maximum total email address length
    }
}

// MARK: - Protocol Conformances
extension RFC_5321.EmailAddress: CustomStringConvertible {}
