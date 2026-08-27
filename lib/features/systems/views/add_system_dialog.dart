import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/system_profile_form.dart';

/// Modal dialog for creating a new BMC connection profile.
class AddSystemDialog extends StatelessWidget {
  /// Creates an [AddSystemDialog].
  const AddSystemDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add system'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: SystemProfileForm(
            onSubmit: (ConnectionProfile profile) {
              ProviderScope.containerOf(context)
                  .read(systemManagerProvider.notifier)
                  .addProfile(profile);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}

/// Opens the [AddSystemDialog] to add a new BMC connection profile.
void showAddSystemDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const AddSystemDialog(),
  );
}
