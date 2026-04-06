/// Returns true when [recognized] is close enough to [expected].
///
/// Matching rules (case-insensitive, after trimming):
/// - exact match
/// - recognized contains expected
/// - expected contains recognized (short utterance)
bool sttRecognizedMatchesExpected(String recognized, String expected) {
  final r = recognized.trim().toLowerCase();
  final e = expected.trim().toLowerCase();
  if (r.isEmpty && e.isEmpty) return true;
  if (r.isEmpty || e.isEmpty) return false;
  return r == e || r.contains(e) || e.contains(r);
}
