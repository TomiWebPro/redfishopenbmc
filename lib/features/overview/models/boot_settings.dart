/// The ComputerSystem `Boot` block (issue #016 PATCH flow).
///
/// Tolerant parse of the `BootSourceOverride*` surface per the served
/// `ComputerSystem.v1_22_0` schema:
///  * `BootSourceOverrideEnabled` — `Once` (one-time override), `Continuous`,
///    or `Disabled` (schema `BootSourceOverrideEnabled` enum);
///  * `BootSourceOverrideTarget` — the source to boot next (schema
///    `BootSource` enum: `None`, `Pxe`, `Cd`, `Usb`, `Hdd`, `BiosSetup`,
///    `Utilities`, `Diags`, `SDCard`, `UefiTarget`);
///  * `BootSourceOverrideTarget@Redfish.AllowableValues` — the DMTF mockup /
///    bmcweb-style annotation enumerating exactly the targets the BMC accepts
///    for a PATCH (DSP0266 §9.9.2 "Allowable values for strings" — the
///    annotation-form allow-list rule #022/#016);
///  * `BootSourceOverrideMode` — `UEFI` / `Legacy` (read-only here).
///
/// Every field is nullable so a BMC that omits parts of the block (or the
/// whole block) yields a usable object instead of a crash.
class BootSettings {
  /// Creates a [BootSettings].
  const BootSettings({
    this.enabled,
    this.target,
    this.mode,
    this.uefiTarget,
    this.allowableTargets = const <String>[],
  });

  /// `BootSourceOverrideEnabled` (`Once` / `Continuous` / `Disabled`), when
  /// reported.
  final String? enabled;

  /// `BootSourceOverrideTarget` (current override), when reported.
  final String? target;

  /// `BootSourceOverrideMode` (`UEFI` / `Legacy`), when reported.
  final String? mode;

  /// `UefiTargetBootSourceOverride` (explicit UEFI path), when reported.
  final String? uefiTarget;

  /// The `BootSourceOverrideTarget@Redfish.AllowableValues` annotation — the
  /// targets the BMC accepts for a PATCH. Empty when the BMC publishes no
  /// annotation (then a mutation flow must not hardcode targets and should
  /// refuse rather than guess).
  final List<String> allowableTargets;

  /// Whether the BMC advertised the allow-list a mutation flow needs to
  /// pre-validate against (the #022/#016 rule: never send an unlisted value).
  bool get hasAllowableTargets => allowableTargets.isNotEmpty;

  /// Whether [target] is in the advertised allow-list (case-sensitive per the
  /// schema enum). Always `false` when the BMC published no annotation.
  bool allows(String? target) =>
      target != null && allowableTargets.contains(target);

  /// Builds a [BootSettings] from a ComputerSystem JSON body.
  factory BootSettings.fromRedfish(Map<String, dynamic> json) {
    final dynamic boot = json['Boot'];
    final Map<String, dynamic> bootMap =
        boot is Map<String, dynamic> ? boot : const <String, dynamic>{};
    final dynamic allowed = bootMap['BootSourceOverrideTarget@Redfish.AllowableValues'];
    return BootSettings(
      enabled: bootMap['BootSourceOverrideEnabled'] as String?,
      target: bootMap['BootSourceOverrideTarget'] as String?,
      mode: bootMap['BootSourceOverrideMode'] as String?,
      uefiTarget: bootMap['UefiTargetBootSourceOverride'] as String?,
      allowableTargets: allowed is List<dynamic>
          ? allowed.map((dynamic e) => e.toString()).toList()
          : const <String>[],
    );
  }

  /// Returns a copy with the given fields overridden.
  BootSettings copyWith({
    String? enabled,
    String? target,
    String? mode,
    String? uefiTarget,
    List<String>? allowableTargets,
  }) =>
      BootSettings(
        enabled: enabled ?? this.enabled,
        target: target ?? this.target,
        mode: mode ?? this.mode,
        uefiTarget: uefiTarget ?? this.uefiTarget,
        allowableTargets: allowableTargets ?? this.allowableTargets,
      );
}
