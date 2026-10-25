/// OData annotation helpers for Redfish resources.
///
/// Redfish payloads are OData-annotated JSON. Every resource carries
/// `@odata.id` (its canonical URI), `@odata.type` (its schema), and
/// sometimes `@odata.context`. Action targets and collection members are
/// exposed as nested `@odata.id` links. These helpers make the discovery
/// engine (#003) resilient to the many shapes BMCs return.
library;

/// A lightweight, immutable view over a Redfish resource map that exposes the
/// standard OData annotations and the most useful link/action accessors.
///
/// Example:
/// ```dart
/// final res = ODataResource(json);
/// final resetTarget = res.actionTarget('#ComputerSystem.Reset');
/// ```
class ODataResource {
  /// Creates an [ODataResource] view over [raw].
  const ODataResource(this.raw);

  /// The underlying decoded JSON for this resource.
  final Map<String, dynamic> raw;

  /// The `@odata.id` of this resource, or `null` when absent.
  String? get id => _asString(raw['@odata.id']);

  /// The `@odata.type` of this resource (e.g. `#ComputerSystem.v1_20_0.ComputerSystem`).
  String? get type => _asString(raw['@odata.type']);

  /// The `@odata.context` of this resource, or `null` when absent.
  String? get context => _asString(raw['@odata.context']);

  /// The `@odata.etag` of this resource, or `null` when absent.
  ///
  /// DSP0266 §6.5: services that support optimistic concurrency publish the
  /// current entity-tag on the resource; a mutation should send it back via
  /// `If-Match` so a stale write is answered 412 instead of silently
  /// overwriting (#016).
  String? get etag => _asString(raw['@odata.etag']);

  /// Whether this resource is a Redfish *collection* (it has a `Members` array).
  bool get isCollection => raw.containsKey('Members');

  /// The `Members` array, typed, or an empty list when absent.
  List<dynamic> get members {
    final m = raw['Members'];
    return m is List<dynamic> ? m : const <dynamic>[];
  }

  /// The `Actions` map of this resource, or an empty map when absent.
  Map<String, dynamic> get actions {
    final a = raw['Actions'];
    if (a is Map<String, dynamic>) return a;
    if (a is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.fromEntries(
        a.entries.map(
          (MapEntry<dynamic, dynamic> e) =>
              MapEntry<String, dynamic>(e.key.toString(), e.value),
        ),
      );
    }
    return const <String, dynamic>{};
  }

  /// Returns the target URI for [actionName] (e.g. `#ComputerSystem.Reset`),
  /// or `null` if the action is not present.
  String? actionTarget(String actionName) {
    final dynamic action = actions[actionName];
    if (action is Map<String, dynamic>) return _asString(action['target']);
    if (action is Map<dynamic, dynamic>) {
      final dynamic target = action['target'];
      return target is String ? target : null;
    }
    return null;
  }

  /// Extracts the `@odata.id` values referenced by [linkFields] on this
  /// resource. Each field may be either a bare string URI or a map carrying
  /// an `@odata.id` member (the Redfish convention for link properties).
  List<String> linkUris(List<String> linkFields) {
    final List<String> out = <String>[];
    for (final String field in linkFields) {
      final dynamic value = raw[field];
      if (value is String) {
        out.add(value);
      } else if (value is Map<dynamic, dynamic> &&
          value['@odata.id'] is String) {
        out.add(value['@odata.id'] as String);
      }
    }
    return out;
  }

  /// The `@odata.id` member URIs of this collection, in order.
  List<String> memberIds() {
    final List<String> ids = <String>[];
    for (final dynamic entry in members) {
      if (entry is Map<dynamic, dynamic> && entry['@odata.id'] is String) {
        ids.add(entry['@odata.id'] as String);
      } else if (entry is String) {
        ids.add(entry);
      }
    }
    return ids;
  }

  /// Whether [otherType] (a lower-cased `@odata.type`) identifies this
  /// resource as a concrete (non-collection) instance of [suffix].
  ///
  /// For example `isType('computersystem')` matches
  /// `#ComputerSystem.v1_20_0.ComputerSystem` but not
  /// `#ComputerSystemCollection...`.
  bool isType(String suffix) {
    final String? t = type;
    if (t == null) return false;
    final String lower = t.toLowerCase();
    return lower.endsWith('.$suffix') || lower.contains('.$suffix.');
  }
}

/// An immutable `@odata.id` link extracted from a resource.
///
/// Unlike [ODataResource] (which wraps a whole resource), [ODataLink] is just
/// the triple of id/type/context that identifies a resource without its body.
class ODataLink {
  /// Creates an [ODataLink].
  const ODataLink({
    required this.id,
    this.type,
    this.context,
  });

  /// The `@odata.id` (canonical URI) of the linked resource.
  final String id;

  /// The `@odata.type` of the linked resource, when known.
  final String? type;

  /// The `@odata.context` of the linked resource, when known.
  final String? context;

  /// Builds an [ODataLink] from a resource map, or `null` if it has no
  /// `@odata.id`.
  static ODataLink? fromResource(Map<String, dynamic> json) {
    final dynamic id = json['@odata.id'];
    if (id is! String) return null;
    return ODataLink(
      id: id,
      type: _asString(json['@odata.type']),
      context: _asString(json['@odata.context']),
    );
  }

  @override
  String toString() => 'ODataLink($id, type=$type)';
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;
