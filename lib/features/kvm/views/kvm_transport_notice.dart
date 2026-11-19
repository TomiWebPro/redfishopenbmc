/// Shared, user-facing transport-safety copy for the KVM cards (issues
/// #009 / #021).
///
/// Both the per-console card (`KvmView._ConsoleCard`) and the per-manager
/// capability card (`KvmCapabilityCard`) surface a resolved console endpoint to
/// the operator. When that endpoint uses plaintext HTTP, console video and
/// injected input (potentially credentials) would travel unencrypted, so both
/// cards must warn with the **exact same** sentence — a single source of truth
/// keeps the two views from drifting. The per-console viewer has its own, more
/// detailed `kvmLaunchStatusText` message for `insecureHtml5` / `insecureHttp`,
/// which is intentionally distinct.
///
/// This is pure presentation copy: it opens no URL and never changes transport
/// security (production TLS is never weakened).
///
/// The same single-source-of-truth approach is used for the two session/
/// enablement notices that appear on more than one KVM surface (RU-2):
/// [kvmSessionPersistenceNotice] and [kvmDisabledOnBmcNotice]. Keeping each of
/// those strings in one place guarantees a screen reader hears identical
/// wording on every surface that shows it — the gated list view, the
/// per-manager capability card and the per-console viewer — with visible text
/// always equal to the merged `excludeSemantics` label.
library;

/// The single visible + announced string for a plaintext-HTTP console URI
/// warning. The card rows use `excludeSemantics`, so this is both the text a
/// sighted operator reads and the label a screen reader announces.
const String kvmInsecureTransportNotice =
    'Unencrypted HTTP console URI. Configure the BMC console to use HTTPS '
    'before opening it in a browser.';

/// The single visible + announced string for the session-persistence notice.
///
/// A BMC console session outlives the app's backgrounding and persists until
/// the manager's own timeout, so the operator is told to close the tab to
/// disconnect. Shown on the gated KVM list view and on the per-console viewer
/// (issue #009; RU-2 cross-surface a11y consistency).
const String kvmSessionPersistenceNotice =
    'Console persists until manager timeout — close tab to disconnect';

/// The single visible + announced string for a disabled KVM service.
///
/// Shown by the per-manager capability card when the manager reports no
/// enabled console (issue #009; RU-2 cross-surface a11y consistency).
const String kvmDisabledOnBmcNotice =
    'KVM disabled on BMC. Enable the console service in the BMC settings.';

/// The single visible + announced disclosure shown on the per-console viewer
/// while a pure-UI console session is active (EP-U4 / #009).
///
/// The viewer is the app's full-screen console surface: entering it opens a
/// client-side session for that manager and leaving it ends the session. The
/// disclosure tells the operator how to end the session explicitly, and is
/// rendered as one merged `excludeSemantics` node so visible text always equals
/// the announced label (no screen-reader-only wording).
const String kvmSessionActiveNotice =
    'Console session active — go back or tap Disconnect console to end it';

/// The single visible + announced disclosure shown on the per-console viewer
/// when no pure-UI console session is active (EP-U4 / #009).
const String kvmSessionIdleNotice = 'No active console session';
