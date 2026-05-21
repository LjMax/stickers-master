/// Publicly-visible profile shown in the Swap area to other users.
///
/// Stored at `public_profiles/{uid}` in Firestore. Any signed-in user can
/// read; only the owner can write (see firestore.rules).
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.displayName,
    required this.city,
    required this.country,
    this.photoUrl,
  });

  /// Firebase Auth uid — also the document ID.
  final String uid;

  /// Human-readable name shown on swap cards. Defaults from Google account
  /// when available; the user can override in Settings → Profile.
  final String displayName;

  /// User-entered city. Used as the primary proximity filter for matches.
  final String city;

  /// User-entered country. Currently informational; matching is by city.
  final String country;

  /// Avatar URL from the user's auth provider (Google photo URL).
  final String? photoUrl;

  factory PublicProfile.fromJson(String uid, Map<String, dynamic> json) {
    return PublicProfile(
      uid: uid,
      displayName: json['display_name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'city': city,
        'country': country,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

  PublicProfile copyWith({
    String? displayName,
    String? city,
    String? country,
    String? photoUrl,
  }) {
    return PublicProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

/// A potential swap partner: their public profile plus the overlap (codes
/// they have as duplicates that I don't yet own).
class SwapMatch {
  const SwapMatch({
    required this.profile,
    required this.overlapCodes,
  });

  final PublicProfile profile;

  /// Sticker codes the other user has 2+ copies of AND I don't yet have
  /// (owned_count == 0). Sorted by code for predictable display.
  final List<String> overlapCodes;

  int get overlapCount => overlapCodes.length;
}
