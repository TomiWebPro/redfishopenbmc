import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/system_profile_form.dart';

/// Full-page editor for an existing [ConnectionProfile].
///
/// Renders the [SystemProfileForm] inside a [Scaffold] and persists changes
/// through [SystemManager.updateProfile] on save.
class EditSystemPage extends StatelessWidget {
  /// Creates an [EditSystemPage] for [profile].
  const EditSystemPage({required this.profile, super.key});

  /// The profile being edited.
  final ConnectionProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit system')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SystemProfileForm(
          initial: profile,
          onSubmit: (ConnectionProfile updated) {
            ProviderScope.containerOf(context)
                .read(systemManagerProvider.notifier)
                .updateProfile(updated);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// Opens the [EditSystemPage] as a dialog for [profile].
void showEditSystemDialog(BuildContext context, ConnectionProfile profile) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Edit system'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: SystemProfileForm(
            initial: profile,
            onSubmit: (ConnectionProfile updated) {
              ProviderScope.containerOf(ctx)
                  .read(systemManagerProvider.notifier)
                  .updateProfile(updated);
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    ),
  );
}
