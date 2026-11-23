/// ASCII-only case folding for Redfish `ConnectType` tokens (issue #009/#021).
///
/// Canonical Redfish connect types (`KVMIP`, `HTML5`, `OEM`, ...) are ASCII, and
/// a BMC may legitimately emit them in any ASCII case and with surrounding
/// whitespace. `String.toUpperCase()` must NOT be used to compare them: its
/// Unicode mapping folds *confusable* code points onto ASCII letters — the
/// dotless i (`ı`, U+0131) uppercases to `I` and the long s (`ſ`, U+017F)
/// uppercases to `S` — so a hostile `KVMıP` token would satisfy a
/// case-insensitive `KVMIP` check and silently flip a capability's `supported`
/// bit even though the operator sees a different, confusable chip (RM-22).
///
/// [kvmConnectTypeKey] folds only ASCII `a`..`z` to `A`..`Z` and preserves every
/// other code point byte-for-byte, so every non-ASCII / fullwidth /
/// compatibility-form token stays distinct from a canonical ASCII token by
/// construction. This is a pure, dependency-free classifier shared by both
/// `fromManager` factories so the console card and the capability card can
/// never disagree about what counts as a real `KVMIP` / `HTML5` / `OEM` token.
library;

/// Returns [value] with ASCII lowercase letters folded to uppercase.
///
/// Non-ASCII code points (dotless/dotted I, Kelvin sign, fullwidth K/V/M/I,
/// combining marks, ...) are preserved verbatim. Callers that read straight
/// from a BMC payload should trim first; [kvmConnectTypeEquals] does so
/// itself.
String kvmConnectTypeKey(String value) {
  final StringBuffer out = StringBuffer();
  for (final int unit in value.codeUnits) {
    out.writeCharCode(unit >= 0x61 && unit <= 0x7A ? unit - 0x20 : unit);
  }
  return out.toString();
}

/// Whether the trimmed [value] equals the canonical [type] after ASCII-only
/// case folding.
///
/// Unlike `value.toUpperCase() == type`, a Unicode confusable never collapses
/// onto a canonical ASCII token: `kvmConnectTypeEquals('KVM\u0131P', 'KVMIP')`
/// is `false` while ordinary ASCII case variants (`'kvmip'`, `' \tKvMiP\n '`)
/// still match.
bool kvmConnectTypeEquals(String value, String type) =>
    kvmConnectTypeKey(value.trim()) == kvmConnectTypeKey(type.trim());
