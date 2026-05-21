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
// If you reintroduce OCR (e.g. via cloud vision), restore this file with the
// new approach and re-add the `google_mlkit_text_recognition` dependency to
// pubspec.yaml.
