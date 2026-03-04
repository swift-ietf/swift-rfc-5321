//
//  RFC_5321.EmailAddress.Parse.swift
//  swift-rfc-5321
//
//  SMTP email address: [display-name] local-part "@" domain
//

public import Parser_Primitives

extension RFC_5321.EmailAddress {
    /// Parses an SMTP email address per RFC 5321 Section 4.1.2.
    ///
    /// Supports two formats:
    /// - Bare address: `local-part "@" domain`
    /// - Angle-bracket: `[display-name] "<" local-part "@" domain ">"`
    ///
    /// Returns the raw byte slices for each component. Validation of
    /// local-part and domain content is left to the caller.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_5321.EmailAddress.Parse {
    public struct Output: Sendable {
        public let displayName: Input?
        public let localPart: Input
        public let domain: Input

        @inlinable
        public init(displayName: Input?, localPart: Input, domain: Input) {
            self.displayName = displayName
            self.localPart = localPart
            self.domain = domain
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
        case missingAtSign
        case emptyLocalPart
        case emptyDomain
        case unterminatedAngleBracket
    }
}

extension RFC_5321.EmailAddress.Parse: Parser.`Protocol` {
    public typealias Failure = RFC_5321.EmailAddress.Parse<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard input.startIndex < input.endIndex else { throw .empty }

        // Scan for '<' to detect angle-bracket format
        var angleBracketIndex: Input.Index? = nil
        var scanIndex = input.startIndex
        while scanIndex < input.endIndex {
            if input[scanIndex] == 0x3C {  // <
                angleBracketIndex = scanIndex
                break
            }
            input.formIndex(after: &scanIndex)
        }

        if let openAngle = angleBracketIndex {
            // Angle-bracket format: [display-name] <local@domain>
            let displayName: Input?
            if openAngle > input.startIndex {
                displayName = input[input.startIndex..<openAngle]
            } else {
                displayName = nil
            }

            let afterAngle = input.index(after: openAngle)

            // Find closing '>'
            var closeAngle: Input.Index? = nil
            var idx = afterAngle
            while idx < input.endIndex {
                if input[idx] == 0x3E {  // >
                    closeAngle = idx
                    break
                }
                input.formIndex(after: &idx)
            }
            guard let close = closeAngle else { throw .unterminatedAngleBracket }

            // Parse local@domain between angle brackets
            let emailSlice = input[afterAngle..<close]
            let (localPart, domain) = try Self._splitAtSign(emailSlice)

            input = input[input.index(after: close)...]
            return Output(displayName: displayName, localPart: localPart, domain: domain)
        } else {
            // Bare format: local@domain — consume until whitespace or end
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
    static func _splitAtSign(
        _ slice: Input
    ) throws(Failure) -> (localPart: Input, domain: Input) {
        // Find last '@' (handles quoted local-parts containing '@')
        var atIndex: Input.Index? = nil
        var idx = slice.startIndex
        while idx < slice.endIndex {
            if slice[idx] == 0x40 {  // @
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
