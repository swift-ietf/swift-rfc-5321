# swift-rfc-5321

Use this package when you need an email address in the strict ASCII form SMTP accepts in its envelope, for example to check a MAIL FROM or RCPT TO address before sending. Start from `RFC_5321.EmailAddress`. If the address may contain non-ASCII characters, use swift-rfc-6531. For addresses in message headers, use swift-rfc-5322. If you don't want to pick a standard, use swift-emailaddress-standard. For `Codable`, add the `RFC 5321 Foundation Integration` product.

## Laws

- Text is read as a bare `local@domain`, or as a display name followed by the address in angle brackets. A display name in double quotes has its quotes and its `\"` and `\\` escapes removed.
- The local part is either a dot-atom or a quoted string. A dot-atom uses letters, digits and the atext punctuation of RFC 5322, with no dot at the start, at the end or next to another dot. A quoted string holds printable ASCII, and only `"` and `\` may be escaped. The local part is kept exactly as written, quotes included.
- The local part is at most 64 bytes, and the local part, `@` and domain together at most 254 bytes. The display name doesn't count.
- The domain must be an RFC 1123 host name.
- Everything must be ASCII, the display name included. Whitespace around a display name is trimmed, and a blank one becomes nil.
- When written out, a display name is quoted, with `"` and `\` escaped, if it contains anything other than letters, digits and whitespace.
- With `RFC 5321 Foundation Integration`, an address and a local part each encode as their text form, and decoding validates it the same way.
