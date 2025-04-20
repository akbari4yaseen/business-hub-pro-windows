import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.about),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        const AssetImage('assets/images/app_logo.png'),
                  ),

                  const SizedBox(height: 24),

                  // App name in bold primary color
                  Text(
                    loc.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.primary,
                      fontFamily: "IRANSans",
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description text
                  Text(
                    loc.aboutDescription,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // A subtle divider…
                  Divider(color: cs.outline),

                  const SizedBox(height: 16),

                  // Copyright line
                  Text(
                    '© ${DateTime.now().year} BusinessHub',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
