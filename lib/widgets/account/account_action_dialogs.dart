import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String accountName;
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({
    Key? key,
    required this.accountName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.confirmDelete),
      content: Text(loc.deleteAccountConfirm(accountName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class ConfirmDeactivateDialog extends StatelessWidget {
  final String accountName;
  final VoidCallback onConfirm;

  const ConfirmDeactivateDialog({
    Key? key,
    required this.accountName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.confirmDeactivate),
      content: Text(loc.deactivateAccountConfirm(accountName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("لغو"),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(loc.deactivateAccount,
              style: const TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}

class ConfirmReactivateDialog extends StatelessWidget {
  final String accountName;
  final VoidCallback onConfirm;

  const ConfirmReactivateDialog({
    Key? key,
    required this.accountName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.confirmReactivate),
      content: Text(loc.reactivateAccountConfirm(accountName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child:
              Text(loc.reactivate, style: const TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}
