public import ASCII_Serializer
public import Binary_Serializable
import INCITS_4_1986
public import Parseable_ASCII
public import RFC_1123
import Standard_Library_Extensions

extension RFC_5321 {

    public struct EmailAddress: Hashable, Sendable, Codable {

        public let displayName: String?

        public let localPart: LocalPart

        public let domain: RFC_1123.Domain

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

        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) throws(Error) {
            let trimmedDisplayName = displayName?.trimming(.ascii.whitespaces)

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

            let addressLength = localPart.value.count + 1 + domain.name.count
            guard addressLength <= Limits.maxTotalLength else {
                throw Error.totalLengthExceeded(addressLength)
            }
        }
    }
}

extension RFC_5321.EmailAddress: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        if let openAngle = bytes.firstIndex(of: ASCII.Code.lessThanSign.byte) {
            guard
                let closeAngle = bytes[bytes.index(after: openAngle)...]
                    .firstIndex(of: ASCII.Code.greaterThanSign.byte)
            else {
                throw Error.unterminatedAngleBracket
            }

            let displayName: String?
            if openAngle > bytes.startIndex {
                let nameBytes = bytes[bytes.startIndex..<openAngle]
                var name = String(decoding: nameBytes, as: UTF8.self).trimming(.ascii.whitespaces)

                if name.hasPrefix("\"") && name.hasSuffix("\"") {
                    let withoutQuotes = String(name.dropFirst().dropLast())
                    name = withoutQuotes.replacing("\\\"", with: "\"")
                        .replacing("\\\\", with: "\\")
                }

                displayName = name.isEmpty ? nil : name
            } else {
                displayName = nil
            }

            let emailBytes = bytes[bytes.index(after: openAngle)..<closeAngle]

            guard let atIndex = emailBytes.firstIndex(of: ASCII.Code.commercialAt.byte) else {
                throw Error.missingAtSign
            }

            let localBytes = emailBytes[emailBytes.startIndex..<atIndex]
            let localPart: LocalPart
            do throws(LocalPart.Error) {
                localPart = try LocalPart(ascii: localBytes)
            } catch {
                throw Error.invalidLocalPart(error)
            }

            let domainBytes = emailBytes[emailBytes.index(after: atIndex)...]
            let domain: RFC_1123.Domain
            do throws(RFC_1123.Domain.Error) {
                domain = try RFC_1123.Domain(ascii: domainBytes)
            } catch {
                throw Error.invalidDomain(error)
            }

            try self.init(displayName: displayName, localPart: localPart, domain: domain)
        } else {

            guard let atIndex = bytes.firstIndex(of: ASCII.Code.commercialAt.byte) else {
                throw Error.missingAtSign
            }

            let localBytes = bytes[bytes.startIndex..<atIndex]
            let localPart: LocalPart
            do throws(LocalPart.Error) {
                localPart = try LocalPart(ascii: localBytes)
            } catch {
                throw Error.invalidLocalPart(error)
            }

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

extension RFC_5321.EmailAddress: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if let displayName = value.displayName {

            let needsQuoting = displayName.utf8.contains { byte in
                let code: ASCII.Code
                do throws(ASCII.Code.Error) {
                    code = try ASCII.Code(Byte(byte))
                } catch {
                    return true
                }
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

        RFC_5321.EmailAddress.LocalPart.serialize(value.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(value.domain, into: &buffer)

        if value.displayName != nil {
            buffer.append(ASCII.Code.greaterThanSign)
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ email: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if let displayName = email.displayName {

            let needsQuoting = displayName.utf8.contains { byte in

                let code: ASCII.Code
                do throws(ASCII.Code.Error) {
                    code = try ASCII.Code(Byte(byte))
                } catch {
                    return true
                }
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

        RFC_5321.EmailAddress.LocalPart.serialize(email.localPart, into: &buffer)
        buffer.append(ASCII.Code.commercialAt)
        RFC_1123.Domain.serialize(email.domain, into: &buffer)

        if email.displayName != nil {
            buffer.append(ASCII.Code.greaterThanSign)
        }
    }
}

extension RFC_5321.EmailAddress: Swift.RawRepresentable {

    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_5321.EmailAddress {

    public var address: String {
        "\(localPart)@\(domain.name)"
    }
}

extension RFC_5321.EmailAddress: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}
