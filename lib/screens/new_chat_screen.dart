import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/countries.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/chat_open_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ChatThread> get _people {
    final query = _search.text.trim().toLowerCase();
    return ChatBook.instance.threads.where((thread) {
      if (query.isEmpty) {
        return true;
      }
      return thread.name.toLowerCase().contains(query) ||
          thread.phone.toLowerCase().contains(query);
    }).toList();
  }

  void _openChat(ChatThread thread) {
    Navigator.of(context).pop(thread);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final people = _people;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        s.newChat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: AppColors.ink),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: s.search,
                    hintStyle: TextStyle(color: AppColors.faint),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.faint,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _action(Icons.group_add_rounded, s.newGroup, () {
                        Navigator.of(context).push(
                          qRoute(const NewGroupScreen(popCount: 2)),
                        );
                      }),
                      Divider(height: 1, color: AppColors.line),
                      _action(Icons.person_add_alt_1_rounded, s.newContact, () {
                        Navigator.of(
                          context,
                        ).push(qRoute(const _NewContactScreen()));
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    s.frequent,
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return ListTile(
                      onTap: () => _openChat(person),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: QAvatar(
                        name: person.name,
                        size: 46,
                        colorIndex: person.colorIndex,
                        photo: person.photo,
                      ),
                      title: Text(
                        person.name,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(person.phone, style: AppText.subtitle),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NewContactScreen extends StatefulWidget {
  const _NewContactScreen();

  @override
  State<_NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<_NewContactScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _extra = <TextEditingController>[];
  Uint8List? _photo;
  var _color = 2;
  var _cloud = true;
  Country _country = countryByIso('IN');
  DateTime? _birthday;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _company.dispose();
    _phone.dispose();
    _email.dispose();
    for (final box in _extra) {
      box.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image, compressionQuality: 55);
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _photo = bytes);
    } catch (_) {}
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              for (final country in countries)
                ListTile(
                  title: Text(
                    '${country.flag}  ${country.iso}  +${country.dial}',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(country.name, style: AppText.subtitle),
                  onTap: () => Navigator.pop(context, country),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _birthday = picked);
    }
  }

  void _save() {
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.isEmpty) {
      return;
    }
    final name = last.isEmpty ? first : '$first $last';
    final dial = '+${_country.dial}';
    final main = _phone.text.trim().isEmpty ? dial : '$dial ${_phone.text.trim()}';
    final bits = <String>[
      if (_company.text.trim().isNotEmpty) _company.text.trim(),
      if (_email.text.trim().isNotEmpty) _email.text.trim(),
      for (final box in _extra)
        if (box.text.trim().isNotEmpty) '$dial ${box.text.trim()}',
      if (_birthday != null)
        '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}',
    ];
    final thread = ChatThread(
      name: name,
      header: name,
      time: S.of(context).now,
      preview: '',
      colorIndex: _color,
      phone: main,
      about: bits.join(' · '),
      photoBytes: _photo,
      messages: [],
    );
    ChatBook.instance.add(thread);
    Navigator.of(context).pushReplacement(qRoute(_SavedContact(thread: thread)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final day = _birthday == null
        ? 'mm/dd/yyyy'
        : '${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.year}';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text(
                        s.newContact,
                        style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _save,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            s.save,
                            style: const TextStyle(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _color = (_color + 1) % 5),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
                              ),
                              child: _photo == null
                                  ? Container(
                                      width: 96,
                                      height: 96,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accent,
                                      ),
                                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
                                    )
                                  : QAvatar(
                                      name: _first.text.trim().isEmpty ? 'Q' : _first.text.trim(),
                                      size: 96,
                                      colorIndex: _color,
                                      bytes: _photo,
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 2,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.accent, width: 1.4),
                                  ),
                                  child: const Icon(Icons.photo_camera_rounded, size: 15, color: AppColors.accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.tapColour,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.faint, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    _line(Icons.person_outline_rounded, s.firstName, _first, onChanged: (_) => setState(() {})),
                    _line(null, s.lastName, _last),
                    _line(Icons.work_outline_rounded, s.company, _company),
                    _phoneLine(s),
                    for (var i = 0; i < _extra.length; i++)
                      _line(Icons.phone_outlined, s.phoneHint, _extra[i], number: true),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _extra.add(TextEditingController())),
                        icon: const Icon(Icons.add, color: AppColors.accent, size: 18),
                        label: Text(
                          s.addNumber,
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    _line(Icons.mail_outline_rounded, s.email, _email, type: TextInputType.emailAddress),
                    InkWell(
                      onTap: _pickBirthday,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.birthday,
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(day, style: TextStyle(color: AppColors.faint, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Divider(height: 1, color: AppColors.line),
                                ],
                              ),
                            ),
                            Icon(Icons.calendar_today_rounded, color: AppColors.inkSoft, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_outlined, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.saveCloud,
                                  style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                                ),
                                Text(s.syncHint, style: TextStyle(color: AppColors.faint, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _cloud,
                            activeThumbColor: AppColors.accent,
                            onChanged: (value) => setState(() => _cloud = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(
    IconData? icon,
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool number = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 28,
            child: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Icon(icon, color: AppColors.inkSoft, size: 20),
                  ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: number ? TextInputType.phone : type,
              textCapitalization: type == TextInputType.name || type == TextInputType.text
                  ? TextCapitalization.words
                  : TextCapitalization.none,
              onChanged: onChanged,
              inputFormatters: number
                  ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)]
                  : null,
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.faint),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.line)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneLine(S s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Icon(Icons.phone_outlined, color: AppColors.inkSoft, size: 20),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _pickCountry,
              child: Row(
                children: [
                  Text(
                    '${_country.iso}  +${_country.dial}',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: s.phoneHint,
                hintStyle: TextStyle(color: AppColors.faint),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.line)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedContact extends StatelessWidget {
  const _SavedContact({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 22),
                Text(
                  s.contactSaved,
                  style: TextStyle(color: AppColors.ink, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                QAvatar(
                  name: thread.name,
                  size: 72,
                  colorIndex: thread.colorIndex,
                  bytes: thread.photoBytes,
                ),
                const SizedBox(height: 12),
                Text(
                  thread.name,
                  style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(thread.phone, style: TextStyle(color: AppColors.faint)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(qRoute(const _NewContactScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.line),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(s.addAnother, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(qRoute(ChatOpenScreen(thread: thread)));
                          },
                          child: Text(
                            s.messageHint,
                            style: const TextStyle(color: AppColors.onAccent, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key, this.popCount = 1});

  final int popCount;

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

const _groupIcons = <(IconData, Color)>[
  (Icons.groups_rounded, Color(0xFF3DDC97)),
  (Icons.celebration_rounded, Color(0xFFE06AD4)),
  (Icons.work_rounded, Color(0xFFE0A15A)),
  (Icons.palette_rounded, Color(0xFF5AA7E0)),
  (Icons.sports_esports_rounded, Color(0xFFB07CFF)),
  (Icons.park_rounded, Color(0xFF7DDC6A)),
];

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  final _picked = <ChatThread>{};
  var _step = 0;
  var _icon = 0;
  var _adminsOnly = false;
  var _vanish = true;

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    ChatBook.instance.add(
      ChatThread(
        name: name,
        header: name,
        time: S.of(context).now,
        preview: '',
        colorIndex: 2,
        phone: '',
        about: S.of(context).groups,
        messages: [],
        groups: _picked.map((person) => person.name).toList(),
        disappear: _vanish ? '24h' : 'off',
      ),
    );
    final pops = widget.popCount;
    Navigator.of(context).pop();
    if (pops > 1 && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _pickStep(S s) {
    final query = _search.text.trim().toLowerCase();
    final people = ChatBook.instance.threads.where((thread) {
      if (thread.phone.trim().isEmpty) {
        return false;
      }
      return query.isEmpty || thread.name.toLowerCase().contains(query);
    }).toList();
    return Column(
      children: [
        if (_picked.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final person in _picked)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: QAvatar(
                        name: person.name,
                        size: 22,
                        colorIndex: person.colorIndex,
                        photo: person.photo,
                        bytes: person.photoBytes,
                      ),
                      label: Text(person.name.split(' ').first),
                      labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                      deleteIcon: Icon(Icons.close_rounded, size: 16, color: AppColors.inkSoft),
                      onDeleted: () => setState(() => _picked.remove(person)),
                      backgroundColor: AppColors.card,
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppColors.ink),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: s.search,
              hintStyle: TextStyle(color: AppColors.faint),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.faint),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              final on = _picked.contains(person);
              return ListTile(
                onTap: () {
                  setState(() {
                    if (on) {
                      _picked.remove(person);
                    } else {
                      _picked.add(person);
                    }
                  });
                },
                leading: QAvatar(
                  name: person.name,
                  photo: person.photo,
                  bytes: person.photoBytes,
                  colorIndex: person.colorIndex,
                ),
                title: Text(person.name, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                subtitle: Text(person.about, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle),
                trailing: Icon(
                  on ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: on ? AppColors.accent : AppColors.faint,
                ),
              );
            },
          ),
        ),
        if (_picked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  height: 36,
                  child: Stack(
                    children: [
                      for (var i = 0; i < _picked.length && i < 3; i++)
                        Positioned(
                          left: i * 18,
                          child: QAvatar(
                            name: _picked.elementAt(i).name,
                            size: 32,
                            colorIndex: _picked.elementAt(i).colorIndex,
                            photo: _picked.elementAt(i).photo,
                            bytes: _picked.elementAt(i).photoBytes,
                          ),
                        ),
                    ],
                  ),
                ),
                Text('${_picked.length} ${s.picked}', style: TextStyle(color: AppColors.inkSoft)),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton(
                    onPressed: () => setState(() => _step = 1),
                    child: Text(s.nextGo, style: AppText.button),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _detailStep(S s) {
    final icon = _groupIcons[_icon];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
            ),
            child: Icon(icon.$1, color: AppColors.ink, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: s.groupHint,
            hintStyle: TextStyle(color: AppColors.faint),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        Text(s.chooseIcon, style: AppText.subtitle),
        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _groupIcons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _groupIcons[index];
              final on = index == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = index),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: on ? AppColors.accent : Colors.transparent, width: 1.6),
                  ),
                  child: Icon(item.$1, color: item.$2),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminOnly, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          value: _adminsOnly,
          activeThumbColor: AppColors.accent,
          onChanged: (value) => setState(() => _adminsOnly = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.vanish24, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          value: _vanish,
          activeThumbColor: AppColors.accent,
          onChanged: (value) => setState(() => _vanish = value),
        ),
        Text(s.members, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final person in _picked)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                QAvatar(
                  name: person.name,
                  size: 46,
                  colorIndex: person.colorIndex,
                  photo: person.photo,
                  bytes: person.photoBytes,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                      ),
                      if (person.phone.trim().isNotEmpty)
                        Text(person.phone, style: TextStyle(color: AppColors.faint, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextButton(
            onPressed: _create,
            child: Text(s.createGroup, style: AppText.button),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step == 1) {
                          setState(() => _step = 0);
                          return;
                        }
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0 ? s.newGroup : s.groupDetails,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_step == 0)
                            Text(
                              '${_picked.length} ${s.picked}',
                              style: AppText.subtitle,
                            ),
                        ],
                      ),
                    ),
                    if (_step == 0)
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(qRoute(const _NewContactScreen()));
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 18),
                        label: Text(
                          s.newContact,
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _step == 0 ? _pickStep(s) : _detailStep(s)),
            ],
          ),
        ),
      ),
    );
  }
}
