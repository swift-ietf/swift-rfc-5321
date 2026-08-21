public import RFC_1123
import Standard_Library_Extensions

extension RFC_5321.EmailAddress {

    public enum Error: Swift.Error, Sendable, Equatable {

        case missingAtSign

        case totalLengthExceeded(_ length: Int)

        case invalidLocalPart(_ error: LocalPart.Error)

        case invalidDomain(_ error: RFC_1123.Domain.Error)

        case unterminatedAngleBracket

        case invalidDisplayName(_ name: String, byte: Byte)
    }
}

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
