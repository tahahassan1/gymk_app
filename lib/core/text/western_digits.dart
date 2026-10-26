/// Shared input/output digit normalization; punctuation and bidi marks remain
/// unchanged. This does not interpret or validate a monetary amount.
String westernDigits(String value) => String.fromCharCodes(
  value.runes.map((rune) {
    if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
    if (rune >= 0x06f0 && rune <= 0x06f9) return rune - 0x06f0 + 0x30;
    return rune;
  }),
);
