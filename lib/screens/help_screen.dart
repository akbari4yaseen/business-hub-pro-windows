import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// A help screen showing app info and contact options.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Unified padding
  static const EdgeInsets _padding = EdgeInsets.all(24);
  static const String _logoAsset = 'assets/images/app_logo.png';
  static const AssetImage _logoImage = AssetImage(_logoAsset);

  // Contact info
  static const String _email = 'akbari01.dev@gmail.com';
  static const String _whatsapp = '+93 793828948';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: colors.primary, fontFamily: 'VazirBold');
    final descStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: colors.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text(loc.help)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _padding,
          child: Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: _padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: _logoImage,
                    ),
                    const SizedBox(height: 24),
                    Text(loc.helpTitle, style: titleStyle),
                    const SizedBox(height: 12),
                    Text(
                      loc.helpDescription,
                      textAlign: TextAlign.center,
                      style: descStyle,
                    ),
                    const SizedBox(height: 24),
                    Divider(color: colors.outline),
                    const SizedBox(height: 16),
                    _ContactTile(
                      icon: Icons.email_outlined,
                      label: loc.email,
                      subtitle: _email,
                      onTap: () => _launchMail(context),
                    ),
                    _ContactTile(
                      icon: FontAwesomeIcons.whatsapp,
                      label: loc.whatsApp,
                      subtitle: '\u200E${_whatsapp}',
                      onTap: () => _launchWhatsApp(context),
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

  static Future<void> _launchMail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open mail client')),
      );
    }
  }

  static Future<void> _launchWhatsApp(BuildContext context) async {
    final number = _whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.https('api.whatsapp.com', '/send', {'phone': number});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }
}

/// A reusable contact tile with icon, title, subtitle, and tap callback.
class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final leading = icon == FontAwesomeIcons.whatsapp
        ? FaIcon(icon, color: color)
        : Icon(icon, color: color);

    return ListTile(
      leading: leading,
      title: Text(label),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 16,
      onTap: onTap,
    );
  }
}
