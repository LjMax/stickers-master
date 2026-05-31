import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../services/team_flag_map.dart';

/// Small rounded-corner country flag for a FIFA team code.
///
/// Renders the country_flags SVG for the team's flag. Falls back to a
/// neutral grey pill when the team code isn't mapped (e.g. the FWC
/// specials group, or any future album that introduces a code we
/// haven't mapped yet) — that way the UI never breaks if the data
/// runs ahead of the map.
class TeamFlag extends StatelessWidget {
  const TeamFlag({
    super.key,
    required this.teamCode,
    this.width = 26,
    this.height = 18,
  });

  /// FIFA 3-letter team code (`ENG`, `SUI`, `POR`, …).
  final String teamCode;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final flagCode = fifaToFlagCode(teamCode);
    if (flagCode == null) {
      // Neutral fallback so a missing-from-map code still lays out cleanly.
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CountryFlag.fromCountryCode(
        flagCode,
        width: width,
        height: height,
      ),
    );
  }
}
