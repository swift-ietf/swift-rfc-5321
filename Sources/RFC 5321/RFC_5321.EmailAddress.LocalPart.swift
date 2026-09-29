import ASCII
public import Byte
import Byte

extension RFC_5321.EmailAddress {

    public struct LocalPart: Hashable, Sendable {

        package let bytes: [Byte]

        package let format: Format
    }
}

extension RFC_5321.EmailAddress.LocalPart {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            var built: [ASCII.Code] = []
            built.reserveCapacity(bytes.count)
            for byte in bytes {
                built.append(try ASCII.Code(byte))
            }
            codes = built
        } catch {
            throw Error.nonASCII
        }

        guard let first = codes.first, let last = codes.last else { throw Error.empty }
        guard codes.count <= Limits.maxLength else {
            throw Error.tooLong(codes.count)
        }

        let rawValue = String(decoding: codes.lazy.map(\.underlying), as: UTF8.self)

        if first == ASCII.Code.quotationMark {
            guard last == ASCII.Code.quotationMark, codes.count >= 2 else {
                throw Error.invalidQuotedString(rawValue)
            }

            var escaped = false
            for code in codes[1..<(codes.count - 1)] {
                if escaped {
                    escaped = false

                    guard code == ASCII.Code.quotationMark || code == ASCII.Code.reverseSolidus
                    else {
                        throw Error.invalidQuotedString(rawValue)
                    }
                } else if code == ASCII.Code.reverseSolidus {
                    escaped = true
                } else if code == ASCII.Code.quotationMark {
                    throw Error.invalidQuotedString(rawValue)
                } else {
                    guard code.isPrintable else {
                        throw Error.invalidCharacter(rawValue, byte: code.byte)
                    }
                }
            }

            guard !escaped else {
                throw Error.invalidQuotedString(rawValue)
            }

            self.bytes = [Byte](bytes)
            self.format = .quoted
        } else {

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

            self.bytes = [Byte](bytes)
            self.format = .dotAtom
        }
    }
}

extension RFC_5321.EmailAddress.LocalPart: CustomStringConvertible {

    public var description: String {
        String(decoding: bytes, as: UTF8.self)
    }
}
