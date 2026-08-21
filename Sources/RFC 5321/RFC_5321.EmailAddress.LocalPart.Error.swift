import Standard_Library_Extensions

extension RFC_5321.EmailAddress.LocalPart {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case tooLong(_ length: Int)

        case nonASCII

        case invalidCharacter(_ value: String, byte: Byte)

        case invalidDotAtom(_ localPart: String)

        case invalidQuotedString(_ localPart: String)
    }
}

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
