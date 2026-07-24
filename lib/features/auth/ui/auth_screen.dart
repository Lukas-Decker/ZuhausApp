import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../data/auth_service.dart';

/// Kombinierter Anmelde-/Registrierungsbildschirm.
///
/// Erreichbar aus den Einstellungen. Die App bleibt auch ohne Anmeldung
/// nutzbar; ein Konto schaltet spaeter Familie und Synchronisierung frei.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Mode { signIn, signUp }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  bool _consent = false;

  bool get _isSignUp => _mode == _Mode.signUp;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(authConfiguredProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Konto erstellen' : 'Anmelden')),
      body: !configured
          ? const _NotConfigured()
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp
                                ? 'Konto für Familie und Sync'
                                : 'Willkommen zurück',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Anzeigename',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => _isSignUp && (v ?? '').trim().isEmpty
                                  ? 'Bitte Namen angeben'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'E-Mail',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Passwort',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => (v ?? '').length < 6
                                ? 'Mindestens 6 Zeichen'
                                : null,
                          ),
                          if (!_isSignUp)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _resetPassword,
                                child: const Text('Passwort vergessen?'),
                              ),
                            ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 4),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _consent,
                              onChanged: (v) =>
                                  setState(() => _consent = v ?? false),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: const Text(
                                'Ich stimme der Verarbeitung meiner Daten zur '
                                'Konto- und Familienverwaltung zu.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_isSignUp ? 'Konto erstellen' : 'Anmelden'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'oder',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _google,
                            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                            label: const Text('Mit Google fortfahren'),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(
                                    () => _mode = _isSignUp
                                        ? _Mode.signIn
                                        : _Mode.signUp,
                                  ),
                            child: Text(
                              _isSignUp
                                  ? 'Schon ein Konto? Anmelden'
                                  : 'Noch kein Konto? Registrieren',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Bitte E-Mail angeben';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Ungueltige E-Mail-Adresse';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSignUp && !_consent) {
      _snack('Bitte stimme der Datenverarbeitung zu.');
      return;
    }

    setState(() => _busy = true);
    final service = ref.read(authServiceProvider);
    final result = _isSignUp
        ? await service.signUp(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
          )
        : await service.signIn(email: _email.text, password: _password.text);

    if (!mounted) return;
    setState(() => _busy = false);
    _handleResult(result);
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    final result = await ref.read(authServiceProvider).signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    // Bei Erfolg schliesst der Deep Link den Login ab; nur Fehler zeigen.
    if (result is AuthFailure) _snack(result.message);
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (_validateEmail(email) != null) {
      _snack('Bitte zuerst eine gueltige E-Mail eintragen.');
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(authServiceProvider).sendPasswordReset(email);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(
      result is AuthSuccess
          ? 'E-Mail zum Zurücksetzen gesendet, falls das Konto existiert.'
          : (result as AuthFailure).message,
    );
  }

  void _handleResult(AuthResult result) {
    switch (result) {
      case AuthSuccess():
        Navigator.of(context).pop();
      case AuthNeedsEmailConfirmation(:final email):
        _showConfirmDialog(email);
      case AuthEmailNotConfirmed(:final email):
        _showNotConfirmedDialog(email);
      case AuthFailure(:final message):
        _snack(message);
    }
  }

  void _showNotConfirmedDialog(String email) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_unread_outlined),
        title: const Text('E-Mail noch nicht bestätigt'),
        content: Text(
          'Für $email steht die Bestätigung noch aus. Öffne den Link aus '
          'der Bestätigungs-Mail und melde dich dann erneut an. Keine Mail '
          'erhalten?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Schließen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final result =
                  await ref.read(authServiceProvider).resendConfirmation(email);
              if (!mounted) return;
              _snack(
                result is AuthSuccess
                    ? 'Bestätigungs-Mail erneut gesendet an $email.'
                    : (result as AuthFailure).message,
              );
            },
            child: const Text('Erneut senden'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String email) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined),
        title: const Text('Fast geschafft'),
        content: Text(
          'Wir haben eine Bestätigungs-Mail an $email geschickt. Bitte '
          'öffne den Link darin und melde dich danach an.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() => _mode = _Mode.signIn);
            },
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Kein Konto-Server eingerichtet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Diese App-Version wurde ohne Supabase-Zugangsdaten gebaut. '
              'Alle Funktionen laufen lokal im Gastmodus; Anmeldung, Familie '
              'und Synchronisierung sind deaktiviert.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
