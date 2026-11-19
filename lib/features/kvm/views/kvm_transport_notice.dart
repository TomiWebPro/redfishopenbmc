/// Shared, user-facing transport-safety copy for the KVM cards (issues
/// #009 / #021).
///
/// Both the per-console card (`KvmView._ConsoleCard`) and the per-manager
/// capability card (`KvmCapabilityCard`) surface a resolved console endpoint to
/// the operator. When that endpoint uses plaintext HTTP, console video and
/// injected input (potentially credentials) would travel unencrypted, so both
/// cards must warn with the **exact same** sentence — a single source of truth
/// keeps the two views from drifting. The per-console viewer has its own, more
/// detailed `kvmLaunchStatusText(KvmLaunchStrategy.insecureHtml5)` message,
/// which is intentionally distinct.
///
/// This is pure presentation copy: it opens no URL and never changes transport
/// security (production TLS is never weakened).
library;

/// The single visible + announced string for a plaintext-HTTP console URI
/// warning. The card rows use `excludeSemantics`, so this is both the text a
/// sighted operator reads and the label a screen reader announces.
const String kvmInsecureTransportNotice =
    'Unencrypted HTTP console URI. Configure the BMC console to use HTTPS '
    'before opening it in a browser.';
