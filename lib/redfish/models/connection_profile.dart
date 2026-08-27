// Re-export of the canonical ConnectionProfile / AuthMethod model.
//
// The authoritative definition lives in the `systems` feature layer
// (`features/systems/models/connection_profile.dart`) per issue #004. This
// shim keeps the #002 client layer (`redfish/client/*`) compiling against the
// same class without a dependency inversion in import sites.
export '../../features/systems/models/connection_profile.dart';
