public enum __RFC_5321_EmailAddress_Parse_Error: Swift.Error, Sendable, Equatable {
    case empty
    case missingAtSign
    case emptyLocalPart
    case emptyDomain
    case unterminatedAngleBracket
}
