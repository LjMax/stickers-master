import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/public_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/user_avatar.dart';

/// Edit the publicly-visible profile (display_name, city, country) shown
/// in the Swap area.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _countryCtrl = TextEditingController(text: 'Srbija');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  /// Pre-fills controllers from the loaded profile (or auth defaults).
  /// Called once when the profile data is first available.
  bool _initialized = false;
  void _maybeInitFromProfile(PublicProfile? profile) {
    if (_initialized) return;
    final user = ref.read(currentUserProvider);
    _displayNameCtrl.text = profile?.displayName ?? user?.displayName ?? '';
    _cityCtrl.text = profile?.city ?? '';
    if ((profile?.country ?? '').isNotEmpty) {
      _countryCtrl.text = profile!.country;
    }
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final profile = PublicProfile(
        uid: user.uid,
        displayName: _displayNameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        photoUrl: user.photoURL,
      );
      await ref.read(swapRepositoryProvider).upsertProfile(profile);
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileSaved)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('profile: save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final asyncProfile = ref.watch(myProfileProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.profileTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l.profileSignInPrompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('profile: stream error: $e');
          return Center(child: Text(l.errorGeneric));
        },
        data: (profile) {
          _maybeInitFromProfile(profile);
          final avatarUrl = profile?.photoUrl ?? user.photoURL;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          UserAvatar(
                            name: _displayNameCtrl.text.isNotEmpty
                                ? _displayNameCtrl.text
                                : (profile?.displayName ??
                                    user.displayName ??
                                    ''),
                            photoUrl: avatarUrl,
                            radius: 36,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _displayNameCtrl,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: l.profileDisplayName,
                        helperText: l.profileDisplayNameHint,
                        prefixIcon: const Icon(Icons.person_outline),
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.profileRequiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityCtrl,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: l.profileCity,
                        helperText: l.profileCityHint,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.profileRequiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryCtrl,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: l.profileCountry,
                        helperText: l.profileCountryHint,
                        prefixIcon: const Icon(Icons.public_outlined),
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.profileRequiredField
                          : null,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(l.profileSave),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
