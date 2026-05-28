// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Stickers Master';

  @override
  String get tabAlbum => 'Album';

  @override
  String get tabStats => 'Statistika';

  @override
  String get tabSwap => 'Razmena';

  @override
  String get tabInbox => 'Poruke';

  @override
  String get tabSettings => 'Podešavanja';

  @override
  String requestDialogTitle(String name) {
    return 'Pošalji poruku — $name';
  }

  @override
  String get requestDialogHint =>
      'Kratka poruka (npr. \"Ćao, vidim da imaš ENG2 koji tražim\")';

  @override
  String get requestDialogSend => 'Pošalji';

  @override
  String get requestDialogCancel => 'Otkaži';

  @override
  String requestDialogCharsLeft(int count) {
    return '$count preostalo';
  }

  @override
  String get requestSent => 'Zahtev je poslat';

  @override
  String get requestSignInRequired => 'Prijavi se da pošalješ poruku';

  @override
  String get inboxTitle => 'Poruke';

  @override
  String get inboxSectionRequests => 'Novi zahtevi';

  @override
  String get inboxSectionChats => 'Aktivni razgovori';

  @override
  String get inboxEmpty => 'Nema novih poruka ili razgovora.';

  @override
  String get inboxEmptyNotSignedIn =>
      'Prijavi se da vidiš poruke od drugih kolekcionara.';

  @override
  String get inboxRequestAccept => 'Prihvati';

  @override
  String get inboxRequestDecline => 'Odbij';

  @override
  String get inboxRequestDeclined => 'Zahtev je odbijen';

  @override
  String get chatNoLastMessage => 'Bez poruka';

  @override
  String get chatInputHint => 'Napiši poruku…';

  @override
  String get chatInputSend => 'Pošalji';

  @override
  String get profileTitle => 'Moj profil';

  @override
  String get profileSettingsEntry => 'Moj profil';

  @override
  String profileSettingsSubtitleSet(String name, String city) {
    return '$name · $city';
  }

  @override
  String get profileSettingsSubtitleUnset => 'Postavi grad za razmenu';

  @override
  String get profileDisplayName => 'Ime';

  @override
  String get profileDisplayNameHint => 'Kako te drugi kolekcionari vide';

  @override
  String get profileCity => 'Grad';

  @override
  String get profileCityHint => 'npr. Beograd';

  @override
  String get profileCountry => 'Država';

  @override
  String get profileCountryHint => 'npr. Srbija';

  @override
  String get profileSave => 'Sačuvaj';

  @override
  String get profileSaved => 'Profil je sačuvan';

  @override
  String get profileRequiredField => 'Obavezno polje';

  @override
  String get profileSignInPrompt =>
      'Prijavi se da podesiš profil i razmenjuješ sa drugima.';

  @override
  String get swapTitle => 'Razmena';

  @override
  String get swapEmptyNotSignedIn =>
      'Prijavi se da vidiš ko može da ti pomogne sa nedostajućim sličicama.';

  @override
  String get swapEmptyNoCity =>
      'Postavi grad u svom profilu da bi filtrirao kolekcionare po gradu.';

  @override
  String get swapEmptyNoCountry =>
      'Postavi državu u svom profilu da pronađeš kolekcionare iz svoje zemlje.';

  @override
  String get swapEmptyNoMissing => 'Sve sličice su u kolekciji — bravo!';

  @override
  String swapEmptyNoMatches(String city) {
    return 'Trenutno nema podudaranja u $city. Pokušaj kasnije.';
  }

  @override
  String swapEmptyNoMatchesCountry(String country) {
    return 'Trenutno nema podudaranja u $country. Pokušaj kasnije.';
  }

  @override
  String swapFilterCityOnly(String city) {
    return 'Samo $city';
  }

  @override
  String get swapOpenProfile => 'Otvori profil';

  @override
  String swapMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sličica za tebe',
      few: '$count sličice za tebe',
      one: '$count sličica za tebe',
    );
    return '$_temp0';
  }

  @override
  String get swapChat => 'Poruka';

  @override
  String get swapChatComingSoon => 'Live chat stiže uskoro — radimo na njemu.';

  @override
  String get swapRefresh => 'Osveži';

  @override
  String get swapAnonymous => 'Anonimni kolekcionar';

  @override
  String get albumPaniniFifa2026 => 'Panini FIFA Svetsko prvenstvo 2026';

  @override
  String wcGroupHeader(String letter) {
    return 'Grupa $letter';
  }

  @override
  String get sectionSpecials => 'Specijalne sličice';

  @override
  String get sectionCollapse => 'Sakrij';

  @override
  String get sectionExpand => 'Prikaži';

  @override
  String get filterAll => 'Sve';

  @override
  String get filterMissing => 'Tražim';

  @override
  String get filterHave => 'Imam';

  @override
  String get filterDuplicates => 'Duplikati';

  @override
  String get filterFoils => 'Foil';

  @override
  String get searchHint => 'Pretraži po šifri (npr. ENG12)';

  @override
  String get albumFilterEmpty => 'Nijedna sličica ne odgovara filteru';

  @override
  String get searchNoResults => 'Nema rezultata';

  @override
  String searchResultCount(int count) {
    return '$count rezultata';
  }

  @override
  String get shareTitle => 'Lista za razmenu';

  @override
  String get shareWanted => 'TRAŽIM';

  @override
  String get shareOffered => 'ZA ZAMENU';

  @override
  String get shareCopy => 'Kopiraj u clipboard';

  @override
  String get shareCopied => 'Lista je kopirana u clipboard';

  @override
  String get shareOpenSheet => 'Podeli listu';

  @override
  String get shareEmpty => 'Nema duplikata niti nedostajućih sličica';

  @override
  String shareHeader(String album) {
    return 'Stickers Master — $album';
  }

  @override
  String shareProgress(int owned, int total, String percent) {
    return 'Stanje: $owned / $total ($percent%)';
  }

  @override
  String get scanPageTooltip => 'Skeniraj stranicu';

  @override
  String scanReviewTitle(String team) {
    return 'Pregled stranice — $team';
  }

  @override
  String get scanBulkInstructions =>
      'Gledaj sliku i označi sličice koje si dodao na ovu stranicu. Već unesene su zaključane.';

  @override
  String get scanSelectAllEmpty => 'Označi sve prazne';

  @override
  String get scanClearAll => 'Obriši izbor';

  @override
  String get scanRetake => 'Ponovi snimanje';

  @override
  String get scanApply => 'Sačuvaj';

  @override
  String get scanCancelled => 'Skeniranje je otkazano';

  @override
  String scanAppliedCount(int count) {
    return 'Dodato $count sličica u kolekciju';
  }

  @override
  String get scanNothingChanged => 'Nije izabrana ni jedna sličica';

  @override
  String scanCameraError(String message) {
    return 'Greška pri otvaranju kamere: $message';
  }

  @override
  String get settingsAccount => 'Nalog';

  @override
  String get accountGuest => 'Gost';

  @override
  String get accountGuestSubtitle =>
      'Prijavi se da sinhronizuješ kolekciju i razmenjuješ.';

  @override
  String get accountSignedIn => 'Prijavljen';

  @override
  String get accountSignedOut => 'Niko nije prijavljen';

  @override
  String get accountFirebaseUnconfiguredTitle => 'Firebase nije podešen';

  @override
  String get accountFirebaseUnconfiguredBody =>
      'Pokreni `flutterfire configure` u app/ folderu da povežeš Firebase projekat.';

  @override
  String get signInTitle => 'Prijava';

  @override
  String get signInSubtitle =>
      'Prijavi se da sinhronizuješ kolekciju između uređaja i razmenjuješ sa drugim kolekcionarima.';

  @override
  String get signInGoogle => 'Prijavi se sa Google nalogom';

  @override
  String get signInGuest => 'Nastavi kao gost';

  @override
  String get signInComingSoon =>
      'Prijava preko emaila i broja telefona — uskoro.';

  @override
  String get signOut => 'Odjavi se';

  @override
  String get signOutConfirmTitle => 'Odjava?';

  @override
  String get signOutConfirmBody =>
      'Tvoja lokalna kolekcija ostaje. Sinhronizacija sa cloud-om se zaustavlja dok se ponovo ne prijaviš.';

  @override
  String get settingsDeleteAccount => 'Obriši nalog';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Trajno ukloni nalog i sve podatke';

  @override
  String get deleteAccountTitle => 'Obrisati nalog?';

  @override
  String get deleteAccountBody =>
      'Ovim se trajno brišu tvoj nalog, tvoja kolekcija, profil za razmenu i sva tvoja ćaskanja i poruke. Razgovori će biti uklonjeni i kod osoba sa kojima si ćaskao. Ova radnja se ne može poništiti.';

  @override
  String get deleteAccountConfirm => 'Obriši';

  @override
  String get deleteAccountProgress => 'Brisanje naloga…';

  @override
  String get deleteAccountDone => 'Tvoj nalog i podaci su obrisani.';

  @override
  String get deleteAccountError =>
      'Brisanje naloga nije uspelo. Proveri internet vezu i pokušaj ponovo.';

  @override
  String stickersOwnedOfTotal(int owned, int total) {
    return '$owned / $total sličica';
  }

  @override
  String stickersOwnedPercent(String percent) {
    return '$percent% kompletirano';
  }

  @override
  String get statusHave => 'Imam';

  @override
  String get statusDuplicate => 'Duplikat';

  @override
  String get statusMissing => 'Tražim';

  @override
  String get statusFoil => 'Foil';

  @override
  String duplicatesShort(int count) {
    return 'x$count';
  }

  @override
  String get settingsLanguage => 'Jezik';

  @override
  String get settingsLanguageSerbian => 'Srpski (latinica)';

  @override
  String get settingsLanguageEnglish => 'Engleski';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistemska';

  @override
  String get settingsThemeLight => 'Svetla';

  @override
  String get settingsThemeDark => 'Tamna';

  @override
  String get settingsAbout => 'O aplikaciji';

  @override
  String settingsVersion(String version) {
    return 'Verzija $version';
  }

  @override
  String stickerEditTitle(String code) {
    return 'Sličica $code';
  }

  @override
  String get stickerEditOwnedCount => 'Koliko ih imaš?';

  @override
  String get stickerEditNone => 'Nemam';

  @override
  String get stickerEditHaveOne => 'Imam jednu';

  @override
  String stickerEditDuplicates(int count) {
    return '$count duplikata';
  }

  @override
  String get actionDone => 'Gotovo';

  @override
  String get actionCancel => 'Otkaži';

  @override
  String get actionReset => 'Resetuj';

  @override
  String get modBlock => 'Blokiraj';

  @override
  String get modBlockUser => 'Blokiraj korisnika';

  @override
  String get modUnblock => 'Deblokiraj';

  @override
  String get modUnblockUser => 'Deblokiraj korisnika';

  @override
  String get modReport => 'Prijavi';

  @override
  String get modReportUser => 'Prijavi korisnika';

  @override
  String modBlockConfirmTitle(String name) {
    return 'Blokirati $name?';
  }

  @override
  String get modBlockConfirmBody =>
      'Nećete više videti njihove poruke ni zahteve za ćaskanje, niti će se pojavljivati u razmeni. Možete ih kasnije deblokirati u Podešavanjima.';

  @override
  String modBlockedSnack(String name) {
    return '$name je blokiran/a.';
  }

  @override
  String modUnblockedSnack(String name) {
    return '$name je deblokiran/a.';
  }

  @override
  String modReportTitle(String name) {
    return 'Prijavi $name';
  }

  @override
  String get modReportReasonLabel => 'Razlog prijave';

  @override
  String get modReportReasonSpam => 'Neželjene poruke (spam)';

  @override
  String get modReportReasonHarassment => 'Uznemiravanje ili vređanje';

  @override
  String get modReportReasonInappropriate => 'Neprikladan sadržaj';

  @override
  String get modReportReasonOther => 'Drugo';

  @override
  String get modReportDetailsHint => 'Dodatni detalji (opciono)';

  @override
  String get modReportSubmit => 'Pošalji prijavu';

  @override
  String get modReportSentSnack =>
      'Prijava je poslata. Hvala što pomažeš da zajednica bude bezbedna.';

  @override
  String get modBlockedUsersTitle => 'Blokirani korisnici';

  @override
  String get modBlockedUsersEmpty => 'Nikoga niste blokirali.';

  @override
  String get modBlockedUsersSubtitle => 'Upravljaj blokiranim korisnicima';

  @override
  String requestCooldownActive(int hours) {
    return 'Ova osoba je nedavno odbila zahtev. Pokušajte ponovo za $hours h.';
  }

  @override
  String get requestAlreadyPending =>
      'Već ste poslali zahtev ovoj osobi. Sačekajte odgovor.';

  @override
  String get actionDelete => 'Obriši';

  @override
  String get chatDeleteTitle => 'Obriši razgovor?';

  @override
  String get chatDeleteBody =>
      'Razgovor će biti uklonjen iz tvoje liste. Ponovo se pojavljuje ako stigne nova poruka.';

  @override
  String get chatDeletedSnack => 'Razgovor je uklonjen.';
}
