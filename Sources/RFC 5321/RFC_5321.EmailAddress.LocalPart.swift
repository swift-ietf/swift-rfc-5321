//
//  RFC_5321.EmailAddress.LocalPart.swift
//  swift-rfc-5321
//
//  LocalPart implementation with canonical byte storage
//

import ASCII_Serializer_Primitives
import INCITS_4_1986
import Standard_Library_Extensions

extension RFC_5321.EmailAddress {
    /// RFC 5321 compliant local-part
    ///
    /// The local-part appears before the @ sign in an email address.
    /// RFC 5321 supports two formats: dot-atom and quoted-string.
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321 Section 4.5.3.1.1:
    /// - Maximum length: 64 octets
    /// - Must be ASCII-only
    /// - Supports dot-atom or quoted-string format
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_5321.EmailAddress.LocalPart(ascii: "user".utf8)
    /// ```
    public struct LocalPart: Hashable, Sendable, Codable {
        /// Canonical byte storage (ASCII-only per RFC 5321)
        let _value: [Byte]

        /// The storage format (dot-atom or quoted)
        private let format: Format

        /// Raw string value
        public var rawValue: String {
            String(decoding: _value, as: UTF8.self)
        }

        /// String representation derived from canonical bytes
        public var value: String {
            String(ascii: self)
        }

        /// Creates local-part WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(__unchecked: Void, rawValue: String) {
            self._value = Array<Byte>(rawValue.utf8)
            // Infer format from presence of quotes
            if rawValue.hasPrefix("\"") && rawValue.hasSuffix("\"") {
                self.format = .quoted
            } else {
                self.format = .dotAtom
            }
        }

        /// Initialize a local-part from a string, validating RFC 5321 rules
        ///
        /// This is a convenience initializer that converts String to bytes.
        public init(_ string: some StringProtocol) throws(Error) {
            try self.init(ascii: Array<Byte>(string.utf8))
        }

        // MARK: - Format

        private enum Format: Hashable, Codable {
            case dotAtom  // Regular unquoted format
            case quoted  // Quoted string format
        }
    }
}

// MARK: - Byte-Level Parsing (Binary.ASCII.Serializable)

extension RFC_5321.EmailAddress.LocalPart: Binary.ASCII.Serializable {
    /// Initialize from ASCII bytes, validating RFC 5321 rules
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5321.EmailAddress.LocalPart (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [UInt8] (UTF-8) → LocalPart
    /// ```
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321 Section 4.5.3.1.1:
    /// - Must be ASCII-only
    /// - Maximum 64 octets
    /// - Supports dot-atom or quoted-string format
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_5321.EmailAddress.LocalPart(ascii: "user".utf8)
    /// ```
    public init<Bytes: Collection>(ascii bytes: Bytes, in _: Void = ()) throws(Error)
    where Bytes.Element == Byte {
        guard let firstByte = bytes.first else { throw Error.empty }

        var count = 0
        var lastByte = firstByte
        for byte in bytes {
            count += 1
            lastByte = byte
            // Validate ASCII-only (high bit must be 0)
            guard ASCII.Code(byte).isASCII else {
                throw Error.nonASCII
            }
        }

        guard count <= Limits.maxLength else {
            throw Error.tooLong(count)
        }

        let rawValue = String(decoding: bytes, as: UTF8.self)

        // Handle quoted string format
        if firstByte == ASCII.Code.quotationMark {
            guard lastByte == ASCII.Code.quotationMark else {
                throw Error.invalidQuotedString(rawValue)
            }

            // Validate quoted string content
            var insideQuotes = false
            var escaped = false
            for byte in bytes {
                if !insideQuotes {
                    if byte == ASCII.Code.quotationMark {
                        insideQuotes = true
                    }
                } else {
                    if escaped {
                        escaped = false
                        // After backslash, allow quote or backslash
                        guard byte == ASCII.Code.quotationMark || byte == ASCII.Code.reverseSolidus else {
                            throw Error.invalidQuotedString(rawValue)
                        }
                    } else if byte == ASCII.Code.reverseSolidus {
                        escaped = true
                    } else if byte == ASCII.Code.quotationMark {
                        // End of quoted string
                        break
                    } else {
                        // Inside quotes: allow printable ASCII (0x20–0x7E)
                        guard ASCII.Code(byte).isPrintable else {
                            throw Error.invalidCharacter(rawValue, byte: byte)
                        }
                    }
                }
            }

            self._value = Array(bytes)
            self.format = .quoted
        }
        // Handle dot-atom format
        else {
            // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
            var lastWasDot = false
            var index = bytes.startIndex

            for byte in bytes {
                let code = ASCII.Code(byte)
                let isAtext =
                    code.isLetter || code.isDigit || code == ASCII.Code.exclamationMark
                    || code == ASCII.Code.numberSign
                    || code == ASCII.Code.dollarSign
                    || code == ASCII.Code.percentSign
                    || code == ASCII.Code.ampersand
                    || code == ASCII.Code.apostrophe
                    || code == ASCII.Code.asterisk
                    || code == ASCII.Code.plus
                    || code == ASCII.Code.hyphen
                    || code == ASCII.Code.solidus
                    || code == ASCII.Code.equalsSign
                    || code == ASCII.Code.questionMark
                    || code == ASCII.Code.circumflex
                    || code == ASCII.Code.underscore
                    || code == ASCII.Code.graveAccent
                    || code == ASCII.Code.leftCurlyBracket
                    || code == ASCII.Code.verticalLine
                    || code == ASCII.Code.rightCurlyBracket
                    || code == ASCII.Code.tilde

                let isDot = byte == ASCII.Code.period

                guard isAtext || isDot else {
                    throw Error.invalidCharacter(rawValue, byte: byte)
                }

                // Can't start or end with dot, can't have consecutive dots
                if isDot {
                    guard index != bytes.startIndex else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                    guard !lastWasDot else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                }

                lastWasDot = isDot
                index = bytes.index(after: index)
            }

            // Can't end with dot
            guard !lastWasDot else {
                throw Error.invalidDotAtom(rawValue)
            }

            self._value = Array(bytes)
            self.format = .dotAtom
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress.LocalPart: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

// MARK: - ASCII Serialization

extension RFC_5321.EmailAddress.LocalPart {
    /// Serialize local-part to ASCII bytes
    ///
    /// Required implementation for `Binary.ASCII.RawRepresentable` to avoid
    /// infinite recursion (since `rawValue` is synthesized from serialization).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii localPart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: localPart._value)
    }
}

extension RFC_5321.EmailAddress.LocalPart: CustomStringConvertible {
    public var description: String {
        String(decoding: _value, as: UTF8.self)
    }
}

// MARK: - Constants

extension RFC_5321.EmailAddress.LocalPart {
    package enum Limits {
        static let maxLength = 64  // Max length for local-part per RFC 5321
    }
}
