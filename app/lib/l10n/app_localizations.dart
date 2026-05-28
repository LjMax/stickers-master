import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sr')
  ];

  /// Display name of the app
  ///
  /// In sr, this message translates to:
  /// **'Stickers Master'**
  String get appTitle;

  /// No description provided for @tabAlbum.
  ///
  /// In sr, this message translates to:
  /// **'Album'**
  String get tabAlbum;

  /// No description provided for @tabStats.
  ///
  /// In sr, this message translates to:
  /// **'Statistika'**
  String get tabStats;

  /// No description provided for @tabSwap.
  ///
  /// In sr, this message translates to:
  /// **'Razmena'**
  String get tabSwap;

  /// No description provided for @tabInbox.
  ///
  /// In sr, this message translates to:
  /// **'Poruke'**
  String get tabInbox;

  /// No description provided for @tabSettings.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja'**
  String get tabSettings;

  /// No description provided for @requestDialogTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji poruku — {name}'**
  String requestDialogTitle(String name);

  /// No description provided for @requestDialogHint.
  ///
  /// In sr, this message translates to:
  /// **'Kratka poruka (npr. \"Ćao, vidim da imaš ENG2 koji tražim\")'**
  String get requestDialogHint;

  /// No description provided for @requestDialogSend.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get requestDialogSend;

  /// No description provided for @requestDialogCancel.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži'**
  String get requestDialogCancel;

  /// No description provided for @requestDialogCharsLeft.
  ///
  /// In sr, this message translates to:
  /// **'{count} preostalo'**
  String requestDialogCharsLeft(int count);

  /// No description provided for @requestSent.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev je poslat'**
  String get requestSent;

  /// No description provided for @requestSignInRequired.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da pošalješ poruku'**
  String get requestSignInRequired;

  /// No description provided for @inboxTitle.
  ///
  /// In sr, this message translates to:
  /// **'Poruke'**
  String get inboxTitle;

  /// No description provided for @inboxSectionRequests.
  ///
  /// In sr, this message translates to:
  /// **'Novi zahtevi'**
  String get inboxSectionRequests;

  /// No description provided for @inboxSectionSent.
  ///
  /// In sr, this message translates to:
  /// **'Poslato'**
  String get inboxSectionSent;

  /// No description provided for @inboxSectionChats.
  ///
  /// In sr, this message translates to:
  /// **'Aktivni razgovori'**
  String get inboxSectionChats;

  /// No description provided for @inboxEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Nema novih poruka ili razgovora.'**
  String get inboxEmpty;

  /// No description provided for @inboxEmptyNotSignedIn.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da vidiš poruke od drugih kolekcionara.'**
  String get inboxEmptyNotSignedIn;

  /// No description provided for @inboxRequestAccept.
  ///
  /// In sr, this message translates to:
  /// **'Prihvati'**
  String get inboxRequestAccept;

  /// No description provided for @inboxRequestDecline.
  ///
  /// In sr, this message translates to:
  /// **'Odbij'**
  String get inboxRequestDecline;

  /// No description provided for @inboxRequestDeclined.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev je odbijen'**
  String get inboxRequestDeclined;

  /// No description provided for @sentRequestStatusPending.
  ///
  /// In sr, this message translates to:
  /// **'Čeka odgovor'**
  String get sentRequestStatusPending;

  /// No description provided for @sentRequestStatusDeclined.
  ///
  /// In sr, this message translates to:
  /// **'Odbijeno'**
  String get sentRequestStatusDeclined;

  /// No description provided for @sentRequestRecipientFallback.
  ///
  /// In sr, this message translates to:
  /// **'Kolekcionar'**
  String get sentRequestRecipientFallback;

  /// No description provided for @sentRequestCancel.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži zahtev'**
  String get sentRequestCancel;

  /// No description provided for @sentRequestDismiss.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni'**
  String get sentRequestDismiss;

  /// No description provided for @sentRequestCancelConfirmTitle.
  ///
  /// In sr, this message translates to:
  /// **'Otkazati ovaj zahtev?'**
  String get sentRequestCancelConfirmTitle;

  /// No description provided for @sentRequestCancelConfirmBody.
  ///
  /// In sr, this message translates to:
  /// **'Primalac ga više neće videti. Možeš poslati novi zahtev kasnije.'**
  String get sentRequestCancelConfirmBody;

  /// No description provided for @sentRequestCancelledSnack.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev je otkazan.'**
  String get sentRequestCancelledSnack;

  /// No description provided for @sentRequestDismissedSnack.
  ///
  /// In sr, this message translates to:
  /// **'Zahtev je uklonjen.'**
  String get sentRequestDismissedSnack;

  /// No description provided for @chatNoLastMessage.
  ///
  /// In sr, this message translates to:
  /// **'Bez poruka'**
  String get chatNoLastMessage;

  /// No description provided for @chatInputHint.
  ///
  /// In sr, this message translates to:
  /// **'Napiši poruku…'**
  String get chatInputHint;

  /// No description provided for @chatInputSend.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get chatInputSend;

  /// No description provided for @profileTitle.
  ///
  /// In sr, this message translates to:
  /// **'Moj profil'**
  String get profileTitle;

  /// No description provided for @profileSettingsEntry.
  ///
  /// In sr, this message translates to:
  /// **'Moj profil'**
  String get profileSettingsEntry;

  /// No description provided for @profileSettingsSubtitleSet.
  ///
  /// In sr, this message translates to:
  /// **'{name} · {city}'**
  String profileSettingsSubtitleSet(String name, String city);

  /// No description provided for @profileSettingsSubtitleUnset.
  ///
  /// In sr, this message translates to:
  /// **'Postavi grad za razmenu'**
  String get profileSettingsSubtitleUnset;

  /// No description provided for @profileDisplayName.
  ///
  /// In sr, this message translates to:
  /// **'Ime'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In sr, this message translates to:
  /// **'Kako te drugi kolekcionari vide'**
  String get profileDisplayNameHint;

  /// No description provided for @profileCity.
  ///
  /// In sr, this message translates to:
  /// **'Grad'**
  String get profileCity;

  /// No description provided for @profileCityHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Beograd'**
  String get profileCityHint;

  /// No description provided for @profileCountry.
  ///
  /// In sr, this message translates to:
  /// **'Država'**
  String get profileCountry;

  /// No description provided for @profileCountryHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. Srbija'**
  String get profileCountryHint;

  /// No description provided for @profileSave.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In sr, this message translates to:
  /// **'Profil je sačuvan'**
  String get profileSaved;

  /// No description provided for @profileRequiredField.
  ///
  /// In sr, this message translates to:
  /// **'Obavezno polje'**
  String get profileRequiredField;

  /// No description provided for @profileSignInPrompt.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da podesiš profil i razmenjuješ sa drugima.'**
  String get profileSignInPrompt;

  /// No description provided for @swapTitle.
  ///
  /// In sr, this message translates to:
  /// **'Razmena'**
  String get swapTitle;

  /// No description provided for @swapEmptyNotSignedIn.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da vidiš ko može da ti pomogne sa nedostajućim sličicama.'**
  String get swapEmptyNotSignedIn;

  /// No description provided for @swapEmptyNoCity.
  ///
  /// In sr, this message translates to:
  /// **'Postavi grad u svom profilu da bi filtrirao kolekcionare po gradu.'**
  String get swapEmptyNoCity;

  /// No description provided for @swapEmptyNoCountry.
  ///
  /// In sr, this message translates to:
  /// **'Postavi državu u svom profilu da pronađeš kolekcionare iz svoje zemlje.'**
  String get swapEmptyNoCountry;

  /// No description provided for @swapEmptyNoMissing.
  ///
  /// In sr, this message translates to:
  /// **'Sve sličice su u kolekciji — bravo!'**
  String get swapEmptyNoMissing;

  /// No description provided for @swapEmptyNoMatches.
  ///
  /// In sr, this message translates to:
  /// **'Trenutno nema podudaranja u {city}. Pokušaj kasnije.'**
  String swapEmptyNoMatches(String city);

  /// No description provided for @swapEmptyNoMatchesCountry.
  ///
  /// In sr, this message translates to:
  /// **'Trenutno nema podudaranja u {country}. Pokušaj kasnije.'**
  String swapEmptyNoMatchesCountry(String country);

  /// No description provided for @swapFilterCityOnly.
  ///
  /// In sr, this message translates to:
  /// **'Samo {city}'**
  String swapFilterCityOnly(String city);

  /// No description provided for @swapOpenProfile.
  ///
  /// In sr, this message translates to:
  /// **'Otvori profil'**
  String get swapOpenProfile;

  /// No description provided for @swapMatchCount.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} sličica za tebe} few{{count} sličice za tebe} other{{count} sličica za tebe}}'**
  String swapMatchCount(int count);

  /// No description provided for @swapChat.
  ///
  /// In sr, this message translates to:
  /// **'Poruka'**
  String get swapChat;

  /// No description provided for @swapChatComingSoon.
  ///
  /// In sr, this message translates to:
  /// **'Live chat stiže uskoro — radimo na njemu.'**
  String get swapChatComingSoon;

  /// No description provided for @swapRefresh.
  ///
  /// In sr, this message translates to:
  /// **'Osveži'**
  String get swapRefresh;

  /// No description provided for @swapAnonymous.
  ///
  /// In sr, this message translates to:
  /// **'Anonimni kolekcionar'**
  String get swapAnonymous;

  /// No description provided for @albumPaniniFifa2026.
  ///
  /// In sr, this message translates to:
  /// **'Panini FIFA Svetsko prvenstvo 2026'**
  String get albumPaniniFifa2026;

  /// No description provided for @wcGroupHeader.
  ///
  /// In sr, this message translates to:
  /// **'Grupa {letter}'**
  String wcGroupHeader(String letter);

  /// No description provided for @sectionSpecials.
  ///
  /// In sr, this message translates to:
  /// **'Specijalne sličice'**
  String get sectionSpecials;

  /// No description provided for @sectionCollapse.
  ///
  /// In sr, this message translates to:
  /// **'Sakrij'**
  String get sectionCollapse;

  /// No description provided for @sectionExpand.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži'**
  String get sectionExpand;

  /// No description provided for @filterAll.
  ///
  /// In sr, this message translates to:
  /// **'Sve'**
  String get filterAll;

  /// No description provided for @filterMissing.
  ///
  /// In sr, this message translates to:
  /// **'Tražim'**
  String get filterMissing;

  /// No description provided for @filterHave.
  ///
  /// In sr, this message translates to:
  /// **'Imam'**
  String get filterHave;

  /// No description provided for @filterDuplicates.
  ///
  /// In sr, this message translates to:
  /// **'Duplikati'**
  String get filterDuplicates;

  /// No description provided for @filterFoils.
  ///
  /// In sr, this message translates to:
  /// **'Foil'**
  String get filterFoils;

  /// No description provided for @searchHint.
  ///
  /// In sr, this message translates to:
  /// **'Pretraži po šifri (npr. ENG12)'**
  String get searchHint;

  /// No description provided for @albumFilterEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Nijedna sličica ne odgovara filteru'**
  String get albumFilterEmpty;

  /// No description provided for @searchNoResults.
  ///
  /// In sr, this message translates to:
  /// **'Nema rezultata'**
  String get searchNoResults;

  /// No description provided for @searchResultCount.
  ///
  /// In sr, this message translates to:
  /// **'{count} rezultata'**
  String searchResultCount(int count);

  /// No description provided for @shareTitle.
  ///
  /// In sr, this message translates to:
  /// **'Lista za razmenu'**
  String get shareTitle;

  /// No description provided for @shareWanted.
  ///
  /// In sr, this message translates to:
  /// **'TRAŽIM'**
  String get shareWanted;

  /// No description provided for @shareOffered.
  ///
  /// In sr, this message translates to:
  /// **'ZA ZAMENU'**
  String get shareOffered;

  /// No description provided for @shareCopy.
  ///
  /// In sr, this message translates to:
  /// **'Kopiraj u clipboard'**
  String get shareCopy;

  /// No description provided for @shareCopied.
  ///
  /// In sr, this message translates to:
  /// **'Lista je kopirana u clipboard'**
  String get shareCopied;

  /// No description provided for @shareOpenSheet.
  ///
  /// In sr, this message translates to:
  /// **'Podeli listu'**
  String get shareOpenSheet;

  /// No description provided for @shareEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Nema duplikata niti nedostajućih sličica'**
  String get shareEmpty;

  /// No description provided for @shareHeader.
  ///
  /// In sr, this message translates to:
  /// **'Stickers Master — {album}'**
  String shareHeader(String album);

  /// No description provided for @shareProgress.
  ///
  /// In sr, this message translates to:
  /// **'Stanje: {owned} / {total} ({percent}%)'**
  String shareProgress(int owned, int total, String percent);

  /// No description provided for @scanPageTooltip.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj stranicu'**
  String get scanPageTooltip;

  /// No description provided for @scanReviewTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pregled stranice — {team}'**
  String scanReviewTitle(String team);

  /// No description provided for @scanBulkInstructions.
  ///
  /// In sr, this message translates to:
  /// **'Gledaj sliku i označi sličice koje si dodao na ovu stranicu. Već unesene su zaključane.'**
  String get scanBulkInstructions;

  /// No description provided for @scanSelectAllEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Označi sve prazne'**
  String get scanSelectAllEmpty;

  /// No description provided for @scanClearAll.
  ///
  /// In sr, this message translates to:
  /// **'Obriši izbor'**
  String get scanClearAll;

  /// No description provided for @scanRetake.
  ///
  /// In sr, this message translates to:
  /// **'Ponovi snimanje'**
  String get scanRetake;

  /// No description provided for @scanApply.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get scanApply;

  /// No description provided for @scanCancelled.
  ///
  /// In sr, this message translates to:
  /// **'Skeniranje je otkazano'**
  String get scanCancelled;

  /// No description provided for @scanAppliedCount.
  ///
  /// In sr, this message translates to:
  /// **'Dodato {count} sličica u kolekciju'**
  String scanAppliedCount(int count);

  /// No description provided for @scanNothingChanged.
  ///
  /// In sr, this message translates to:
  /// **'Nije izabrana ni jedna sličica'**
  String get scanNothingChanged;

  /// No description provided for @scanCameraError.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri otvaranju kamere: {message}'**
  String scanCameraError(String message);

  /// No description provided for @settingsAccount.
  ///
  /// In sr, this message translates to:
  /// **'Nalog'**
  String get settingsAccount;

  /// No description provided for @accountGuest.
  ///
  /// In sr, this message translates to:
  /// **'Gost'**
  String get accountGuest;

  /// No description provided for @accountGuestSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da sinhronizuješ kolekciju i razmenjuješ.'**
  String get accountGuestSubtitle;

  /// No description provided for @accountSignedIn.
  ///
  /// In sr, this message translates to:
  /// **'Prijavljen'**
  String get accountSignedIn;

  /// No description provided for @accountSignedOut.
  ///
  /// In sr, this message translates to:
  /// **'Niko nije prijavljen'**
  String get accountSignedOut;

  /// No description provided for @accountFirebaseUnconfiguredTitle.
  ///
  /// In sr, this message translates to:
  /// **'Firebase nije podešen'**
  String get accountFirebaseUnconfiguredTitle;

  /// No description provided for @accountFirebaseUnconfiguredBody.
  ///
  /// In sr, this message translates to:
  /// **'Pokreni `flutterfire configure` u app/ folderu da povežeš Firebase projekat.'**
  String get accountFirebaseUnconfiguredBody;

  /// No description provided for @signInTitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijava'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se da sinhronizuješ kolekciju između uređaja i razmenjuješ sa drugim kolekcionarima.'**
  String get signInSubtitle;

  /// No description provided for @signInGoogle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se sa Google nalogom'**
  String get signInGoogle;

  /// No description provided for @signInGuest.
  ///
  /// In sr, this message translates to:
  /// **'Nastavi kao gost'**
  String get signInGuest;

  /// No description provided for @signInComingSoon.
  ///
  /// In sr, this message translates to:
  /// **'Prijava preko emaila i broja telefona — uskoro.'**
  String get signInComingSoon;

  /// No description provided for @signOut.
  ///
  /// In sr, this message translates to:
  /// **'Odjavi se'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In sr, this message translates to:
  /// **'Odjava?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In sr, this message translates to:
  /// **'Tvoja lokalna kolekcija ostaje. Sinhronizacija sa cloud-om se zaustavlja dok se ponovo ne prijaviš.'**
  String get signOutConfirmBody;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In sr, this message translates to:
  /// **'Obriši nalog'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Trajno ukloni nalog i sve podatke'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In sr, this message translates to:
  /// **'Obrisati nalog?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In sr, this message translates to:
  /// **'Ovim se trajno brišu tvoj nalog, tvoja kolekcija, profil za razmenu i sva tvoja ćaskanja i poruke. Razgovori će biti uklonjeni i kod osoba sa kojima si ćaskao. Ova radnja se ne može poništiti.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Obriši'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountProgress.
  ///
  /// In sr, this message translates to:
  /// **'Brisanje naloga…'**
  String get deleteAccountProgress;

  /// No description provided for @deleteAccountDone.
  ///
  /// In sr, this message translates to:
  /// **'Tvoj nalog i podaci su obrisani.'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountError.
  ///
  /// In sr, this message translates to:
  /// **'Brisanje naloga nije uspelo. Proveri internet vezu i pokušaj ponovo.'**
  String get deleteAccountError;

  /// No description provided for @stickersOwnedOfTotal.
  ///
  /// In sr, this message translates to:
  /// **'{owned} / {total} sličica'**
  String stickersOwnedOfTotal(int owned, int total);

  /// No description provided for @stickersOwnedPercent.
  ///
  /// In sr, this message translates to:
  /// **'{percent}% kompletirano'**
  String stickersOwnedPercent(String percent);

  /// No description provided for @statusHave.
  ///
  /// In sr, this message translates to:
  /// **'Imam'**
  String get statusHave;

  /// No description provided for @statusDuplicate.
  ///
  /// In sr, this message translates to:
  /// **'Duplikat'**
  String get statusDuplicate;

  /// No description provided for @statusMissing.
  ///
  /// In sr, this message translates to:
  /// **'Tražim'**
  String get statusMissing;

  /// No description provided for @statusFoil.
  ///
  /// In sr, this message translates to:
  /// **'Foil'**
  String get statusFoil;

  /// No description provided for @duplicatesShort.
  ///
  /// In sr, this message translates to:
  /// **'x{count}'**
  String duplicatesShort(int count);

  /// No description provided for @settingsLanguage.
  ///
  /// In sr, this message translates to:
  /// **'Jezik'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSerbian.
  ///
  /// In sr, this message translates to:
  /// **'Srpski (latinica)'**
  String get settingsLanguageSerbian;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In sr, this message translates to:
  /// **'Engleski'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In sr, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In sr, this message translates to:
  /// **'Sistemska'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In sr, this message translates to:
  /// **'Svetla'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In sr, this message translates to:
  /// **'Tamna'**
  String get settingsThemeDark;

  /// No description provided for @settingsAbout.
  ///
  /// In sr, this message translates to:
  /// **'O aplikaciji'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In sr, this message translates to:
  /// **'Verzija {version}'**
  String settingsVersion(String version);

  /// No description provided for @stickerEditTitle.
  ///
  /// In sr, this message translates to:
  /// **'Sličica {code}'**
  String stickerEditTitle(String code);

  /// No description provided for @stickerEditOwnedCount.
  ///
  /// In sr, this message translates to:
  /// **'Koliko ih imaš?'**
  String get stickerEditOwnedCount;

  /// No description provided for @stickerEditNone.
  ///
  /// In sr, this message translates to:
  /// **'Nemam'**
  String get stickerEditNone;

  /// No description provided for @stickerEditHaveOne.
  ///
  /// In sr, this message translates to:
  /// **'Imam jednu'**
  String get stickerEditHaveOne;

  /// No description provided for @stickerEditDuplicates.
  ///
  /// In sr, this message translates to:
  /// **'{count} duplikata'**
  String stickerEditDuplicates(int count);

  /// No description provided for @actionDone.
  ///
  /// In sr, this message translates to:
  /// **'Gotovo'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži'**
  String get actionCancel;

  /// No description provided for @actionReset.
  ///
  /// In sr, this message translates to:
  /// **'Resetuj'**
  String get actionReset;

  /// No description provided for @modBlock.
  ///
  /// In sr, this message translates to:
  /// **'Blokiraj'**
  String get modBlock;

  /// No description provided for @modBlockUser.
  ///
  /// In sr, this message translates to:
  /// **'Blokiraj korisnika'**
  String get modBlockUser;

  /// No description provided for @modUnblock.
  ///
  /// In sr, this message translates to:
  /// **'Deblokiraj'**
  String get modUnblock;

  /// No description provided for @modUnblockUser.
  ///
  /// In sr, this message translates to:
  /// **'Deblokiraj korisnika'**
  String get modUnblockUser;

  /// No description provided for @modReport.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi'**
  String get modReport;

  /// No description provided for @modReportUser.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi korisnika'**
  String get modReportUser;

  /// No description provided for @modBlockConfirmTitle.
  ///
  /// In sr, this message translates to:
  /// **'Blokirati {name}?'**
  String modBlockConfirmTitle(String name);

  /// No description provided for @modBlockConfirmBody.
  ///
  /// In sr, this message translates to:
  /// **'Nećete više videti njihove poruke ni zahteve za ćaskanje, niti će se pojavljivati u razmeni. Možete ih kasnije deblokirati u Podešavanjima.'**
  String get modBlockConfirmBody;

  /// No description provided for @modBlockedSnack.
  ///
  /// In sr, this message translates to:
  /// **'{name} je blokiran/a.'**
  String modBlockedSnack(String name);

  /// No description provided for @modUnblockedSnack.
  ///
  /// In sr, this message translates to:
  /// **'{name} je deblokiran/a.'**
  String modUnblockedSnack(String name);

  /// No description provided for @modReportTitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi {name}'**
  String modReportTitle(String name);

  /// No description provided for @modReportReasonLabel.
  ///
  /// In sr, this message translates to:
  /// **'Razlog prijave'**
  String get modReportReasonLabel;

  /// No description provided for @modReportReasonSpam.
  ///
  /// In sr, this message translates to:
  /// **'Neželjene poruke (spam)'**
  String get modReportReasonSpam;

  /// No description provided for @modReportReasonHarassment.
  ///
  /// In sr, this message translates to:
  /// **'Uznemiravanje ili vređanje'**
  String get modReportReasonHarassment;

  /// No description provided for @modReportReasonInappropriate.
  ///
  /// In sr, this message translates to:
  /// **'Neprikladan sadržaj'**
  String get modReportReasonInappropriate;

  /// No description provided for @modReportReasonOther.
  ///
  /// In sr, this message translates to:
  /// **'Drugo'**
  String get modReportReasonOther;

  /// No description provided for @modReportDetailsHint.
  ///
  /// In sr, this message translates to:
  /// **'Dodatni detalji (opciono)'**
  String get modReportDetailsHint;

  /// No description provided for @modReportSubmit.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji prijavu'**
  String get modReportSubmit;

  /// No description provided for @modReportSentSnack.
  ///
  /// In sr, this message translates to:
  /// **'Prijava je poslata. Hvala što pomažeš da zajednica bude bezbedna.'**
  String get modReportSentSnack;

  /// No description provided for @modBlockedUsersTitle.
  ///
  /// In sr, this message translates to:
  /// **'Blokirani korisnici'**
  String get modBlockedUsersTitle;

  /// No description provided for @modBlockedUsersEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Nikoga niste blokirali.'**
  String get modBlockedUsersEmpty;

  /// No description provided for @modBlockedUsersSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Upravljaj blokiranim korisnicima'**
  String get modBlockedUsersSubtitle;

  /// No description provided for @requestCooldownActive.
  ///
  /// In sr, this message translates to:
  /// **'Ova osoba je nedavno odbila zahtev. Pokušajte ponovo za {hours} h.'**
  String requestCooldownActive(int hours);

  /// No description provided for @requestAlreadyPending.
  ///
  /// In sr, this message translates to:
  /// **'Već ste poslali zahtev ovoj osobi. Sačekajte odgovor.'**
  String get requestAlreadyPending;

  /// No description provided for @actionDelete.
  ///
  /// In sr, this message translates to:
  /// **'Obriši'**
  String get actionDelete;

  /// No description provided for @chatActionsTitle.
  ///
  /// In sr, this message translates to:
  /// **'Razgovor'**
  String get chatActionsTitle;

  /// No description provided for @chatActionHide.
  ///
  /// In sr, this message translates to:
  /// **'Sakrij razgovor'**
  String get chatActionHide;

  /// No description provided for @chatActionHideSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Uklanja iz tvoje liste. Ponovo se pojavljuje kada stigne nova poruka.'**
  String get chatActionHideSubtitle;

  /// No description provided for @chatActionDeleteForever.
  ///
  /// In sr, this message translates to:
  /// **'Obriši zauvek'**
  String get chatActionDeleteForever;

  /// No description provided for @chatActionDeleteForeverSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Briše sve poruke iz tvog prikaza. Druga strana zadržava svoju kopiju.'**
  String get chatActionDeleteForeverSubtitle;

  /// No description provided for @chatHideTitle.
  ///
  /// In sr, this message translates to:
  /// **'Sakriti razgovor?'**
  String get chatHideTitle;

  /// No description provided for @chatHideBody.
  ///
  /// In sr, this message translates to:
  /// **'Razgovor će biti uklonjen iz tvoje liste. Ponovo se pojavljuje kada stigne nova poruka.'**
  String get chatHideBody;

  /// No description provided for @chatHiddenSnack.
  ///
  /// In sr, this message translates to:
  /// **'Razgovor je sakriven.'**
  String get chatHiddenSnack;

  /// No description provided for @chatDeleteForeverTitle.
  ///
  /// In sr, this message translates to:
  /// **'Obrisati razgovor zauvek?'**
  String get chatDeleteForeverTitle;

  /// No description provided for @chatDeleteForeverBody.
  ///
  /// In sr, this message translates to:
  /// **'Sve poruke će nestati iz tvog prikaza ovog razgovora. Ako ikad ponovo razgovaraš sa ovom osobom, krećeš iz čistog razgovora. Druga osoba i dalje vidi tvoje prethodne poruke. Ovo se ne može poništiti.'**
  String get chatDeleteForeverBody;

  /// No description provided for @chatDeletedForeverSnack.
  ///
  /// In sr, this message translates to:
  /// **'Razgovor je obrisan iz tvog prikaza.'**
  String get chatDeletedForeverSnack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
