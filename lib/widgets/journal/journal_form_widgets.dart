import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/utilities.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../themes/app_theme.dart';

/// A reusable field for selecting an account.
class AccountField extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> accounts;
  final ValueChanged<int> onSelected;
  final TextEditingValue? initialValue;

  const AccountField({
    Key? key,
    required this.label,
    required this.accounts,
    required this.onSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Autocomplete<Map<String, dynamic>>(
      initialValue: initialValue ?? TextEditingValue(),
      optionsBuilder: (txt) => txt.text.isEmpty
          ? accounts
          : accounts.where((a) =>
              getLocalizedSystemAccountName(context, a['name'])
                  .toLowerCase()
                  .contains(txt.text.toLowerCase())),
      displayStringForOption: (a) =>
          getLocalizedSystemAccountName(context, a['name']),
      onSelected: (a) => onSelected(a['id'] as int),
      fieldViewBuilder: (ctx, ctl, fn, sub) => TextFormField(
        controller: ctl,
        focusNode: fn,
        decoration: InputDecoration(labelText: label),
        validator: (v) => v?.isEmpty == true ? loc.pleaseSelectAccount : null,
      ),
    );
  }
}

/// A pair of toggle buttons for 'credit' and 'debit'.
class JournalToggleButtons extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const JournalToggleButtons({
    Key? key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: options.map((opt) {
        final isSel = selected == opt.toLowerCase();
        final isCredit = opt.toLowerCase() == 'credit';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSel ? AppTheme.primaryColor : Colors.grey[300],
                foregroundColor: isSel ? Colors.white : Colors.black,
              ),
              onPressed: () => onChanged(opt.toLowerCase()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCredit ? FontAwesomeIcons.circlePlus : FontAwesomeIcons.circleMinus,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCredit ? localizations.credit : localizations.debit,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A segmented selector for track options: treasure, noTreasure, or custom track.
class TrackSelector extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final String selectedOption;
  final String customTrackName;
  final void Function(String option, int? id) onOptionChanged;

  const TrackSelector({
    Key? key,
    required this.accounts,
    required this.selectedOption,
    required this.customTrackName,
    required this.onOptionChanged,
  }) : super(key: key);

  Widget _buildSegmentLabel(String text) => FittedBox(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'treasure', label: _buildSegmentLabel(loc.treasure)),
        ButtonSegment(
            value: 'noTreasure', label: _buildSegmentLabel(loc.noTreasure)),
        ButtonSegment(
            value: 'track', label: _buildSegmentLabel(customTrackName)),
      ],
      selected: {selectedOption},
      onSelectionChanged: (s) async {
        final opt = s.first;
        if (opt == 'track') {
          final selected = await showDialog<int>(
            context: context,
            builder: (_) => TrackDialog(accounts: accounts),
          );
          onOptionChanged('track', selected);
        } else {
          onOptionChanged(opt, opt == 'treasure' ? 1 : 2);
        }
      },
    );
  }
}

/// A dialog for selecting a track from the list of accounts.
class TrackDialog extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  const TrackDialog({Key? key, required this.accounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Map<String, dynamic>? sel;
    return AlertDialog(
      title: Text(loc.selectTrack),
      content: Autocomplete<Map<String, dynamic>>(
        optionsBuilder: (txt) => txt.text.isEmpty
            ? accounts
            : accounts.where((a) =>
                getLocalizedSystemAccountName(context, a['name'])
                    .toLowerCase()
                    .contains(txt.text.toLowerCase())),
        displayStringForOption: (a) =>
            getLocalizedSystemAccountName(context, a['name']),
        onSelected: (a) => sel = a,
        fieldViewBuilder: (ctx, ctl, fn, sub) => TextField(
          controller: ctl,
          focusNode: fn,
          decoration: InputDecoration(hintText: loc.typeToSearchTrack),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (sel != null) {
              Navigator.pop(context, sel!['id'] as int);
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(loc.pleaseSelectTrack)));
            }
          },
          child: Text(loc.confirm),
        ),
      ],
    );
  }
}
