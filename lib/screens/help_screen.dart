import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  // Constants for styling and content
  static const _padding = EdgeInsets.all(24);
  static const _cardPadding = EdgeInsets.all(32);
  static const _logoAsset = 'assets/images/app_logo.png';
  static const _email = 'support@businesshub.com';
  static const _whatsappNumber = '+93 793 828 948';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final titleStyle = textTheme.titleLarge?.copyWith(
      color: cs.primary,
      fontFamily: 'IRANSans',
    );
    final descriptionStyle = textTheme.bodyLarge?.copyWith(
      color: cs.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.help)),
      body: SafeArea(
        child: ListView(
          padding: _padding,
          children: [
            Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: _cardPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: const AssetImage(_logoAsset),
                    ),
                    const SizedBox(height: 24),
                    Text(loc.helpTitle, style: titleStyle),
                    const SizedBox(height: 12),
                    Text(
                      loc.helpDescription,
                      textAlign: TextAlign.center,
                      style: descriptionStyle,
                    ),
                    const SizedBox(height: 24),
                    Divider(color: cs.outline),
                    const SizedBox(height: 16),
                    _buildContactTile(
                      context,
                      icon: Icons.email_outlined,
                      title: loc.email,
                      subtitle: _email,
                    ),
                    _buildContactTile(
                      context,
                      icon: FontAwesomeIcons.whatsapp,
                      title: loc.whatsApp,
                      subtitle: '\u200E${_whatsappNumber}',
                      isFa: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFa = false,
  }) {
    final leading = isFa
        ? FaIcon(icon, color: Theme.of(context).colorScheme.primary)
        : Icon(icon, color: Theme.of(context).colorScheme.primary);

    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 16,
    );
  }
}
