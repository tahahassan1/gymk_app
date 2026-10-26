import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'جيمك'**
  String get appName;

  /// No description provided for @members.
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء'**
  String get members;

  /// No description provided for @dropins.
  ///
  /// In ar, this message translates to:
  /// **'الحصص'**
  String get dropins;

  /// No description provided for @statistics.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @membersDescription.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء الجيم واشتراكاتهم في مكان واحد'**
  String get membersDescription;

  /// No description provided for @dropinsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحصص الفردية ومراجعة أيامها'**
  String get dropinsDescription;

  /// No description provided for @statisticsDescription.
  ///
  /// In ar, this message translates to:
  /// **'متابعة المتحصلات الشهرية من الاشتراكات والحصص'**
  String get statisticsDescription;

  /// No description provided for @settingsDescription.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجيم والأسعار الافتراضية'**
  String get settingsDescription;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'المكان ده بيجهّز لك. الخدمة هتكون متاحة قريبًا.'**
  String get comingSoon;

  /// No description provided for @memberDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العضو'**
  String get memberDetails;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك العضو'**
  String get subscription;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @deletePermanently.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get deletePermanently;

  /// No description provided for @unavailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفتح الصفحة'**
  String get unavailableTitle;

  /// No description provided for @unavailableMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب ترجع للأعضاء وتفتح الصفحة تاني.'**
  String get unavailableMessage;

  /// No description provided for @backToMembers.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للأعضاء'**
  String get backToMembers;

  /// No description provided for @previewTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الواجهة'**
  String get previewTitle;

  /// No description provided for @previewDescription.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الألوان والخطوط والنماذج. البيانات هنا للتجربة فقط.'**
  String get previewDescription;

  /// No description provided for @previewForm.
  ///
  /// In ar, this message translates to:
  /// **'معاينة النموذج'**
  String get previewForm;

  /// No description provided for @previewDelete.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الحذف'**
  String get previewDelete;

  /// No description provided for @previewDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات التجربة؟'**
  String get previewDeleteTitle;

  /// No description provided for @previewDeleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'ده مثال لشكل التأكيد. مفيش بيانات هتتحذف.'**
  String get previewDeleteMessage;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم التليفون (اختياري)'**
  String get phone;

  /// No description provided for @requiredName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم الأول'**
  String get requiredName;

  /// No description provided for @chooseDate.
  ///
  /// In ar, this message translates to:
  /// **'اختار التاريخ'**
  String get chooseDate;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'ساري'**
  String get active;

  /// No description provided for @expiring.
  ///
  /// In ar, this message translates to:
  /// **'قرب يخلص'**
  String get expiring;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @noSubscription.
  ///
  /// In ar, this message translates to:
  /// **'بدون اشتراك'**
  String get noSubscription;

  /// No description provided for @previewFeedback.
  ///
  /// In ar, this message translates to:
  /// **'دي معاينة للرسائل وإعادة المحاولة.'**
  String get previewFeedback;

  /// No description provided for @previewSaved.
  ///
  /// In ar, this message translates to:
  /// **'تمت تجربة النموذج. مفيش بيانات اتحفظت.'**
  String get previewSaved;
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
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
