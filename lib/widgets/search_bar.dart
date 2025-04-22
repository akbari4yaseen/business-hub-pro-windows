import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/debouncer.dart';

/// A reusable, customizable search bar for accounts, with debounce, loading indicator, and clear/cancel actions.
class CommonSearchBar extends StatefulWidget {
  /// Text controller for the search input.
  final TextEditingController controller;

  /// Called (debounced) whenever the text changes.
  final ValueChanged<String> onChanged;

  /// Called when the user taps the cancel (back) icon.
  final VoidCallback onCancel;

  /// Called when the user taps the clear icon. If null, defaults to clearing input and re-focusing.
  final VoidCallback? onClear;

  /// Called when the user submits via keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Debounce duration for onChanged.
  final Duration debounceDuration;

  /// When true, shows a loading spinner instead of the clear icon.
  final bool isLoading;

  /// Custom hint text. Defaults to localized 'search'.
  final String? hintText;

  const CommonSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onCancel,
    this.onClear,
    this.onSubmitted,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.isLoading = false,
    this.hintText,
  }) : super(key: key);

  @override
  _CommonSearchBarState createState() => _CommonSearchBarState();
}

class _CommonSearchBarState extends State<CommonSearchBar> {
  late Debouncer _debouncer;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _debouncer =
        Debouncer(milliseconds: widget.debounceDuration.inMilliseconds);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CommonSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debounceDuration != widget.debounceDuration) {
      _debouncer =
          Debouncer(milliseconds: widget.debounceDuration.inMilliseconds);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange(String text) {
    _debouncer.run(() => widget.onChanged(text));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        elevation: 1,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: widget.onSubmitted != null
              ? TextInputAction.search
              : TextInputAction.done,
          onChanged: _handleTextChange,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText ?? loc.search,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: InputBorder.none,
            prefixIcon: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onCancel,
              tooltip: loc.cancel,
            ),
            suffixIcon: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox(width: 48);
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: widget.onClear ??
                            () {
                              widget.controller.clear();
                              widget.onChanged('');
                              _focusNode.requestFocus();
                            },
                        tooltip: loc.clear,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
