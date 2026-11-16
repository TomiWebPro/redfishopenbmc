/// Models for the Redfish Bios resource and pending `@Redfish.Settings`
/// surface (issue #028, smallest safe slice).
///
/// Tolerant parsing: missing/mistyped fields degrade to `null` or empty values
/// rather than throwing so capability-gated consumers can render "not exposed"
/// states safely.
///
/// References:
/// - DMTF DSP0266 §9.9 payload annotations (`@Redfish.Settings` / settings
///   object ETag used as the #016 If-Match precondition token)
/// - `Bios.v1_2_2.json` (served) / `Settings.v1_3_5.json` (served)
library;

/// A message reported on the `@Redfish.Settings` annotation (e.g. a failed
/// apply such as `Base.1.0.SettingsFailed`).
class BiosSettingsMessage {
  /// Creates a [BiosSettingsMessage].
  const BiosSettingsMessage({
    this.messageId,
    this.relatedProperties = const <String>[],
    this.message,
    this.severity,
  });

  /// Registry message id (for example `Base.1.0.SettingsFailed`).
  final String? messageId;

  /// JSON-pointer-like properties related to the message.
  final List<String> relatedProperties;

  /// Optional human-readable message text, when provided.
  final String? message;

  /// Optional severity, when provided.
  final String? severity;

  /// Parses a message entry from a `@Redfish.Settings.Messages` array.
  factory BiosSettingsMessage.fromJson(Map<String, dynamic> json) {
    final dynamic related = json['RelatedProperties'];
    return BiosSettingsMessage(
      messageId: json['MessageId'] as String?,
      relatedProperties: related is List<dynamic>
          ? related.map((dynamic e) => e.toString()).toList(growable: false)
          : const <String>[],
      message: json['Message'] as String?,
      severity: json['Severity'] as String?,
    );
  }
}

/// The `@Redfish.Settings` payload annotation attached to a Bios resource.
///
/// Per DSP0266 §9.9.4 the settings-object [etag] is the optimistic-concurrency
/// token a PATCH of the pending settings resource must send as `If-Match`.
class BiosSettingsAnnotation {
  /// Creates a [BiosSettingsAnnotation].
  const BiosSettingsAnnotation({
    this.etag,
    this.settingsObjectUri,
    this.time,
    this.messages = const <BiosSettingsMessage>[],
    this.odataType,
  });

  /// Settings-object ETag (not necessarily HTTP-quoted in the payload).
  final String? etag;

  /// `SettingsObject.@odata.id` — the URI of the pending settings resource.
  final String? settingsObjectUri;

  /// Timestamp reported by the service for the settings state, if any.
  final String? time;

  /// Messages from the last apply attempt.
  final List<BiosSettingsMessage> messages;

  /// `@odata.type` of the settings annotation, when present.
  final String? odataType;

  /// Parses a `@Redfish.Settings` annotation map.
  factory BiosSettingsAnnotation.fromJson(Map<String, dynamic> json) {
    final dynamic messages = json['Messages'];
    final dynamic settingsObject = json['SettingsObject'];
    final String? settingsUri = settingsObject is Map<String, dynamic>
        ? settingsObject['@odata.id'] as String?
        : null;
    return BiosSettingsAnnotation(
      etag: json['ETag'] as String?,
      settingsObjectUri: settingsUri,
      time: json['Time'] as String?,
      messages: messages is List<dynamic>
          ? messages
              .whereType<Map<String, dynamic>>()
              .map(BiosSettingsMessage.fromJson)
              .toList(growable: false)
          : const <BiosSettingsMessage>[],
      odataType: json['@odata.type'] as String?,
    );
  }
}

/// Action targets exposed by the Bios resource.
class BiosActions {
  /// Creates [BiosActions].
  const BiosActions({this.resetBiosTarget, this.changePasswordTarget});

  /// Target URI for `#Bios.ResetBios`, when advertised.
  final String? resetBiosTarget;

  /// Target URI for `#Bios.ChangePassword`, when advertised.
  ///
  /// This is surfaced for capability detection only; callers must never send
  /// real credentials except through an explicitly safe, reviewed flow.
  final String? changePasswordTarget;

  /// Parses action targets from a Bios resource body.
  factory BiosActions.fromJson(Map<String, dynamic> json) {
    final dynamic actions = json['Actions'];
    if (actions is! Map<String, dynamic>) {
      return const BiosActions();
    }
    String? targetOf(String key) {
      final dynamic action = actions[key];
      if (action is Map<String, dynamic>) {
        final dynamic target = action['target'];
        return target is String ? target : null;
      }
      return null;
    }

    return BiosActions(
      resetBiosTarget: targetOf('#Bios.ResetBios'),
      changePasswordTarget: targetOf('#Bios.ChangePassword'),
    );
  }
}

/// The current (or pending) Bios attribute set.
class BiosAttributes {
  /// Creates [BiosAttributes].
  const BiosAttributes(this.values);

  /// Raw attribute key/value map as served by the BMC.
  final Map<String, dynamic> values;

  /// Parses `Attributes` from a Bios-like resource body.
  factory BiosAttributes.fromJson(Map<String, dynamic> json) {
    final dynamic attrs = json['Attributes'];
    if (attrs is Map<String, dynamic>) {
      return BiosAttributes(Map<String, dynamic>.from(attrs));
    }
    return const BiosAttributes(<String, dynamic>{});
  }

  /// Returns keys whose values differ between [current] and [pending].
  static Set<String> diffKeys(BiosAttributes current, BiosAttributes pending) {
    final Set<String> keys = <String>{
      ...current.values.keys,
      ...pending.values.keys,
    };
    final Set<String> changed = <String>{};
    for (final String key in keys) {
      if (!_deepEquals(current.values[key], pending.values[key])) {
        changed.add(key);
      }
    }
    return changed;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final Object? key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// A Bios resource (current settings view).
class BiosResource {
  /// Creates a [BiosResource].
  const BiosResource({
    this.id,
    this.name,
    this.attributeRegistry,
    this.attributes = const BiosAttributes(<String, dynamic>{}),
    this.resetBiosToDefaultsPending,
    this.settings,
    this.actions = const BiosActions(),
    this.odataId,
    this.odataType,
  });

  /// Resource id (for example `Bios`).
  final String? id;

  /// Resource name.
  final String? name;

  /// Attribute registry identifier.
  final String? attributeRegistry;

  /// Current attribute values.
  final BiosAttributes attributes;

  /// Whether a reset-to-defaults operation is pending.
  final bool? resetBiosToDefaultsPending;

  /// `@Redfish.Settings` annotation, when present.
  final BiosSettingsAnnotation? settings;

  /// Advertised actions.
  final BiosActions actions;

  /// `@odata.id` of the resource.
  final String? odataId;

  /// `@odata.type` of the resource.
  final String? odataType;

  /// URI of the pending settings resource, if advertised.
  String? get pendingSettingsUri => settings?.settingsObjectUri;

  /// Settings-object ETag to use as `If-Match` when patching pending settings.
  String? get settingsEtag => settings?.etag;

  /// Parses a Bios resource body.
  factory BiosResource.fromJson(Map<String, dynamic> json) {
    final dynamic settings = json['@Redfish.Settings'];
    return BiosResource(
      id: json['Id'] as String?,
      name: json['Name'] as String?,
      attributeRegistry: json['AttributeRegistry'] as String?,
      attributes: BiosAttributes.fromJson(json),
      resetBiosToDefaultsPending: json['ResetBiosToDefaultsPending'] as bool?,
      settings: settings is Map<String, dynamic>
          ? BiosSettingsAnnotation.fromJson(settings)
          : null,
      actions: BiosActions.fromJson(json),
      odataId: json['@odata.id'] as String?,
      odataType: json['@odata.type'] as String?,
    );
  }
}

/// The pending settings resource served at `Bios/Settings`.
class BiosPendingSettings {
  /// Creates [BiosPendingSettings].
  const BiosPendingSettings({
    this.id,
    this.name,
    this.attributeRegistry,
    this.attributes = const BiosAttributes(<String, dynamic>{}),
    this.odataId,
    this.odataType,
  });

  /// Resource id (for example `Settings`).
  final String? id;

  /// Resource name.
  final String? name;

  /// Attribute registry identifier.
  final String? attributeRegistry;

  /// Pending attribute values.
  final BiosAttributes attributes;

  /// `@odata.id` of the resource.
  final String? odataId;

  /// `@odata.type` of the resource.
  final String? odataType;

  /// Parses a pending Bios settings resource body.
  factory BiosPendingSettings.fromJson(Map<String, dynamic> json) {
    return BiosPendingSettings(
      id: json['Id'] as String?,
      name: json['Name'] as String?,
      attributeRegistry: json['AttributeRegistry'] as String?,
      attributes: BiosAttributes.fromJson(json),
      odataId: json['@odata.id'] as String?,
      odataType: json['@odata.type'] as String?,
    );
  }
}
