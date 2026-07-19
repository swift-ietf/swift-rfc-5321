//
//  RFC_5321.EmailAddress.Angle Bracket Parsing Tests.swift
//  swift-rfc-5321
//
//  fable-448 F-001 regression coverage: init(ascii:) must not trap when a
//  close angle bracket precedes the open angle bracket, and must throw
//  instead of silently mis-parsing when an open angle bracket has no
//  matching close angle bracket anywhere after it.
//

import RFC_5321
import Testing

extension RFC_5321.EmailAddress {
    @Suite
    struct `Angle Bracket Parsing` {
        @Suite struct `Edge Case` {}
    }
}

extension RFC_5321.EmailAddress.`Angle Bracket Parsing`.`Edge Case` {
    @Test
    func `init(ascii:) throws instead of trapping when a close angle precedes the open angle`() {
        // Pre-fix, `bytes.firstIndex(of: '<')` and `bytes.firstIndex(of: '>')`
        // were located independently. Here '>' (index 1) precedes '<' (index
        // 3), so the old code formed `bytes[bytes.index(after: 3)..<1]` — a
        // Range with upperBound < lowerBound — which traps the process.
        let malformed = [Byte]("a>b<c@example.com".utf8)
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(ascii: malformed)
        }
    }

    @Test
    func `init(ascii:) throws instead of silently succeeding when an open angle has no close angle anywhere after it`() {
        // Pre-fix, when `bytes.firstIndex(of: '>')` is nil the compound
        // `if let` fails as a whole and parsing silently falls back to the
        // bare `local@domain` path over the ENTIRE input — including the
        // stray '<' — rather than reporting the malformed angle-bracket
        // input. Here the stray '<' lands inside a quoted local-part (where
        // '<' is a valid printable-ASCII quoted-string character), so the
        // bare-address fallback parses successfully and silently accepts
        // clearly-malformed angle-bracket input.
        let malformed = [Byte](#""john<doe"@example.com"#.utf8)
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(ascii: malformed)
        }
    }
}
