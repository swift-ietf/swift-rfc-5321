// Hoisted to non-generic module scope per [API-ERR-009]: `RFC_5321.EmailAddress.Parse<Input>`
// is generic, but these cases never use `Input` — nesting the error there risks an
// accidentally-generic `@error` SIL result under `-O -enable-default-cmo`
// (swiftlang/swift#89617). `RFC_5321.EmailAddress.Parse.Error` stays available as a
// typealias so the nested spelling keeps resolving.
public enum __RFC_5321_EmailAddress_Parse_Error: Swift.Error, Sendable, Equatable {
    case empty
    case missingAtSign
    case emptyLocalPart
    case emptyDomain
    case unterminatedAngleBracket
}
