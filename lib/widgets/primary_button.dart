import 'package:flutter/material.dart';
import 'package:qapp/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconOnEdge = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool iconOnEdge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14695C).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: iconOnEdge ? _edgeIcon() : _inlineIcon(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.button,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 18),
        ],
      ],
    );
  }

  Widget _edgeIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.button,
        ),
        if (icon != null)
          Align(
            alignment: Alignment.centerRight,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
      ],
    );
  }
}
