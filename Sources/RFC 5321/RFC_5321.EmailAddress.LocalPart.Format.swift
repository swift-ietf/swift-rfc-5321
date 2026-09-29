extension RFC_5321.EmailAddress.LocalPart {

    package enum Format: Hashable, Sendable {
        case dotAtom
        case quoted
    }
}
