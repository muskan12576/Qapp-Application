import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Views/AiAssistantModule/ai_voice_assistant_sheet.dart';
import 'package:qapp/Views/AiAssistantModule/model/ai_assistant_vm.dart';
import 'package:qapp/Views/AiAssistantModule/widgets/gemini_live_orb.dart';
import 'package:qapp/Views/ChatModule/chat_open_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AiVoiceAssistantSheet.show(context);
  }

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  bool _isListening = true;
  bool _isSpeaking = false;
  bool _isSuccess = false;
  String _assistantPrompt = "Boliye, kya bhejna hai?";
  String _recognizedSpeech = "";
  Timer? _speechCycleTimer;

  final List<String> _quickCommands = [
    "Muskan ko meri current location share kar",
    "1 hour ke liye live location bhejo",
    "Aman ko message: Main 10 min me aa raha hu",
    "Rahul ko voice call lagao",
  ];

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    // Start initial listening animation
    _speechCycleTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _assistantPrompt = "Suniye! Main sun rahi hu... Boliye:";
        });
      }
    });
  }

  @override
  void dispose() {
    _speechCycleTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCommand(String text) async {
    HapticFeedback.lightImpact();
    setState(() {
      _recognizedSpeech = text;
      _isListening = false;
      _isSpeaking = true;
      _assistantPrompt = "Command samajh raha hu...";
    });

    final res = AiAssistantViewModel.instance.parseCommand(text);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (res.intent == AiIntent.unknown || res.matchedThread == null) {
      // If no direct thread match, check if we have any active thread to use as fallback
      final firstThread = AiAssistantViewModel.instance.findDefaultThread();
      if (firstThread != null) {
        final fallbackRes = AiCommandResult(
          intent: res.intent == AiIntent.unknown ? AiIntent.shareLocation : res.intent,
          contactName: firstThread.header,
          matchedThread: firstThread,
          messageText: res.messageText ?? "Hi, meri current location check karein",
          durationText: res.durationText ?? "1 hour",
          durationHours: res.durationHours,
          rawQuery: text,
          explanation: "${firstThread.header} ko location bheji ja rahi hai",
        );
        return _completeExecution(fallbackRes);
      }

      setState(() {
        _isSpeaking = false;
        _isListening = true;
        _assistantPrompt = "Contact nahi mila. Kripya dobara bolein.";
      });
      return;
    }

    await _completeExecution(res);
  }

  Future<void> _completeExecution(AiCommandResult res) async {
    final contact = res.contactName ?? res.matchedThread?.header ?? "Contact";
    final success = await AiAssistantViewModel.instance.executeCommand(res);

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSuccess = true;
        _isSpeaking = true;
        _isListening = false;
        _assistantPrompt = "$contact ko aapki live location bhej di gayi hai!";
      });

      // Voice Feedback delay then auto navigate directly to chat
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      Navigator.of(context).pop();

      if (res.matchedThread != null) {
        Navigator.of(context).push(
          qRoute(ChatOpenScreen(thread: res.matchedThread!)),
        );
      }
    } else {
      setState(() {
        _isSpeaking = false;
        _isListening = true;
        _assistantPrompt = "Command execute nahi ho saka. Dobara koshish karein.";
      });
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
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),

              // Title matching screenshot: "Choose your voice" / "Qapp AI Assistant"
              Text(
                "Choose your voice",
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),

              // The Beautiful Gemini Ethereal Blue Wave Orb
              Center(
                child: GeminiLiveOrb(
                  size: 190,
                  isListening: _isListening,
                  isSpeaking: _isSpeaking,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isListening = !_isListening;
                      _assistantPrompt = _isListening
                          ? "Boliye, kya bhejna hai?"
                          : "Paused. Tap orb to speak.";
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Alexa / Assistant Speech Feedback Box
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF81C784)
                        : const Color(0xFFD2E3FC),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_rounded
                          : (_isListening ? Icons.mic_rounded : Icons.graphic_eq_rounded),
                      size: 20,
                      color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFF1967D2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _assistantPrompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isSuccess
                              ? const Color(0xFF1B5E20)
                              : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_recognizedSpeech.isNotEmpty && !_isSuccess) ...[
                const SizedBox(height: 12),
                Text(
                  '"$_recognizedSpeech"',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Quick Voice Command Pills (Discrete, sleek, minimal)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quickCommands.map((cmd) {
                  return InkWell(
                    onTap: () => _handleCommand(cmd),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cmd.contains('location')
                                ? Icons.location_on_outlined
                                : (cmd.contains('call')
                                    ? Icons.call_outlined
                                    : Icons.chat_bubble_outline_rounded),
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cmd.length > 32 ? '${cmd.substring(0, 30)}...' : cmd,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
