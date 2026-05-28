# ProGuard / R8 rules for release builds.
#
# Keep this list narrow — only add rules that are needed to make R8
# happy. Anything more sweeping should be justified in a comment.

# ---------------------------------------------------------------------------
# google_mlkit_text_recognition references all five script-specific
# TextRecognizer option classes (Latin, Chinese, Japanese, Korean,
# Devanagari) from a single switch in its plugin code. We only bundle the
# Latin script (see pubspec.yaml: google_mlkit_text_recognition + the
# default `script: TextRecognitionScript.latin`), so R8 cannot find the
# other four packages and aborts with "Missing class …" errors.
#
# These -dontwarn directives tell R8 it's fine for those references to
# resolve at no-op since the Latin path is the only one taken at runtime.
# ---------------------------------------------------------------------------
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
