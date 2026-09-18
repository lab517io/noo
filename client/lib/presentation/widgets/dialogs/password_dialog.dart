import 'package:flutter/material.dart';

/// Dialog result containing password
class PasswordDialogResult {
  final String password;

  const PasswordDialogResult({
    required this.password,
  });
}

/// Dialog for entering database password
class PasswordDialog extends StatefulWidget {
  /// Title for the dialog
  final String title;

  /// Whether this is for creating a new database (shows confirmation field)
  final bool isNewDatabase;

  /// Optional error message to display
  final String? errorMessage;

  /// Optional database file path to display to the user
  final String? databasePath;

  const PasswordDialog({
    super.key,
    required this.title,
    this.isNewDatabase = false,
    this.errorMessage,
    this.databasePath,
  });

  /// Show dialog for opening existing database
  static Future<PasswordDialogResult?> showOpen(
    BuildContext context, {
    String? errorMessage,
    String? databasePath,
  }) {
    return showDialog<PasswordDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        title: 'Enter Password',
        isNewDatabase: false,
        errorMessage: errorMessage,
        databasePath: databasePath,
      ),
    );
  }

  /// Show dialog for creating new database
  static Future<PasswordDialogResult?> showCreate(
    BuildContext context, {
    String? databasePath,
  }) {
    return showDialog<PasswordDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        title: 'Set Database Password',
        isNewDatabase: true,
        databasePath: databasePath,
      ),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      // Scrollable so the content shrinks instead of overflowing when the
      // on-screen keyboard takes most of a phone's height.
      scrollable: true,
      content: SizedBox(
        width: 350,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.databasePath != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tooltip(
                          message: widget.databasePath!,
                          child: SelectableText(
                            widget.databasePath!,
                            maxLines: 3,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (widget.isNewDatabase && value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
                onChanged: widget.isNewDatabase
                    ? (_) => setState(() {})
                    : null,
                onFieldSubmitted: (_) {
                  if (!widget.isNewDatabase) {
                    _submit();
                  }
                },
              ),
              if (widget.isNewDatabase) ...[
                const SizedBox(height: 8),
                _PasswordStrengthIndicator(password: _passwordController.text),
              ],
              if (widget.isNewDatabase) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (widget.isNewDatabase) ...[
                const SizedBox(height: 8),
                Text(
                  'The password will be used to encrypt your database. '
                  'If you forget it, the data cannot be recovered.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isNewDatabase ? 'Create' : 'Open'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        PasswordDialogResult(
          password: _passwordController.text,
        ),
      );
    }
  }
}

/// Live strength meter shown while choosing a password for a new database.
/// Heuristic only (length + character variety) — it nudges the user toward
/// longer, mixed passwords without blocking any choice.
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  /// 0..4: very weak, weak, fair, good, strong.
  static int estimateStrength(String password) {
    if (password.isEmpty) return 0;

    var classes = 0;
    if (password.contains(RegExp(r'[a-z]'))) classes++;
    if (password.contains(RegExp(r'[A-Z]'))) classes++;
    if (password.contains(RegExp(r'[0-9]'))) classes++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) classes++;

    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (classes >= 2) score++;
    if (classes >= 3) score++;

    return score.clamp(0, 4);
  }

  static const _labels = ['Very weak', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    Color(0xFFD32F2F), // red
    Color(0xFFF57C00), // orange
    Color(0xFFFBC02D), // amber
    Color(0xFF7CB342), // light green
    Color(0xFF388E3C), // green
  ];

  @override
  Widget build(BuildContext context) {
    final score = estimateStrength(password);
    final color = _colors[score];

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: password.isEmpty ? 0 : (score + 1) / 5,
              minHeight: 6,
              color: color,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            password.isEmpty ? '' : _labels[score],
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: password.isEmpty
                      ? Theme.of(context).colorScheme.outline
                      : color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
