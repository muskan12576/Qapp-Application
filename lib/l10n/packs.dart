class AppLanguage {
  const AppLanguage(this.code, this.label, {this.rtl = false});

  final String code;
  final String label;
  final bool rtl;
}

const stringKeys = <String>[
  'start',
  'loginBig',
  'loginSmall',
  'phoneHint',
  'sendOtp',
  'otpTitle',
  'otpSub',
  'resend',
  'next',
  'profileTitle',
  'profileSmall',
  'nameHint',
  'bioHint',
  'done',
  'chats',
  'search',
  'activeMessages',
  'active',
  'online',
  'messageHint',
  'statusTitle',
  'newUpdates',
  'viewStatus',
  'myStatus',
  'statusHint',
  'friendsUpdates',
  'callsTitle',
  'callsSub',
  'callHistory',
  'groups',
  'newGroup',
  'groupTitle',
  'groupHint',
  'create',
  'settings',
  'language',
  'languageHint',
  'notifications',
  'notificationsHint',
  'privacy',
  'privacyHint',
  'about',
  'aboutHint',
  'calling',
  'connected',
  'callStatus',
  'mute',
  'speaker',
  'end',
  'flip',
  'camera',
  'voiceCall',
  'videoCall',
  'attach',
  'image',
  'document',
  'pdf',
  'now',
  'statusPlay',
  'all',
  'unread',
  'favourite',
  'media',
  'starred',
  'muteNotif',
  'disappearing',
  'off',
  'privacyAdv',
  'theme',
  'encrypted',
  'commonGroups',
  'addFav',
  'addList',
  'exportChat',
  'clearChat',
  'block',
  'report',
  'deleteChat',
  'chooseCountry',
  'you',
  'blocked',
  'unblock',
  'noMedia',
  'noChats',
  'cameraHint',
  'reported',
  'listAdded',
  'copied',
  'clearAsk',
  'deleteAsk',
  'blockAsk',
  'cancel',
  'yes',
  'newChat',
  'newContact',
  'frequent',
  'contactName',
  'save',
  'statusLabel',
  'adminOnly',
  'vanish24',
  'groupDetails',
  'chooseIcon',
  'members',
  'picked',
  'nextGo',
  'createGroup',
  'pro',
  'stAvailable',
  'stBusy',
  'stOnQapp',
  'stMeeting',
  'stWork',
  'stEmergency',
  'stSleep',
  'recentUpdates',
  'viewedUpdates',
  'tapStatus',
  'pinned',
  'unpin',
  'reply',
  'deleteAll',
  'deletedMsg',
  'unmute',
  'darkMode',
  'lightMode',
  'forward',
  'edit',
  'firstName',
  'lastName',
  'tapColour',
  'company',
  'email',
  'addNumber',
  'birthday',
  'saveCloud',
  'syncHint',
  'contactSaved',
  'addAnother',
  'video',
  'shareContact',
];

const appLanguages = <AppLanguage>[
  AppLanguage('hing', 'Hinglish'),
  AppLanguage('en', 'English'),
  AppLanguage('hi', 'हिन्दी'),
  AppLanguage('ur', 'اردو', rtl: true),
  AppLanguage('pa', 'ਪੰਜਾਬੀ'),
  AppLanguage('bn', 'বাংলা'),
  AppLanguage('ta', 'தமிழ்'),
  AppLanguage('te', 'తెలుగు'),
  AppLanguage('mr', 'मराठी'),
  AppLanguage('gu', 'ગુજરાતી'),
  AppLanguage('kn', 'ಕನ್ನಡ'),
  AppLanguage('ml', 'മലയാളം'),
  AppLanguage('or', 'ଓଡ଼ିଆ'),
  AppLanguage('ne', 'नेपाली'),
  AppLanguage('ar', 'العربية', rtl: true),
  AppLanguage('fa', 'فارسی', rtl: true),
  AppLanguage('es', 'Español'),
  AppLanguage('fr', 'Français'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('pt', 'Português'),
  AppLanguage('it', 'Italiano'),
  AppLanguage('ru', 'Русский'),
  AppLanguage('uk', 'Українська'),
  AppLanguage('zh', '中文'),
  AppLanguage('ja', '日本語'),
  AppLanguage('ko', '한국어'),
  AppLanguage('tr', 'Türkçe'),
  AppLanguage('id', 'Bahasa Indonesia'),
  AppLanguage('ms', 'Melayu'),
  AppLanguage('vi', 'Tiếng Việt'),
  AppLanguage('th', 'ไทย'),
  AppLanguage('sw', 'Kiswahili'),
  AppLanguage('fil', 'Filipino'),
];

const _rows = <String, String>{
  'en':
      'Get started|Enter your number|We will send a 6 digit OTP.|Mobile number|Send OTP|Verify OTP|Enter the code you received|Resend OTP|Continue|Create your profile|Or pick one|Your name|Write your status...|Done|Chats|Search|Active messages|Active|Online|Message|Status|New updates|View status|My status|Add your status|Friends updates|Calls|Calls and more|Call history|Groups|Create a group|New group|Group name|Create|Settings|Language|The whole app switches to this language|Notifications|Messages, calls and status|Privacy|Who can see your profile|About Qapp|Version 1.0.0|Calling…|Connected|{name} is online|Mute|Speaker|End|Flip|Camera|Voice call|Video call|Share|Photo|Document|PDF|Now|Status|All|Unread|Favourite|Media, links and docs|Starred messages|Mute notifications|Disappearing messages|Off|Advanced chat privacy|Chat theme|Messages are end-to-end encrypted|Groups in common|Add to favourites|Add to list|Export chat|Clear chat|Block|Report|Delete chat|Choose country|You|Blocked|Unblock|No media yet|No chats here|Camera is off|Report sent|Added to the list|Chat copied|Clear all messages?|Delete this chat?|Block this person?|Cancel|Yes|New chat|New contact|Frequently contacted|Name|Save|Your status|Only admins can send messages|Messages disappear after 24 hours|Group details|Choose a group icon|Members|selected|Next|Create group|PRO|Available|Busy|On Qapp|In a meeting|At work|Emergency only|Sleeping|Recent updates|Viewed updates|Tap to add a status update|Pinned|Unpin|Reply|Delete for everyone|This message was deleted|Unmute|Dark mode|Light mode|Forward|Edit|First name|Last name|Tap to change colour|Company|Email|Add another number|Birthday|Save to phone & cloud|Sync with your account|Contact saved|Add another|Video|Share contact',
  'hing':
      'Chalo shuru karein!|Apna Number Daalein|Enter your mobile number|Yahan mobile number likhein|OTP Bhejein|OTP Verify Karein|Jo code mila hai, yahan daalein|OTP fir se bhejein|Aage Badhein|Profile Banayein|Add your name and bio|Aapna Naam|Bio/Status|Done|Aapki Chats|Search karein...|Active Messages|Active|Online|Message...|Updates / Status|Nayee Updates|Status Dekhein|Mera Status|Mera Status daalein|Friends ke Updates|Call log / Features|Calls and More|Call history|Groups|Naya Group banayein|Naya Group|Group ka naam|Banayein|Settings|Language|Poori app isi language mein badal jayegi|Notifications|Message, call aur status|Privacy|Profile kaun dekh sakta hai|Qapp ke baare mein|Version 1.0.0|Call ho rahi hai…|Connected|{name} online hai|Mute|Speaker|End|Flip|Camera|Voice call|Video call|Share karein|Image|Document|PDF|Now|Status|Sab|Unread|Favourite|Media, links aur docs|Starred messages|Mute notifications|Disappearing messages|Off|Advanced chat privacy|Chat theme|Messages end-to-end encrypted hain|Common groups|Favourites mein daalein|List mein daalein|Chat export karein|Chat saaf karein|Block karein|Report karein|Chat delete karein|Desh chunein|Aap|Blocked hai|Unblock|Abhi media nahi|Yahan koi chat nahi|Camera band hai|Report chali gayi|List mein add ho gaya|Chat copy ho gayi|Saare messages mitaein?|Ye chat delete karein?|Is person ko block karein?|Cancel|Haan|Naya chat|Naya contact|Aksar baat|Naam|Save|Aapka status|Sirf admin message bhejein|Messages 24 ghante mein gayab|Group ki details|Group icon chunein|Members|chune|Aage|Group banayein|PRO|Available 🟢|Busy 🔴|Qapp pe hoon 💬|Meeting mein 📅|Kaam mein 💼|Sirf emergency 🚨|Sleeping 😴',
  'hi':
      'शुरू करें|अपना मोबाइल नंबर डालें|हम आपको एक बार का कोड भेजेंगे|मोबाइल नंबर|OTP भेजें|OTP जाँचें|मिला हुआ 6 अंकों का कोड डालें|OTP फिर भेजें|आगे बढ़ें|अपनी प्रोफ़ाइल बनाएँ|दोस्त आपको ऐसे देखेंगे|आपका नाम|बायो|हो गया|आपकी चैट|खोजें|चालू संदेश|चालू|ऑनलाइन|संदेश|अपडेट|नए अपडेट|स्टेटस देखें|मेरा स्टेटस|अपना स्टेटस लिखें|दोस्तों के अपडेट|कॉल|कॉल और भी बहुत कुछ|कॉल इतिहास|ग्रुप|नया ग्रुप बनाएँ|नया ग्रुप|ग्रुप का नाम|बनाएँ|सेटिंग्स|भाषा|पूरी ऐप इस भाषा में बदल जाएगी|नोटिफिकेशन|संदेश, कॉल और स्टेटस|प्राइवेसी|प्रोफ़ाइल कौन देख सकता है|Qapp के बारे में|Version 1.0.0|कॉल हो रही है…|जुड़ गया|{name} ऑनलाइन है|म्यूट|स्पीकर|काटें|पलटें|कैमरा|वॉइस कॉल|वीडियो कॉल|शेयर करें|फोटो|दस्तावेज़|PDF|अभी|स्टेटस|सभी|अनरीड|पसंदीदा|मीडिया, लिंक और डॉक|स्टार किए संदेश|नोटिफिकेशन म्यूट करें|गायब होने वाले संदेश|बंद|एडवांस चैट प्राइवेसी|चैट थीम|संदेश एंड-टू-एंड एन्क्रिप्टेड हैं|कॉमन ग्रुप|पसंदीदा में जोड़ें|लिस्ट में जोड़ें|चैट एक्सपोर्ट करें|चैट साफ़ करें|ब्लॉक करें|रिपोर्ट करें|चैट डिलीट करें|देश चुनें|आप|ब्लॉक है|अनब्लॉक|अभी कोई मीडिया नहीं|यहाँ कोई चैट नहीं|कैमरा बंद है|रिपोर्ट भेज दी गई|लिस्ट में जोड़ दिया|चैट कॉपी हो गई|सारे संदेश मिटाएँ?|यह चैट डिलीट करें?|इस व्यक्ति को ब्लॉक करें?|रद्द करें|हाँ',
  'ur':
      'شروع کریں|اپنا موبائل نمبر ڈالیں|ہم آپ کو ایک بار کا کوڈ بھیجیں گے|موبائل نمبر|OTP بھیجیں|OTP چیک کریں|ملا ہوا 6 ہندسوں کا کوڈ ڈالیں|OTP دوبارہ بھیجیں|آگے بڑھیں|اپنی پروفائل بنائیں|دوست آپ کو ایسے دیکھیں گے|آپ کا نام|بایو|ہو گیا|آپ کی چیٹس|تلاش|فعال پیغامات|فعال|آن لائن|پیغام|اپڈیٹس|نئی اپڈیٹس|اسٹیٹس دیکھیں|میری اسٹیٹس|اپنی اسٹیٹس لکھیں|دوستوں کی اپڈیٹس|کالز|کالز اور مزید|کال ہسٹری|گروپس|نیا گروپ بنائیں|نیا گروپ|گروپ کا نام|بنائیں|سیٹنگز|زبان|پوری ایپ اس زبان میں بدل جائے گی|نوٹیفیکیشن|پیغام، کال اور اسٹیٹس|پرائیویسی|پروفائل کون دیکھ سکتا ہے|Qapp کے بارے میں|Version 1.0.0|کال ہو رہی ہے…|جڑ گیا|{name} آن لائن ہے|میوٹ|اسپیکر|کاٹیں|پلٹیں|کیمرہ|وائس کال|ویڈیو کال|شیئر کریں|تصویر|دستاویز|PDF|ابھی|اسٹیٹس|سب|ان ریڈ|پسندیدہ|میڈیا، لنک اور ڈاک|ستارہ والے پیغام|نوٹیفیکیشن میوٹ کریں|غائب ہونے والے پیغام|بند|ایڈوانس چیٹ پرائیویسی|چیٹ تھیم|پیغام اینڈ ٹو اینڈ انکرپٹڈ ہیں|مشترک گروپ|پسندیدہ میں شامل کریں|لسٹ میں شامل کریں|چیٹ ایکسپورٹ کریں|چیٹ صاف کریں|بلاک کریں|رپورٹ کریں|چیٹ ڈیلیٹ کریں|ملک چنیں|آپ|بلاک ہے|ان بلاک|ابھی میڈیا نہیں|یہاں کوئی چیٹ نہیں|کیمرہ بند ہے|رپورٹ بھیج دی گئی|لسٹ میں شامل ہو گیا|چیٹ کاپی ہو گئی|سارے پیغام مٹا دیں؟|یہ چیٹ ڈیلیٹ کریں؟|اس شخص کو بلاک کریں؟|منسوخ|ہاں',
  'pa':
      'ਸ਼ੁਰੂ ਕਰੋ|ਆਪਣਾ ਮੋਬਾਈਲ ਨੰਬਰ ਪਾਓ|ਅਸੀਂ ਤੁਹਾਨੂੰ ਇੱਕ ਵਾਰ ਦਾ ਕੋਡ ਭੇਜਾਂਗੇ|ਮੋਬਾਈਲ ਨੰਬਰ|OTP ਭੇਜੋ|OTP ਜਾਂਚੋ|ਮਿਲਿਆ 6 ਅੰਕਾਂ ਦਾ ਕੋਡ ਪਾਓ|OTP ਫਿਰ ਭੇਜੋ|ਅੱਗੇ ਵਧੋ|ਆਪਣੀ ਪ੍ਰੋਫ਼ਾਈਲ ਬਣਾਓ|ਦੋਸਤ ਤੁਹਾਨੂੰ ਇੰਜ ਦੇਖਣਗੇ|ਤੁਹਾਡਾ ਨਾਮ|ਬਾਇਓ|ਹੋ ਗਿਆ|ਤੁਹਾਡੀਆਂ ਚੈਟਾਂ|ਖੋਜੋ|ਚਾਲੂ ਸੁਨੇਹੇ|ਚਾਲੂ|ਔਨਲਾਈਨ|ਸੁਨੇਹਾ|ਅਪਡੇਟ|ਨਵੇਂ ਅਪਡੇਟ|ਸਟੇਟਸ ਵੇਖੋ|ਮੇਰਾ ਸਟੇਟਸ|ਆਪਣਾ ਸਟੇਟਸ ਲਿਖੋ|ਦੋਸਤਾਂ ਦੇ ਅਪਡੇਟ|ਕਾਲਾਂ|ਕਾਲਾਂ ਅਤੇ ਹੋਰ|ਕਾਲ ਇਤਿਹਾਸ|ਗਰੁੱਪ|ਨਵਾਂ ਗਰੁੱਪ ਬਣਾਓ|ਨਵਾਂ ਗਰੁੱਪ|ਗਰੁੱਪ ਦਾ ਨਾਮ|ਬਣਾਓ|ਸੈਟਿੰਗਾਂ|ਭਾਸ਼ਾ|ਸਾਰੀ ਐਪ ਇਸ ਭਾਸ਼ਾ ਵਿੱਚ ਬਦਲ ਜਾਵੇਗੀ|ਨੋਟੀਫਿਕੇਸ਼ਨ|ਸੁਨੇਹੇ, ਕਾਲਾਂ ਅਤੇ ਸਟੇਟਸ|ਪ੍ਰਾਈਵੇਸੀ|ਪ੍ਰੋਫ਼ਾਈਲ ਕੌਣ ਵੇਖ ਸਕਦਾ ਹੈ|Qapp ਬਾਰੇ|Version 1.0.0|ਕਾਲ ਹੋ ਰਹੀ ਹੈ…|ਜੁੜ ਗਿਆ|{name} ਔਨਲਾਈਨ ਹੈ|ਮਿਊਟ|ਸਪੀਕਰ|ਕਾਟੋ|ਪਲਟੋ|ਕੈਮਰਾ|ਵੌਇਸ ਕਾਲ|ਵੀਡੀਓ ਕਾਲ|ਸਾਂਝਾ ਕਰੋ|ਫੋਟੋ|ਦਸਤਾਵੇਜ਼|PDF|ਹੁਣੇ|ਸਟੇਟਸ|ਸਭ|ਅਨਰੀਡ|ਪਸੰਦੀਦਾ|ਮੀਡੀਆ, ਲਿੰਕ ਅਤੇ ਡੌਕ|ਸਟਾਰ ਕੀਤੇ ਸੁਨੇਹੇ|ਨੋਟੀਫਿਕੇਸ਼ਨ ਮਿਊਟ ਕਰੋ|ਗਾਇਬ ਹੋਣ ਵਾਲੇ ਸੁਨੇਹੇ|ਬੰਦ|ਐਡਵਾਂਸ ਚੈਟ ਪ੍ਰਾਈਵੇਸੀ|ਚੈਟ ਥੀਮ|ਸੁਨੇਹੇ ਐਂਡ-ਟੂ-ਐਂਡ ਇਨਕ੍ਰਿਪਟਡ ਹਨ|ਸਾਂਝੇ ਗਰੁੱਪ|ਪਸੰਦੀਦਾ ਵਿੱਚ ਪਾਓ|ਲਿਸਟ ਵਿੱਚ ਪਾਓ|ਚੈਟ ਐਕਸਪੋਰਟ ਕਰੋ|ਚੈਟ ਸਾਫ਼ ਕਰੋ|ਬਲਾਕ ਕਰੋ|ਰਿਪੋਰਟ ਕਰੋ|ਚੈਟ ਡਿਲੀਟ ਕਰੋ|ਦੇਸ਼ ਚੁਣੋ|ਤੁਸੀਂ|ਬਲਾਕ ਹੈ|ਅਨਬਲਾਕ|ਅਜੇ ਮੀਡੀਆ ਨਹੀਂ|ਇੱਥੇ ਕੋਈ ਚੈਟ ਨਹੀਂ|ਕੈਮਰਾ ਬੰਦ ਹੈ|ਰਿਪੋਰਟ ਚਲੀ ਗਈ|ਲਿਸਟ ਵਿੱਚ ਪਾ ਦਿੱਤਾ|ਚੈਟ ਕਾਪੀ ਹੋ ਗਈ|ਸਾਰੇ ਸੁਨੇਹੇ ਮਿਟਾਉਣੇ?|ਇਹ ਚੈਟ ਡਿਲੀਟ ਕਰਨੀ?|ਇਸ ਵਿਅਕਤੀ ਨੂੰ ਬਲਾਕ ਕਰਨਾ?|ਰੱਦ ਕਰੋ|ਹਾਂ',
  'bn':
      'শুরু করুন|আপনার মোবাইল নম্বর দিন|আমরা একটি একবারের কোড পাঠাব|মোবাইল নম্বর|OTP পাঠান|OTP যাচাই|পাওয়া ৬ সংখ্যার কোড দিন|OTP আবার পাঠান|এগিয়ে যান|আপনার প্রোফাইল বানান|বন্ধুরা আপনাকে এভাবে দেখবে|আপনার নাম|বায়ো|হয়ে গেছে|আপনার চ্যাট|খুঁজুন|চালু বার্তা|চালু|অনলাইন|বার্তা|আপডেট|নতুন আপডেট|স্ট্যাটাস দেখুন|আমার স্ট্যাটাস|নিজের স্ট্যাটাস লিখুন|বন্ধুদের আপডেট|কল|কল এবং আরও|কল ইতিহাস|গ্রুপ|নতুন গ্রুপ বানান|নতুন গ্রুপ|গ্রুপের নাম|বানান|সেটিংস|ভাষা|পুরো অ্যাপ এই ভাষায় বদলে যাবে|নোটিফিকেশন|বার্তা, কল এবং স্ট্যাটাস|প্রাইভেসি|প্রোফাইল কে দেখতে পারে|Qapp সম্পর্কে|Version 1.0.0|কল হচ্ছে…|যুক্ত|{name} অনলাইনে আছে|মিউট|স্পিকার|কাটুন|উল্টান|ক্যামেরা|ভয়েস কল|ভিডিও কল|শেয়ার|ছবি|নথি|PDF|এখন|স্ট্যাটাস|সব|অপঠিত|পছন্দের|মিডিয়া, লিংক ও ডক|স্টার করা বার্তা|নোটিফিকেশন মিউট|অদৃশ্য বার্তা|বন্ধ|উন্নত চ্যাট প্রাইভেসি|চ্যাট থিম|বার্তা এন্ড-টু-এন্ড এনক্রিপ্টেড|কমন গ্রুপ|পছন্দে যোগ করুন|তালিকায় যোগ করুন|চ্যাট এক্সপোর্ট|চ্যাট মুছুন|ব্লক|রিপোর্ট|চ্যাট ডিলিট|দেশ বাছুন|আপনি|ব্লক করা|আনব্লক|এখনো মিডিয়া নেই|এখানে চ্যাট নেই|ক্যামেরা বন্ধ|রিপোর্ট পাঠানো হয়েছে|তালিকায় যোগ হয়েছে|চ্যাট কপি হয়েছে|সব বার্তা মুছবেন?|এই চ্যাট ডিলিট করবেন?|এই মানুষকে ব্লক করবেন?|বাতিল|হ্যাঁ',
  'ta':
      'தொடங்கு|உங்கள் மொபைல் எண்ணை உள்ளிடுங்கள்|ஒரு முறை குறியீட்டை அனுப்புவோம்|மொபைல் எண்|OTP அனுப்பு|OTP சரிபார்|வந்த 6 இலக்க குறியீட்டை உள்ளிடுங்கள்|OTP மீண்டும் அனுப்பு|தொடரவும்|உங்கள் சுயவிவரத்தை உருவாக்குங்கள்|நண்பர்கள் உங்களை இப்படி பார்ப்பார்கள்|உங்கள் பெயர்|பயோ|முடிந்தது|உங்கள் அரட்டைகள்|தேடு|செயலில் உள்ள செய்திகள்|செயலில்|ஆன்லைன்|செய்தி|புதுப்பிப்புகள்|புதிய புதுப்பிப்புகள்|ஸ்டேட்டஸ் பார்|என் ஸ்டேட்டஸ்|உங்கள் ஸ்டேட்டஸை எழுதுங்கள்|நண்பர்களின் புதுப்பிப்புகள்|அழைப்புகள்|அழைப்புகளும் மேலும்|அழைப்பு வரலாறு|குழுக்கள்|புதிய குழு உருவாக்கு|புதிய குழு|குழுவின் பெயர்|உருவாக்கு|அமைப்புகள்|மொழி|முழு செயலியும் இந்த மொழிக்கு மாறும்|அறிவிப்புகள்|செய்தி, அழைப்பு, ஸ்டேட்டஸ்|தனியுரிமை|சுயவிவரத்தை யார் பார்க்கலாம்|Qapp பற்றி|Version 1.0.0|அழைக்கிறது…|இணைந்தது|{name} ஆன்லைனில் உள்ளார்|முடக்கு|ஸ்பீக்கர்|துண்டி|திருப்பு|கேமரா|குரல் அழைப்பு|வீடியோ அழைப்பு|பகிர்|படம்|ஆவணம்|PDF|இப்போது|ஸ்டேட்டஸ்|அனைத்தும்|படிக்காதவை|பிடித்தவை|மீடியா, இணைப்பு, ஆவணம்|நட்சத்திர செய்திகள்|அறிவிப்பை முடக்கு|மறையும் செய்திகள்|ஆஃப்|மேம்பட்ட அரட்டை தனியுரிமை|அரட்டை தீம்|செய்திகள் எண்ட்-டு-எண்ட் மறைகுறியாக்கப்பட்டவை|பொது குழுக்கள்|பிடித்தவையில் சேர்|பட்டியலில் சேர்|அரட்டையை ஏற்றுமதி செய்|அரட்டையை அழி|தடு|புகார்|அரட்டையை நீக்கு|நாட்டைத் தேர்ந்தெடு|நீங்கள்|தடுக்கப்பட்டது|தடுப்பை நீக்கு|இன்னும் மீடியா இல்லை|இங்கே அரட்டை இல்லை|கேமரா ஆஃப்|புகார் அனுப்பப்பட்டது|பட்டியலில் சேர்க்கப்பட்டது|அரட்டை நகலானது|எல்லா செய்திகளையும் அழிக்கவா?|இந்த அரட்டையை நீக்கவா?|இவரைத் தடுக்கவா?|ரத்து|ஆம்',
  'te':
      'ప్రారంభించండి|మీ మొబైల్ నంబర్ ఇవ్వండి|మేము ఒకసారి కోడ్ పంపుతాము|మొబైల్ నంబర్|OTP పంపండి|OTP తనిఖీ|వచ్చిన 6 అంకెల కోడ్ ఇవ్వండి|OTP మళ్లీ పంపండి|కొనసాగండి|మీ ప్రొఫైల్ తయారు చేయండి|స్నేహితులు మిమ్మల్ని ఇలా చూస్తారు|మీ పేరు|బయో|అయింది|మీ చాట్లు|వెతకండి|యాక్టివ్ సందేశాలు|యాక్టివ్|ఆన్‌లైన్|సందేశం|అప్‌డేట్లు|కొత్త అప్‌డేట్లు|స్టేటస్ చూడండి|నా స్టేటస్|మీ స్టేటస్ రాయండి|స్నేహితుల అప్‌డేట్లు|కాల్స్|కాల్స్ మరియు మరిన్ని|కాల్ చరిత్ర|గ్రూపులు|కొత్త గ్రూప్ చేయండి|కొత్త గ్రూప్|గ్రూప్ పేరు|చేయండి|సెట్టింగ్స్|భాష|మొత్తం యాప్ ఈ భాషలో మారుతుంది|నోటిఫికేషన్లు|సందేశాలు, కాల్స్, స్టేటస్|గోప్యత|ప్రొఫైల్ ఎవరు చూడవచ్చు|Qapp గురించి|Version 1.0.0|కాల్ అవుతోంది…|కనెక్ట్ అయింది|{name} ఆన్‌లైన్‌లో ఉన్నారు|మ్యూట్|స్పీకర్|ముగించు|తిప్పు|కెమెరా|వాయిస్ కాల్|వీడియో కాల్|షేర్|ఫోటో|పత్రం|PDF|ఇప్పుడు|స్టేటస్|అన్నీ|చదవనివి|ఇష్టమైనవి|మీడియా, లింకులు, పత్రాలు|స్టార్ సందేశాలు|నోటిఫికేషన్ మ్యూట్|అదృశ్య సందేశాలు|ఆఫ్|అధునాతన చాట్ గోప్యత|చాట్ థీమ్|సందేశాలు ఎండ్-టు-ఎండ్ ఎన్‌క్రిప్ట్|ఉమ్మడి గ్రూపులు|ఇష్టాల్లో చేర్చు|జాబితాలో చేర్చు|చాట్ ఎగుమతి|చాట్ తుడుచు|బ్లాక్|రిపోర్ట్|చాట్ తొలగించు|దేశం ఎంచుకోండి|మీరు|బ్లాక్ అయింది|అన్‌బ్లాక్|ఇంకా మీడియా లేదు|ఇక్కడ చాట్ లేదు|కెమెరా ఆఫ్|రిపోర్ట్ పంపాం|జాబితాలో చేర్చాం|చాట్ కాపీ అయింది|అన్ని సందేశాలు తొలగించాలా?|ఈ చాట్ తొలగించాలా?|ఈ వ్యక్తిని బ్లాక్ చేయాలా?|రద్దు|అవును',
  'mr':
      'सुरू करा|तुमचा मोबाइल नंबर टाका|आम्ही एकदाचा कोड पाठवू|मोबाइल नंबर|OTP पाठवा|OTP तपासा|मिळालेला 6 अंकी कोड टाका|OTP पुन्हा पाठवा|पुढे जा|तुमची प्रोफाइल बनवा|मित्र तुम्हाला असे पाहतील|तुमचे नाव|बायो|झाले|तुमच्या चॅट्स|शोधा|सक्रिय संदेश|सक्रिय|ऑनलाइन|संदेश|अपडेट्स|नवीन अपडेट्स|स्टेटस पहा|माझा स्टेटस|तुमचा स्टेटस लिहा|मित्रांचे अपडेट्स|कॉल्स|कॉल्स आणि आणखी|कॉल इतिहास|ग्रुप|नवा ग्रुप बनवा|नवा ग्रुप|ग्रुपचे नाव|बनवा|सेटिंग्ज|भाषा|संपूर्ण अॅप या भाषेत बदलेल|नोटिफिकेशन|संदेश, कॉल आणि स्टेटस|गोपनीयता|प्रोफाइल कोण पाहू शकतो|Qapp बद्दल|Version 1.0.0|कॉल होत आहे…|जोडले|{name} ऑनलाइन आहे|म्यूट|स्पीकर|कट करा|फिरवा|कॅमेरा|व्हॉइस कॉल|व्हिडिओ कॉल|शेअर करा|फोटो|दस्तऐवज|PDF|आत्ता|स्टेटस|सर्व|न वाचलेले|आवडते|मीडिया, लिंक आणि डॉक|स्टार केलेले संदेश|नोटिफिकेशन म्यूट|नाहीसे होणारे संदेश|बंद|प्रगत चॅट गोपनीयता|चॅट थीम|संदेश एंड-टू-एंड एन्क्रिप्टेड आहेत|समान ग्रुप|आवडत्यात जोडा|यादीत जोडा|चॅट एक्सपोर्ट|चॅट साफ करा|ब्लॉक|रिपोर्ट|चॅट डिलीट|देश निवडा|तुम्ही|ब्लॉक आहे|अनब्लॉक|अजून मीडिया नाही|इथे चॅट नाही|कॅमेरा बंद आहे|रिपोर्ट पाठवली|यादीत जोडले|चॅट कॉपी झाली|सारे संदेश पुसून टाकायचे?|ही चॅट डिलीट करायची?|या व्यक्तीला ब्लॉक करायचे?|रद्द|हो',
  'gu':
      'શરૂ કરો|તમારો મોબાઇલ નંબર નાખો|અમે એક વખતનો કોડ મોકલીશું|મોબાઇલ નંબર|OTP મોકલો|OTP ચકાસો|મળેલો 6 અંકનો કોડ નાખો|OTP ફરી મોકલો|આગળ વધો|તમારી પ્રોફાઇલ બનાવો|મિત્રો તમને આવા જોશે|તમારું નામ|બાયો|થઈ ગયું|તમારી ચેટ|શોધો|સક્રિય સંદેશા|સક્રિય|ઓનલાઇન|સંદેશ|અપડેટ|નવા અપડેટ|સ્ટેટસ જુઓ|મારું સ્ટેટસ|તમારું સ્ટેટસ લખો|મિત્રોના અપડેટ|કોલ|કોલ અને વધુ|કોલ ઇતિહાસ|ગ્રુપ|નવું ગ્રુપ બનાવો|નવું ગ્રુપ|ગ્રુપનું નામ|બનાવો|સેટિંગ્સ|ભાષા|આખી એપ આ ભાષામાં બદલાશે|નોટિફિકેશન|સંદેશ, કોલ અને સ્ટેટસ|ગોપનીયતા|પ્રોફાઇલ કોણ જોઈ શકે|Qapp વિશે|Version 1.0.0|કોલ થઈ રહ્યો છે…|જોડાયું|{name} ઓનલાઇન છે|મ્યૂટ|સ્પીકર|કાપો|ઉલટાવો|કેમેરા|વોઇસ કોલ|વિડિયો કોલ|શેર કરો|ફોટો|દસ્તાવેજ|PDF|હમણાં|સ્ટેટસ|બધું|ન વાંચેલું|મનપસંદ|મીડિયા, લિંક અને ડોક|સ્ટાર કરેલા સંદેશા|નોટિફિકેશન મ્યૂટ|અદૃશ્ય સંદેશા|બંધ|એડવાન્સ ચેટ ગોપનીયતા|ચેટ થીમ|સંદેશા એન્ડ-ટુ-એન્ડ એન્ક્રિપ્ટેડ છે|સામાન્ય ગ્રુપ|મનપસંદમાં ઉમેરો|યાદીમાં ઉમેરો|ચેટ એક્સપોર્ટ|ચેટ સાફ કરો|બ્લોક|રિપોર્ટ|ચેટ ડિલીટ|દેશ પસંદ કરો|તમે|બ્લોક છે|અનબ્લોક|હજુ મીડિયા નથી|અહીં ચેટ નથી|કેમેરા બંધ છે|રિપોર્ટ મોકલાઈ|યાદીમાં ઉમેરાયું|ચેટ કોપી થઈ|બધા સંદેશા ભૂંસવા?|આ ચેટ ડિલીટ કરવી?|આ વ્યક્તિને બ્લોક કરવી?|રદ|હા',
  'kn':
      'ಪ್ರಾರಂಭಿಸಿ|ನಿಮ್ಮ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಹಾಕಿ|ನಾವು ಒಂದು ಬಾರಿ ಕೋಡ್ ಕಳುಹಿಸುತ್ತೇವೆ|ಮೊಬೈಲ್ ಸಂಖ್ಯೆ|OTP ಕಳುಹಿಸಿ|OTP ಪರಿಶೀಲಿಸಿ|ಬಂದ 6 ಅಂಕಿಯ ಕೋಡ್ ಹಾಕಿ|OTP ಮತ್ತೆ ಕಳುಹಿಸಿ|ಮುಂದುವರಿಸಿ|ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ಮಾಡಿ|ಸ್ನೇಹಿತರು ನಿಮ್ಮನ್ನು ಹೀಗೆ ನೋಡುತ್ತಾರೆ|ನಿಮ್ಮ ಹೆಸರು|ಬಯೋ|ಆಯಿತು|ನಿಮ್ಮ ಚಾಟ್‌ಗಳು|ಹುಡುಕಿ|ಸಕ್ರಿಯ ಸಂದೇಶಗಳು|ಸಕ್ರಿಯ|ಆನ್‌ಲೈನ್|ಸಂದೇಶ|ಅಪ್‌ಡೇಟ್‌ಗಳು|ಹೊಸ ಅಪ್‌ಡೇಟ್‌ಗಳು|ಸ್ಟೇಟಸ್ ನೋಡಿ|ನನ್ನ ಸ್ಟೇಟಸ್|ನಿಮ್ಮ ಸ್ಟೇಟಸ್ ಬರೆಯಿರಿ|ಸ್ನೇಹಿತರ ಅಪ್‌ಡೇಟ್‌ಗಳು|ಕರೆಗಳು|ಕರೆಗಳು ಮತ್ತು ಇನ್ನಷ್ಟು|ಕರೆ ಇತಿಹಾಸ|ಗುಂಪುಗಳು|ಹೊಸ ಗುಂಪು ಮಾಡಿ|ಹೊಸ ಗುಂಪು|ಗುಂಪಿನ ಹೆಸರು|ಮಾಡಿ|ಸೆಟ್ಟಿಂಗ್‌ಗಳು|ಭಾಷೆ|ಇಡೀ ಆ್ಯಪ್ ಈ ಭಾಷೆಗೆ ಬದಲಾಗುತ್ತದೆ|ಅಧಿಸೂಚನೆಗಳು|ಸಂದೇಶ, ಕರೆ ಮತ್ತು ಸ್ಟೇಟಸ್|ಗೌಪ್ಯತೆ|ಪ್ರೊಫೈಲ್ ಯಾರು ನೋಡಬಹುದು|Qapp ಬಗ್ಗೆ|Version 1.0.0|ಕರೆ ಹೋಗುತ್ತಿದೆ…|ಸೇರಿತು|{name} ಆನ್‌ಲೈನ್‌ನಲ್ಲಿದ್ದಾರೆ|ಮ್ಯೂಟ್|ಸ್ಪೀಕರ್|ಕತ್ತರಿಸಿ|ತಿರುಗಿಸಿ|ಕ್ಯಾಮೆರಾ|ವಾಯ್ಸ್ ಕರೆ|ವೀಡಿಯೊ ಕರೆ|ಹಂಚಿ|ಫೋಟೋ|ದಾಖಲೆ|PDF|ಈಗ|ಸ್ಟೇಟಸ್|ಎಲ್ಲಾ|ಓದದಿರುವುದು|ಮೆಚ್ಚಿನವು|ಮೀಡಿಯಾ, ಲಿಂಕ್ ಮತ್ತು ಡಾಕ್|ಸ್ಟಾರ್ ಸಂದೇಶಗಳು|ಅಧಿಸೂಚನೆ ಮ್ಯೂಟ್|ಮಾಯವಾಗುವ ಸಂದೇಶಗಳು|ಆಫ್|ಸುಧಾರಿತ ಚಾಟ್ ಗೌಪ್ಯತೆ|ಚಾಟ್ ಥೀಮ್|ಸಂದೇಶಗಳು ಎಂಡ್-ಟು-ಎಂಡ್ ಎನ್‌ಕ್ರಿಪ್ಟ್|ಒಟ್ಟಿಗಿನ ಗುಂಪುಗಳು|ಮೆಚ್ಚಿನವುಗಳಿಗೆ ಸೇರಿಸಿ|ಪಟ್ಟಿಗೆ ಸೇರಿಸಿ|ಚಾಟ್ ರಫ್ತು|ಚಾಟ್ ಅಳಿಸಿ|ಬ್ಲಾಕ್|ವರದಿ|ಚಾಟ್ ಅಳಿಸಿ|ದೇಶ ಆಯ್ಕೆಮಾಡಿ|ನೀವು|ಬ್ಲಾಕ್ ಆಗಿದೆ|ಅನ್‌ಬ್ಲಾಕ್|ಇನ್ನೂ ಮೀಡಿಯಾ ಇಲ್ಲ|ಇಲ್ಲಿ ಚಾಟ್ ಇಲ್ಲ|ಕ್ಯಾಮೆರಾ ಆಫ್|ವರದಿ ಕಳುಹಿಸಲಾಗಿದೆ|ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ|ಚಾಟ್ ನಕಲಾಗಿದೆ|ಎಲ್ಲಾ ಸಂದೇಶಗಳನ್ನು ಅಳಿಸಬೇಕೆ?|ಈ ಚಾಟ್ ಅಳಿಸಬೇಕೆ?|ಈ ವ್ಯಕ್ತಿಯನ್ನು ಬ್ಲಾಕ್ ಮಾಡಬೇಕೆ?|ರದ್ದು|ಹೌದು',
  'ml':
      'തുടങ്ങാം|നിങ്ങളുടെ മൊബൈൽ നമ്പർ നൽകുക|ഞങ്ങൾ ഒരു തവണത്തെ കോഡ് അയയ്ക്കും|മൊബൈൽ നമ്പർ|OTP അയയ്ക്കുക|OTP പരിശോധിക്കുക|കിട്ടിയ 6 അക്ക കോഡ് നൽകുക|OTP വീണ്ടും അയയ്ക്കുക|തുടരുക|നിങ്ങളുടെ പ്രൊഫൈൽ ഉണ്ടാക്കുക|സുഹൃത്തുക്കൾ നിങ്ങളെ ഇങ്ങനെ കാണും|നിങ്ങളുടെ പേര്|ബയോ|കഴിഞ്ഞു|നിങ്ങളുടെ ചാറ്റുകൾ|തിരയുക|സജീവ സന്ദേശങ്ങൾ|സജീവം|ഓൺലൈൻ|സന്ദേശം|അപ്ഡേറ്റുകൾ|പുതിയ അപ്ഡേറ്റുകൾ|സ്റ്റാറ്റസ് കാണുക|എന്റെ സ്റ്റാറ്റസ്|നിങ്ങളുടെ സ്റ്റാറ്റസ് എഴുതുക|സുഹൃത്തുക്കളുടെ അപ്ഡേറ്റുകൾ|കോളുകൾ|കോളുകളും മറ്റും|കോൾ ചരിത്രം|ഗ്രൂപ്പുകൾ|പുതിയ ഗ്രൂപ്പ് ഉണ്ടാക്കുക|പുതിയ ഗ്രൂപ്പ്|ഗ്രൂപ്പിന്റെ പേര്|ഉണ്ടാക്കുക|ക്രമീകരണങ്ങൾ|ഭാഷ|മുഴുവൻ ആപ്പും ഈ ഭാഷയിലാകും|അറിയിപ്പുകൾ|സന്ദേശം, കോൾ, സ്റ്റാറ്റസ്|സ്വകാര്യത|പ്രൊഫൈൽ ആർക്ക് കാണാം|Qappയെക്കുറിച്ച്|Version 1.0.0|വിളിക്കുന്നു…|ബന്ധിച്ചു|{name} ഓൺലൈനാണ്|മ്യൂട്ട്|സ്പീക്കർ|കട്ട്|തിരിക്കുക|ക്യാമറ|വോയ്സ് കോൾ|വീഡിയോ കോൾ|പങ്കിടുക|ഫോട്ടോ|രേഖ|PDF|ഇപ്പോൾ|സ്റ്റാറ്റസ്|എല്ലാം|വായിക്കാത്തത്|പ്രിയപ്പെട്ടത്|മീഡിയ, ലിങ്ക്, ഡോക്|നക്ഷത്ര സന്ദേശങ്ങൾ|അറിയിപ്പ് മ്യൂട്ട്|മറയുന്ന സന്ദേശങ്ങൾ|ഓഫ്|വിപുല ചാറ്റ് സ്വകാര്യത|ചാറ്റ് തീം|സന്ദേശങ്ങൾ എൻഡ്-ടു-എൻഡ് എൻക്രിപ്റ്റഡ്|പൊതു ഗ്രൂപ്പുകൾ|പ്രിയപ്പെട്ടതിൽ ചേർക്കുക|ലിസ്റ്റിൽ ചേർക്കുക|ചാറ്റ് എക്സ്പോർട്ട്|ചാറ്റ് മായ്ക്കുക|ബ്ലോക്ക്|റിപ്പോർട്ട്|ചാറ്റ് ഡിലീറ്റ്|രാജ്യം തിരഞ്ഞെടുക്കുക|നിങ്ങൾ|ബ്ലോക്ക് ചെയ്തു|അൺബ്ലോക്ക്|ഇതുവരെ മീഡിയ ഇല്ല|ഇവിടെ ചാറ്റ് ഇല്ല|ക്യാമറ ഓഫ്|റിപ്പോർട്ട് അയച്ചു|ലിസ്റ്റിൽ ചേർത്തു|ചാറ്റ് പകർത്തി|എല്ലാ സന്ദേശങ്ങളും മായ്ക്കണോ?|ഈ ചാറ്റ് ഡിലീറ്റ് ചെയ്യണോ?|ഈ ആളെ ബ്ലോക്ക് ചെയ്യണോ?|റദ്ദാക്കുക|അതെ',
  'or':
      'ଆରମ୍ଭ କରନ୍ତୁ|ଆପଣଙ୍କ ମୋବାଇଲ୍ ନମ୍ବର ଦିଅନ୍ତୁ|ଆମେ ଏକ ଥର କୋଡ୍ ପଠାଇବୁ|ମୋବାଇଲ୍ ନମ୍ବର|OTP ପଠାନ୍ତୁ|OTP ଯାଞ୍ଚ କରନ୍ତୁ|ମିଳିଥିବା 6 ଅଙ୍କର କୋଡ୍ ଦିଅନ୍ତୁ|OTP ପୁଣି ପଠାନ୍ତୁ|ଆଗକୁ ବଢ଼ନ୍ତୁ|ଆପଣଙ୍କ ପ୍ରୋଫାଇଲ୍ ତିଆରି କରନ୍ତୁ|ବନ୍ଧୁମାନେ ଆପଣଙ୍କୁ ଏମିତି ଦେଖିବେ|ଆପଣଙ୍କ ନାମ|ବାୟୋ|ହୋଇଗଲା|ଆପଣଙ୍କ ଚାଟ୍|ଖୋଜନ୍ତୁ|ସକ୍ରିୟ ସନ୍ଦେଶ|ସକ୍ରିୟ|ଅନଲାଇନ୍|ସନ୍ଦେଶ|ଅପଡେଟ୍|ନୂଆ ଅପଡେଟ୍|ଷ୍ଟାଟସ୍ ଦେଖନ୍ତୁ|ମୋ ଷ୍ଟାଟସ୍|ଆପଣଙ୍କ ଷ୍ଟାଟସ୍ ଲେଖନ୍ତୁ|ବନ୍ଧୁଙ୍କ ଅପଡେଟ୍|କଲ୍|କଲ୍ ଏବଂ ଅଧିକ|କଲ୍ ଇତିହାସ|ଗ୍ରୁପ୍|ନୂଆ ଗ୍ରୁପ୍ ତିଆରି କରନ୍ତୁ|ନୂଆ ଗ୍ରୁପ୍|ଗ୍ରୁପ୍ ନାମ|ତିଆରି କରନ୍ତୁ|ସେଟିଂସ୍|ଭାଷା|ସମସ୍ତ ଆପ୍ ଏହି ଭାଷାକୁ ବଦଳିବ|ନୋଟିଫିକେସନ୍|ସନ୍ଦେଶ, କଲ୍ ଏବଂ ଷ୍ଟାଟସ୍|ଗୋପନୀୟତା|ପ୍ରୋଫାଇଲ୍ କିଏ ଦେଖିପାରିବେ|Qapp ବିଷୟରେ|Version 1.0.0|କଲ୍ ହେଉଛି…|ଯୋଡ଼ି ହେଲା|{name} ଅନଲାଇନ୍ ଅଛନ୍ତି|ମ୍ୟୁଟ୍|ସ୍ପିକର୍|କାଟନ୍ତୁ|ଓଲଟାନ୍ତୁ|କ୍ୟାମେରା|ଭଏସ୍ କଲ୍|ଭିଡିଓ କଲ୍|ସେୟାର୍|ଫଟୋ|ଡକ୍ୟୁମେଣ୍ଟ|PDF|ବର୍ତ୍ତମାନ|ଷ୍ଟାଟସ୍|ସବୁ|ନ ପଢ଼ା|ପସନ୍ଦ|ମିଡିଆ, ଲିଙ୍କ ଏବଂ ଡକ୍|ଷ୍ଟାର୍ ସନ୍ଦେଶ|ନୋଟିଫିକେସନ୍ ମ୍ୟୁଟ୍|ଉଭେଇଯାଉଥିବା ସନ୍ଦେଶ|ବନ୍ଦ|ଉନ୍ନତ ଚାଟ୍ ଗୋପନୀୟତା|ଚାଟ୍ ଥିମ୍|ସନ୍ଦେଶ ଏଣ୍ଡ-ଟୁ-ଏଣ୍ଡ ଏନକ୍ରିପ୍ଟେଡ୍|ସାଧାରଣ ଗ୍ରୁପ୍|ପସନ୍ଦରେ ଯୋଡ଼ନ୍ତୁ|ତାଲିକାରେ ଯୋଡ଼ନ୍ତୁ|ଚାଟ୍ ଏକ୍ସପୋର୍ଟ|ଚାଟ୍ ସଫା କରନ୍ତୁ|ବ୍ଲକ୍|ରିପୋର୍ଟ|ଚାଟ୍ ଡିଲିଟ୍|ଦେଶ ବାଛନ୍ତୁ|ଆପଣ|ବ୍ଲକ୍ ଅଛି|ଅନବ୍ଲକ୍|ଏଯାଏଁ ମିଡିଆ ନାହିଁ|ଏଠାରେ ଚାଟ୍ ନାହିଁ|କ୍ୟାମେରା ବନ୍ଦ|ରିପୋର୍ଟ ଯାଇଛି|ତାଲିକାରେ ଯୋଡ଼ାଗଲା|ଚାଟ୍ କପି ହେଲା|ସବୁ ସନ୍ଦେଶ ମିଟାଇବେ?|ଏହି ଚାଟ୍ ଡିଲିଟ୍ କରିବେ?|ଏହି ବ୍ୟକ୍ତିଙ୍କୁ ବ୍ଲକ୍ କରିବେ?|ବାତିଲ|ହଁ',
  'ne':
      'सुरु गरौं|आफ्नो मोबाइल नम्बर हाल्नुहोस्|हामी एक पटकको कोड पठाउँछौं|मोबाइल नम्बर|OTP पठाउनुहोस्|OTP जाँच्नुहोस्|आएको ६ अंकको कोड हाल्नुहोस्|OTP फेरि पठाउनुहोस्|अघि बढ्नुहोस्|आफ्नो प्रोफाइल बनाउनुहोस्|साथीहरूले तपाईंलाई यसरी देख्छन्|तपाईंको नाम|बायो|सकियो|तपाईंका च्याट|खोज्नुहोस्|सक्रिय सन्देश|सक्रिय|अनलाइन|सन्देश|अपडेट|नयाँ अपडेट|स्टेटस हेर्नुहोस्|मेरो स्टेटस|आफ्नो स्टेटस लेख्नुहोस्|साथीका अपडेट|कलहरू|कल र अरू|कल इतिहास|समूह|नयाँ समूह बनाउनुहोस्|नयाँ समूह|समूहको नाम|बनाउनुहोस्|सेटिङ|भाषा|पूरै एप यो भाषामा बदलिन्छ|सूचना|सन्देश, कल र स्टेटस|गोपनीयता|प्रोफाइल कसले हेर्न सक्छ|Qapp बारे|Version 1.0.0|कल हुँदै छ…|जोडियो|{name} अनलाइन हुनुहुन्छ|म्युट|स्पिकर|काट्नुहोस्|पल्टाउनुहोस्|क्यामेरा|भ्वाइस कल|भिडियो कल|सेयर|फोटो|कागजात|PDF|अहिले|स्टेटस|सबै|नपढिएको|मनपर्ने|मिडिया, लिंक र डक|तारा लागेका सन्देश|सूचना म्युट|हराउने सन्देश|बन्द|उन्नत च्याट गोपनीयता|च्याट थिम|सन्देश एन्ड-टु-एन्ड इन्क्रिप्टेड छन्|साझा समूह|मनपर्नेमा थप्नुहोस्|सूचीमा थप्नुहोस्|च्याट एक्सपोर्ट|च्याट खाली गर्नुहोस्|ब्लक|रिपोर्ट|च्याट मेट्नुहोस्|देश छान्नुहोस्|तपाईं|ब्लक छ|अनब्लक|अहिले मिडिया छैन|यहाँ च्याट छैन|क्यामेरा बन्द छ|रिपोर्ट पठाइयो|सूचीमा थपियो|च्याट कपी भयो|सबै सन्देश मेट्ने?|यो च्याट मेट्ने?|यो व्यक्तिलाई ब्लक गर्ने?|रद्द|हो',
  'ar':
      'ابدأ|أدخل رقم جوالك|سنرسل لك رمزاً لمرة واحدة|رقم الجوال|إرسال الرمز|تحقق من الرمز|أدخل الرمز المكوّن من 6 أرقام|إعادة إرسال الرمز|متابعة|أنشئ ملفك|هكذا سيراك الأصدقاء|اسمك|نبذة|تم|محادثاتك|بحث|الرسائل النشطة|نشط|متصل|رسالة|التحديثات|تحديثات جديدة|عرض الحالة|حالتي|أضف حالتك|تحديثات الأصدقاء|المكالمات|المكالمات والمزيد|سجل المكالمات|المجموعات|إنشاء مجموعة|مجموعة جديدة|اسم المجموعة|إنشاء|الإعدادات|اللغة|سيتبدل التطبيق كله إلى هذه اللغة|الإشعارات|الرسائل والمكالمات والحالة|الخصوصية|من يرى ملفك|حول Qapp|Version 1.0.0|جارٍ الاتصال…|متصل الآن|{name} متصل|كتم|مكبر الصوت|إنهاء|قلب|الكاميرا|مكالمة صوتية|مكالمة فيديو|مشاركة|صورة|مستند|PDF|الآن|الحالة|الكل|غير مقروء|المفضلة|الوسائط والروابط والمستندات|الرسائل المميزة|كتم الإشعارات|الرسائل المختفية|إيقاف|خصوصية الدردشة المتقدمة|مظهر الدردشة|الرسائل مشفرة من الطرفين|مجموعات مشتركة|أضف إلى المفضلة|أضف إلى قائمة|تصدير الدردشة|مسح الدردشة|حظر|إبلاغ|حذف الدردشة|اختر الدولة|أنت|محظور|إلغاء الحظر|لا وسائط بعد|لا دردشات هنا|الكاميرا متوقفة|تم إرسال البلاغ|أُضيف إلى القائمة|تم نسخ الدردشة|مسح كل الرسائل؟|حذف هذه الدردشة؟|حظر هذا الشخص؟|إلغاء|نعم',
  'fa':
      'شروع|شماره موبایل را وارد کنید|یک کد یک‌بارمصرف می‌فرستیم|شماره موبایل|ارسال کد|تأیید کد|کد ۶ رقمی را وارد کنید|ارسال دوباره کد|ادامه|پروفایل بسازید|دوستانت این‌طور می‌بینندت|نام شما|بیو|تمام|گفتگوهای شما|جستجو|پیام‌های فعال|فعال|آنلاین|پیام|به‌روزرسانی‌ها|به‌روزرسانی تازه|دیدن وضعیت|وضعیت من|وضعیت بنویسید|به‌روزرسانی دوستان|تماس‌ها|تماس و بیشتر|تاریخچه تماس|گروه‌ها|ساخت گروه|گروه تازه|نام گروه|بساز|تنظیمات|زبان|کل برنامه به این زبان عوض می‌شود|اعلان‌ها|پیام، تماس و وضعیت|حریم خصوصی|چه کسی پروفایل را ببیند|درباره Qapp|Version 1.0.0|در حال تماس…|وصل شد|{name} آنلاین است|بی‌صدا|بلندگو|قطع|برگردان|دوربین|تماس صوتی|تماس تصویری|اشتراک|عکس|سند|PDF|الان|وضعیت|همه|نخوانده|علاقه‌مندی|رسانه، پیوند و سند|پیام‌های ستاره‌دار|بی‌صدا کردن اعلان|پیام‌های ناپدیدشونده|خاموش|حریم خصوصی پیشرفته|تم گفتگو|پیام‌ها سرتاسری رمز شده‌اند|گروه‌های مشترک|افزودن به علاقه‌مندی|افزودن به فهرست|خروجی گفتگو|پاک کردن گفتگو|مسدود|گزارش|حذف گفتگو|کشور را انتخاب کنید|شما|مسدود است|رفع مسدودیت|هنوز رسانه‌ای نیست|اینجا گفتگویی نیست|دوربین خاموش است|گزارش فرستاده شد|به فهرست اضافه شد|گفتگو کپی شد|همه پیام‌ها پاک شود؟|این گفتگو حذف شود؟|این شخص مسدود شود؟|لغو|بله',
  'es':
      'Empezar|Escribe tu número|Te enviaremos un código de un solo uso|Número de móvil|Enviar código|Verificar código|Escribe el código de 6 dígitos|Reenviar código|Continuar|Crea tu perfil|Así te verán tus amigos|Tu nombre|Bio|Listo|Tus chats|Buscar|Mensajes activos|Activo|En línea|Mensaje|Novedades|Novedades nuevas|Ver estado|Mi estado|Añade tu estado|Novedades de amigos|Llamadas|Llamadas y más|Historial de llamadas|Grupos|Crear un grupo|Grupo nuevo|Nombre del grupo|Crear|Ajustes|Idioma|Toda la app cambia a este idioma|Avisos|Mensajes, llamadas y estados|Privacidad|Quién puede ver tu perfil|Acerca de Qapp|Version 1.0.0|Llamando…|Conectado|{name} está en línea|Silencio|Altavoz|Colgar|Girar|Cámara|Llamada de voz|Videollamada|Compartir|Foto|Documento|PDF|Ahora|Estado|Todos|No leídos|Favoritos|Multimedia, enlaces y docs|Mensajes destacados|Silenciar avisos|Mensajes temporales|Desactivado|Privacidad avanzada|Tema del chat|Los mensajes van cifrados de extremo a extremo|Grupos en común|Añadir a favoritos|Añadir a una lista|Exportar chat|Vaciar chat|Bloquear|Reportar|Eliminar chat|Elegir país|Tú|Bloqueado|Desbloquear|Aún no hay multimedia|No hay chats aquí|La cámara está apagada|Reporte enviado|Añadido a la lista|Chat copiado|¿Borrar todos los mensajes?|¿Eliminar este chat?|¿Bloquear a esta persona?|Cancelar|Sí',
  'fr':
      'Commencer|Entrez votre numéro|Nous enverrons un code à usage unique|Numéro de mobile|Envoyer le code|Vérifier le code|Entrez le code à 6 chiffres reçu|Renvoyer le code|Continuer|Créez votre profil|Vos amis vous verront ainsi|Votre nom|Bio|Terminé|Vos discussions|Rechercher|Messages actifs|Actif|En ligne|Message|Actualités|Nouvelles actualités|Voir le statut|Mon statut|Ajoutez votre statut|Actualités des amis|Appels|Appels et plus|Historique des appels|Groupes|Créer un groupe|Nouveau groupe|Nom du groupe|Créer|Réglages|Langue|Toute l’app passe dans cette langue|Notifications|Messages, appels et statuts|Confidentialité|Qui peut voir votre profil|À propos de Qapp|Version 1.0.0|Appel…|Connecté|{name} est en ligne|Muet|Haut-parleur|Raccrocher|Retourner|Caméra|Appel vocal|Appel vidéo|Partager|Photo|Document|PDF|Maintenant|Statut|Tous|Non lus|Favoris|Médias, liens et docs|Messages suivis|Couper les notifications|Messages éphémères|Désactivé|Confidentialité avancée|Thème du chat|Les messages sont chiffrés de bout en bout|Groupes en commun|Ajouter aux favoris|Ajouter à une liste|Exporter la discussion|Effacer la discussion|Bloquer|Signaler|Supprimer la discussion|Choisir le pays|Vous|Bloqué|Débloquer|Pas encore de média|Aucune discussion ici|Caméra éteinte|Signalement envoyé|Ajouté à la liste|Discussion copiée|Effacer tous les messages ?|Supprimer cette discussion ?|Bloquer cette personne ?|Annuler|Oui',
  'de':
      'Loslegen|Gib deine Handynummer ein|Wir senden dir einen Einmalcode|Handynummer|Code senden|Code prüfen|Gib den 6-stelligen Code ein|Code erneut senden|Weiter|Profil erstellen|So sehen dich Freunde|Dein Name|Bio|Fertig|Deine Chats|Suchen|Aktive Nachrichten|Aktiv|Online|Nachricht|Updates|Neue Updates|Status ansehen|Mein Status|Status hinzufügen|Updates von Freunden|Anrufe|Anrufe und mehr|Anrufliste|Gruppen|Gruppe erstellen|Neue Gruppe|Gruppenname|Erstellen|Einstellungen|Sprache|Die ganze App wechselt in diese Sprache|Mitteilungen|Nachrichten, Anrufe und Status|Privatsphäre|Wer dein Profil sieht|Über Qapp|Version 1.0.0|Anrufen…|Verbunden|{name} ist online|Stumm|Lautsprecher|Auflegen|Drehen|Kamera|Sprachanruf|Videoanruf|Teilen|Foto|Dokument|PDF|Jetzt|Status|Alle|Ungelesen|Favoriten|Medien, Links und Dokumente|Markierte Nachrichten|Mitteilungen stumm|Verschwindende Nachrichten|Aus|Erweiterter Chat-Schutz|Chat-Design|Nachrichten sind Ende-zu-Ende verschlüsselt|Gemeinsame Gruppen|Zu Favoriten|Zu einer Liste|Chat exportieren|Chat leeren|Blockieren|Melden|Chat löschen|Land wählen|Du|Blockiert|Entblocken|Noch keine Medien|Keine Chats hier|Kamera ist aus|Meldung gesendet|Zur Liste hinzugefügt|Chat kopiert|Alle Nachrichten löschen?|Diesen Chat löschen?|Diese Person blockieren?|Abbrechen|Ja',
  'pt':
      'Começar|Digite seu número|Vamos enviar um código de uso único|Número de celular|Enviar código|Verificar código|Digite o código de 6 dígitos|Reenviar código|Continuar|Crie seu perfil|É assim que os amigos verão você|Seu nome|Bio|Pronto|Seus chats|Buscar|Mensagens ativas|Ativo|Online|Mensagem|Atualizações|Novas atualizações|Ver status|Meu status|Adicione seu status|Atualizações dos amigos|Chamadas|Chamadas e mais|Histórico de chamadas|Grupos|Criar um grupo|Novo grupo|Nome do grupo|Criar|Ajustes|Idioma|O app inteiro muda para este idioma|Notificações|Mensagens, chamadas e status|Privacidade|Quem pode ver seu perfil|Sobre o Qapp|Version 1.0.0|Chamando…|Conectado|{name} está online|Mudo|Alto-falante|Desligar|Virar|Câmera|Chamada de voz|Chamada de vídeo|Compartilhar|Foto|Documento|PDF|Agora|Status|Tudo|Não lidas|Favoritos|Mídia, links e docs|Mensagens com estrela|Silenciar avisos|Mensagens temporárias|Desligado|Privacidade avançada|Tema do chat|As mensagens são criptografadas de ponta a ponta|Grupos em comum|Adicionar aos favoritos|Adicionar a uma lista|Exportar chat|Limpar chat|Bloquear|Denunciar|Apagar chat|Escolher país|Você|Bloqueado|Desbloquear|Ainda sem mídia|Nenhum chat aqui|Câmera desligada|Denúncia enviada|Adicionado à lista|Chat copiado|Apagar todas as mensagens?|Apagar este chat?|Bloquear esta pessoa?|Cancelar|Sim',
  'it':
      'Inizia|Inserisci il tuo numero|Ti invieremo un codice usa e getta|Numero di cellulare|Invia codice|Verifica codice|Inserisci il codice di 6 cifre|Reinvia codice|Continua|Crea il tuo profilo|Gli amici ti vedranno così|Il tuo nome|Bio|Fatto|Le tue chat|Cerca|Messaggi attivi|Attivo|Online|Messaggio|Aggiornamenti|Nuovi aggiornamenti|Vedi stato|Il mio stato|Aggiungi il tuo stato|Aggiornamenti degli amici|Chiamate|Chiamate e altro|Cronologia chiamate|Gruppi|Crea un gruppo|Nuovo gruppo|Nome del gruppo|Crea|Impostazioni|Lingua|Tutta l’app passa a questa lingua|Notifiche|Messaggi, chiamate e stati|Privacy|Chi può vedere il profilo|Informazioni su Qapp|Version 1.0.0|Chiamata…|Connesso|{name} è online|Muto|Vivavoce|Chiudi|Gira|Fotocamera|Chiamata vocale|Videochiamata|Condividi|Foto|Documento|PDF|Ora|Stato|Tutte|Non lette|Preferiti|Media, link e documenti|Messaggi speciali|Silenzia notifiche|Messaggi a scomparsa|Spento|Privacy avanzata della chat|Tema della chat|I messaggi sono cifrati end-to-end|Gruppi in comune|Aggiungi ai preferiti|Aggiungi a una lista|Esporta chat|Svuota chat|Blocca|Segnala|Elimina chat|Scegli il paese|Tu|Bloccato|Sblocca|Ancora nessun media|Nessuna chat qui|Fotocamera spenta|Segnalazione inviata|Aggiunto alla lista|Chat copiata|Cancellare tutti i messaggi?|Eliminare questa chat?|Bloccare questa persona?|Annulla|Sì',
  'ru':
      'Начать|Введите номер телефона|Мы отправим одноразовый код|Номер телефона|Отправить код|Проверить код|Введите 6-значный код|Отправить код снова|Далее|Создайте профиль|Так вас увидят друзья|Ваше имя|О себе|Готово|Ваши чаты|Поиск|Активные сообщения|Активно|В сети|Сообщение|Обновления|Новые обновления|Смотреть статус|Мой статус|Добавьте статус|Обновления друзей|Звонки|Звонки и ещё|История звонков|Группы|Создать группу|Новая группа|Название группы|Создать|Настройки|Язык|Всё приложение переключится на этот язык|Уведомления|Сообщения, звонки и статусы|Конфиденциальность|Кто видит профиль|О Qapp|Version 1.0.0|Звонок…|Соединено|{name} в сети|Без звука|Динамик|Завершить|Перевернуть|Камера|Голосовой звонок|Видеозвонок|Поделиться|Фото|Документ|PDF|Сейчас|Статус|Все|Непрочитанные|Избранное|Медиа, ссылки и документы|Отмеченные сообщения|Отключить уведомления|Исчезающие сообщения|Выкл|Расширенная приватность|Тема чата|Сообщения защищены сквозным шифрованием|Общие группы|В избранное|В список|Экспорт чата|Очистить чат|Заблокировать|Пожаловаться|Удалить чат|Выберите страну|Вы|Заблокирован|Разблокировать|Медиа пока нет|Здесь нет чатов|Камера выключена|Жалоба отправлена|Добавлено в список|Чат скопирован|Удалить все сообщения?|Удалить этот чат?|Заблокировать этого человека?|Отмена|Да',
  'uk':
      'Почати|Введіть номер телефону|Ми надішлемо одноразовий код|Номер телефону|Надіслати код|Перевірити код|Введіть 6-значний код|Надіслати код знову|Далі|Створіть профіль|Так вас бачитимуть друзі|Ваше ім’я|Про себе|Готово|Ваші чати|Пошук|Активні повідомлення|Активно|У мережі|Повідомлення|Оновлення|Нові оновлення|Дивитися статус|Мій статус|Додайте статус|Оновлення друзів|Дзвінки|Дзвінки й ще|Історія дзвінків|Групи|Створити групу|Нова група|Назва групи|Створити|Налаштування|Мова|Увесь застосунок перемкнеться на цю мову|Сповіщення|Повідомлення, дзвінки й статуси|Приватність|Хто бачить профіль|Про Qapp|Version 1.0.0|Дзвінок…|З’єднано|{name} у мережі|Без звуку|Динамік|Завершити|Перевернути|Камера|Голосовий дзвінок|Відеодзвінок|Поділитися|Фото|Документ|PDF|Зараз|Статус|Усі|Непрочитані|Обране|Медіа, посилання й документи|Позначені повідомлення|Вимкнути сповіщення|Зникаючі повідомлення|Вимк|Розширена приватність|Тема чату|Повідомлення захищені наскрізним шифруванням|Спільні групи|До обраного|До списку|Експорт чату|Очистити чат|Заблокувати|Поскаржитися|Видалити чат|Оберіть країну|Ви|Заблоковано|Розблокувати|Медіа ще немає|Тут немає чатів|Камеру вимкнено|Скаргу надіслано|Додано до списку|Чат скопійовано|Видалити всі повідомлення?|Видалити цей чат?|Заблокувати цю людину?|Скасувати|Так',
  'zh':
      '开始|输入你的手机号|我们会发送一次验证码|手机号|发送验证码|验证验证码|输入收到的 6 位验证码|重新发送|继续|创建你的资料|朋友会这样看到你|你的名字|简介|完成|你的聊天|搜索|进行中的消息|在线活动|在线|消息|动态|新动态|查看状态|我的状态|写下你的状态|朋友的动态|通话|通话及更多|通话记录|群组|创建群组|新群组|群组名称|创建|设置|语言|整个应用会切换到这个语言|通知|消息、通话和状态|隐私|谁可以看你的资料|关于 Qapp|Version 1.0.0|正在呼叫…|已接通|{name} 在线|静音|扬声器|挂断|翻转|相机|语音通话|视频通话|分享|照片|文档|PDF|现在|状态|全部|未读|收藏|媒体、链接和文档|星标消息|静音通知|阅后即焚|关闭|高级聊天隐私|聊天主题|消息已端到端加密|共同群组|加入收藏|加入列表|导出聊天|清空聊天|拉黑|举报|删除聊天|选择国家|你|已拉黑|取消拉黑|还没有媒体|这里没有聊天|相机已关闭|举报已发送|已加入列表|聊天已复制|清空全部消息？|删除这个聊天？|拉黑这个人？|取消|是',
  'ja':
      'はじめる|携帯番号を入力|ワンタイムコードを送ります|携帯番号|コードを送る|コードを確認|届いた6桁のコードを入力|コードを再送|続ける|プロフィールを作る|友だちにはこう見えます|あなたの名前|自己紹介|完了|あなたのチャット|検索|進行中のメッセージ|アクティブ|オンライン|メッセージ|アップデート|新しいアップデート|ステータスを見る|自分のステータス|ステータスを書く|友だちのアップデート|通話|通話とその他|通話履歴|グループ|グループを作る|新しいグループ|グループ名|作成|設定|言語|アプリ全体がこの言語に切り替わります|通知|メッセージ、通話、ステータス|プライバシー|プロフィールを見られる人|Qapp について|Version 1.0.0|発信中…|接続しました|{name} はオンライン|ミュート|スピーカー|終了|反転|カメラ|音声通話|ビデオ通話|共有|写真|書類|PDF|今|ステータス|すべて|未読|お気に入り|メディア、リンク、書類|スター付きメッセージ|通知をミュート|消えるメッセージ|オフ|詳細なチャットのプライバシー|チャットのテーマ|メッセージはエンドツーエンドで暗号化|共通のグループ|お気に入りに追加|リストに追加|チャットを書き出す|チャットを消去|ブロック|報告|チャットを削除|国を選ぶ|あなた|ブロック中|ブロック解除|メディアはまだありません|チャットはありません|カメラはオフです|報告を送りました|リストに追加しました|チャットをコピーしました|すべてのメッセージを消しますか？|このチャットを削除しますか？|この人をブロックしますか？|キャンセル|はい',
  'ko':
      '시작|휴대폰 번호를 입력하세요|일회용 코드를 보내 드립니다|휴대폰 번호|코드 보내기|코드 확인|받은 6자리 코드를 입력|코드 다시 보내기|계속|프로필 만들기|친구들에게 이렇게 보입니다|이름|소개|완료|내 채팅|검색|진행 중인 메시지|활성|온라인|메시지|업데이트|새 업데이트|상태 보기|내 상태|상태를 적어 보세요|친구 업데이트|통화|통화와 더보기|통화 기록|그룹|그룹 만들기|새 그룹|그룹 이름|만들기|설정|언어|앱 전체가 이 언어로 바뀝니다|알림|메시지, 통화, 상태|개인정보|프로필을 볼 수 있는 사람|Qapp 정보|Version 1.0.0|전화 거는 중…|연결됨|{name} 님이 온라인입니다|음소거|스피커|종료|전환|카메라|음성 통화|영상 통화|공유|사진|문서|PDF|지금|상태|전체|안 읽음|즐겨찾기|미디어, 링크, 문서|별표 메시지|알림 끄기|사라지는 메시지|끄기|고급 채팅 개인정보|채팅 테마|메시지는 종단간 암호화됩니다|함께 있는 그룹|즐겨찾기에 추가|목록에 추가|채팅 내보내기|채팅 비우기|차단|신고|채팅 삭제|국가 선택|나|차단됨|차단 해제|아직 미디어가 없습니다|여기 채팅이 없습니다|카메라가 꺼져 있습니다|신고를 보냈습니다|목록에 추가했습니다|채팅을 복사했습니다|모든 메시지를 지울까요?|이 채팅을 삭제할까요?|이 사람을 차단할까요?|취소|예',
  'tr':
      'Başla|Telefon numaranı gir|Sana tek kullanımlık bir kod göndereceğiz|Telefon numarası|Kodu gönder|Kodu doğrula|Gelen 6 haneli kodu gir|Kodu yeniden gönder|Devam|Profilini oluştur|Arkadaşların seni böyle görür|Adın|Biyo|Bitti|Sohbetlerin|Ara|Aktif mesajlar|Aktif|Çevrimiçi|Mesaj|Güncellemeler|Yeni güncellemeler|Durumu gör|Durumum|Durumunu yaz|Arkadaş güncellemeleri|Aramalar|Aramalar ve fazlası|Arama geçmişi|Gruplar|Grup oluştur|Yeni grup|Grup adı|Oluştur|Ayarlar|Dil|Tüm uygulama bu dile geçer|Bildirimler|Mesajlar, aramalar ve durum|Gizlilik|Profilini kim görebilir|Qapp hakkında|Version 1.0.0|Aranıyor…|Bağlandı|{name} çevrimiçi|Sessiz|Hoparlör|Kapat|Çevir|Kamera|Sesli arama|Görüntülü arama|Paylaş|Fotoğraf|Belge|PDF|Şimdi|Durum|Tümü|Okunmamış|Favoriler|Medya, bağlantı ve belgeler|Yıldızlı mesajlar|Bildirimleri sessize al|Kaybolan mesajlar|Kapalı|Gelişmiş sohbet gizliliği|Sohbet teması|Mesajlar uçtan uca şifrelidir|Ortak gruplar|Favorilere ekle|Listeye ekle|Sohbeti dışa aktar|Sohbeti temizle|Engelle|Şikayet et|Sohbeti sil|Ülke seç|Sen|Engelli|Engeli kaldır|Henüz medya yok|Burada sohbet yok|Kamera kapalı|Şikayet gönderildi|Listeye eklendi|Sohbet kopyalandı|Tüm mesajlar silinsin mi?|Bu sohbet silinsin mi?|Bu kişi engellensin mi?|İptal|Evet',
  'id':
      'Mulai|Masukkan nomor ponsel|Kami kirim kode sekali pakai|Nomor ponsel|Kirim kode|Periksa kode|Masukkan kode 6 digit yang diterima|Kirim ulang kode|Lanjut|Buat profilmu|Teman akan melihatmu seperti ini|Namamu|Bio|Selesai|Chat kamu|Cari|Pesan aktif|Aktif|Online|Pesan|Pembaruan|Pembaruan baru|Lihat status|Status saya|Tulis statusmu|Pembaruan teman|Panggilan|Panggilan dan lainnya|Riwayat panggilan|Grup|Buat grup|Grup baru|Nama grup|Buat|Pengaturan|Bahasa|Seluruh aplikasi berganti ke bahasa ini|Notifikasi|Pesan, panggilan, dan status|Privasi|Siapa yang bisa melihat profil|Tentang Qapp|Version 1.0.0|Memanggil…|Terhubung|{name} sedang online|Senyap|Speaker|Akhiri|Balik|Kamera|Panggilan suara|Panggilan video|Bagikan|Foto|Dokumen|PDF|Sekarang|Status|Semua|Belum dibaca|Favorit|Media, tautan, dan dokumen|Pesan berbintang|Senyapkan notifikasi|Pesan yang hilang|Mati|Privasi chat lanjutan|Tema chat|Pesan dienkripsi ujung ke ujung|Grup bersama|Tambah ke favorit|Tambah ke daftar|Ekspor chat|Hapus isi chat|Blokir|Laporkan|Hapus chat|Pilih negara|Kamu|Diblokir|Buka blokir|Belum ada media|Tidak ada chat di sini|Kamera mati|Laporan terkirim|Ditambahkan ke daftar|Chat disalin|Hapus semua pesan?|Hapus chat ini?|Blokir orang ini?|Batal|Ya',
  'ms':
      'Mula|Masukkan nombor telefon|Kami hantar kod sekali guna|Nombor telefon|Hantar kod|Sahkan kod|Masukkan kod 6 digit yang diterima|Hantar semula kod|Teruskan|Cipta profil anda|Rakan akan melihat anda begini|Nama anda|Bio|Siap|Sembang anda|Cari|Mesej aktif|Aktif|Dalam talian|Mesej|Kemas kini|Kemas kini baharu|Lihat status|Status saya|Tulis status anda|Kemas kini rakan|Panggilan|Panggilan dan lagi|Sejarah panggilan|Kumpulan|Cipta kumpulan|Kumpulan baharu|Nama kumpulan|Cipta|Tetapan|Bahasa|Seluruh apl bertukar ke bahasa ini|Pemberitahuan|Mesej, panggilan dan status|Privasi|Siapa boleh lihat profil|Perihal Qapp|Version 1.0.0|Memanggil…|Bersambung|{name} dalam talian|Senyap|Pembesar suara|Tamat|Balik|Kamera|Panggilan suara|Panggilan video|Kongsi|Foto|Dokumen|PDF|Sekarang|Status|Semua|Belum dibaca|Kegemaran|Media, pautan dan dokumen|Mesej berbintang|Senyapkan pemberitahuan|Mesej yang hilang|Mati|Privasi sembang lanjutan|Tema sembang|Mesej disulitkan hujung ke hujung|Kumpulan bersama|Tambah ke kegemaran|Tambah ke senarai|Eksport sembang|Kosongkan sembang|Sekat|Lapor|Padam sembang|Pilih negara|Anda|Disekat|Nyahsekat|Belum ada media|Tiada sembang di sini|Kamera mati|Laporan dihantar|Ditambah ke senarai|Sembang disalin|Padam semua mesej?|Padam sembang ini?|Sekat orang ini?|Batal|Ya',
  'vi':
      'Bắt đầu|Nhập số điện thoại|Chúng tôi gửi mã dùng một lần|Số điện thoại|Gửi mã|Xác minh mã|Nhập mã 6 số bạn nhận được|Gửi lại mã|Tiếp tục|Tạo hồ sơ|Bạn bè sẽ thấy bạn như thế này|Tên của bạn|Tiểu sử|Xong|Cuộc trò chuyện|Tìm|Tin nhắn đang hoạt động|Hoạt động|Trực tuyến|Tin nhắn|Cập nhật|Cập nhật mới|Xem trạng thái|Trạng thái của tôi|Viết trạng thái|Cập nhật của bạn bè|Cuộc gọi|Cuộc gọi và hơn thế|Lịch sử cuộc gọi|Nhóm|Tạo nhóm|Nhóm mới|Tên nhóm|Tạo|Cài đặt|Ngôn ngữ|Cả ứng dụng chuyển sang ngôn ngữ này|Thông báo|Tin nhắn, cuộc gọi và trạng thái|Quyền riêng tư|Ai xem được hồ sơ|Giới thiệu Qapp|Version 1.0.0|Đang gọi…|Đã kết nối|{name} đang trực tuyến|Tắt tiếng|Loa|Kết thúc|Lật|Máy ảnh|Gọi thoại|Gọi video|Chia sẻ|Ảnh|Tài liệu|PDF|Bây giờ|Trạng thái|Tất cả|Chưa đọc|Yêu thích|Phương tiện, liên kết và tài liệu|Tin đã gắn sao|Tắt thông báo|Tin nhắn tự xóa|Tắt|Quyền riêng tư nâng cao|Chủ đề trò chuyện|Tin nhắn được mã hóa đầu cuối|Nhóm chung|Thêm vào yêu thích|Thêm vào danh sách|Xuất cuộc trò chuyện|Xóa nội dung|Chặn|Báo cáo|Xóa cuộc trò chuyện|Chọn quốc gia|Bạn|Đã chặn|Bỏ chặn|Chưa có phương tiện|Không có cuộc trò chuyện|Máy ảnh đang tắt|Đã gửi báo cáo|Đã thêm vào danh sách|Đã sao chép|Xóa mọi tin nhắn?|Xóa cuộc trò chuyện này?|Chặn người này?|Hủy|Có',
  'th':
      'เริ่มเลย|ใส่เบอร์มือถือ|เราจะส่งรหัสใช้ครั้งเดียว|เบอร์มือถือ|ส่งรหัส|ตรวจรหัส|ใส่รหัส 6 หลักที่ได้รับ|ส่งรหัสอีกครั้ง|ต่อไป|สร้างโปรไฟล์|เพื่อนจะเห็นคุณแบบนี้|ชื่อของคุณ|ไบโอ|เสร็จ|แชทของคุณ|ค้นหา|ข้อความที่ใช้งาน|ใช้งานอยู่|ออนไลน์|ข้อความ|อัปเดต|อัปเดตใหม่|ดูสเตตัส|สเตตัสของฉัน|เขียนสเตตัส|อัปเดตของเพื่อน|สาย|สายและอื่น ๆ|ประวัติสาย|กลุ่ม|สร้างกลุ่ม|กลุ่มใหม่|ชื่อกลุ่ม|สร้าง|การตั้งค่า|ภาษา|ทั้งแอปจะเปลี่ยนเป็นภาษานี้|การแจ้งเตือน|ข้อความ สาย และสเตตัส|ความเป็นส่วนตัว|ใครเห็นโปรไฟล์ได้|เกี่ยวกับ Qapp|Version 1.0.0|กำลังโทร…|เชื่อมต่อแล้ว|{name} ออนไลน์|ปิดเสียง|ลำโพง|วางสาย|สลับ|กล้อง|โทรเสียง|วิดีโอคอล|แชร์|รูป|เอกสาร|PDF|ตอนนี้|สเตตัส|ทั้งหมด|ยังไม่อ่าน|รายการโปรด|สื่อ ลิงก์ และเอกสาร|ข้อความติดดาว|ปิดการแจ้งเตือน|ข้อความที่หายไป|ปิด|ความเป็นส่วนตัวขั้นสูง|ธีมแชท|ข้อความถูกเข้ารหัสแบบต้นทางถึงปลายทาง|กลุ่มที่มีร่วมกัน|เพิ่มในรายการโปรด|เพิ่มในลิสต์|ส่งออกแชท|ล้างแชท|บล็อก|รายงาน|ลบแชท|เลือกประเทศ|คุณ|ถูกบล็อก|ปลดบล็อก|ยังไม่มีสื่อ|ไม่มีแชทที่นี่|กล้องปิดอยู่|ส่งรายงานแล้ว|เพิ่มในลิสต์แล้ว|คัดลอกแชทแล้ว|ลบข้อความทั้งหมด?|ลบแชทนี้?|บล็อกคนนี้?|ยกเลิก|ใช่',
  'sw':
      'Anza|Weka nambari yako|Tutakutumia msimbo wa mara moja|Nambari ya simu|Tuma msimbo|Thibitisha msimbo|Weka msimbo wa tarakimu 6|Tuma msimbo tena|Endelea|Tengeneza wasifu|Marafiki watakuona hivi|Jina lako|Bio|Imekamilika|Soga zako|Tafuta|Ujumbe hai|Hai|Mtandaoni|Ujumbe|Taarifa|Taarifa mpya|Tazama hali|Hali yangu|Andika hali yako|Taarifa za marafiki|Simu|Simu na zaidi|Historia ya simu|Vikundi|Unda kikundi|Kikundi kipya|Jina la kikundi|Unda|Mipangilio|Lugha|Programu yote inabadilika kwenda lugha hii|Arifa|Ujumbe, simu na hali|Faragha|Nani anaona wasifu|Kuhusu Qapp|Version 1.0.0|Inapiga…|Imeunganishwa|{name} yuko mtandaoni|Nyamazisha|Spika|Kata|Geuza|Kamera|Simu ya sauti|Simu ya video|Shiriki|Picha|Hati|PDF|Sasa|Hali|Zote|Hazijasomwa|Vipendwa|Midia, viungo na hati|Ujumbe wenye nyota|Zima arifa|Ujumbe unaopotea|Imezimwa|Faragha ya juu ya soga|Mandhari ya soga|Ujumbe umesimbwa mwisho hadi mwisho|Vikundi vya pamoja|Ongeza kwa vipendwa|Ongeza kwenye orodha|Hamisha soga|Futa soga|Zuia|Ripoti|Futa soga|Chagua nchi|Wewe|Amezuiwa|Ondoa kizuizi|Bado hakuna midia|Hakuna soga hapa|Kamera imezimwa|Ripoti imetumwa|Imeongezwa kwenye orodha|Soga imenakiliwa|Futa ujumbe wote?|Futa soga hii?|Zuia mtu huyu?|Ghairi|Ndiyo',
  'fil':
      'Simulan|Ilagay ang numero mo|Magpapadala kami ng isang-beses na code|Numero ng mobile|Ipadala ang code|I-verify ang code|Ilagay ang 6 na digit na code|Ipadala ulit ang code|Magpatuloy|Gumawa ng profile|Ganito ka makikita ng mga kaibigan|Pangalan mo|Bio|Tapos|Mga chat mo|Hanapin|Aktibong mensahe|Aktibo|Online|Mensahe|Mga update|Bagong update|Tingnan ang status|Status ko|Isulat ang status mo|Update ng mga kaibigan|Mga tawag|Mga tawag at iba pa|History ng tawag|Mga grupo|Gumawa ng grupo|Bagong grupo|Pangalan ng grupo|Gawin|Settings|Wika|Ang buong app ay magiging wikang ito|Mga abiso|Mensahe, tawag, at status|Privacy|Sino ang makakakita ng profile|Tungkol sa Qapp|Version 1.0.0|Tumatawag…|Konektado|{name} ay online|I-mute|Speaker|Ibaba|I-flip|Camera|Voice call|Video call|Ibahagi|Larawan|Dokumento|PDF|Ngayon|Status|Lahat|Hindi pa nababasa|Paborito|Media, link, at docs|Naka-star na mensahe|I-mute ang abiso|Nawawalang mensahe|Naka-off|Advanced na privacy|Tema ng chat|Naka-encrypt ang mga mensahe|Mga grupong pareho|Idagdag sa paborito|Idagdag sa listahan|I-export ang chat|I-clear ang chat|I-block|I-report|Burahin ang chat|Pumili ng bansa|Ikaw|Naka-block|I-unblock|Wala pang media|Walang chat dito|Naka-off ang camera|Naipadala ang report|Naidagdag sa listahan|Nakopya ang chat|Burahin lahat ng mensahe?|Burahin ang chat na ito?|I-block ang taong ito?|Kanselahin|Oo',
};

final packs = <String, Map<String, String>>{
  for (final entry in _rows.entries) entry.key: _pack(entry.value, _rows['en']!),
};

Map<String, int> packLengths() => {
  for (final entry in _rows.entries) entry.key: entry.value.split('|').length,
};

List<String> _fields(String row) => row.split('|');

Map<String, String> _pack(String row, String english) {
  final values = _fields(row);
  final fallback = _fields(english);
  return {
    for (var i = 0; i < stringKeys.length; i++)
      stringKeys[i]: i < values.length && values[i].isNotEmpty
          ? values[i]
          : fallback[i],
  };
}
