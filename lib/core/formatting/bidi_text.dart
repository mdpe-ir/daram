/// Isolation helpers for mixed Persian/Latin strings.
///
/// Persian text with embedded English words, model names or URLs can render in
/// surprising order around punctuation. Wrapping the Latin fragment with a
/// Unicode isolate keeps its internal order intact inside an RTL paragraph.
const String _lri = '\u2066'; // Left-to-right isolate
const String _pdi = '\u2069'; // Pop directional isolate
const String _rli = '\u2067'; // Right-to-left isolate

/// Keeps [text] as a left-to-right island inside an RTL string.
String isolateLtr(String text) => '$_lri$text$_pdi';

/// Keeps [text] as a right-to-left island inside an LTR string.
String isolateRtl(String text) => '$_rli$text$_pdi';
