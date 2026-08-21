public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives
import Standard_Library_Extensions

extension RFC_5321.EmailAddress {

    public struct LocalPart: Hashable, Sendable, Codable {

        let _value: [Byte]

        private let format: Format

        init(__unchecked: Void, rawValue: String) {
            self._value = [Byte](rawValue.utf8)

            if rawValue.hasPrefix("\"") && rawValue.hasSuffix("\"") {
                self.format = .quoted
            } else {
                self.format = .dotAtom
            }
        }

        public init(_ string: some StringProtocol) throws(Error) {
            try self.init(ascii: [Byte](string.utf8))
        }
    }
}

extension RFC_5321.EmailAddress.LocalPart {

    public var rawValue: String {
        String(decoding: _value, as: UTF8.self)
    }

    public var value: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_5321.EmailAddress.LocalPart: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

extension RFC_5321.EmailAddress.LocalPart: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

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

        if first == ASCII.Code.quotationMark {
            guard last == ASCII.Code.quotationMark else {
                throw Error.invalidQuotedString(rawValue)
            }

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

                        guard code == ASCII.Code.quotationMark || code == ASCII.Code.reverseSolidus
                        else {
                            throw Error.invalidQuotedString(rawValue)
                        }
                    } else if code == ASCII.Code.reverseSolidus {
                        escaped = true
                    } else if code == ASCII.Code.quotationMark {

                        break
                    } else {

                        guard code.isPrintable else {
                            throw Error.invalidCharacter(rawValue, byte: code.byte)
                        }
                    }
                }
            }

            self._value = Array(bytes)
            self.format = .quoted
        }

        else {

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

            guard !lastWasDot else {
                throw Error.invalidDotAtom(rawValue)
            }

            self._value = Array(bytes)
            self.format = .dotAtom
        }
    }
}

extension RFC_5321.EmailAddress.LocalPart: Swift.RawRepresentable {

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
