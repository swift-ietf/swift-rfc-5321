public import Parser

extension RFC_5321.EmailAddress {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_5321.EmailAddress.Parse {
    public typealias Error = __RFC_5321_EmailAddress_Parse_Error
}

extension RFC_5321.EmailAddress.Parse: Parser.`Protocol` {
    public typealias Failure = __RFC_5321_EmailAddress_Parse_Error
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard input.startIndex < input.endIndex else { throw .empty }

        var angleBracketIndex: Input.Index? = nil
        var scanIndex = input.startIndex
        while scanIndex < input.endIndex {
            if input[scanIndex] == 0x3C {
                angleBracketIndex = scanIndex
                break
            }
            input.formIndex(after: &scanIndex)
        }

        if let openAngle = angleBracketIndex {

            let displayName: Input?
            if openAngle > input.startIndex {
                displayName = input[input.startIndex..<openAngle]
            } else {
                displayName = nil
            }

            let afterAngle = input.index(after: openAngle)

            var closeAngle: Input.Index? = nil
            var idx = afterAngle
            while idx < input.endIndex {
                if input[idx] == 0x3E {
                    closeAngle = idx
                    break
                }
                input.formIndex(after: &idx)
            }
            guard let close = closeAngle else { throw .unterminatedAngleBracket }

            let emailSlice = input[afterAngle..<close]
            let (localPart, domain) = try Self._splitAtSign(emailSlice)

            input = input[input.index(after: close)...]
            return Output(displayName: displayName, localPart: localPart, domain: domain)
        } else {

            var endIdx = input.startIndex
            while endIdx < input.endIndex {
                let byte = input[endIdx]
                if byte == 0x20 || byte == 0x09 || byte == 0x0D || byte == 0x0A { break }
                input.formIndex(after: &endIdx)
            }

            let emailSlice = input[input.startIndex..<endIdx]
            let (localPart, domain) = try Self._splitAtSign(emailSlice)

            input = input[endIdx...]
            return Output(displayName: nil, localPart: localPart, domain: domain)
        }
    }

    @inlinable
    package static func _splitAtSign(
        _ slice: Input
    ) throws(Failure) -> (localPart: Input, domain: Input) {

        var atIndex: Input.Index? = nil
        var idx = slice.startIndex
        while idx < slice.endIndex {
            if slice[idx] == 0x40 {
                atIndex = idx
            }
            slice.formIndex(after: &idx)
        }
        guard let at = atIndex else { throw .missingAtSign }
        guard at > slice.startIndex else { throw .emptyLocalPart }

        let afterAt = slice.index(after: at)
        guard afterAt < slice.endIndex else { throw .emptyDomain }

        return (slice[slice.startIndex..<at], slice[afterAt..<slice.endIndex])
    }
}
