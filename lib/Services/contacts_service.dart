import 'package:flutter/services.dart';

class ContactItem {
  final String name;
  final String phone;
  final String? photo;
  final bool isRegistered;
  final String? userId;
  final String? about;

  const ContactItem({
    required this.name,
    required this.phone,
    this.photo,
    this.isRegistered = false,
    this.userId,
    this.about,
  });
}

class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  static const _channel = MethodChannel('qapp/contacts');

  Future<bool> hasPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('hasPermission');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestPermission');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ContactItem>> fetchContacts({List<Map<String, dynamic>>? registeredPeers}) async {
    try {
      final raw = await _channel.invokeListMethod<Map>('getContacts');
      if (raw == null) return [];

      // Build map of registered peers by cleaned phone number
      final peerPhoneMap = <String, Map<String, dynamic>>{};
      if (registeredPeers != null) {
        for (final p in registeredPeers) {
          final pPhone = _cleanPhone(p['phone']?.toString() ?? '');
          if (pPhone.isNotEmpty) {
            peerPhoneMap[pPhone] = p;
          }
        }
      }

      final list = <ContactItem>[];
      for (final item in raw) {
        final name = item['name']?.toString() ?? '';
        final rawPhone = item['phone']?.toString() ?? '';
        final photo = item['photo']?.toString();
        final clean = _cleanPhone(rawPhone);

        // Check matching registered peer
        Map<String, dynamic>? match;
        if (clean.isNotEmpty) {
          match = peerPhoneMap[clean];
          if (match == null && clean.length >= 10) {
            final last10 = clean.substring(clean.length - 10);
            for (final entry in peerPhoneMap.entries) {
              if (entry.key.endsWith(last10)) {
                match = entry.value;
                break;
              }
            }
          }
        }

        list.add(
          ContactItem(
            name: name.isNotEmpty ? name : rawPhone,
            phone: rawPhone,
            photo: match?['profile_image_url']?.toString() ?? photo,
            isRegistered: match != null,
            userId: match?['id']?.toString(),
            about: match?['about']?.toString(),
          ),
        );
      }

      // Sort: registered users first, then alphabetically
      list.sort((a, b) {
        if (a.isRegistered != b.isRegistered) {
          return a.isRegistered ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return list;
    } catch (_) {
      return [];
    }
  }

  String _cleanPhone(String p) {
    return p.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
