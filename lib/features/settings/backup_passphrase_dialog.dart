import 'package:flutter/material.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../data/backup/encrypted_backup_envelope.dart';
import '../../l10n/app_localizations.dart';

enum BackupPassphrasePurpose {
  /// A new passphrase, typed twice, with a warning that it cannot be recovered.
  encrypt,

  /// The passphrase of an existing encrypted file.
  decrypt,
}

/// Returns the passphrase, or null when the user cancelled.
Future<String?> showBackupPassphraseDialog(
  BuildContext context, {
  required BackupPassphrasePurpose purpose,
  String? errorText,
}) => showDialog<String>(
  context: context,
  builder: (context) => _BackupPassphraseDialog(purpose: purpose, initialErrorText: errorText),
);

class _BackupPassphraseDialog extends StatefulWidget {
  const _BackupPassphraseDialog({required this.purpose, required this.initialErrorText});

  final BackupPassphrasePurpose purpose;
  final String? initialErrorText;

  @override
  State<_BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<_BackupPassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  bool _isPassphraseVisible = false;

  bool get _isNewPassphrase => widget.purpose == BackupPassphrasePurpose.encrypt;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) Navigator.of(context).pop(_passphraseController.text);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final visibilityToggle = IconButton(
      tooltip: _isPassphraseVisible ? localizations.hidePassphrase : localizations.showPassphrase,
      icon: Icon(_isPassphraseVisible ? KomitIcons.eyeOff : KomitIcons.eye),
      onPressed: () => setState(() => _isPassphraseVisible = !_isPassphraseVisible),
    );
    return AlertDialog(
      title: Text(_isNewPassphrase ? localizations.encryptBackupTitle : localizations.decryptBackupTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNewPassphrase ? localizations.encryptBackupMessage : localizations.decryptBackupMessage,
                style: textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
              ),
              const SizedBox(height: AppSpacing.large),
              TextFormField(
                controller: _passphraseController,
                autofocus: true,
                obscureText: !_isPassphraseVisible,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: _isNewPassphrase ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: _isNewPassphrase ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: localizations.passphrase,
                  errorText: widget.initialErrorText,
                  suffixIcon: visibilityToggle,
                ),
                validator: (passphrase) => _isNewPassphrase && (passphrase ?? '').length < minimumBackupPassphraseLength
                    ? localizations.passphraseTooShort(minimumBackupPassphraseLength)
                    : (passphrase ?? '').isEmpty
                    ? localizations.passphraseRequired
                    : null,
              ),
              if (_isNewPassphrase) ...[
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  obscureText: !_isPassphraseVisible,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: localizations.confirmPassphrase),
                  validator: (confirmation) =>
                      confirmation == _passphraseController.text ? null : localizations.passphrasesDoNotMatch,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(localizations.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, AppSizes.minimumTouchTarget)),
          onPressed: _submit,
          child: Text(_isNewPassphrase ? localizations.encryptAndExport : localizations.unlock),
        ),
      ],
    );
  }
}
