import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'home': 'الرئيسية', 'services': 'الخدمات', 'discover_more': 'اكتشف المزيد',
      'quran': 'اقرأ القرآن', 'recitation': 'التلاوة الذكية', 'prayer': 'مواقيت الصلاة',
      'qibla': 'القبلة', 'tasbih': 'المسبحة', 'zakat': 'الزكاة', 'adhkar': 'الأذكار',
      'duas': 'الأدعية', 'tajweed': 'التجويد', 'tafsir': 'التفاسير', 'audio': 'القرآن الصوتي',
      'mood_quran': 'القرآن حسب حالتك', 'hifz': 'تحدي الحفظ', 'inheritance': 'حاسبة الميراث',
      'sacred_places': 'المعالم المقدسة', 'settings': 'الإعدادات', 'about_us': 'من نحن',
      'kids_mode': 'وضع الأطفال', 'waqf': 'الصدقة الجارية', 'smart_adhkar': 'أذكار ذكية',
      'dark_mode': 'الوضع الداكن', 'language': 'اللغة', 'ask_ai': 'المساعد الذكي'
    },
    'en': {
      'home': 'Home', 'services': 'Services', 'discover_more': 'Discover More',
      'quran': 'Read Quran', 'recitation': 'AI Recitation', 'prayer': 'Prayer Times',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Duas', 'tajweed': 'Tajweed', 'tafsir': 'Tafsir', 'audio': 'Audio Quran',
      'mood_quran': 'Quran by Mood', 'hifz': 'Hifz Challenge', 'inheritance': 'Inheritance',
      'sacred_places': 'Sacred Places', 'settings': 'Settings', 'about_us': 'About Us',
      'kids_mode': 'Kids Mode', 'waqf': 'Charity Waqf', 'smart_adhkar': 'Smart Adhkar',
      'dark_mode': 'Dark Mode', 'language': 'Language', 'ask_ai': 'Ask AI'
    },
    'fr': {
      'home': 'Accueil', 'services': 'Services', 'discover_more': 'Découvrir Plus',
      'quran': 'Lire le Coran', 'recitation': 'Récitation IA', 'prayer': 'Heures de Prière',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Invocations', 'tajweed': 'Tajwid', 'tafsir': 'Tafsir', 'audio': 'Coran Audio',
      'mood_quran': 'Coran par Humeur', 'hifz': 'Défi de Mémorisation', 'inheritance': 'Héritage',
      'sacred_places': 'Lieux Sacrés', 'settings': 'Paramètres', 'about_us': 'À Propos',
      'kids_mode': 'Mode Enfants', 'waqf': 'Waqf (Charité)', 'smart_adhkar': 'Adhkar Intelligents',
      'dark_mode': 'Mode Sombre', 'language': 'Langue', 'ask_ai': 'Demander à l\'IA'
    },
    'es': {
      'home': 'Inicio', 'services': 'Servicios', 'discover_more': 'Descubrir Más',
      'quran': 'Leer Corán', 'recitation': 'Recitación IA', 'prayer': 'Horarios de Oración',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Súplicas', 'tajweed': 'Taywid', 'tafsir': 'Tafsir', 'audio': 'Corán Audio',
      'mood_quran': 'Corán por Estado', 'hifz': 'Desafío de Memorización', 'inheritance': 'Herencia',
      'sacred_places': 'Lugares Sagrados', 'settings': 'Ajustes', 'about_us': 'Sobre Nosotros',
      'kids_mode': 'Modo Niños', 'waqf': 'Caridad Waqf', 'smart_adhkar': 'Adhkar Inteligentes',
      'dark_mode': 'Modo Oscuro', 'language': 'Idioma', 'ask_ai': 'Preguntar a IA'
    },
    'ur': {
      'home': 'ہوم', 'services': 'خدمات', 'discover_more': 'مزید دریافت کریں',
      'quran': 'قرآن پڑھیں', 'recitation': 'سمارٹ تلاوت', 'prayer': 'نماز کے اوقات',
      'qibla': 'قبلہ', 'tasbih': 'تسبیح', 'zakat': 'زکوٰۃ', 'adhkar': 'اذکار',
      'duas': 'دعائیں', 'tajweed': 'تجوید', 'tafsir': 'تفاسیر', 'audio': 'صوتی قرآن',
      'mood_quran': 'مزاج کے مطابق قرآن', 'hifz': 'حفظ چیلنج', 'inheritance': 'وراثت',
      'sacred_places': 'مقدس مقامات', 'settings': 'ترتیبات', 'about_us': 'ہمارے بارے میں',
      'kids_mode': 'بچوں کا موڈ', 'waqf': 'صدقہ جاریہ', 'smart_adhkar': 'سمارٹ اذکار',
      'dark_mode': 'ڈارک موڈ', 'language': 'زبان', 'ask_ai': 'AI سے پوچھیں'
    },
    'id': {
      'home': 'Beranda', 'services': 'Layanan', 'discover_more': 'Temukan Lebih Banyak',
      'quran': 'Baca Quran', 'recitation': 'Tilawah AI', 'prayer': 'Waktu Sholat',
      'qibla': 'Kiblat', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Dzikir',
      'duas': 'Doa', 'tajweed': 'Tajwid', 'tafsir': 'Tafsir', 'audio': 'Quran Audio',
      'mood_quran': 'Quran Sesuai Suasana', 'hifz': 'Tantangan Hafalan', 'inheritance': 'Waris',
      'sacred_places': 'Tempat Suci', 'settings': 'Pengaturan', 'about_us': 'Tentang Kami',
      'kids_mode': 'Mode Anak', 'waqf': 'Wakaf (Amal)', 'smart_adhkar': 'Dzikir Pintar',
      'dark_mode': 'Mode Gelap', 'language': 'Bahasa', 'ask_ai': 'Tanya AI'
    },
    'hi': {
      'home': 'होम', 'services': 'सेवाएं', 'discover_more': 'और जानें',
      'quran': 'कुरान पढ़ें', 'recitation': 'स्मार्ट तिलावत', 'prayer': 'नमाज़ का समय',
      'qibla': 'किबला', 'tasbih': 'तस्बीह', 'zakat': 'ज़कात', 'adhkar': 'अज़्कार',
      'duas': 'दुआएं', 'tajweed': 'तजवीद', 'tafsir': 'तफ़सीर', 'audio': 'ऑडियो कुरान',
      'mood_quran': 'मूड के अनुसार कुरान', 'hifz': 'हिफ़्ज़ चैलेंज', 'inheritance': 'विरासत',
      'sacred_places': 'पवित्र स्थान', 'settings': 'सेटिंग्स', 'about_us': 'हमारे बारे में',
      'kids_mode': 'बच्चों का मोड', 'waqf': 'वक्फ (दान)', 'smart_adhkar': 'स्मार्ट अज़्कार',
      'dark_mode': 'डार्क मोड', 'language': 'भाषा', 'ask_ai': 'AI से पूछें'
    },
    'bn': {
      'home': 'হোম', 'services': 'পরিষেবা', 'discover_more': 'আরও জানুন',
      'quran': 'কুরআন পড়ুন', 'recitation': 'স্মার্ট তিলাওয়াত', 'prayer': 'নামাজের সময়',
      'qibla': 'কিবলা', 'tasbih': 'তাসবিহ', 'zakat': 'যাকাত', 'adhkar': 'আযকার',
      'duas': 'দোয়া', 'tajweed': 'তাজবীদ', 'tafsir': 'তাফসীর', 'audio': 'অডিও কুরআন',
      'mood_quran': 'মুড অনুযায়ী কুরআন', 'hifz': 'হিফজ চ্যালেঞ্জ', 'inheritance': 'উত্তরাধিকার',
      'sacred_places': 'পবিত্র স্থান', 'settings': 'সেটিংস', 'about_us': 'আমাদের সম্পর্কে',
      'kids_mode': 'শিশু মোড', 'waqf': 'ওয়াকফ (দান)', 'smart_adhkar': 'স্মার্ট আযকার',
      'dark_mode': 'ডার্ক মোড', 'language': 'ভাষা', 'ask_ai': 'AI-কে জিজ্ঞাসা করুন'
    },
    'fa': {
      'home': 'خانه', 'services': 'خدمات', 'discover_more': 'بیشتر کشف کنید',
      'quran': 'خواندن قرآن', 'recitation': 'تلاوت هوشمند', 'prayer': 'اوقات نماز',
      'qibla': 'قبله', 'tasbih': 'تسبیح', 'zakat': 'زکات', 'adhkar': 'اذکار',
      'duas': 'دعاها', 'tajweed': 'تجوید', 'tafsir': 'تفاسیر', 'audio': 'قرآن صوتی',
      'mood_quran': 'قرآن بر اساس حال', 'hifz': 'چالش حفظ', 'inheritance': 'ارث',
      'sacred_places': 'مکان‌های مقدس', 'settings': 'تنظیمات', 'about_us': 'درباره ما',
      'kids_mode': 'حالت کودکان', 'waqf': 'وقف (صدقه جاریه)', 'smart_adhkar': 'اذکار هوشمند',
      'dark_mode': 'حالت تاریک', 'language': 'زبان', 'ask_ai': 'از AI بپرسید'
    },
    'uz': {
      'home': 'Asosiy', 'services': 'Xizmatlar', 'discover_more': 'Ko\'proq kashf eting',
      'quran': 'Quran o\'qish', 'recitation': 'Aqlli tilovat', 'prayer': 'Namoz vaqtlari',
      'qibla': 'Qibla', 'tasbih': 'Tasbeh', 'zakat': 'Zakot', 'adhkar': 'Azklar',
      'duas': 'Duolar', 'tajweed': 'Tajvid', 'tafsir': 'Tafsir', 'audio': 'Audio Quran',
      'mood_quran': 'Kayfiyatga ko\'ra Quran', 'hifz': 'Yodlash musobaqasi', 'inheritance': 'Meros',
      'sacred_places': 'Muqaddas joylar', 'settings': 'Sozlamalar', 'about_us': 'Biz haqimizda',
      'kids_mode': 'Bolalar rejimi', 'waqf': 'Vaqf (Xayriya)', 'smart_adhkar': 'Aqlli azklar',
      'dark_mode': 'Tungi rejim', 'language': 'Til', 'ask_ai': 'AI dan so\'rang'
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['ar', 'en', 'fr', 'es', 'ur', 'id', 'hi', 'bn', 'fa', 'uz'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
