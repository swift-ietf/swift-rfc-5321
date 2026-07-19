//
//  RFC_5321.EmailAddress.swift
//  swift-rfc-5321
//
//  EmailAddress implementation
//

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives
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
            let trimmedDisplayName = displayName?.trimming(.ascii.whitespaces)

            // fable-448 F-004: RFC 5321 mailboxes are an ASCII grammar; a
            // non-ASCII display name must be RFC 2047-encoded upstream
            // before it reaches this initializer. Validating here is what
            // makes the `ASCII.Code(unchecked:)` lifts in `serialize` below
            // sound — they now only ever see bytes that passed this check
            // (the internal `__unchecked` initializer remains a deliberate,
            // documented escape hatch for pre-validated values and is out
            // of scope for this check).
            if let trimmedDisplayName {
                for byte in trimmedDisplayName.utf8 {
                    guard byte < 0x80 else {
                        throw Error.invalidDisplayName(trimmedDisplayName, byte: Byte(byte))
                    }
                }
            }

            self.displayName = trimmedDisplayName
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

// MARK: - Byte-Level Parsing

extension RFC_5321.EmailAddress: ASCII.Parseable {
    /// Creates an email address by validating `string`'s UTF-8 bytes as ASCII.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

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
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        // Check for angle bracket format: [display-name] <local@domain>
        //
        // fable-448 F-001: the closing '>' must be located strictly after the
        // opening '<'. Scanning for '<' and '>' independently (the prior
        // approach) traps whenever a '>' occurs earlier in `bytes` than the
        // first '<' (e.g. "a>b<c@d.com") — the resulting `emailBytes` range
        // below would have upperBound < lowerBound. This mirrors the scan
        // order `RFC_5321.EmailAddress.Parse` already uses.
        if let openAngle = bytes.firstIndex(of: ASCII.Code.lessThanSign.byte) {
            guard
                let closeAngle = bytes[bytes.index(after: openAngle)...]
                    .firstIndex(of: ASCII.Code.greaterThanSign.byte)
            else {
                throw Error.unterminatedAngleBracket
            }

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
            do throws(LocalPart.Error) {
                localPart = try LocalPart(ascii: localBytes)
            } catch {
                throw Error.invalidLocalPart(error)
            }

            // Extract domain
            let domainBytes = emailBytes[emailBytes.index(after: atIndex)...]
            let domain: RFC_1123.Domain
            do throws(RFC_1123.Domain.Error) {
                domain = try RFC_1123.Domain(ascii: domainBytes)
            } catch {
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
            do throws(LocalPart.Error) {
                localPart = try LocalPart(ascii: localBytes)
            } catch {
                throw Error.invalidLocalPart(error)
            }

            // Extract domain
            let domainBytes = bytes[bytes.index(after: atIndex)...]
            let domain: RFC_1123.Domain
            do throws(RFC_1123.Domain.Error) {
                domain = try RFC_1123.Domain(ascii: domainBytes)
            } catch {
                throw Error.invalidDomain(error)
            }

            try self.init(displayName: nil, localPart: localPart, domain: domain)
        }
    }
}

// MARK: - ASCII Serialization

extension RFC_5321.EmailAddress: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — the RFC 5321 mailbox/address
    /// form, composing the already-re-cut `LocalPart` / `Domain` **ASCII** verbs
    /// directly into the `ASCII.Code` buffer (evergreen same-format composition;
    /// no byte-detour). The display-name leaf is emitted on the ASCII-code
    /// substrate. Output is identical to the Binary witness body (`serializeBytes`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if let displayName = value.displayName {
            // fable-448 F-004: `ASCII.Code(unchecked:)` below is sound because
            // `init(displayName:localPart:domain:)` now rejects any non-ASCII
            // byte in `displayName` before a `Self` can exist with one — this
            // block never sees a byte outside 0x00–0x7F for a publicly
            // constructed value.
            let needsQuoting = displayName.utf8.contains { byte in
                guard let code = try? ASCII.Code(Byte(byte)) else { return true }
                return !code.isLetter && !code.isDigit && !code.isWhitespace
            }

            if needsQuoting {
                buffer.append(ASCII.Code.quotationMark)
                for char in displayName.utf8 {
                    let code = ASCII.Code(unchecked: Byte(char))
                    if code == ASCII.Code.quotationMark || code == ASCII.Code.reverseSolidus {
                        buffer.append(ASCII.Code.reverseSolidus)
                    }
                    buffer.append(code)
                }
                buffer.append(ASCII.Code.quotationMark)
            } else {
                buffer.append(contentsOf: displayName.utf8.map { ASCII.Code(unchecked: Byte($0)) })
            }

            buffer.append(ASCII.Code.space)
            buffer.append(ASCII.Code.lessThanSign)
        }

        // local-part@domain — direct same-format composition of the re-cut verbs
        RFC_5321.EmailAddress.LocalPart.serialize(value.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(value.domain, into: &buffer)

        if value.displayName != nil {
            buffer.append(ASCII.Code.greaterThanSign)
        }
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (RFC 5321 mailbox/address).
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ email: Self,
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
                    if byte == ASCII.Code.quotationMark.byte
                        || byte == ASCII.Code.reverseSolidus.byte
                    {
                        buffer.append(ASCII.Code.reverseSolidus)
                    }
                    buffer.append(byte)
                }
                buffer.append(ASCII.Code.quotationMark)
            } else {
                buffer.append(contentsOf: [Byte](displayName.utf8))
            }

            buffer.append(ASCII.Code.space)
            buffer.append(ASCII.Code.lessThanSign)
        }

        // local-part@domain
        RFC_5321.EmailAddress.LocalPart.serialize(email.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(email.domain, into: &buffer)

        if email.displayName != nil {
            buffer.append(ASCII.Code.greaterThanSign)
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress: Swift.RawRepresentable {
    /// The email address's ASCII serialization as a `String` (computed; the
    /// rawValue is derived from serialization, not stored).
    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public init?(rawValue: String) { try? self.init(rawValue) }
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
    package enum Limits {}
}

extension RFC_5321.EmailAddress.Limits {
    static let maxTotalLength = 254  // Maximum total email address length
}

// MARK: - Protocol Conformances
extension RFC_5321.EmailAddress: CustomStringConvertible {
    /// The email address's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}
