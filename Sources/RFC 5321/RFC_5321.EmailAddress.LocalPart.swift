//
//  RFC_5321.EmailAddress.LocalPart.swift
//  swift-rfc-5321
//
//  LocalPart implementation with canonical byte storage
//

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives
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

        /// Creates local-part WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(__unchecked: Void, rawValue: String) {
            self._value = [Byte](rawValue.utf8)
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
            try self.init(ascii: [Byte](string.utf8))
        }
    }
}

// MARK: - Accessors & Format (API-IMPL-008: extracted from type body)

extension RFC_5321.EmailAddress.LocalPart {
    /// Raw string value
    public var rawValue: String {
        String(decoding: _value, as: UTF8.self)
    }

    /// String representation derived from canonical bytes
    public var value: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - ASCII Serialization

extension RFC_5321.EmailAddress.LocalPart: ASCII.Serializable, Binary.Serializable {
    /// Serializes `value` as ASCII bytes into `buffer` (own `ASCII.Serializable` verb).
    ///
    /// The bytes are the UTF-8 of the `String` `rawValue` (the ASCII-only
    /// `_value` store projected through `rawValue`), lifted into the
    /// `ASCII.Code` substrate.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        // swift-linter:disable:next raw value access
        // REASON: same-package extension implementing the type's own ASCII.Serializable boundary; `.rawValue` is the type's own canonical projection.
        // swift-linter:disable:next chained rawvalue access
        // REASON: same-package extension implementing the type's own ASCII.Serializable boundary; `.rawValue.utf8` is the type's own canonical projection, not an external escape.
        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable defaults; bytes derive from `.serialized`.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

// MARK: - Byte-Level Parsing

extension RFC_5321.EmailAddress.LocalPart: ASCII.Parseable {
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
    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Lift to the ASCII.Code domain once; the throwing lift IS the ASCII-only
        // validation (an RFC 5321 local-part is an ASCII grammar).
        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            codes = try [ASCII.Code](bytes)
        } catch {
            throw Error.nonASCII
        }

        guard let first = codes.first, let last = codes.last else { throw Error.empty }
        guard codes.count <= Limits.maxLength else {
            throw Error.tooLong(codes.count)
        }

        let rawValue = String(decoding: codes, as: UTF8.self)

        // Handle quoted string format
        if first == ASCII.Code.quotationMark {
            guard last == ASCII.Code.quotationMark else {
                throw Error.invalidQuotedString(rawValue)
            }

            // Validate quoted string content
            var insideQuotes = false
            var escaped = false
            for code in codes {
                if !insideQuotes {
                    if code == ASCII.Code.quotationMark {
                        insideQuotes = true
                    }
                } else {
                    if escaped {
                        escaped = false
                        // After backslash, allow quote or backslash
                        guard code == ASCII.Code.quotationMark || code == ASCII.Code.reverseSolidus
                        else {
                            throw Error.invalidQuotedString(rawValue)
                        }
                    } else if code == ASCII.Code.reverseSolidus {
                        escaped = true
                    } else if code == ASCII.Code.quotationMark {
                        // End of quoted string
                        break
                    } else {
                        // Inside quotes: allow printable ASCII (0x20–0x7E)
                        guard code.isPrintable else {
                            throw Error.invalidCharacter(rawValue, byte: code.byte)
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

            for (offset, code) in codes.enumerated() {
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

                let isDot = code == ASCII.Code.period

                guard isAtext || isDot else {
                    throw Error.invalidCharacter(rawValue, byte: code.byte)
                }

                // Can't start or end with dot, can't have consecutive dots
                if isDot {
                    guard offset != 0 else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                    guard !lastWasDot else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                }

                lastWasDot = isDot
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

extension RFC_5321.EmailAddress.LocalPart: Swift.RawRepresentable {
    /// `rawValue` is the computed `String` getter defined on the type; the
    /// failable init re-validates through the canonical string initializer.
    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_5321.EmailAddress.LocalPart: CustomStringConvertible {
    public var description: String {
        String(decoding: _value, as: UTF8.self)
    }
}

