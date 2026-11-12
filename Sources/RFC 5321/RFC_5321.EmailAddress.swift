import ASCII
public import Byte
import INCITS_4_1986
public import RFC_1123
import Standard_Library_Extensions

extension RFC_5321 {

    public struct EmailAddress: Hashable, Sendable {

        public let displayName: String?

        public let localPart: LocalPart

        public let domain: RFC_1123.Domain

        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) throws(Error) {
            let trimmed = displayName.flatMap { name -> String? in
                let value = String(name.trimming(.ascii.whitespaces))
                return value.isEmpty ? nil : value
            }

            if let trimmed {
                for byte in trimmed.utf8 {
                    guard byte < 0x80 else {
                        throw Error.invalidDisplayName(trimmed, byte: Byte(bitPattern: byte))
                    }
                }
            }

            self.displayName = trimmed
            self.localPart = localPart
            self.domain = domain

            let addressLength = localPart.bytes.count + 1 + domain.name.utf8.count
            guard addressLength <= Limits.maxTotalLength else {
                throw Error.totalLengthExceeded(addressLength)
            }
        }
    }
}

extension RFC_5321.EmailAddress {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        if let openAngle = bytes.firstIndex(of: ASCII.Code.lessThanSign.byte) {
            guard
                let closeAngle = Self.lastIndex(
                    of: ASCII.Code.greaterThanSign.byte,
                    in: bytes[bytes.index(after: openAngle)...]
                )
            else {
                throw Error.unterminatedAngleBracket
            }

            guard
                bytes[bytes.index(after: closeAngle)...].allSatisfy({ byte in
                    byte == ASCII.Code.space.byte || byte == ASCII.Code.htab.byte
                })
            else {
                throw Error.trailingText
            }

            let displayName: String?
            if openAngle > bytes.startIndex {
                let nameBytes = bytes[bytes.startIndex..<openAngle]
                var name = String(
                    String(decoding: nameBytes, as: UTF8.self).trimming(.ascii.whitespaces)
                )

                if name.hasPrefix("\"") && name.hasSuffix("\"") {
                    let withoutQuotes = String(name.dropFirst().dropLast())
                    name = Self.unescapedFromQuotedString(withoutQuotes)
                }

                displayName = name.isEmpty ? nil : name
            } else {
                displayName = nil
            }

            let emailBytes = bytes[bytes.index(after: openAngle)..<closeAngle]

            guard let atIndex = Self.lastIndex(of: ASCII.Code.commercialAt.byte, in: emailBytes) else {
                throw Error.missingAtSign
            }

            let localPart = try Self.validatedLocalPart(emailBytes[emailBytes.startIndex..<atIndex])
            let domain = try Self.validatedDomain(emailBytes[emailBytes.index(after: atIndex)...])

            try self.init(displayName: displayName, localPart: localPart, domain: domain)
        } else {

            guard let atIndex = Self.lastIndex(of: ASCII.Code.commercialAt.byte, in: bytes) else {
                throw Error.missingAtSign
            }

            let localPart = try Self.validatedLocalPart(bytes[bytes.startIndex..<atIndex])
            let domain = try Self.validatedDomain(bytes[bytes.index(after: atIndex)...])

            try self.init(displayName: nil, localPart: localPart, domain: domain)
        }
    }

    private static func lastIndex<Bytes: Swift::Collection>(
        of target: Byte,
        in bytes: Bytes
    ) -> Bytes.Index? where Bytes.Element == Byte {
        var found: Bytes.Index?
        var index = bytes.startIndex
        while index != bytes.endIndex {
            if bytes[index] == target {
                found = index
            }
            index = bytes.index(after: index)
        }
        return found
    }

    private static func validatedLocalPart<Bytes: Swift::Collection>(
        _ bytes: Bytes
    ) throws(Error) -> LocalPart where Bytes.Element == Byte {
        do throws(LocalPart.Error) {
            return try LocalPart(ascii: bytes)
        } catch {
            throw Error.invalidLocalPart(error)
        }
    }

    private static func validatedDomain<Bytes: Swift::Collection>(
        _ bytes: Bytes
    ) throws(Error) -> RFC_1123.Domain where Bytes.Element == Byte {
        do throws(RFC_1123.Domain.Error) {
            return try RFC_1123.Domain(ascii: bytes)
        } catch {
            throw Error.invalidDomain(error)
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
        guard let displayName else {
            return address
        }

        let needsQuoting = displayName.contains { character in
            !character.ascii.isLetter && !character.ascii.isDigit
                && !character.ascii.isWhitespace
        }

        let name = needsQuoting ? "\"\(Self.escapedForQuotedString(displayName))\"" : displayName
        return "\(name) <\(address)>"
    }

    private static func escapedForQuotedString(_ displayName: String) -> String {
        var escaped = ""
        for character in displayName {
            if character == "\\" || character == "\"" {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }

    private static func unescapedFromQuotedString(_ content: String) -> String {
        var unescaped = ""
        var pending = false
        for character in content {
            if !pending && character == "\\" {
                pending = true
                continue
            }
            unescaped.append(character)
            pending = false
        }
        return unescaped
    }
}

extension RFC_5321.EmailAddress: Swift::RawRepresentable {

    public var rawValue: String {
        description
    }

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}
