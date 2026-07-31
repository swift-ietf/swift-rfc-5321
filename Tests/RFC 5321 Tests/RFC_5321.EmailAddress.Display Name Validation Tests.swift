//
//  RFC_5321.EmailAddress.Display Name Validation Tests.swift
//  swift-rfc-5321
//
//  fable-448 F-004 regression coverage: init(displayName:localPart:domain:)
//  must reject a non-ASCII display name instead of silently accepting it
//  and later force-lifting its non-ASCII bytes through
//  `ASCII.Code(unchecked:)` during serialization.
//

import RFC_1123
import RFC_5321
import Testing

extension RFC_5321.EmailAddress {
    @Suite
    struct `Display Name Validation` {
        @Suite struct `Edge Case` {}
    }
}

extension RFC_5321.EmailAddress.`Display Name Validation`.`Edge Case` {
    @Test
    func
        `init(displayName:localPart:domain:) throws instead of silently accepting a non-ASCII display name`()
        throws
    {
        // Pre-fix, the display name is never validated: this construction
        // silently succeeds, and the non-ASCII byte in "é" is later
        // force-lifted through `ASCII.Code(unchecked:)` during ASCII
        // serialization — an invalid `ASCII.Code` (outside 0x00–0x7F) that
        // violates the type's own documented invariant.
        let localPart = try RFC_5321.EmailAddress.LocalPart("jose")
        let domain = try RFC_1123.Domain("example.com")
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(
                displayName: "José García",
                localPart: localPart,
                domain: domain
            )
        }
    }

    @Test
    func
        `init(displayName:localPart:domain:) still accepts an ASCII-only display name after the fix`()
        throws
    {
        let localPart = try RFC_5321.EmailAddress.LocalPart("jose")
        let domain = try RFC_1123.Domain("example.com")
        let email = try RFC_5321.EmailAddress(
            displayName: "Jose Garcia",
            localPart: localPart,
            domain: domain
        )
        #expect(email.displayName == "Jose Garcia")
    }
}
