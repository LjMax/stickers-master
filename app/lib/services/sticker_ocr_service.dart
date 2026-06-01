// Intentionally empty.
//
// This file previously hosted a Google ML Kit Text Recognition wrapper that
// tried to auto-detect which sticker slots were empty by reading the printed
// `ENG 14` labels on the page. After real-album testing on the Panini FIFA
// World Cup 2026 album, ML Kit's accuracy on Panini's heavily-stylized slot
// fonts was too low to be useful (consistently 2-3 detections out of 10
// empty slots across multiple teams and lighting conditions).
//
// The scan feature was pivoted in v1.4 to a manual "bulk-mark with photo
// reference" model: the user takes a photo for visual reference, then ticks
// the stickers they've placed on that page via a 20-row checkbox list.
//
// OCR was later re-added (commit 50867c9) — but NOT here. The live scanner now
// lives in `screens/scan/sticker_scan_screen.dart` (camera stream + ML Kit),
// with `services/sticker_ocr_parser.dart` doing the parse + dictionary
// cross-check that this original wrapper lacked (that filter is what makes it
// usable). This file stays intentionally empty; treat it as historical only.
