import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'database_settings_screen.dart';
import '../../themes/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        backgroundColor: themeProvider.appBarBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.appBarTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // Currency Settings
            _buildDropdownSetting(
              context: context,
              icon: Icons.currency_exchange,
              title: AppLocalizations.of(context)!.defaultCurrency,
              value: settingsProvider.defaultCurrency,
              items: SettingsProvider.availableCurrencies,
              onChanged: (value) =>
                  settingsProvider.setSetting('default_currency', value!),
            ),

            // Transaction Type Settings
            _buildDropdownSetting(
              context: context,
              icon: Icons.compare_arrows,
              title: AppLocalizations.of(context)!.defaultTransactionType,
              value: settingsProvider.defaultTransaction,
              items: SettingsProvider.availableTransactionTypes,
              onChanged: (value) =>
                  settingsProvider.setSetting('default_transaction', value!),
              itemLabelBuilder: (item) {
                switch (item) {
                  case 'credit':
                    return AppLocalizations.of(context)!.credit;
                  case 'debit':
                    return AppLocalizations.of(context)!.debit;
                  default:
                    return item;
                }
              },
            ),

            // Track Settings
            _buildDropdownSetting(
              context: context,
              icon: Icons.wallet_membership,
              title: AppLocalizations.of(context)!.defaultTrack,
              value: settingsProvider.defaultTrackOption,
              items: SettingsProvider.availableTrackOptions,
              onChanged: (value) =>
                  settingsProvider.setSetting('default_track_option', value!),
              itemLabelBuilder: (item) {
                switch (item) {
                  case 'treasure':
                    return AppLocalizations.of(context)!.treasure;
                  case 'noTreasure':
                    return AppLocalizations.of(context)!.noTreasure;
                  default:
                    return item;
                }
              },
            ),

            // Language Settings
            _buildDropdownSetting(
              context: context,
              icon: Icons.language,
              title: AppLocalizations.of(context)!.appLanguage,
              value: settingsProvider.appLanguage,
              items: SettingsProvider.availableLanguages,
              onChanged: (value) =>
                  settingsProvider.setSetting('app_language', value!),
              itemLabelBuilder: (item) {
                switch (item) {
                  case 'fa':
                    return AppLocalizations.of(context)!.languageFarsi;
                  case 'ps':
                    return AppLocalizations.of(context)!.languagePashto;
                  case 'en':
                    return AppLocalizations.of(context)!.languageEnglish;
                  default:
                    return item;
                }
              },
            ),

            // Theme Settings
            _buildThemeSwitch(context, themeProvider, settingsProvider),

            // Inactivity Days Setting
            _buildDropdownSetting(
              context: context,
              icon: Icons.notifications_on,
              title: AppLocalizations.of(context)!.inactivityDays,
              value: settingsProvider.inactivityDays.toString(),
              items: SettingsProvider.availableInactivityDays,
              onChanged: (value) =>
                  settingsProvider.setSetting('inactivity_days', value!),
            ),

            // Fingerprint Authentication Setting
            _buildSwitchSetting(
                context: context,
                icon: Icons.fingerprint,
                title: AppLocalizations.of(context)!.useFingerprint,
                value: settingsProvider.useFingerprint,
                onChanged: (value) => settingsProvider.setSetting(
                    'use_fingerprint', value ? 'true' : 'false')),

            _buildSettingsOption(
              context,
              icon: Icons.lock,
              text: AppLocalizations.of(context)!.password,
              onTap: () => Navigator.pushNamed(context, '/user_settings'),
            ),

            _buildSettingsOption(
              context,
              icon: Icons.business,
              text: AppLocalizations.of(context)!.companyInfo,
              onTap: () => Navigator.pushNamed(context, '/company_info'),
            ),

            _buildSettingsOption(
              context,
              icon: Icons.storage,
              text: AppLocalizations.of(context)!.databaseSettings,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DatabaseSettingsScreen()),
                );
              },
            ),

            _buildSettingsOption(
              context,
              icon: Icons.logout,
              text: AppLocalizations.of(context)!.logout,
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? itemLabelBuilder,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: DropdownButton<String>(
          value: value,
          items: items.map((String item) {
            final label =
                itemLabelBuilder != null ? itemLabelBuilder(item) : item;
            return DropdownMenuItem<String>(
              value: item,
              child: Text(label),
            );
          }).toList(),
          onChanged: onChanged,
          underline: Container(),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(text,
            style: TextStyle(
              fontSize: 16,
            )),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildThemeSwitch(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: themeProvider.isDarkMode
              ? const Icon(Icons.dark_mode,
                  key: ValueKey('theme_mode'), size: 28, color: Colors.amber)
              : const Icon(Icons.light_mode,
                  key: ValueKey('theme_mode'), size: 28, color: AppTheme.primaryColor),
        ),
        title: Text(
          AppLocalizations.of(context)!.themeMode(themeProvider.isDarkMode
              ? AppLocalizations.of(context)!.dark
              : AppLocalizations.of(context)!.light),
          style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black),
        ),
        trailing: Switch.adaptive(
          value: themeProvider.isDarkMode,
          activeColor: Colors.amber,
          inactiveThumbColor: AppTheme.primaryColor,
          onChanged: (value) {
            themeProvider.toggleTheme();
            settingsProvider.setSetting('theme_mode', value ? 'dark' : 'light');
          },
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
