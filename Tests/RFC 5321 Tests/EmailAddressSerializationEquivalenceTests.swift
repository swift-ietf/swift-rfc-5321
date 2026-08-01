//
//  EmailAddressSerializationEquivalenceTests.swift
//  swift-rfc-5321
//
//  [FAM-012] composite re-cut guard. The EmailAddress `ASCII.Serializable` verb
//  (direct same-format composition) MUST emit byte-identical output to the
//  `Binary.Serializable` witness (`serializeBytes`) for the quoting/escape path —
//  the path the README `.description` test does not output-assert. Asserts the
//  refactor invariant directly (ASCII output == Binary output), so no expected
//  string is hand-derived.
//

import RFC_5321
import Testing

@Suite
struct `EmailAddress Serialization Equivalence` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `EmailAddress Serialization Equivalence`.Unit {
    @Test
    func `ASCII verb output equals Binary witness output for the quoting and escape path`() throws {
        // A display name containing a `"` forces BOTH the quoting wrapper and the
        // backslash-escape branch — exactly the logic transcribed into the ASCII verb.
        let email = try RFC_5321.EmailAddress(
            displayName: "Doe \"JD\" John",
            localPart: try RFC_5321.EmailAddress.LocalPart("jd"),
            domain: try RFC_1123.Domain("example.com")
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = email.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_5321.EmailAddress.serialize(email, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
