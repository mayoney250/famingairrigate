import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../generated/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool isCompact;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    final languages = [
      {'name': 'English', 'flag': '🇬🇧', 'locale': const Locale('en')},
      {'name': 'French', 'flag': '🇫🇷', 'locale': const Locale('fr')},
      {'name': 'Swahili', 'flag': '🇹🇿', 'locale': const Locale('sw')},
      {'name': 'Kinyarwanda', 'flag': '🇷🇼', 'locale': const Locale('rw')},
    ];

    if (isCompact) {
      return PopupMenuButton<Locale>(
        icon: const Icon(Icons.language),
        tooltip: l10n.language,
        onSelected: (Locale locale) {
          languageProvider.setLocale(locale);
        },
        itemBuilder: (BuildContext context) {
          return languages.map((lang) {
            final locale = lang['locale'] as Locale;
            final isSelected = languageProvider.currentLocale == locale;
            return PopupMenuItem<Locale>(
              value: locale,
              child: Row(
                children: [
                  Text(
                    lang['flag'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang['name'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList();
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          DropdownButton<Locale>(
            value: languageProvider.currentLocale,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                languageProvider.setLocale(newLocale);
              }
            },
            items: languages.map((lang) {
              final locale = lang['locale'] as Locale;
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Row(
                  children: [
                    Text(
                      lang['flag'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(lang['name'] as String),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class LanguageSwitcherDialog extends StatelessWidget {
  const LanguageSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    final languages = [
      {
        'name': 'English',
        'flag': '🇬🇧',
        'locale': const Locale('en'),
        'nativeName': 'English'
      },
      {
        'name': 'French',
        'flag': '🇫🇷',
        'locale': const Locale('fr'),
        'nativeName': 'Français'
      },
      {
        'name': 'Swahili',
        'flag': '🇹🇿',
        'locale': const Locale('sw'),
        'nativeName': 'Kiswahili'
      },
      {
        'name': 'Kinyarwanda',
        'flag': '🇷🇼',
        'locale': const Locale('rw'),
        'nativeName': 'Ikinyarwanda'
      },
    ];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 12),
          Text(l10n.language),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final locale = lang['locale'] as Locale;
            final isSelected = languageProvider.currentLocale == locale;

            return ListTile(
              leading: Text(
                lang['flag'] as String,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                lang['name'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                lang['nativeName'] as String,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: isSelected,
              selectedTileColor:
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              onTap: () {
                languageProvider.setLocale(locale);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSwitcherDialog(),
    );
  }
}
