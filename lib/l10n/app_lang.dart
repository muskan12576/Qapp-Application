import 'package:flutter/material.dart';
import 'package:qapp/l10n/packs.dart';

class AppLang extends ChangeNotifier {
  AppLang._();

  static final AppLang instance = AppLang._();

  String code = 'en';

  void use(String value) {
    if (value == code || !packs.containsKey(value)) {
      return;
    }
    code = value;
    notifyListeners();
  }

  bool get rtl {
    for (final language in appLanguages) {
      if (language.code == code) {
        return language.rtl;
      }
    }
    return false;
  }
}

class LangScope extends InheritedNotifier<AppLang> {
  LangScope({super.key, required super.child}) : super(notifier: AppLang.instance);

  static String codeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LangScope>();
    return scope?.notifier?.code ?? 'en';
  }
}

class S {
  const S(this.code);

  final String code;

  static S of(BuildContext context) => S(LangScope.codeOf(context));

  String tr(String key) {
    return packs[code]?[key] ?? packs['en']?[key] ?? packs['hing']?[key] ?? key;
  }

  String get start => tr('start');
  String get loginBig => tr('loginBig');
  String get loginSmall => tr('loginSmall');
  String get phoneHint => tr('phoneHint');
  String get sendOtp => tr('sendOtp');
  String get otpTitle => tr('otpTitle');
  String get otpSub => tr('otpSub');
  String get next => tr('next');
  String get profileTitle => tr('profileTitle');
  String get profileSmall => tr('profileSmall');
  String get nameHint => tr('nameHint');
  String get bioHint => tr('bioHint');
  String get done => tr('done');
  String get chats => tr('chats');
  String get search => tr('search');
  String get activeMessages => tr('activeMessages');
  String get active => tr('active');
  String get online => tr('online');
  String get messageHint => tr('messageHint');
  String get statusTitle => tr('statusTitle');
  String get newUpdates => tr('newUpdates');
  String get viewStatus => tr('viewStatus');
  String get myStatus => tr('myStatus');
  String get statusHint => tr('statusHint');
  String get friendsUpdates => tr('friendsUpdates');
  String get callsTitle => tr('callsTitle');
  String get callsSub => tr('callsSub');
  String get callHistory => tr('callHistory');
  String get groups => tr('groups');
  String get newGroup => tr('newGroup');
  String get groupTitle => tr('groupTitle');
  String get groupHint => tr('groupHint');
  String get create => tr('create');
  String get settings => tr('settings');
  String get language => tr('language');
  String get languageHint => tr('languageHint');
  String get notifications => tr('notifications');
  String get notificationsHint => tr('notificationsHint');
  String get privacy => tr('privacy');
  String get privacyHint => tr('privacyHint');
  String get about => tr('about');
  String get aboutHint => tr('aboutHint');
  String get calling => tr('calling');
  String get connected => tr('connected');
  String get mute => tr('mute');
  String get speaker => tr('speaker');
  String get end => tr('end');
  String get flip => tr('flip');
  String get camera => tr('camera');
  String get voiceCall => tr('voiceCall');
  String get videoCall => tr('videoCall');
  String get attach => tr('attach');
  String get image => tr('image');
  String get document => tr('document');
  String get pdf => tr('pdf');
  String get now => tr('now');
  String get statusPlay => tr('statusPlay');
  String get all => tr('all');
  String get unread => tr('unread');
  String get favourite => tr('favourite');
  String get media => tr('media');
  String get starred => tr('starred');
  String get muteNotif => tr('muteNotif');
  String get disappearing => tr('disappearing');
  String get off => tr('off');
  String get privacyAdv => tr('privacyAdv');
  String get theme => tr('theme');
  String get encrypted => tr('encrypted');
  String get commonGroups => tr('commonGroups');
  String get addFav => tr('addFav');
  String get addList => tr('addList');
  String get exportChat => tr('exportChat');
  String get clearChat => tr('clearChat');
  String get block => tr('block');
  String get report => tr('report');
  String get deleteChat => tr('deleteChat');
  String get chooseCountry => tr('chooseCountry');
  String get you => tr('you');
  String get blocked => tr('blocked');
  String get unblock => tr('unblock');
  String get noMedia => tr('noMedia');
  String get noChats => tr('noChats');
  String get cameraHint => tr('cameraHint');
  String get reported => tr('reported');
  String get listAdded => tr('listAdded');
  String get copied => tr('copied');
  String get clearAsk => tr('clearAsk');
  String get deleteAsk => tr('deleteAsk');
  String get blockAsk => tr('blockAsk');
  String get cancel => tr('cancel');
  String get yes => tr('yes');
  String get newChat => tr('newChat');
  String get newContact => tr('newContact');
  String get frequent => tr('frequent');
  String get contactName => tr('contactName');
  String get save => tr('save');
  String get statusLabel => tr('statusLabel');
  String get adminOnly => tr('adminOnly');
  String get vanish24 => tr('vanish24');
  String get groupDetails => tr('groupDetails');
  String get chooseIcon => tr('chooseIcon');
  String get members => tr('members');
  String get picked => tr('picked');
  String get nextGo => tr('nextGo');
  String get createGroup => tr('createGroup');
  String get pro => tr('pro');
  String get stAvailable => tr('stAvailable');
  String get stBusy => tr('stBusy');
  String get stOnQapp => tr('stOnQapp');
  String get stMeeting => tr('stMeeting');
  String get stWork => tr('stWork');
  String get stEmergency => tr('stEmergency');
  String get stSleep => tr('stSleep');
  String get recentUpdates => tr('recentUpdates');
  String get viewedUpdates => tr('viewedUpdates');
  String get tapStatus => tr('tapStatus');
  String get pinned => tr('pinned');
  String get unpin => tr('unpin');
  String get reply => tr('reply');
  String get deleteAll => tr('deleteAll');
  String get deletedMsg => tr('deletedMsg');
  String get unmute => tr('unmute');
  String get darkMode => tr('darkMode');
  String get lightMode => tr('lightMode');
  String get forward => tr('forward');
  String get edit => tr('edit');
  String get firstName => tr('firstName');
  String get lastName => tr('lastName');
  String get tapColour => tr('tapColour');
  String get company => tr('company');
  String get email => tr('email');
  String get addNumber => tr('addNumber');
  String get birthday => tr('birthday');
  String get saveCloud => tr('saveCloud');
  String get syncHint => tr('syncHint');
  String get contactSaved => tr('contactSaved');
  String get addAnother => tr('addAnother');
  String get video => tr('video');
  String get shareContact => tr('shareContact');

  String resend(int seconds) {
    final label = tr('resend');
    if (seconds <= 0) {
      return label;
    }
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$label ($m:${s}s)';
  }

  String callStatus(String name) => tr('callStatus').replaceAll('{name}', name);
}
