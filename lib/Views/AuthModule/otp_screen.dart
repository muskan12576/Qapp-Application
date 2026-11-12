import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Api/api_exceptions.dart';
import 'package:qapp/Views/AuthModule/model/auth_vm.dart';
import 'package:qapp/Services/zego_session.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/Views/HomeModule/home_shell.dart';
import 'package:qapp/Views/AuthModule/profile_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone = '', this.rawPhone = '', this.phoneToken = ''});

  final String phone;
  final String rawPhone;
  final String phoneToken;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _count = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  Timer? _timer;
  int _seconds = 30;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_count, (_) => TextEditingController());
    _nodes = List.generate(_count, (index) {
      return FocusNode()..addListener(() => setState(() {}));
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final data = await AuthController.instance.sendPhone(widget.rawPhone);
      if (!mounted) return;
      for (final controller in _controllers) {
        controller.clear();
      }
      setState(() => _seconds = 30);
      _startTimer();
      _nodes.first.requestFocus();
      if (data['token'] != null) {
        Navigator.of(context).pushReplacement(qRoute(OtpScreen(
          phone: widget.phone,
          rawPhone: widget.rawPhone,
          phoneToken: data['token'].toString(),
        )));
      }
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    print('widget.phoneToken: ${widget.phoneToken}');
    
    final code = _controllers.map((item) => item.text).join();
    print("Code: $code");
    if (code.length != _count) {
      setState(() => _error = '6 digit OTP daalo');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final data = await AuthController.instance.verifyOtp(phoneToken: widget.phoneToken, otp: code);
      if (!mounted) return;
      if (data['profile_complete'] == true) {
        await TokenStorage.instance.saveLogin(data, phone: widget.rawPhone);
        MyProfile.name = TokenStorage.instance.name;
        MyProfile.bio = TokenStorage.instance.about;
        await ZegoSession.instance.connect();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(qRoute(const HomeShell()), (route) => false);
        return;
      }
      Navigator.of(context).push(qRoute(ProfileScreen(
        setupToken: data['token']?.toString() ?? '',
        phone: widget.rawPhone,
      )));
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (index > 0) {
        _nodes[index - 1].requestFocus();
      }
      return;
    }
    if (digits.length > 1) {
      for (var i = 0; i < _count; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length >= _count ? _count - 1 : digits.length;
      _nodes[next].requestFocus();
      return;
    }
    if (_controllers[index].text != digits) {
      _controllers[index].text = digits;
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }
    if (index < _count - 1) {
      _nodes[index + 1].requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: QBackground(
        watermark: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    S.of(context).otpTitle,
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).otpSub,
                    textAlign: TextAlign.center,
                    style: AppText.subtitle,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_count, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _nodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) => _onChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.w700)),
                  ],
                  GestureDetector(
                    onTap: _seconds == 0 ? _resend : null,
                    child: Text(
                      S.of(context).resend(_seconds),
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  PrimaryButton(
                    label: _busy ? '...' : S.of(context).next,
                    onPressed: _busy ? () {} : _verify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
