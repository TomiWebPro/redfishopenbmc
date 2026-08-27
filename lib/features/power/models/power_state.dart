/// Power states surfaced by the power management UI (issue #005).
enum PowerState {
  on,
  off,
  poweringOn,
  poweringOff,
  unknown,
}

extension PowerStateX on PowerState {
  static PowerState fromRedfish(String? value) {
    switch (value?.toLowerCase()) {
      case 'on':
        return PowerState.on;
      case 'off':
        return PowerState.off;
      default:
        return PowerState.unknown;
    }
  }

  String get label {
    switch (this) {
      case PowerState.on:
        return 'On';
      case PowerState.off:
        return 'Off';
      case PowerState.poweringOn:
        return 'Powering on…';
      case PowerState.poweringOff:
        return 'Powering off…';
      case PowerState.unknown:
        return 'Unknown';
    }
  }

  bool get isTransitioning =>
      this == PowerState.poweringOn || this == PowerState.poweringOff;
}

enum ResetType {
  on,
  forceOff,
  gracefulShutdown,
  gracefulRestart,
  forceRestart,
  powerCycle,
  nmi;

  String toRedfish() {
    switch (this) {
      case ResetType.on:
        return 'On';
      case ResetType.forceOff:
        return 'ForceOff';
      case ResetType.gracefulShutdown:
        return 'GracefulShutdown';
      case ResetType.gracefulRestart:
        return 'GracefulRestart';
      case ResetType.forceRestart:
        return 'ForceRestart';
      case ResetType.powerCycle:
        return 'PowerCycle';
      case ResetType.nmi:
        return 'Nmi';
    }
  }

  static ResetType? fromRedfish(String? value) {
    switch (value?.toLowerCase()) {
      case 'on':
        return ResetType.on;
      case 'forceoff':
        return ResetType.forceOff;
      case 'gracefulshutdown':
        return ResetType.gracefulShutdown;
      case 'gracefulrestart':
        return ResetType.gracefulRestart;
      case 'forcerestart':
        return ResetType.forceRestart;
      case 'powercycle':
        return ResetType.powerCycle;
      case 'nmi':
        return ResetType.nmi;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ResetType.on:
        return 'Power On';
      case ResetType.forceOff:
        return 'Force Off';
      case ResetType.gracefulShutdown:
        return 'Graceful Shutdown';
      case ResetType.gracefulRestart:
        return 'Graceful Restart';
      case ResetType.forceRestart:
        return 'Force Restart';
      case ResetType.powerCycle:
        return 'Power Cycle';
      case ResetType.nmi:
        return 'NMI';
    }
  }

  bool get isDestructive => this != ResetType.on;

  PowerState get optimisticState {
    switch (this) {
      case ResetType.on:
        return PowerState.poweringOn;
      case ResetType.forceOff:
      case ResetType.gracefulShutdown:
        return PowerState.poweringOff;
      case ResetType.gracefulRestart:
      case ResetType.forceRestart:
      case ResetType.powerCycle:
        return PowerState.poweringOn;
      case ResetType.nmi:
        return PowerState.unknown;
    }
  }

  static const List<ResetType> primaryActions = <ResetType>[
    ResetType.on,
    ResetType.forceOff,
    ResetType.gracefulRestart,
    ResetType.forceRestart,
  ];
}
