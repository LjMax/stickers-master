# Stickers Master — Play Store Screenshots

Google Play requires **2 to 8 phone screenshots**. You capture these on a real device
or an emulator — they can't be generated. This is the shot list and the specs.

## Specs (phone screenshots)

- Format: PNG or JPEG
- Aspect ratio: portrait (9:16) — capture the whole phone screen
- Each side: between 320 px and 3840 px (a normal phone screenshot, e.g. 1080×2400, is fine)
- The long side must be at most twice the short side
- No rounded corners or device frames needed — Google adds presentation styling

## How to capture

On a connected device or emulator: `flutter run --release`, navigate to each screen,
then press the volume-down + power buttons (device) or use the emulator's camera button.
Capturing from a `--release` build avoids the debug banner.

If the **default Play Console listing language is Serbian**, capture the set with the
app set to Serbian (Settings → Language). You can optionally upload a second English
set under the English translation later — not required for launch.

## Shot list (capture these 6, in this order)

The order matters — the first 2–3 are what most users see before tapping "more".

1. **Album screen — collection grid.** The main album view with the sticker grid,
   the progress bar/percentage at the top, and a mix of owned, duplicate, and missing
   stickers visible. This is the hero shot; make sure it looks full and colourful.

2. **Album screen — a filter applied.** Tap the "Missing" filter (or open search and
   type a code) so the screenshot shows the filter chips and demonstrates that the
   album is searchable and filterable.

3. **Stats screen.** The progress/completion view — shows the collector how far along
   they are. Pick an account that's partway done, not 0% and not 100%.

4. **Page scan — review screen.** The photo-assisted bulk-marking screen, with a
   captured album page and tick boxes. This is a standout feature; show it mid-review.

5. **Swap screen.** The list of nearby collectors with their match counts ("X stickers
   for you"). Use an account with a city set so real matches appear.

6. **Inbox or chat detail.** Either the inbox with an active chat / request, or an open
   1:1 chat thread — shows the swap-coordination side of the app.

## Tips

- Use an account that has a realistic, partly-complete collection — empty screens look
  unfinished, 100%-complete screens look like there's nothing to do.
- Keep any visible names/cities innocuous (your own test data is fine).
- Capture in both light theme (cleaner for most viewers); a dark-theme shot or two is
  optional.
- A minimum of 2 is required, but 6 fills the listing properly and is worth it.

## Optional: tablet screenshots

Not required. If you ever want a "Designed for tablets" note you'd add 7"/10" tablet
screenshots, but for a phone-first launch, skip them.
