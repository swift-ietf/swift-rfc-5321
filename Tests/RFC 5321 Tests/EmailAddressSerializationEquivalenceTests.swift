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

        let email = try RFC_5321.EmailAddress(
            displayName: "Doe \"JD\" John",
            localPart: try RFC_5321.EmailAddress.LocalPart("jd"),
            domain: try RFC_1123.Domain("example.com")
        )

        let viaASCII: [Byte] = email.serialized

        var viaBinary: [Byte] = []
        RFC_5321.EmailAddress.serialize(email, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
