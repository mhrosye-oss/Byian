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
      'app_title': 'إتقان',
      'home': 'الرئيسية', 'services': 'الخدمات', 'discover_more': 'اكتشف المزيد',
      'quran': 'اقرأ القرآن', 'recitation': 'التلاوة الذكية', 'prayer': 'مواقيت الصلاة',
      'qibla': 'القبلة', 'tasbih': 'المسبحة', 'zakat': 'الزكاة', 'adhkar': 'الأذكار',
      'duas': 'الأدعية', 'tajweed': 'التجويد', 'tafsir': 'التفاسير', 'audio': 'القرآن الصوتي',
      'mood_quran': 'القرآن حسب حالتك', 'hifz': 'تحدي الحفظ', 'inheritance': 'حاسبة الميراث',
      'sacred_places': 'المعالم المقدسة', 'settings': 'الإعدادات', 'about_us': 'من نحن',
      'kids_mode': 'وضع الأطفال', 'waqf': 'الصدقة الجارية', 'smart_adhkar': 'أذكار ذكية',
      'dark_mode': 'الوضع الداكن', 'language': 'اللغة', 'ask_ai': 'المساعد الذكي',
      'drawer_welcome': 'مرحباً بك في إتقان', 'drawer_login': 'تسجيل الدخول', 'drawer_logout': 'تسجيل الخروج',
      'drawer_fazakkir': 'فَذَكِّر (تذكير شخصي هادئ)', 'drawer_world': 'عالم إتقان والمهام العشرون',
      'drawer_profile': 'ملفي الشخصي وكود الإحالة', 'drawer_share_cards': 'بطاقات المشاركة الاجتماعية',
      'drawer_leaderboard': 'العشرة الأوائل', 'drawer_achievements': 'الأوسمة والإنجازات',
      'drawer_ai': 'المساعد الذكي', 'drawer_kids': 'وضع الأطفال', 'drawer_waqf': 'الصدقة الجارية',
      'drawer_contributors': 'شكراً لمساهمينا', 'drawer_about': 'من نحن',
      'drawer_language_title': 'اللغة', 'choose_language': 'اختر اللغة', 'language_error': 'تعذر تغيير اللغة: ',
      'onboarding_skip': 'تخطي', 'onboarding_next': 'التالي', 'onboarding_start': 'ابدأ الآن',
      'onboarding_confirm_lang': 'تأكيد اللغة',
      'onboarding_title_1': 'إتقان', 'onboarding_sub_1': 'أتقن تلاوة القرآن الكريم',
      'onboarding_title_2': 'حدد مستواك', 'onboarding_sub_2': 'اختر مستواك لنقدم لك تجربة مخصصة',
      'onboarding_title_3': 'ابدأ رحلتك', 'onboarding_sub_3': 'استمع، اقرأ، وتدبر آيات الله',
      'teacher_home_title': 'معلّم القرآن الذكي',
      'memorization': 'احفظ معي',
      'recitation_title': 'سمّع لي',
      'recitation_intro_title': 'تنويه خدمة التسميع',
      'recitation_result_title': 'نتيجة التسميع',
      'revision_title': 'راجع معي',
      'tajweed_lessons': 'حسّن تلاوتك',
    },
    'en': {
      'app_title': 'Itqan',
      'home': 'Home', 'services': 'Services', 'discover_more': 'Discover More',
      'quran': 'Read Quran', 'recitation': 'AI Recitation', 'prayer': 'Prayer Times',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Duas', 'tajweed': 'Tajweed', 'tafsir': 'Tafsir', 'audio': 'Audio Quran',
      'mood_quran': 'Quran by Mood', 'hifz': 'Hifz Challenge', 'inheritance': 'Inheritance',
      'sacred_places': 'Sacred Places', 'settings': 'Settings', 'about_us': 'About Us',
      'kids_mode': 'Kids Mode', 'waqf': 'Charity Waqf', 'smart_adhkar': 'Smart Adhkar',
      'dark_mode': 'Dark Mode', 'language': 'Language', 'ask_ai': 'Ask AI',
      'teacher_home_title': 'Smart Quran Teacher',
      'memorization': 'Memorize with Me',
      'recitation_title': 'Recite to Me',
      'recitation_intro_title': 'Recitation Notice',
      'recitation_result_title': 'Recitation Result',
      'revision_title': 'Review with Me',
      'tajweed_lessons': 'Improve Your Tajweed',
      'drawer_welcome': 'Welcome to Itqan', 'drawer_login': 'Login', 'drawer_logout': 'Logout',
      'drawer_fazakkir': 'Fazakkir (Personal Reminder)', 'drawer_world': 'Itqan World & 20 Tasks',
      'drawer_profile': 'My Profile & Referral Code', 'drawer_share_cards': 'Social Share Cards',
      'drawer_leaderboard': 'Top 10', 'drawer_achievements': 'Badges & Achievements',
      'drawer_ai': 'AI Assistant', 'drawer_kids': 'Kids Mode', 'drawer_waqf': 'Charity Waqf',
      'drawer_contributors': 'Thanks to Our Contributors', 'drawer_about': 'About Us',
      'drawer_language_title': 'Language', 'choose_language': 'Choose Language', 'language_error': 'Could not change language: ',
      'onboarding_skip': 'Skip', 'onboarding_next': 'Next', 'onboarding_start': 'Start Now',
      'onboarding_confirm_lang': 'Confirm Language',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': 'Perfect your Quran recitation',
      'onboarding_title_2': 'Set Your Level', 'onboarding_sub_2': 'Choose your level for a personalized experience',
      'onboarding_title_3': 'Start Your Journey', 'onboarding_sub_3': 'Listen, read, and reflect on the verses of Allah'
    },
    'fr': {
      'home': 'Accueil', 'services': 'Services', 'discover_more': 'Découvrir Plus',
      'quran': 'Lire le Coran', 'recitation': 'Récitation IA', 'prayer': 'Heures de Prière',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Invocations', 'tajweed': 'Tajwid', 'tafsir': 'Tafsir', 'audio': 'Coran Audio',
      'mood_quran': 'Coran par Humeur', 'hifz': 'Défi de Mémorisation', 'inheritance': 'Héritage',
      'sacred_places': 'Lieux Sacrés', 'settings': 'Paramètres', 'about_us': 'À Propos',
      'kids_mode': 'Mode Enfants', 'waqf': 'Waqf (Charité)', 'smart_adhkar': 'Adhkar Intelligents',
      'dark_mode': 'Mode Sombre', 'language': 'Langue', 'ask_ai': "Demander à l'IA",
      'drawer_welcome': 'Bienvenue sur Itqan', 'drawer_login': 'Connexion', 'drawer_logout': 'Déconnexion',
      'drawer_fazakkir': 'Fazakkir (Rappel Personnel)', 'drawer_world': 'Monde Itqan & 20 Tâches',
      'drawer_profile': 'Mon Profil & Code Parrainage', 'drawer_share_cards': 'Cartes de Partage',
      'drawer_leaderboard': 'Top 10', 'drawer_achievements': 'Badges & Réalisations',
      'drawer_ai': 'Assistant IA', 'drawer_kids': 'Mode Enfants', 'drawer_waqf': 'Waqf (Charité)',
      'drawer_contributors': 'Merci à Nos Contributeurs', 'drawer_about': 'À Propos',
      'drawer_language_title': 'Langue', 'choose_language': 'Choisir la Langue', 'language_error': 'Impossible de changer de langue: ',
      'onboarding_skip': 'Passer', 'onboarding_next': 'Suivant', 'onboarding_start': 'Commencer',
      'onboarding_confirm_lang': 'Confirmer la Langue',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': 'Perfectionnez votre récitation du Coran',
      'onboarding_title_2': 'Définir votre niveau', 'onboarding_sub_2': 'Choisissez votre niveau pour une expérience personnalisée',
      'onboarding_title_3': 'Commencer votre voyage', 'onboarding_sub_3': "Écoutez, lisez et méditez les versets d'Allah"
    },
    'es': {
      'home': 'Inicio', 'services': 'Servicios', 'discover_more': 'Descubrir Más',
      'quran': 'Leer Corán', 'recitation': 'Recitación IA', 'prayer': 'Horarios de Oración',
      'qibla': 'Qibla', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Adhkar',
      'duas': 'Súplicas', 'tajweed': 'Taywid', 'tafsir': 'Tafsir', 'audio': 'Corán Audio',
      'mood_quran': 'Corán por Estado', 'hifz': 'Desafío de Memorización', 'inheritance': 'Herencia',
      'sacred_places': 'Lugares Sagrados', 'settings': 'Ajustes', 'about_us': 'Sobre Nosotros',
      'kids_mode': 'Modo Niños', 'waqf': 'Caridad Waqf', 'smart_adhkar': 'Adhkar Inteligentes',
      'dark_mode': 'Modo Oscuro', 'language': 'Idioma', 'ask_ai': 'Preguntar a IA',
      'drawer_welcome': 'Bienvenido a Itqan', 'drawer_login': 'Iniciar Sesión', 'drawer_logout': 'Cerrar Sesión',
      'drawer_fazakkir': 'Fazakkir (Recordatorio Personal)', 'drawer_world': 'Mundo Itqan & 20 Tareas',
      'drawer_profile': 'Mi Perfil & Código de Referido', 'drawer_share_cards': 'Tarjetas para Compartir',
      'drawer_leaderboard': 'Top 10', 'drawer_achievements': 'Insignias y Logros',
      'drawer_ai': 'Asistente IA', 'drawer_kids': 'Modo Niños', 'drawer_waqf': 'Caridad Waqf',
      'drawer_contributors': 'Gracias a Nuestros Colaboradores', 'drawer_about': 'Sobre Nosotros',
      'drawer_language_title': 'Idioma', 'choose_language': 'Elegir Idioma', 'language_error': 'No se pudo cambiar el idioma: ',
      'onboarding_skip': 'Omitir', 'onboarding_next': 'Siguiente', 'onboarding_start': 'Comenzar',
      'onboarding_confirm_lang': 'Confirmar Idioma',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': 'Perfeccione su recitación del Corán',
      'onboarding_title_2': 'Define tu nivel', 'onboarding_sub_2': 'Elige tu nivel para una experiencia personalizada',
      'onboarding_title_3': 'Comienza tu viaje', 'onboarding_sub_3': 'Escucha, lee y reflexiona sobre los versículos de Allah'
    },
    'ur': {
      'home': 'ہوم', 'services': 'خدمات', 'discover_more': 'مزید دریافت کریں',
      'quran': 'قرآن پڑھیں', 'recitation': 'سمارٹ تلاوت', 'prayer': 'نماز کے اوقات',
      'qibla': 'قبلہ', 'tasbih': 'تسبیح', 'zakat': 'زکوٰۃ', 'adhkar': 'اذکار',
      'duas': 'دعائیں', 'tajweed': 'تجوید', 'tafsir': 'تفاسیر', 'audio': 'صوتی قرآن',
      'mood_quran': 'مزاج کے مطابق قرآن', 'hifz': 'حفظ چیلنج', 'inheritance': 'وراثت',
      'sacred_places': 'مقدس مقامات', 'settings': 'ترتیبات', 'about_us': 'ہمارے بارے میں',
      'kids_mode': 'بچوں کا موڈ', 'waqf': 'صدقہ جاریہ', 'smart_adhkar': 'سمارٹ اذکار',
      'dark_mode': 'ڈارک موڈ', 'language': 'زبان', 'ask_ai': 'AI سے پوچھیں',
      'drawer_welcome': 'اتقان میں خوش آمدید', 'drawer_login': 'لاگ ان', 'drawer_logout': 'لاگ آؤٹ',
      'drawer_fazakkir': 'فذکّر (ذاتی یاد دہانی)', 'drawer_world': 'اتقان کی دنیا اور 20 کام',
      'drawer_profile': 'میری پروفائل اور ریفرل کوڈ', 'drawer_share_cards': 'سوشل شیئرنگ کارڈز',
      'drawer_leaderboard': 'سرفہرست 10', 'drawer_achievements': 'تمغات اور کامیابیاں',
      'drawer_ai': 'AI معاون', 'drawer_kids': 'بچوں کا موڈ', 'drawer_waqf': 'صدقہ جاریہ',
      'drawer_contributors': 'ہمارے معاونین کا شکریہ', 'drawer_about': 'ہمارے بارے میں',
      'drawer_language_title': 'زبان', 'choose_language': 'زبان منتخب کریں', 'language_error': 'زبان تبدیل نہیں ہو سکی: ',
      'onboarding_skip': 'چھوڑیں', 'onboarding_next': 'اگلا', 'onboarding_start': 'ابھی شروع کریں',
      'onboarding_confirm_lang': 'زبان کی تصدیق کریں',
      'onboarding_title_1': 'اتقان', 'onboarding_sub_1': 'اپنی تلاوت قرآن کو بہترین بنائیں',
      'onboarding_title_2': 'اپنا معیار طے کریں', 'onboarding_sub_2': 'ذاتی تجربے کے لیے اپنی سطح منتخب کریں',
      'onboarding_title_3': 'اپنا سفر شروع کریں', 'onboarding_sub_3': 'اللہ کی آیات سنیں، پڑھیں اور غور کریں'
    },
    'id': {
      'home': 'Beranda', 'services': 'Layanan', 'discover_more': 'Temukan Lebih Banyak',
      'quran': 'Baca Quran', 'recitation': 'Tilawah AI', 'prayer': 'Waktu Sholat',
      'qibla': 'Kiblat', 'tasbih': 'Tasbih', 'zakat': 'Zakat', 'adhkar': 'Dzikir',
      'duas': 'Doa', 'tajweed': 'Tajwid', 'tafsir': 'Tafsir', 'audio': 'Quran Audio',
      'mood_quran': 'Quran Sesuai Suasana', 'hifz': 'Tantangan Hafalan', 'inheritance': 'Waris',
      'sacred_places': 'Tempat Suci', 'settings': 'Pengaturan', 'about_us': 'Tentang Kami',
      'kids_mode': 'Mode Anak', 'waqf': 'Wakaf (Amal)', 'smart_adhkar': 'Dzikir Pintar',
      'dark_mode': 'Mode Gelap', 'language': 'Bahasa', 'ask_ai': 'Tanya AI',
      'drawer_welcome': 'Selamat Datang di Itqan', 'drawer_login': 'Masuk', 'drawer_logout': 'Keluar',
      'drawer_fazakkir': 'Fazakkir (Pengingat Pribadi)', 'drawer_world': 'Dunia Itqan & 20 Misi',
      'drawer_profile': 'Profil Saya & Kode Referral', 'drawer_share_cards': 'Kartu Berbagi Sosial',
      'drawer_leaderboard': '10 Teratas', 'drawer_achievements': 'Lencana & Pencapaian',
      'drawer_ai': 'Asisten AI', 'drawer_kids': 'Mode Anak', 'drawer_waqf': 'Wakaf (Amal)',
      'drawer_contributors': 'Terima Kasih Kontributor', 'drawer_about': 'Tentang Kami',
      'drawer_language_title': 'Bahasa', 'choose_language': 'Pilih Bahasa', 'language_error': 'Gagal mengubah bahasa: ',
      'onboarding_skip': 'Lewati', 'onboarding_next': 'Lanjut', 'onboarding_start': 'Mulai Sekarang',
      'onboarding_confirm_lang': 'Konfirmasi Bahasa',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': 'Sempurnakan bacaan Al-Quran Anda',
      'onboarding_title_2': 'Tentukan Level Anda', 'onboarding_sub_2': 'Pilih level Anda untuk pengalaman yang dipersonalisasi',
      'onboarding_title_3': 'Mulai Perjalanan Anda', 'onboarding_sub_3': 'Dengarkan, baca, dan tadaburi ayat-ayat Allah'
    },
    'hi': {
      'home': 'होम', 'services': 'सेवाएं', 'discover_more': 'और जानें',
      'quran': 'कुरान पढ़ें', 'recitation': 'स्मार्ट तिलावत', 'prayer': 'नमाज़ का समय',
      'qibla': 'किबला', 'tasbih': 'तस्बीह', 'zakat': 'ज़कात', 'adhkar': 'अज़्कार',
      'duas': 'दुआएं', 'tajweed': 'तजवीद', 'tafsir': 'तफ़सीर', 'audio': 'ऑडियो कुरान',
      'mood_quran': 'मूड के अनुसार कुरान', 'hifz': 'हिफ़्ज़ चैलेंज', 'inheritance': 'विरासत',
      'sacred_places': 'पवित्र स्थान', 'settings': 'सेटिंग्स', 'about_us': 'हमारे बारे में',
      'kids_mode': 'बच्चों का मोड', 'waqf': 'वक्फ (दान)', 'smart_adhkar': 'स्मार्ट अज़्कार',
      'dark_mode': 'डार्क मोड', 'language': 'भाषा', 'ask_ai': 'AI से पूछें',
      'drawer_welcome': 'Itqan में आपका स्वागत है', 'drawer_login': 'लॉग इन', 'drawer_logout': 'लॉग आउट',
      'drawer_fazakkir': 'फ़ज़क्किर (व्यक्तिगत अनुस्मारक)', 'drawer_world': 'Itqan की दुनिया और 20 कार्य',
      'drawer_profile': 'मेरी प्रोफ़ाइल और रेफरल कोड', 'drawer_share_cards': 'सामाजिक साझाकरण कार्ड',
      'drawer_leaderboard': 'शीर्ष 10', 'drawer_achievements': 'बैज और उपलब्धियां',
      'drawer_ai': 'AI सहायक', 'drawer_kids': 'बच्चों का मोड', 'drawer_waqf': 'वक्फ (दान)',
      'drawer_contributors': 'हमारे योगदानकर्ताओं का धन्यवाद', 'drawer_about': 'हमारे बारे में',
      'drawer_language_title': 'भाषा', 'choose_language': 'भाषा चुनें', 'language_error': 'भाषा बदली नहीं जा सकी: ',
      'onboarding_skip': 'छोड़ें', 'onboarding_next': 'आगे', 'onboarding_start': 'अभी शुरू करें',
      'onboarding_confirm_lang': 'भाषा की पुष्टि करें',
      'onboarding_title_1': 'इतक़ान', 'onboarding_sub_1': 'अपनी कुरान तिलावत को परिपूर्ण करें',
      'onboarding_title_2': 'अपना स्तर चुनें', 'onboarding_sub_2': 'व्यक्तिगत अनुभव के लिए अपना स्तर चुनें',
      'onboarding_title_3': 'अपनी यात्रा शुरू करें', 'onboarding_sub_3': 'अल्लाह की आयतों को सुनें, पढ़ें और समझें'
    },
    'bn': {
      'home': 'হোম', 'services': 'পরিষেবা', 'discover_more': 'আরও জানুন',
      'quran': 'কুরআন পড়ুন', 'recitation': 'স্মার্ট তিলাওয়াত', 'prayer': 'নামাজের সময়',
      'qibla': 'কিবলা', 'tasbih': 'তাসবিহ', 'zakat': 'যাকাত', 'adhkar': 'আযকার',
      'duas': 'দোয়া', 'tajweed': 'তাজবীদ', 'tafsir': 'তাফসীর', 'audio': 'অডিও কুরআন',
      'mood_quran': 'মুড অনুযায়ী কুরআন', 'hifz': 'হিফজ চ্যালেঞ্জ', 'inheritance': 'উত্তরাধিকার',
      'sacred_places': 'পবিত্র স্থান', 'settings': 'সেটিংস', 'about_us': 'আমাদের সম্পর্কে',
      'kids_mode': 'শিশু মোড', 'waqf': 'ওয়াকফ (দান)', 'smart_adhkar': 'স্মার্ট আযকার',
      'dark_mode': 'ডার্ক মোড', 'language': 'ভাষা', 'ask_ai': 'AI-কে জিজ্ঞাসা করুন',
      'drawer_welcome': 'Itqan-এ স্বাগতম', 'drawer_login': 'লগ ইন', 'drawer_logout': 'লগ আউট',
      'drawer_fazakkir': 'ফাযাক্কির (ব্যক্তিগত স্মরণিকা)', 'drawer_world': 'Itqan জগৎ এবং ২০ কাজ',
      'drawer_profile': 'আমার প্রোফাইল ও রেফারেল কোড', 'drawer_share_cards': 'সামাজিক শেয়ার কার্ড',
      'drawer_leaderboard': 'শীর্ষ ১০', 'drawer_achievements': 'ব্যাজ এবং কৃতিত্ব',
      'drawer_ai': 'AI সহায়ক', 'drawer_kids': 'শিশু মোড', 'drawer_waqf': 'ওয়াকফ (দান)',
      'drawer_contributors': 'আমাদের অবদানকারীদের ধন্যবাদ', 'drawer_about': 'আমাদের সম্পর্কে',
      'drawer_language_title': 'ভাষা', 'choose_language': 'ভাষা নির্বাচন করুন', 'language_error': 'ভাষা পরিবর্তন করা যায়নি: ',
      'onboarding_skip': 'এড়িয়ে যান', 'onboarding_next': 'পরবর্তী', 'onboarding_start': 'এখনই শুরু করুন',
      'onboarding_confirm_lang': 'ভাষা নিশ্চিত করুন',
      'onboarding_title_1': 'ইতকান', 'onboarding_sub_1': 'আপনার কুরআন তিলাওয়াত নিখুঁত করুন',
      'onboarding_title_2': 'আপনার স্তর নির্ধারণ করুন', 'onboarding_sub_2': 'ব্যক্তিগত অভিজ্ঞতার জন্য আপনার স্তর নির্বাচন করুন',
      'onboarding_title_3': 'আপনার যাত্রা শুরু করুন', 'onboarding_sub_3': 'আল্লাহর আয়াত শুনুন, পড়ুন এবং অনুধাবন করুন'
    },
    'fa': {
      'home': 'خانه', 'services': 'خدمات', 'discover_more': 'بیشتر کشف کنید',
      'quran': 'خواندن قرآن', 'recitation': 'تلاوت هوشمند', 'prayer': 'اوقات نماز',
      'qibla': 'قبله', 'tasbih': 'تسبیح', 'zakat': 'زکات', 'adhkar': 'اذکار',
      'duas': 'دعاها', 'tajweed': 'تجوید', 'tafsir': 'تفاسیر', 'audio': 'قرآن صوتی',
      'mood_quran': 'قرآن بر اساس حال', 'hifz': 'چالش حفظ', 'inheritance': 'ارث',
      'sacred_places': 'مکان‌های مقدس', 'settings': 'تنظیمات', 'about_us': 'درباره ما',
      'kids_mode': 'حالت کودکان', 'waqf': 'وقف (صدقه جاریه)', 'smart_adhkar': 'اذکار هوشمند',
      'dark_mode': 'حالت تاریک', 'language': 'زبان', 'ask_ai': 'از AI بپرسید',
      'drawer_welcome': 'به Itqan خوش آمدید', 'drawer_login': 'ورود', 'drawer_logout': 'خروج',
      'drawer_fazakkir': 'فاذکّر (یادآور شخصی)', 'drawer_world': 'دنیای Itqan و ۲۰ مأموریت',
      'drawer_profile': 'پروفایل من و کد معرف', 'drawer_share_cards': 'کارت‌های اشتراک‌گذاری',
      'drawer_leaderboard': 'برترین ۱۰', 'drawer_achievements': 'نشان‌ها و دستاوردها',
      'drawer_ai': 'دستیار هوش مصنوعی', 'drawer_kids': 'حالت کودکان', 'drawer_waqf': 'وقف',
      'drawer_contributors': 'تشکر از مشارکت‌کنندگان', 'drawer_about': 'درباره ما',
      'drawer_language_title': 'زبان', 'choose_language': 'انتخاب زبان', 'language_error': 'تغییر زبان انجام نشد: ',
      'onboarding_skip': 'رد کردن', 'onboarding_next': 'بعدی', 'onboarding_start': 'شروع اکنون',
      'onboarding_confirm_lang': 'تأیید زبان',
      'onboarding_title_1': 'اتقان', 'onboarding_sub_1': 'تلاوت قرآن خود را کامل کنید',
      'onboarding_title_2': 'سطح خود را تعیین کنید', 'onboarding_sub_2': 'سطح خود را برای تجربه‌ای شخصی‌سازی‌شده انتخاب کنید',
      'onboarding_title_3': 'سفر خود را آغاز کنید', 'onboarding_sub_3': 'به آیات خداوند گوش فرا دهید، بخوانید و تفکر کنید'
    },
    'uz': {
      'home': 'Asosiy', 'services': 'Xizmatlar', 'discover_more': "Ko'proq kashf eting",
      'quran': "Quran o'qish", 'recitation': 'Aqlli tilovat', 'prayer': 'Namoz vaqtlari',
      'qibla': 'Qibla', 'tasbih': 'Tasbeh', 'zakat': 'Zakot', 'adhkar': 'Azklar',
      'duas': 'Duolar', 'tajweed': 'Tajvid', 'tafsir': 'Tafsir', 'audio': 'Audio Quran',
      'mood_quran': "Kayfiyatga ko'ra Quran", 'hifz': 'Yodlash musobaqasi', 'inheritance': 'Meros',
      'sacred_places': 'Muqaddas joylar', 'settings': 'Sozlamalar', 'about_us': 'Biz haqimizda',
      'kids_mode': 'Bolalar rejimi', 'waqf': 'Vaqf (Xayriya)', 'smart_adhkar': 'Aqlli azklar',
      'dark_mode': 'Tungi rejim', 'language': 'Til', 'ask_ai': "AI dan so'rang",
      'drawer_welcome': "Itqan ga xush kelibsiz", 'drawer_login': 'Kirish', 'drawer_logout': 'Chiqish',
      'drawer_fazakkir': "Fazakkir (Shaxsiy eslatma)", 'drawer_world': "Itqan dunyosi va 20 vazifa",
      'drawer_profile': "Mening profilim va referal kod", 'drawer_share_cards': 'Ijtimoiy ulashish kartalari',
      'drawer_leaderboard': 'Top 10', 'drawer_achievements': "Nishonlar va yutuqlar",
      'drawer_ai': 'AI yordamchi', 'drawer_kids': 'Bolalar rejimi', 'drawer_waqf': 'Vaqf (Xayriya)',
      'drawer_contributors': "Hissadorlarimizga rahmat", 'drawer_about': 'Biz haqimizda',
      'drawer_language_title': 'Til', 'choose_language': 'Tilni tanlang', 'language_error': "Til o'zgartirilmadi: ",
      'onboarding_skip': "O'tkazib yuborish", 'onboarding_next': 'Keyingi', 'onboarding_start': 'Hozir boshlash',
      'onboarding_confirm_lang': 'Tilni tasdiqlash',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': "Qur'on tilovatingizni mukammallashtiring",
      'onboarding_title_2': 'Darajangizni belgilang', 'onboarding_sub_2': 'Moslashtirilgan tajriba uchun darajangizni tanlang',
      'onboarding_title_3': 'Sayohatingizni boshlang', 'onboarding_sub_3': "Allohning oyatlarini tinglang, o'qing va tafakkur qiling"
    },
    'tr': {
      'home': 'Ana Sayfa', 'services': 'Hizmetler', 'discover_more': 'Daha Fazlasını Keşfet',
      'quran': "Kuran Oku", 'recitation': 'Akıllı Tilavet', 'prayer': 'Namaz Vakitleri',
      'qibla': 'Kıble', 'tasbih': 'Tesbih', 'zakat': 'Zekat', 'adhkar': 'Zikirler',
      'duas': 'Dualar', 'tajweed': 'Tecvid', 'tafsir': 'Tefsir', 'audio': 'Sesli Kuran',
      'mood_quran': 'Ruh Haline Göre Kuran', 'hifz': 'Hafızlık Yarışması', 'inheritance': 'Miras',
      'sacred_places': 'Kutsal Yerler', 'settings': 'Ayarlar', 'about_us': 'Hakkımızda',
      'kids_mode': 'Çocuk Modu', 'waqf': 'Vakıf (Sadaka)', 'smart_adhkar': 'Akıllı Zikirler',
      'dark_mode': 'Karanlık Mod', 'language': 'Dil', 'ask_ai': "AI'ya Sor",
      'drawer_welcome': "Itqan'a Hoş Geldiniz", 'drawer_login': 'Giriş Yap', 'drawer_logout': 'Çıkış Yap',
      'drawer_fazakkir': 'Fazakkir (Kişisel Hatırlatıcı)', 'drawer_world': 'İtqan Dünyası ve 20 Görev',
      'drawer_profile': 'Profilim ve Davet Kodu', 'drawer_share_cards': 'Sosyal Paylaşım Kartları',
      'drawer_leaderboard': 'İlk 10', 'drawer_achievements': 'Madalyalar ve Başarılar',
      'drawer_ai': 'Yapay Zeka Asistanı', 'drawer_kids': 'Çocuk Modu', 'drawer_waqf': 'Vakıf (Sadaka)',
      'drawer_contributors': 'Katkıda Bulunanlarımıza Teşekkür', 'drawer_about': 'Hakkımızda',
      'drawer_language_title': 'Dil', 'choose_language': 'Dil Seçin', 'language_error': 'Dil değiştirilemedi: ',
      'onboarding_skip': 'Atla', 'onboarding_next': 'İleri', 'onboarding_start': 'Şimdi Başla',
      'onboarding_confirm_lang': 'Dili Onayla',
      'onboarding_title_1': 'Itqan', 'onboarding_sub_1': "Kuran tilavetinizi mükemmelleştirin",
      'onboarding_title_2': 'Seviyenizi Belirleyin', 'onboarding_sub_2': 'Kişiselleştirilmiş bir deneyim için seviyenizi seçin',
      'onboarding_title_3': 'Yolculuğunuza Başlayın', 'onboarding_sub_3': 'Allah\'ın ayetlerini dinleyin, okuyun ve tefekkür edin'
    },
  };

  static String tr(BuildContext context, String key) {
    try {
      final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
      if (loc != null) {
        return loc.translate(key);
      }
    } catch (e) {
      // تجاهل الخطأ
    }
    return _localizedValues['ar']?[key] ?? key;
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'fr', 'es', 'ur', 'id', 'hi', 'bn', 'fa', 'uz', 'tr']
          .contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
