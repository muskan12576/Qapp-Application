import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Services/location_helper_service.dart';
import 'package:qapp/Services/speech_service.dart';
import 'package:qapp/Services/tts_service.dart';
import 'package:qapp/Views/AiAssistantModule/model/ai_assistant_service.dart';
import 'package:qapp/Views/AiAssistantModule/widgets/gemini_live_orb.dart';
import 'package:qapp/Views/AuthModule/profile_screen.dart';
import 'package:qapp/Views/CallModule/calls_screen.dart';
import 'package:qapp/Views/CallModule/group_call_screen.dart';
import 'package:qapp/Views/CallModule/voice_call_screen.dart';
import 'package:qapp/Views/CallModule/video_call_screen.dart';
import 'package:qapp/Views/ChatModule/chat_open_screen.dart';
import 'package:qapp/Views/ChatModule/new_chat_screen.dart';
import 'package:qapp/Views/ProfileModule/settings_screen.dart';
import 'package:qapp/Views/StatusModule/status_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/main.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';

class AiVoiceAssistantSheet extends StatefulWidget {
  const AiVoiceAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiVoiceAssistantSheet(),
    );
  }

  @override
  State<AiVoiceAssistantSheet> createState() => _AiVoiceAssistantSheetState();
}

class _AiVoiceAssistantSheetState extends State<AiVoiceAssistantSheet> {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  StreamSubscription? _ttsSub;

  String _assistantPrompt = "Haan ji, boliye! Main sun rahi hoon. Kya karna hai?";
  String _recognizedSpeech = "";
  Map<String, dynamic>? _conversationContext;
  List<dynamic>? _duplicateContacts;
  AiVoiceCommandResponse? _pendingDuplicateResponse;
  Timer? _speechSilenceTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _ttsSub = TtsService.instance.onSpeakingChanged.listen((speaking) {
      if (mounted) setState(() => _isSpeaking = speaking);
    });
    _greetAndListen();
  }

  Future<void> _greetAndListen() async {
    const greeting = "Haan ji, boliye! Main sun rahi hoon. Kya karna hai?";
    await _speakAndListen(greeting, keepListening: true);
  }

  @override
  void dispose() {
    _speechSilenceTimer?.cancel();
    _ttsSub?.cancel();
    TtsService.instance.stop();
    SpeechService.instance.stopListening();
    super.dispose();
  }

  /// Central speech output + auto continuous listening loop
  Future<void> _speakAndListen(
    String prompt, {
    bool keepListening = true,
    bool isClosing = false,
  }) async {
    if (!mounted) return;
    _speechSilenceTimer?.cancel();
    setState(() {
      _assistantPrompt = prompt;
      _isSpeaking = true;
      _isListening = false;
    });

    await TtsService.instance.speak(prompt);
    if (!mounted) return;

    if (isClosing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (keepListening) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) _startVoiceRecognition();
    }
  }

  Future<void> _startVoiceRecognition() async {
    if (!mounted) return;
    _speechSilenceTimer?.cancel();
    setState(() {
      _isListening = true;
      _recognizedSpeech = "";
    });

    final started = await SpeechService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted || _isProcessing) return;
        setState(() {
          _recognizedSpeech = text;
        });

        if (isFinal && text.trim().isNotEmpty) {
          _speechSilenceTimer?.cancel();
          _onSpeechComplete(text.trim());
        } else if (text.trim().isNotEmpty) {
          // Continuous voice debounce: auto-complete after 1.3s pause in speech
          _speechSilenceTimer?.cancel();
          _speechSilenceTimer = Timer(const Duration(milliseconds: 1300), () {
            if (mounted && !_isProcessing && _recognizedSpeech.trim().isNotEmpty) {
              _onSpeechComplete(_recognizedSpeech.trim());
            }
          });
        }
      },
      onStatus: (status) {
        debugPrint('🎙️ [ASSISTANT] Speech Status: $status');
        if (status == 'notListening' || status == 'done') {
          _speechSilenceTimer?.cancel();
          if (mounted && !_isProcessing) {
            final pending = _recognizedSpeech.trim();
            _recognizedSpeech = "";
            if (pending.isNotEmpty) {
              _onSpeechComplete(pending);
            } else {
              setState(() => _isListening = false);
            }
          }
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
        _assistantPrompt = "Mic on karne ke liye orb par tap karein:";
      });
    }
  }

  Future<void> _toggleMic() async {
    HapticFeedback.selectionClick();
    _speechSilenceTimer?.cancel();
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
      final pending = _recognizedSpeech.trim();
      _recognizedSpeech = "";
      if (pending.isNotEmpty) {
        _onSpeechComplete(pending);
      }
    } else {
      await TtsService.instance.stop();
      _startVoiceRecognition();
    }
  }

  DateTime? _lastSpeechCompletedAt;

  Future<void> _onSpeechComplete(String speechText) async {
    _speechSilenceTimer?.cancel();
    if (_isProcessing) return;

    // Debounce to prevent 1 message firing multiple times within 1.5s
    final now = DateTime.now();
    if (_lastSpeechCompletedAt != null &&
        now.difference(_lastSpeechCompletedAt!) < const Duration(milliseconds: 1500)) {
      debugPrint('⚠️ [ASSISTANT] Duplicate rapid speech trigger ignored');
      return;
    }
    _lastSpeechCompletedAt = now;

    // Immediately lock processing state synchronously!
    _isProcessing = true;
    _isListening = false;
    final textToProcess = speechText.trim();
    _recognizedSpeech = "";

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _isListening = false;
        _duplicateContacts = null;
        _recognizedSpeech = textToProcess;
        _assistantPrompt = "Sun raha hoon...";
      });
    }

    try {
      await SpeechService.instance.stopListening();
    } catch (_) {}
    if (!mounted) return;

    final lower = textToProcess.toLowerCase();

    // Check if user wants to close / cancel assistant by voice
    if (lower == "cancel" ||
        lower == "band karo" ||
        lower == "band kar" ||
        lower == "hatao" ||
        lower == "ruk jao" ||
        lower == "chodo" ||
        lower == "bye" ||
        lower == "alvida" ||
        lower == "kuch nahi" ||
        lower == "kuch ni" ||
        lower == "close" ||
        lower == "rehne do") {
      await _speakAndListen(
        "Theek hai ji, jab bhi zaroorat ho awaaz de dena!",
        keepListening: false,
        isClosing: true,
      );
      return;
    }

    final response = await AiAssistantService.instance.sendVoiceCommand(
      textToProcess,
      context: _conversationContext,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (response == null) {
      await _speakAndListen(
        "Server se connect nahi ho sake ji. Dobara koshish karein?",
        keepListening: true,
      );
      return;
    }

    // Handle IGNORED_DUPLICATE from backend
    if (response.intent == "IGNORED_DUPLICATE") {
      return;
    }

    // Handle ADD_CONTACT
    if (response.intent == "ADD_CONTACT") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Naya contact add karne ki screen khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(
        qRoute(
          NewContactScreen(
            initialName: response.contactName,
            initialPhone: response.phoneNumber,
          ),
        ),
      );
      return;
    }

    // Handle OPEN_SETTINGS
    if (response.intent == "OPEN_SETTINGS") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Settings khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const SettingsScreen()));
      return;
    }

    // Handle OPEN_PROFILE
    if (response.intent == "OPEN_PROFILE") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Profile khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const ProfileScreen()));
      return;
    }

    // Handle OPEN_STATUS
    if (response.intent == "OPEN_STATUS") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Status screen khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const StatusScreen()));
      return;
    }

    // Handle OPEN_CALLS
    if (response.intent == "OPEN_CALLS") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Call history khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const CallsScreen()));
      return;
    }

    // Handle NEW_GROUP
    if (response.intent == "NEW_GROUP") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Naya group banane ki screen khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const NewGroupScreen(popCount: 1)));
      return;
    }

    // Handle OPEN_CONTACTS
    if (response.intent == "OPEN_CONTACTS") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Contacts list khol rahe hain...",
        keepListening: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalVariable.navState.currentState?.push(qRoute(const NewChatScreen()));
      return;
    }

    // Handle CLOSE_ASSISTANT
    if (response.intent == "CLOSE_ASSISTANT" || response.isClosing) {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Theek hai ji, alvida!",
        keepListening: false,
        isClosing: true,
      );
      return;
    }

    // Handle FRIENDLY_CHAT
    if (response.intent == "FRIENDLY_CHAT") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Main badhiya hoon ji! Boliye kya karna hai?",
        keepListening: true,
      );
      return;
    }

    // Handle Duplicate Contacts
    if (response.isDuplicate &&
        response.duplicateContacts != null &&
        response.duplicateContacts!.isNotEmpty) {
      setState(() {
        _duplicateContacts = response.duplicateContacts;
        _pendingDuplicateResponse = response;
      });
      await _speakAndListen(response.responsePrompt, keepListening: true);
      return;
    }

    // Handle Contact Not Found
    if (response.intent == "CONTACT_NOT_FOUND") {
      _conversationContext = null;
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Aapke contacts mein yeh naam nahi mila. Kisi aur ka naam bolein?",
        keepListening: true,
      );
      return;
    }

    // Handle Unknown Command
    if (response.intent == "UNKNOWN") {
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Main samajh nahi paya ji. Dobara bol sakte hain?",
        keepListening: true,
      );
      return;
    }

    // Handle ASK_MESSAGE_BODY (User asked to send message, but didn't specify text)
    if (response.intent == "ASK_MESSAGE_BODY") {
      _conversationContext = response.context;
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Kya message bhejna hai, boliye?",
        keepListening: true,
      );
      return;
    }

    // Handle DIRECT MAKE_CALL (Voice / Video)
    if (response.intent == "MAKE_CALL") {
      final recipient = response.recipient;
      final name = recipient?['name']?.toString() ?? 'Contact';
      final recipientId = recipient?['id']?.toString() ?? '';
      final photo = recipient?['photoUrl']?.toString();
      final isVideo = response.callType == 'video';

      await _speakAndListen(
        "$name ko ${isVideo ? 'video' : 'voice'} call mila rahe hain...",
        keepListening: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (isVideo) {
        GlobalVariable.navState.currentState?.push(
          qRoute(
            VideoCallScreen(
              name: name,
              recipientId: recipientId,
              photo: photo,
            ),
          ),
        );
      } else {
        GlobalVariable.navState.currentState?.push(
          qRoute(
            VoiceCallScreen(
              name: name,
              recipientId: recipientId,
              photo: photo,
            ),
          ),
        );
      }
      return;
    }

    // Handle GROUP_CALL (Multi-recipient group call)
    if (response.intent == "GROUP_CALL") {
      final participants = response.recipients ?? [];
      final names = participants
          .map((p) => p['name']?.toString() ?? 'Contact')
          .join(' aur ');
      final pIds = participants
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final isVideo = response.callType == 'video';

      await _speakAndListen(
        "$names ke sath group call connect kar rahe hain...",
        keepListening: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      GlobalVariable.navState.currentState?.push(
        qRoute(
          GroupCallScreen(
            groupName: names,
            roomId: 'group_${DateTime.now().millisecondsSinceEpoch}',
            participantIds: pIds,
            isVideo: isVideo,
          ),
        ),
      );
      return;
    }

    // Handle SEND_GROUP_MESSAGE
    if (response.intent == "SEND_GROUP_MESSAGE" ||
        (response.intent == "MESSAGE_SENT" && response.group != null)) {
      _conversationContext = null;
      HapticFeedback.heavyImpact();
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Group mein message daal diya! Aur koi kaam hai?",
        keepListening: true,
      );
      return;
    }

    // Handle SEND_MESSAGE
    if (response.intent == "SEND_MESSAGE" || response.intent == "MESSAGE_SENT") {
      _conversationContext = null;
      HapticFeedback.heavyImpact();
      await _speakAndListen(
        response.responsePrompt.isNotEmpty
            ? response.responsePrompt
            : "Message bhej diya! Aur koi kaam hai?",
        keepListening: true,
      );
      return;
    }

    // Handle SHARE_LOCATION
    if (response.intent == "SHARE_LOCATION") {
      final recipient = response.recipient;
      if (recipient != null) {
        final name = recipient['name']?.toString() ?? 'Contact';
        final recipientId = recipient['id']?.toString() ?? '';
        final existingChatId = recipient['chatId']?.toString();

        setState(() {
          _isProcessing = true;
          _assistantPrompt = "$name ke sath GPS location share kar rahe hain...";
        });

        final loc = await LocationHelperService.instance.getCurrentLocation();
        if (!mounted) return;

        if (loc == null) {
          setState(() => _isProcessing = false);
          await _speakAndListen(
            "Phone ki GPS location on karein, tabhi location bhej sakte hain.",
            keepListening: true,
          );
          return;
        }

        final execResult = await AiAssistantService.instance.executeAction(
          intent: 'SHARE_LOCATION',
          recipientId: recipientId,
          chatId: existingChatId,
          latitude: loc.latitude,
          longitude: loc.longitude,
          mapsUrl: loc.mapsUrl,
        );

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (execResult != null && execResult['success'] == true) {
          HapticFeedback.heavyImpact();
          await _speakAndListen(
            "$name ko location bhej di gayi hai! Aur koi kaam hai?",
            keepListening: true,
          );
        } else {
          await _speakAndListen(
            "Location share karne mein dikkat aayi. Dobara try karein?",
            keepListening: true,
          );
        }
      }
      return;
    }

    // Handle OPEN_CHAT
    if (response.intent == "OPEN_CHAT") {
      final recipient = response.recipient;
      final name = recipient?['name']?.toString() ?? 'Contact';

      await _speakAndListen(
        "$name ki chat khol rahe hain...",
        keepListening: false,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ChatThread? thread = threadFor(name);
      if (thread == null) {
        thread = ChatThread(
          name: name,
          header: name,
          colorIndex: 1,
          phone: recipient?['phone']?.toString() ?? '',
          about: recipient?['about']?.toString() ?? 'On Qapp',
          time: 'Now',
          preview: 'Chat',
          messages: [],
          chatId: recipient?['chatId']?.toString(),
          peerId: recipient?['id']?.toString(),
          photo: recipient?['photoUrl']?.toString(),
        );
        ChatBook.instance.threads.insert(0, thread);
      }
      GlobalVariable.navState.currentState?.push(
        qRoute(ChatOpenScreen(thread: thread)),
      );
      return;
    }
  }

  void _selectDuplicateContact(Map<String, dynamic> contact) {
    HapticFeedback.lightImpact();
    setState(() {
      _duplicateContacts = null;
    });
    if (_pendingDuplicateResponse != null) {
      final name = contact['name']?.toString() ?? 'Contact';
      _onSpeechComplete("$name ko call laga");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet Grab Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),

              // Clean Header with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF4285F4),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Qapp AI Voice Assistant",
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.muted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pure Glowing Gemini Live Orb (Interactive)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GeminiLiveOrb(
                      size: 175,
                      isListening: _isListening,
                      isSpeaking: _isSpeaking,
                      onTap: _toggleMic,
                    ),
                    if (_isProcessing)
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Assistant Response Speech Bubble (Warm, Friendly dialogue)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFFE8F0FE)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isListening
                        ? const Color(0xFF4285F4).withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isListening
                          ? Icons.mic_rounded
                          : (_isSpeaking
                              ? Icons.volume_up_rounded
                              : Icons.chat_bubble_outline_rounded),
                      size: 22,
                      color: _isListening
                          ? const Color(0xFF1967D2)
                          : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _assistantPrompt,
                        style: TextStyle(
                          color: _isListening
                              ? const Color(0xFF174EA6)
                              : Colors.black87,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Speech Transcript
              if (_recognizedSpeech.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '"$_recognizedSpeech"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Duplicate Contacts (if multiple contacts share same name)
              if (_duplicateContacts != null &&
                  _duplicateContacts!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _duplicateContacts!.map((contact) {
                    final cMap = Map<String, dynamic>.from(contact);
                    final cName = cMap['name']?.toString() ?? 'Contact';
                    final cPhone = cMap['phone']?.toString() ?? '';
                    return ActionChip(
                      avatar: QAvatar(name: cName, size: 24, colorIndex: 2),
                      label: Text('$cName ($cPhone)'),
                      onPressed: () => _selectDuplicateContact(cMap),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
