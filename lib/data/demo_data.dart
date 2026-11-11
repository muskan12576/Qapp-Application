import 'package:flutter/foundation.dart';

enum ChatKind { text, image, pdf, doc, audio, video, contact }

enum Tick { sent, delivered, read }

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.mine,
    this.time,
    this.kind = ChatKind.text,
    this.bytes,
    this.asset,
    this.path,
    this.tick = Tick.read,
    this.starred = false,
    this.replyName,
    this.replyText,
    this.deleted = false,
    this.forwarded = false,
  });

  final String text;
  final bool mine;
  final String? time;
  final ChatKind kind;
  final Uint8List? bytes;
  final String? asset;
  final String? path;
  final String? replyName;
  final String? replyText;
  Tick tick;
  bool starred;
  bool deleted;
  bool forwarded;
}

class ChatThread {
  ChatThread({
    required this.name,
    required this.header,
    required this.time,
    required this.preview,
    required this.colorIndex,
    required this.messages,
    required this.phone,
    required this.about,
    this.photo,
    this.photoBytes,
    this.unread = 0,
    this.favourite = false,
    this.pinned = false,
    this.muted = false,
    this.blocked = false,
    this.groups = const [],
    this.disappear = 'off',
    this.themeIndex = 0,
    this.listName,
    this.online = false,
  });

  final String name;
  final String header;
  final int colorIndex;
  final String phone;
  final String about;
  final String? photo;
  final Uint8List? photoBytes;
  final List<ChatMessage> messages;
  final List<String> groups;

  String time;
  String preview;
  int unread;
  bool favourite;
  bool pinned;
  bool muted;
  bool blocked;
  String disappear;
  int themeIndex;
  String? listName;
  final bool online;
}

Uint8List demoNotesPdf() {
  const raw =
      '%PDF-1.4\n'
      '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
      '2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n'
      '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 300 200]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj\n'
      '4 0 obj<</Length 41>>stream\n'
      'BT /F1 18 Tf 36 110 Td (Qapp notes) Tj ET\n'
      'endstream\n'
      'endobj\n'
      '5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\n'
      'xref\n'
      '0 6\n'
      '0000000000 65535 f \n'
      '0000000009 00000 n \n'
      '0000000052 00000 n \n'
      '0000000101 00000 n \n'
      '0000000211 00000 n \n'
      '0000000298 00000 n \n'
      'trailer<</Size 6/Root 1 0 R>>\n'
      'startxref\n'
      '359\n'
      '%%EOF\n';
  return Uint8List.fromList(raw.codeUnits);
}

class MyProfile {
  static Uint8List? photo;
  static String name = '';
  static String bio = '';
}

class ShareContact {
  const ShareContact(this.name, this.phone, this.colorIndex, {this.photo});

  final String name;
  final String phone;
  final int colorIndex;
  final String? photo;
}

const shareContacts = <ShareContact>[
  ShareContact('Aapna Naam', '+91 98765 43210', 0, photo: 'assets/images/avatars/aapna.jpg'),
  ShareContact('Aman Bahani', '+91 98111 22334', 1, photo: 'assets/images/avatars/aman.jpg'),
  ShareContact('Aman Bouu', '+91 97654 11002', 2, photo: 'assets/images/avatars/bouu.jpg'),
  ShareContact('Amrit Reban', '+91 90000 11223', 3, photo: 'assets/images/avatars/amrit.jpg'),
  ShareContact('Riya Sen', '+91 98100 11001', 4),
  ShareContact('Kabir Shah', '+91 98200 22002', 0),
  ShareContact('Neha Kapoor', '+91 98300 33003', 1),
  ShareContact('Arjun Mehta', '+91 98400 44004', 2),
  ShareContact('Sana Qureshi', '+91 98500 55005', 3),
  ShareContact('Dev Patel', '+91 98600 66006', 4),
  ShareContact('Meera Joshi', '+91 98700 77007', 0),
  ShareContact('Rohan Iyer', '+91 98800 88008', 1),
  ShareContact('Pooja Nair', '+91 98900 99009', 2),
  ShareContact('Ishaan Gill', '+91 99000 10101', 3),
  ShareContact('Ananya Rao', '+91 99100 20202', 4),
  ShareContact('Vikram Das', '+91 99200 30303', 0),
  ShareContact('Tara Singh', '+91 99300 40404', 1),
  ShareContact('Yash Malhotra', '+91 99400 50505', 2),
  ShareContact('Kiara Bose', '+91 99500 60606', 3),
  ShareContact('Omar Khan', '+91 99600 70707', 4),
];

class ChatBook extends ChangeNotifier {
  ChatBook._();

  static final ChatBook instance = ChatBook._();

  final List<ChatThread> threads = [
    ChatThread(
      name: 'Aapna Naam',
      header: 'Aapna Naam',
      time: '2:31 AM',
      preview: 'Haan, dekh liya.',
      colorIndex: 0,
      phone: '+91 98765 43210',
      about: 'Hey there, Qapp use kar rahi hoon',
      photo: 'assets/images/avatars/aapna.jpg',
      unread: 3,
      pinned: true,
      online: true,
      groups: const ['Family'],
      messages: [
        ChatMessage(
          text: 'Latest messages av...',
          mine: false,
          time: '2:28 AM',
        ),
        ChatMessage(
          text: 'Haan, dekh liya.',
          mine: true,
          time: '2:31 AM',
          tick: Tick.delivered,
        ),
      ],
    ),
    ChatThread(
      name: 'Aman Bahani',
      header: 'Aman',
      time: '1:23 PM',
      preview: 'Haan bhai, kya haal?',
      colorIndex: 1,
      phone: '+91 98111 22334',
      about: 'Office ke baad free hoon',
      photo: 'assets/images/avatars/aman.jpg',
      favourite: true,
      muted: true,
      groups: const ['Family', 'Office'],
      messages: [
        ChatMessage(
          text: 'Photo',
          mine: false,
          time: '1:10 PM',
          kind: ChatKind.image,
          asset: 'assets/images/avatars/aapna.jpg',
        ),
        ChatMessage(
          text: 'Photo',
          mine: true,
          time: '1:12 PM',
          kind: ChatKind.image,
          asset: 'assets/images/avatars/amrit.jpg',
          tick: Tick.read,
        ),
        ChatMessage(text: 'Haan bhai, kya haal?', mine: false, time: '1:20 PM'),
        ChatMessage(
          text: 'Haan bhai, kya haal?',
          mine: true,
          time: '1:22 PM',
          tick: Tick.read,
        ),
        ChatMessage(
          text: 'Sab badhiya! Aap batao',
          mine: false,
          time: '1:22 PM',
        ),
        ChatMessage(
          text: 'Haan bhai, kya haal?',
          mine: true,
          time: '1:23 PM',
          tick: Tick.read,
        ),
      ],
    ),
    ChatThread(
      name: 'Aman Bouu',
      header: 'Aman Bouu',
      time: '9:10 PM',
      preview: 'Kal baat karte hain.',
      colorIndex: 2,
      phone: '+91 97654 11002',
      about: 'Kal milte hain',
      photo: 'assets/images/avatars/bouu.jpg',
      unread: 1,
      online: true,
      groups: const ['Qapp Friends'],
      messages: [
        ChatMessage(
          text: 'Latest messages av...',
          mine: false,
          time: '9:04 PM',
        ),
        ChatMessage(
          text: 'notes.pdf',
          mine: true,
          time: '9:08 PM',
          kind: ChatKind.pdf,
          bytes: demoNotesPdf(),
          tick: Tick.delivered,
        ),
        ChatMessage(
          text: 'Kal baat karte hain.',
          mine: true,
          time: '9:10 PM',
          tick: Tick.sent,
        ),
      ],
    ),
    ChatThread(
      name: 'Amrit Reban',
      header: 'Amrit Reban',
      time: 'Now',
      preview: 'Hall',
      colorIndex: 3,
      phone: '+91 90000 11223',
      about: 'Status dekho',
      photo: 'assets/images/avatars/amrit.jpg',
      unread: 4,
      favourite: true,
      listName: 'Close',
      groups: const ['College'],
      messages: [
        ChatMessage(text: 'Hall', mine: false, time: 'Now'),
        ChatMessage(
          text: 'Haan bhai, bol.',
          mine: true,
          time: 'Now',
          tick: Tick.read,
        ),
      ],
    ),
    ChatThread(
      name: 'Family',
      header: 'Family',
      time: '8:41 PM',
      preview: 'Photo bhej dena.',
      colorIndex: 2,
      phone: '',
      about: 'Family group',
      unread: 2,
      groups: const ['Aapna Naam', 'Aman Bahani', 'Amrit Reban'],
      messages: [
        ChatMessage(text: 'Good morning sabko.', mine: false, time: '8:01 AM'),
        ChatMessage(text: 'Morning! Chai ready hai.', mine: true, time: '8:04 AM', tick: Tick.read),
        ChatMessage(text: 'Aaj shaam ko kaun free hai?', mine: false, time: '11:16 AM'),
        ChatMessage(text: 'Main 6 baje ke baad free hoon.', mine: true, time: '11:20 AM', tick: Tick.read),
        ChatMessage(
          text: 'Park mein milte hain.',
          mine: false,
          time: '11:28 AM',
          replyName: 'Aman',
          replyText: 'Main 6 baje ke baad free hoon.',
        ),
        ChatMessage(text: 'Theek hai, main bhi aaunga.', mine: false, time: '11:31 AM'),
        ChatMessage(text: 'Kids ko bhi le aana.', mine: false, time: '2:05 PM'),
        ChatMessage(
          text: 'Haan, unke liye juice le lunga.',
          mine: true,
          time: '2:12 PM',
          tick: Tick.read,
          replyName: 'Aapna',
          replyText: 'Kids ko bhi le aana.',
        ),
        ChatMessage(text: 'Dinner ghar par hi rakhte hain.', mine: false, time: '4:40 PM'),
        ChatMessage(text: 'Menu bata dena, main market se laata hoon.', mine: true, time: '4:44 PM', tick: Tick.read),
        ChatMessage(text: 'Daal, roti, aur salad kaafi hai.', mine: false, time: '4:51 PM'),
        ChatMessage(text: 'Koi meetha bhi rakh lena.', mine: false, time: '5:02 PM'),
        ChatMessage(
          text: 'Gulab jamun le aata hoon.',
          mine: true,
          time: '5:10 PM',
          tick: Tick.delivered,
          replyName: 'Amrit',
          replyText: 'Koi meetha bhi rakh lena.',
        ),
        ChatMessage(text: 'Barish ka chance hai, jaldi nikalna.', mine: false, time: '7:18 PM'),
        ChatMessage(text: 'Main 6:10 par nikal raha hoon.', mine: true, time: '7:22 PM', tick: Tick.read),
        ChatMessage(text: 'Gate par milte hain.', mine: false, time: '8:36 PM'),
        ChatMessage(text: 'Photo bhej dena.', mine: true, time: '8:41 PM', tick: Tick.sent),
      ],
    ),
    ChatThread(
      name: 'Office',
      header: 'Office',
      time: '6:05 PM',
      preview: 'Notes kal subah bhej dunga.',
      colorIndex: 1,
      phone: '',
      about: 'Office group',
      unread: 1,
      groups: const ['Aman Bahani', 'Aapna Naam'],
      messages: [
        ChatMessage(text: 'Standup 10:30 par hai.', mine: false, time: '9:12 AM'),
        ChatMessage(text: 'Main join kar lunga.', mine: true, time: '9:14 AM', tick: Tick.read),
        ChatMessage(text: 'Client ne homepage change maanga hai.', mine: false, time: '10:02 AM'),
        ChatMessage(text: 'Kaunsa section?', mine: true, time: '10:05 AM', tick: Tick.read),
        ChatMessage(
          text: 'Hero aur pricing dono.',
          mine: false,
          time: '10:08 AM',
          replyName: 'Aman',
          replyText: 'Kaunsa section?',
        ),
        ChatMessage(text: 'Main design aaj shaam tak de dunga.', mine: false, time: '10:21 AM'),
        ChatMessage(text: 'Copy short rakhna, mobile par padhna hai.', mine: true, time: '10:26 AM', tick: Tick.read),
        ChatMessage(text: 'API 3 baje tak ready hogi.', mine: false, time: '1:15 PM'),
        ChatMessage(text: 'Main tab tak screens jod leta hoon.', mine: true, time: '1:18 PM', tick: Tick.read),
        ChatMessage(text: 'Bug list group mein daal di hai.', mine: false, time: '3:40 PM'),
        ChatMessage(
          text: 'Pehle login wala fix karta hoon.',
          mine: true,
          time: '3:46 PM',
          tick: Tick.delivered,
          replyName: 'Aman',
          replyText: 'Bug list group mein daal di hai.',
        ),
        ChatMessage(text: 'Review call 6 baje shift kar do.', mine: false, time: '5:12 PM'),
        ChatMessage(text: 'Done, invite bhej diya.', mine: true, time: '5:20 PM', tick: Tick.read),
        ChatMessage(text: 'Koi slides ready hai?', mine: false, time: '5:48 PM'),
        ChatMessage(text: 'Notes kal subah bhej dunga.', mine: true, time: '6:05 PM', tick: Tick.sent),
      ],
    ),
  ];

  void ping() => notifyListeners();

  void add(ChatThread thread) {
    threads.insert(0, thread);
    notifyListeners();
  }

  void remove(ChatThread thread) {
    threads.remove(thread);
    notifyListeners();
  }
}

class DemoPerson {
  const DemoPerson(this.name, this.colorIndex, {this.photo, this.caption = ''});

  final String name;
  final int colorIndex;
  final String? photo;
  final String caption;
}

class StatusUpdate {
  StatusUpdate({required this.caption, required this.time, this.bytes});

  final String caption;
  final String time;
  final Uint8List? bytes;
}

class StatusBook extends ChangeNotifier {
  StatusBook._();

  static final StatusBook instance = StatusBook._();

  final List<StatusUpdate> mine = [];

  void add(StatusUpdate update) {
    mine.insert(0, update);
    notifyListeners();
  }
}

class DemoCall {
  const DemoCall(this.name, this.time);

  final String name;
  final String time;
}

const statusFriends = <DemoPerson>[
  DemoPerson('Roundoria', 3, photo: 'assets/images/avatars/amrit.jpg', caption: 'Evening walk by the lake'),
  DemoPerson('Friendling', 1, photo: 'assets/images/avatars/aman.jpg', caption: 'New song on repeat'),
  DemoPerson('Friends', 4, photo: 'assets/images/avatars/aapna.jpg', caption: 'Coffee before work'),
];

const callHistory = <DemoCall>[
  DemoCall('Aman', '2:30 AM'),
  DemoCall('Aapna Naam', 'Yesterday'),
  DemoCall('Amrit Reban', 'Yesterday'),
  DemoCall('Aman Bahani', 'Mon'),
];

ChatThread? threadFor(String name) {
  for (final thread in ChatBook.instance.threads) {
    if (thread.name == name || thread.header == name) {
      return thread;
    }
  }
  return null;
}
