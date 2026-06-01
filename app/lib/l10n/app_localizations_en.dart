// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stickers Master';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get tabAlbum => 'Album';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabSwap => 'Swap';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabSettings => 'Settings';

  @override
  String requestDialogTitle(String name) {
    return 'Send a message — $name';
  }

  @override
  String get requestDialogHint =>
      'Short intro (e.g. \"Hi, I see you have ENG2 which I need\")';

  @override
  String get requestDialogSend => 'Send';

  @override
  String get requestDialogCancel => 'Cancel';

  @override
  String requestDialogCharsLeft(int count) {
    return '$count left';
  }

  @override
  String get requestSent => 'Request sent';

  @override
  String get requestSignInRequired => 'Sign in to send a message';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxSectionRequests => 'New requests';

  @override
  String get inboxSectionSent => 'Sent';

  @override
  String get inboxSectionChats => 'Active chats';

  @override
  String get inboxEmpty => 'No new messages or chats.';

  @override
  String get inboxEmptyNotSignedIn =>
      'Sign in to see messages from other collectors.';

  @override
  String get inboxRequestAccept => 'Accept';

  @override
  String get inboxRequestDecline => 'Decline';

  @override
  String get inboxRequestDeclined => 'Request declined';

  @override
  String get sentRequestStatusPending => 'Pending';

  @override
  String get sentRequestStatusDeclined => 'Declined';

  @override
  String get sentRequestRecipientFallback => 'Collector';

  @override
  String get sentRequestCancel => 'Cancel request';

  @override
  String get sentRequestDismiss => 'Dismiss';

  @override
  String get sentRequestCancelConfirmTitle => 'Cancel this request?';

  @override
  String get sentRequestCancelConfirmBody =>
      'The recipient will stop seeing it. You can send a new request later.';

  @override
  String get sentRequestCancelledSnack => 'Request cancelled.';

  @override
  String get sentRequestDismissedSnack => 'Request dismissed.';

  @override
  String get chatNoLastMessage => 'No messages yet';

  @override
  String get chatInputHint => 'Write a message…';

  @override
  String get chatInputSend => 'Send';

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileSettingsEntry => 'My profile';

  @override
  String profileSettingsSubtitleSet(String name, String city) {
    return '$name · $city';
  }

  @override
  String get profileSettingsSubtitleUnset => 'Set your city for swap matches';

  @override
  String get profileDisplayName => 'Name';

  @override
  String get profileDisplayNameHint => 'How other collectors see you';

  @override
  String get profileCity => 'City';

  @override
  String get profileCityHint => 'e.g. Belgrade';

  @override
  String get profileCountry => 'Country';

  @override
  String get profileCountryHint => 'e.g. Serbia';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileRequiredField => 'Required';

  @override
  String get profileSignInPrompt =>
      'Sign in to set your profile and swap with others.';

  @override
  String get swapTitle => 'Swap';

  @override
  String get swapEmptyNotSignedIn =>
      'Sign in to see who can help with your missing stickers.';

  @override
  String get swapEmptyNoCity =>
      'Set your city in profile to filter collectors by city.';

  @override
  String get swapEmptyNoCountry =>
      'Set your country in profile to find collectors in your country.';

  @override
  String get swapEmptyNoMissing =>
      'All stickers are in your collection — nice work!';

  @override
  String swapEmptyNoMatches(String city) {
    return 'No matches in $city right now. Check back later.';
  }

  @override
  String swapEmptyNoMatchesCountry(String country) {
    return 'No matches in $country right now. Check back later.';
  }

  @override
  String swapFilterCityOnly(String city) {
    return 'Only $city';
  }

  @override
  String get swapOpenProfile => 'Open profile';

  @override
  String swapMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stickers for you',
      one: '$count sticker for you',
    );
    return '$_temp0';
  }

  @override
  String get swapChat => 'Message';

  @override
  String get swapChatComingSoon =>
      'Live chat is coming soon — we\'re working on it.';

  @override
  String get swapRefresh => 'Refresh';

  @override
  String get swapAnonymous => 'Anonymous collector';

  @override
  String get albumPaniniFifa2026 => 'Panini FIFA World Cup 2026';

  @override
  String wcGroupHeader(String letter) {
    return 'Group $letter';
  }

  @override
  String get sectionSpecials => 'Special stickers';

  @override
  String get sectionCollapse => 'Collapse';

  @override
  String get sectionExpand => 'Expand';

  @override
  String get filterAll => 'All';

  @override
  String get filterMissing => 'Missing';

  @override
  String get filterHave => 'Have';

  @override
  String get filterDuplicates => 'Duplicates';

  @override
  String get filterFoils => 'Foils';

  @override
  String get searchStickerTitle => 'Search sticker';

  @override
  String get searchHint => 'Search by code (e.g. ENG12)';

  @override
  String get albumFilterEmpty => 'No stickers match this filter';

  @override
  String get searchNoResults => 'No results';

  @override
  String searchResultCount(int count) {
    return '$count results';
  }

  @override
  String get shareTitle => 'Swap list';

  @override
  String get shareWanted => 'WANTED';

  @override
  String get shareOffered => 'OFFERED';

  @override
  String get shareCopy => 'Copy to clipboard';

  @override
  String get shareCopied => 'List copied to clipboard';

  @override
  String get shareOpenSheet => 'Share list';

  @override
  String get shareEmpty => 'No duplicates or missing stickers';

  @override
  String shareHeader(String album) {
    return 'Stickers Master — $album';
  }

  @override
  String shareProgress(int owned, int total, String percent) {
    return 'Status: $owned / $total ($percent%)';
  }

  @override
  String get scanStickerTitle => 'Scan sticker';

  @override
  String get scanInstruction => 'Point camera at the back of a sticker';

  @override
  String get scanAutoAdvanceTooltip => 'Auto-advance after adding';

  @override
  String get scanPermissionDeniedTitle => 'Camera permission denied';

  @override
  String get scanPermissionDeniedBody =>
      'Allow camera access in your phone settings to scan stickers.';

  @override
  String get scanCameraErrorTitle => 'Camera unavailable';

  @override
  String get scanCameraErrorBody =>
      'Couldn\'t open the camera. Try again or restart the app.';

  @override
  String get scanStatusMissing => 'Missing';

  @override
  String get scanStatusHave => 'Already in album';

  @override
  String scanStatusHaveWithDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '$count duplicate',
    );
    return 'Already in album · $_temp0';
  }

  @override
  String get scanActionAddToAlbum => 'Add to album';

  @override
  String get scanActionAddDuplicate => 'Add as duplicate';

  @override
  String get scanNextSticker => 'Scan next sticker';

  @override
  String get scanSkipThis => 'Skip this one';

  @override
  String scanAddedSummary(String code) {
    return 'Added $code';
  }

  @override
  String scanAddedDuplicateSummary(String code, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '$count duplicate',
    );
    return 'Added $code ($_temp0)';
  }

  @override
  String get missingListTitle => 'Show what I\'m missing';

  @override
  String missingListSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing stickers',
      one: '$count missing sticker',
    );
    return '$_temp0';
  }

  @override
  String get missingListCopy => 'Copy';

  @override
  String get missingListCopied => 'List copied to clipboard.';

  @override
  String missingListMarkedFound(String code) {
    return 'Added $code to your album';
  }

  @override
  String get actionUndo => 'Undo';

  @override
  String get missingListCompleteTitle => 'Album complete!';

  @override
  String get missingListCompleteBody => 'You have every sticker. Nice work.';

  @override
  String get settingsScanAutoAdvance => 'Auto-advance scanner';

  @override
  String get settingsScanAutoAdvanceSubtitle =>
      'Resume scanning automatically after each sticker is added.';

  @override
  String get scanPageTooltip => 'Scan page';

  @override
  String scanReviewTitle(String team) {
    return 'Page review — $team';
  }

  @override
  String get scanBulkInstructions =>
      'Look at the photo and tick the stickers you\'ve placed on this page. Already-owned ones are locked.';

  @override
  String get scanSelectAllEmpty => 'Select all empty';

  @override
  String get scanClearAll => 'Clear selection';

  @override
  String get scanRetake => 'Retake photo';

  @override
  String get scanApply => 'Save';

  @override
  String get scanCancelled => 'Scan cancelled';

  @override
  String scanAppliedCount(int count) {
    return 'Added $count stickers to your collection';
  }

  @override
  String get scanNothingChanged => 'No stickers selected';

  @override
  String scanCameraError(String message) {
    return 'Couldn\'t open the camera: $message';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get accountGuest => 'Guest';

  @override
  String get accountGuestSubtitle =>
      'Sign in to sync your collection and swap with others.';

  @override
  String get accountSignedIn => 'Signed in';

  @override
  String get accountSignedOut => 'Not signed in';

  @override
  String get accountFirebaseUnconfiguredTitle => 'Firebase isn\'t configured';

  @override
  String get accountFirebaseUnconfiguredBody =>
      'Run `flutterfire configure` in the app/ directory to connect a Firebase project.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Sign in to sync your collection across devices and swap with other collectors.';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInGuest => 'Continue as guest';

  @override
  String get signInComingSoon => 'Email and phone sign-in coming soon.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'Your local collection stays. Cloud sync pauses until you sign back in.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Permanently remove your account and all data';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, your collection, your swap profile, and all of your chats and messages. Conversations will be removed for the people you chatted with too. This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get deleteAccountProgress => 'Deleting your account…';

  @override
  String get deleteAccountDone => 'Your account and data have been deleted.';

  @override
  String get deleteAccountError =>
      'Couldn\'t delete your account. Check your connection and try again.';

  @override
  String stickersOwnedOfTotal(int owned, int total) {
    return '$owned / $total stickers';
  }

  @override
  String stickersOwnedPercent(String percent) {
    return '$percent% complete';
  }

  @override
  String get statusHave => 'Have';

  @override
  String get statusDuplicate => 'Duplicate';

  @override
  String get statusMissing => 'Missing';

  @override
  String get statusFoil => 'Foil';

  @override
  String duplicatesShort(int count) {
    return 'x$count';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSerbian => 'Serbian (Latin)';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String stickerEditTitle(String code) {
    return 'Sticker $code';
  }

  @override
  String get stickerEditOwnedCount => 'How many do you have?';

  @override
  String get stickerEditNone => 'None';

  @override
  String get stickerEditHaveOne => 'Have one';

  @override
  String stickerEditDuplicates(int count) {
    return '$count duplicates';
  }

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionReset => 'Reset';

  @override
  String get modBlock => 'Block';

  @override
  String get modBlockUser => 'Block user';

  @override
  String get modUnblock => 'Unblock';

  @override
  String get modUnblockUser => 'Unblock user';

  @override
  String get modReport => 'Report';

  @override
  String get modReportUser => 'Report user';

  @override
  String modBlockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get modBlockConfirmBody =>
      'You won\'t see their messages or chat requests anymore, and they won\'t appear in the swap area. You can unblock them later in Settings.';

  @override
  String modBlockedSnack(String name) {
    return '$name blocked.';
  }

  @override
  String modUnblockedSnack(String name) {
    return '$name unblocked.';
  }

  @override
  String modReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get modReportReasonLabel => 'Reason for report';

  @override
  String get modReportReasonSpam => 'Spam';

  @override
  String get modReportReasonHarassment => 'Harassment or abuse';

  @override
  String get modReportReasonInappropriate => 'Inappropriate content';

  @override
  String get modReportReasonOther => 'Other';

  @override
  String get modReportDetailsHint => 'Additional details (optional)';

  @override
  String get modReportSubmit => 'Submit report';

  @override
  String get modReportSentSnack =>
      'Report submitted. Thanks for helping keep the community safe.';

  @override
  String get modBlockedUsersTitle => 'Blocked users';

  @override
  String get modBlockedUsersEmpty => 'You haven\'t blocked anyone.';

  @override
  String get modBlockedUsersSubtitle => 'Manage blocked users';

  @override
  String requestCooldownActive(int hours) {
    return 'This person recently declined a request. Try again in $hours h.';
  }

  @override
  String get requestAlreadyPending =>
      'You\'ve already sent a request to this person. Wait for a reply.';

  @override
  String get actionDelete => 'Delete';

  @override
  String get chatActionsTitle => 'Chat actions';

  @override
  String get chatActionHide => 'Hide chat';

  @override
  String get chatActionHideSubtitle =>
      'Removes it from your inbox. Reappears if a new message arrives.';

  @override
  String get chatActionDeleteForever => 'Delete forever';

  @override
  String get chatActionDeleteForeverSubtitle =>
      'Erases all messages from your view. The other person keeps their copy.';

  @override
  String get chatHideTitle => 'Hide chat?';

  @override
  String get chatHideBody =>
      'The chat will be removed from your list. It reappears if a new message arrives.';

  @override
  String get chatHiddenSnack => 'Chat hidden.';

  @override
  String get chatDeleteForeverTitle => 'Delete chat forever?';

  @override
  String get chatDeleteForeverBody =>
      'All messages will disappear from your view of this chat. If you ever talk to this person again, you\'ll start with a fresh conversation. The other person will still see your past messages. This can\'t be undone.';

  @override
  String get chatDeletedForeverSnack => 'Chat deleted from your view.';
}
