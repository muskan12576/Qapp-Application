import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/countries.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/otp_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  Country _country = countryByIso('IN');

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CountrySheet(selected: _country.iso),
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: QBackground(
        login: true,
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
                    S.of(context).loginBig,
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).loginSmall,
                    textAlign: TextAlign.center,
                    style: AppText.subtitle,
                  ),
                  const SizedBox(height: 28),
                  _PhoneField(
                    controller: _phone,
                    hint: S.of(context).phoneHint,
                    country: _country,
                    onCode: _pickCountry,
                  ),
                  const SizedBox(height: 120),
                  PrimaryButton(
                    label: S.of(context).sendOtp,
                    onPressed: () {
                      final typed = _phone.text.trim();
                      final shown = typed.isEmpty
                          ? '+${_country.dial}'
                          : '+${_country.dial} $typed';
                      Navigator.of(context).push(qRoute(OtpScreen(phone: shown)));
                    },
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

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.hint,
    required this.country,
    required this.onCode,
  });

  final TextEditingController controller;
  final String hint;
  final Country country;
  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onCode,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Text(
                '+${country.dial}',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.38),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});

  final String selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = _query.text.trim().toLowerCase();
    final list = countries.where((country) {
      if (q.isEmpty) {
        return true;
      }
      return country.name.toLowerCase().contains(q) ||
          country.dial.contains(q) ||
          country.iso.toLowerCase().contains(q);
    }).toList();
    if (q.isEmpty) {
      list.sort((a, b) => a.name.compareTo(b.name));
      final india = countryByIso('IN');
      list.removeWhere((country) => country.iso == 'IN');
      list.insert(0, india);
    }

    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.chooseCountry,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.ink),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: s.search,
                  hintStyle: TextStyle(color: AppColors.faint),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final country = list[index];
                  final selected = country.iso == widget.selected;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(country),
                    leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Text(
                      '+${country.dial}',
                      style: TextStyle(
                        color: selected ? AppColors.accent : AppColors.inkSoft,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

