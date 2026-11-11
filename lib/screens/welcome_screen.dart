import 'package:flutter/material.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/login_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/qapp_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoW = (constraints.maxWidth * 0.56).clamp(170.0, 250.0);
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    SizedBox(
                      width: logoW,
                      height: logoW * 0.7,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: logoW * 0.86,
                            height: logoW * 0.86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF155659).withValues(alpha: 0.7),
                                  const Color(0xFF155659).withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          QappLogo(width: logoW, hero: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qapp',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const Spacer(flex: 6),
                    PrimaryButton(
                      label: S.of(context).start,
                      onPressed: () {
                        Navigator.of(context).push(qRoute(const LoginScreen()));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
