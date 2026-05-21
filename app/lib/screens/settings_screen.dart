import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show firebaseReadyProvider;
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/user_avatar.dart';
import 'blocked_users_screen.dart';
import 'profile_edit_screen.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(currentUserProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        children: [
          _SectionHeader(label: l.settingsAccount),
          _AccountTile(
            user: user,
            firebaseReady: firebaseReady,
            onSignIn: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
            ),
            onSignOut: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
          if (user != null && firebaseReady)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(l.profileSettingsEntry),
              subtitle: Text(
                (profile != null &&
                        profile.displayName.isNotEmpty &&
                        profile.city.isNotEmpty)
                    ? l.profileSettingsSubtitleSet(profile.displayName, profile.city)
                    : l.profileSettingsSubtitleUnset,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileEditScreen(),
                ),
              ),
            ),
          if (user != null && firebaseReady)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l.modBlockedUsersTitle),
              subtitle: Text(l.modBlockedUsersSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BlockedUsersScreen(),
                ),
              ),
            ),
          const Divider(),
          _SectionHeader(label: l.settingsLanguage),
          RadioListTile<String>(
            title: Text(l.settingsLanguageSerbian),
            value: 'sr',
            groupValue: locale.languageCode,
            onChanged: (_) => ref.read(localeProvider.notifier).setSerbianLatin(),
          ),
          RadioListTile<String>(
            title: Text(l.settingsLanguageEnglish),
            value: 'en',
            groupValue: locale.languageCode,
            onChanged: (_) => ref.read(localeProvider.notifier).setEnglish(),
          ),
          const Divider(),
          _SectionHeader(label: l.settingsTheme),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeSystem),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) =>
                v == null ? null : ref.read(themeProvider.notifier).set(v),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeLight),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) =>
                v == null ? null : ref.read(themeProvider.notifier).set(v),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeDark),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) =>
                v == null ? null : ref.read(themeProvider.notifier).set(v),
          ),
          const Divider(),
          _SectionHeader(label: l.settingsAbout),
          ListTile(
            title: Text(l.settingsVersion('0.1.0')),
            subtitle: const Text('Stickers Master'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.user,
    required this.firebaseReady,
    required this.onSignIn,
    required this.onSignOut,
  });

  final User? user;
  final bool firebaseReady;
  final VoidCallback onSignIn;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (!firebaseReady) {
      return ListTile(
        leading: Icon(
          Icons.cloud_off,
          color: Theme.of(context).colorScheme.outline,
        ),
        title: Text(l.accountFirebaseUnconfiguredTitle),
        subtitle: Text(l.accountFirebaseUnconfiguredBody),
      );
    }

    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.person_off_outlined),
        title: Text(l.accountSignedOut),
        trailing: FilledButton.tonal(
          onPressed: onSignIn,
          child: Text(l.signInTitle),
        ),
      );
    }

    if (user!.isAnonymous) {
      return ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l.accountGuest),
        subtitle: Text(l.accountGuestSubtitle),
        trailing: FilledButton.tonal(
          onPressed: onSignIn,
          child: Text(l.signInTitle),
        ),
      );
    }

    // Signed in with a real account (Google / Email / Phone).
    final display = user!.displayName ?? user!.email ?? user!.phoneNumber ?? '';
    return ListTile(
      leading: UserAvatar(
        name: display.isEmpty ? l.accountSignedIn : display,
        photoUrl: user!.photoURL,
        radius: 20,
      ),
      title: Text(display.isNotEmpty ? display : l.accountSignedIn),
      subtitle: Text(user!.email ?? user!.phoneNumber ?? ''),
      trailing: TextButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.signOutConfirmTitle),
              content: Text(l.signOutConfirmBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l.signOut),
                ),
              ],
            ),
          );
          if (confirmed == true) await onSignOut();
        },
        child: Text(l.signOut),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}
