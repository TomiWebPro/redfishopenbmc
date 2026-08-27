import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';

/// Validates a Redfish host entry (hostname or IPv4/IPv6 literal).
String? validateHost(String? value) {
  final String v = (value ?? '').trim();
  if (v.isEmpty) return 'Host is required';
  final bool isIpv4 = RegExp(
    r'^(25[0-5]|2[0-4]\d|1?\d?\d)(\.(25[0-5]|2[0-4]\d|1?\d?\d)){3}$',
  ).hasMatch(v);
  final bool isIpv6 = RegExp(r'^\[?([0-9a-fA-F:]+)\]?$').hasMatch(v);
  final bool isHostname = RegExp(
    r'^(?=.{1,253}$)([a-zA-Z0-9](-?[a-zA-Z0-9])*\.)*[a-zA-Z0-9](-?[a-zA-Z0-9])*$',
  ).hasMatch(v);
  if (!isIpv4 && !isIpv6 && !isHostname) return 'Enter a valid host or IP';
  return null;
}

/// Validates a TCP port in the range 1–65535.
String? validatePort(String? value) {
  final String v = (value ?? '').trim();
  if (v.isEmpty) return 'Port is required';
  final int? parsed = int.tryParse(v);
  if (parsed == null) return 'Port must be a number';
  if (parsed < 1 || parsed > 65535) return 'Port must be 1–65535';
  return null;
}

/// Reusable form for creating or editing a [ConnectionProfile].
///
/// Callers pass an optional [initial] profile (for edit) and receive the
/// assembled profile via [onSubmit] when the form validates. The form never
/// persists anything itself — it only emits a [ConnectionProfile].
class SystemProfileForm extends StatefulWidget {
  /// Creates a [SystemProfileForm].
  const SystemProfileForm({
    required this.onSubmit,
    this.initial,
    this.showButtons = true,
    super.key,
  });

  /// Called with a validated [ConnectionProfile] on save.
  final ValueChanged<ConnectionProfile> onSubmit;

  /// Profile to pre-populate (null = create mode).
  final ConnectionProfile? initial;

  /// Whether to render the action buttons inside the form.
  final bool showButtons;

  @override
  State<SystemProfileForm> createState() => _SystemProfileFormState();
}

class _SystemProfileFormState extends State<SystemProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _host = TextEditingController();
  final TextEditingController _port = TextEditingController();
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  late bool _useTls;
  late AuthMethod _authMethod;
  late bool _rememberPassword;
  late bool _allowSelfSigned;

  @override
  void initState() {
    super.initState();
    final ConnectionProfile? p = widget.initial;
    _name.text = p?.name ?? '';
    _host.text = p?.host ?? '';
    _port.text = (p?.port ?? 443).toString();
    _user.text = p?.username ?? '';
    _pass.text = p?.password ?? '';
    _useTls = p?.useTls ?? true;
    _authMethod = p?.authMethod ?? AuthMethod.session;
    _rememberPassword = p?.rememberPassword ?? false;
    _allowSelfSigned = p?.allowSelfSigned ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  ConnectionProfile _build() {
    final String name = _name.text.trim();
    final String host = _host.text.trim();
    final String user = _user.text.trim();
    final String pass = _pass.text;
    return ConnectionProfile(
      id: widget.initial?.id ?? '',
      name: name.isEmpty ? null : name,
      host: host,
      port: int.parse(_port.text.trim()),
      scheme: _useTls ? 'https' : 'http',
      allowSelfSigned: _allowSelfSigned,
      preferSessionAuth: _authMethod == AuthMethod.session,
      authMethod: _authMethod,
      username: user.isEmpty ? null : user,
      password: pass.isEmpty ? null : pass,
      rememberPassword: _rememberPassword,
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_build());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Display name (optional)',
              hintText: 'e.g. bmc-lab-01',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _host,
            decoration: const InputDecoration(
              labelText: 'Host / IP',
              hintText: '192.168.1.10 or bmc.example.com',
            ),
            validator: validateHost,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _port,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '443',
            ),
            keyboardType: TextInputType.number,
            validator: validatePort,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Use TLS (HTTPS)'),
            subtitle: const Text('TLS-first transport is recommended'),
            value: _useTls,
            onChanged: (bool v) => setState(() => _useTls = v),
            contentPadding: EdgeInsets.zero,
          ),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Auth method'),
            child: DropdownButton<AuthMethod>(
              value: _authMethod,
              isExpanded: true,
              items: const <DropdownMenuItem<AuthMethod>>[
                DropdownMenuItem<AuthMethod>(
                  value: AuthMethod.session,
                  child: Text('Session (token)'),
                ),
                DropdownMenuItem<AuthMethod>(
                  value: AuthMethod.basic,
                  child: Text('Basic'),
                ),
              ],
              onChanged: (AuthMethod? v) {
                if (v != null) setState(() => _authMethod = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _user,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pass,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SwitchListTile(
            title: const Text('Remember password'),
            subtitle: const Text('Stored encrypted in the OS keystore'),
            value: _rememberPassword,
            onChanged: (bool v) => setState(() => _rememberPassword = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Allow self-signed certificate'),
            value: _allowSelfSigned,
            onChanged: (bool v) => setState(() => _allowSelfSigned = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_allowSelfSigned)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Self-signed certificates disable TLS verification. '
                      'Only enable for trusted, isolated management networks.',
                    ),
                  ),
                ],
              ),
            ),
          if (widget.showButtons) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? 'Add system' : 'Save'),
            ),
          ],
        ],
      ),
    );
  }
}
