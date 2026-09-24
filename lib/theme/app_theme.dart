import 'package:flutter/material.dart';

/// Shared design tokens for the RUSH / UniKL RCMP portals.
/// Keeping these in one place means every screen (Helpdesk, Vendor,
/// User Login, Operator) looks visually consistent.
class AppColors {
  static const navy = Color(0xFF16233F);
  static const navyDark = Color(0xFF0F1A30);
  static const gold = Color(0xFFC9A227);
  static const pageBackground = Color(0xFFEFF2F7);
  static const cardBackground = Color(0xFFFFFFFF);
  static const fieldBackground = Color(0xFFF3F5F9);
  static const border = Color(0xFFE1E5EE);
  static const textPrimary = Color(0xFF16233F);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9AA3B2);
}

class AppTextStyles {
  static const brand = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
    letterSpacing: 0.2,
  );

  static const brandSub = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static const cardTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const cardSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

/// A reusable top bar used by the Vendor / Operator / Helpdesk screens.
/// Shows a small crest, a two-line title, and an optional trailing action.
class PortalTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PortalTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom:
          false, // Kita matikan bottom supaya dia tidak kacau bahagian bawah skrin
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const _Crest(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.brand),
                Text(subtitle, style: AppTextStyles.brandSub),
              ],
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, // Besarkan sikit lebar untuk logo landscape
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'lib/assets/images/unikl_logo.png',
        fit: BoxFit.contain, // 🚀 KUNCI: Biar dia ikut ratio asal
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.shield_outlined, color: AppColors.gold, size: 18),
      ),
    );
  }
}

/// A rounded, shadowed card used to hold login forms.
class AuthCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthCard({super.key, required this.child, this.maxWidth = 400});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Standard labeled text field used on the login forms.
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextEditingController? controller;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }
}

/// Solid navy "primary" button used for Sign In / Continue actions.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final Widget buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (icon != null) ...[
          const SizedBox(width: 6),
          Icon(icon, size: 16),
        ],
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding:
          width == null ? const EdgeInsets.symmetric(horizontal: 24) : null,
    );

    return SizedBox(
      width: width,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }
}

/// Outlined button used for secondary actions like "Continue with Microsoft".
class MicrosoftButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? width;

  const MicrosoftButton({
    super.key,
    required this.onPressed,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding:
              width == null ? const EdgeInsets.symmetric(horizontal: 24) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _MicrosoftLogo(),
            const SizedBox(width: 10),
            const Text(
              'Continue with Microsoft (UniKL SSO)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicrosoftLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple 4-color square approximation of the Microsoft logo.
    return SizedBox(
      width: 16,
      height: 16,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ColoredBox(color: Color(0xFFF25022)),
          ColoredBox(color: Color(0xFF7FBA00)),
          ColoredBox(color: Color(0xFF00A4EF)),
          ColoredBox(color: Color(0xFFFFB900)),
        ],
      ),
    );
  }
}

/// A generic SSO button used for other authentication methods.
class RealSSOButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? width;

  const RealSSOButton({
    super.key,
    required this.onPressed,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding:
              width == null ? const EdgeInsets.symmetric(horizontal: 24) : null,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_outlined, size: 18),
            SizedBox(width: 10),
            Text(
              'Sign in with Real SSO',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets shared by the "Submit a Complaint" flow + Dashboard screens.
// ---------------------------------------------------------------------------

/// A plain white content shell with rounded corners, used to wrap each
/// step of the Submit-a-Complaint flow (Fill Details / Preview / Confirm).
class FlowCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const FlowCard({super.key, required this.child, this.maxWidth = 560});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Three decorative icon tabs shown at the top of the complaint flow cards
/// (category-style tabs in the mock-up). Only visual — not wired to
/// anything yet.
class TopIconTabs extends StatelessWidget {
  final int activeIndex;
  const TopIconTabs({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.chat_bubble_outline,
      Icons.edit_outlined,
      Icons.grid_view_outlined,
    ];
    return Row(
      children: List.generate(icons.length, (i) {
        final active = i == activeIndex;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.navy : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              icons[i],
              size: 18,
              color: active ? AppColors.navy : AppColors.textMuted,
            ),
          ),
        );
      }),
    );
  }
}

/// Horizontal 4-step progress tracker: Fill Details -> Preview & Review ->
/// Confirm -> Submitted. [currentStep] is 1-indexed.
class StepTracker extends StatelessWidget {
  final int currentStep;

  const StepTracker({super.key, required this.currentStep});

  static const _labels = [
    'Fill Details',
    'Preview & Review',
    'Confirm',
    'Submitted'
  ];
  static const _icons = [
    Icons.description_outlined,
    Icons.visibility_outlined,
    Icons.fact_check_outlined,
    Icons.check_circle_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line between two step circles.
          final leftStep = (i ~/ 2) + 1;
          final done = leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.navy : AppColors.border,
            ),
          );
        }
        final step = (i ~/ 2) + 1;
        final active = step == currentStep;
        final done = step < currentStep;
        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (active || done)
                    ? AppColors.navy
                    : AppColors.fieldBackground,
                border: Border.all(
                  color: (active || done) ? AppColors.navy : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                done ? Icons.check : _icons[step - 1],
                size: 14,
                color: (active || done) ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 76,
              child: Text(
                _labels[step - 1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

enum BannerTone { info, success, warning }

/// Colored inline banner used for SLA notices, edit-lock warnings, and
/// working-hours notices across the complaint flow.
class InfoBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final BannerTone tone;

  const InfoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.tone = BannerTone.info,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, border, fg, iconColor;
    late IconData icon;
    switch (tone) {
      case BannerTone.success:
        bg = const Color(0xFFEAF7EE);
        border = const Color(0xFFBCE6C6);
        fg = const Color(0xFF1E6B3A);
        iconColor = const Color(0xFF2E9E52);
        icon = Icons.check_circle_outline;
        break;
      case BannerTone.warning:
        bg = const Color(0xFFFFF8E6);
        border = const Color(0xFFF3E0A6);
        fg = const Color(0xFF8A6D1D);
        iconColor = const Color(0xFFC9A227);
        icon = Icons.warning_amber_outlined;
        break;
      case BannerTone.info:
        bg = const Color(0xFFEAF1FB);
        border = const Color(0xFFC6D9F3);
        fg = const Color(0xFF1F3E6B);
        iconColor = const Color(0xFF2F5FA3);
        icon = Icons.info_outline;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 11, color: fg)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase section heading, e.g. "COMPLAINT DETAILS".
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeading({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTextStyles.cardSubtitle),
        ],
      ],
    );
  }
}

/// A fully functional dynamic dropdown-styled field.
class LabeledDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;
  final List<String> items; // Ditambah untuk menerima data database
  final String? value; // Ditambah untuk memegang nilai pilihan
  final ValueChanged<String?>?
      onChanged; // Ditambah untuk mengesan klik pengguna

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.required = false,
    this.items = const [], // Lalai (default) senarai kosong
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTextStyles.fieldLabel,
            children: required
                ? const [
                    TextSpan(text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textMuted),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }
}

/// A labeled multiline text area (visual container over a TextField).
class LabeledTextArea extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;

  const LabeledTextArea({
    super.key,
    required this.label,
    required this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTextStyles.fieldLabel,
            children: required
                ? const [
                    TextSpan(text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed drag-and-drop style attachment upload box (visual only).
class AttachmentUploadBox extends StatelessWidget {
  final VoidCallback onTap;

  const AttachmentUploadBox({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  color: AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              const Text('Drag your file, or browse',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              const Text('PNG, JPG or PDF up to 10MB',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal dashed-border container (Flutter has no built-in dashed border).
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A read-only label/value pair used in the Preview & Confirm screens.
class ReviewField extends StatelessWidget {
  final String label;
  final String value;

  const ReviewField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

/// Small colored pill/tag, e.g. "Complaint", "Closed".
class StatusTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const StatusTag({
    super.key,
    required this.label,
    this.background = const Color(0xFFEAF1FB),
    this.foreground = const Color(0xFF2F5FA3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

/// Outlined secondary button (Cancel / Back to Edit / Add Another / etc).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15),
              const SizedBox(width: 6)
            ],
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Solid green "forward" action button (Preview & Review / Next / Submit All).
class SuccessButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const SuccessButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E9E52),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (icon != null) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 15)
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets shared by the Admin (IT Department) and Staff consoles.
// ---------------------------------------------------------------------------

class SidebarNavItem {
  final IconData icon;
  final String label;
  final String route;

  const SidebarNavItem(
      {required this.icon, required this.label, required this.route});
}

/// Dark navy left-hand navigation sidebar used across the admin/staff
/// console screens. [items] are wired to real navigation (they form a
/// persistent nav, matching the double-headed arrows in the diagram).
/// [currentRoute] highlights the active item.
class ConsoleSidebar extends StatelessWidget {
  final String departmentLabel;
  final List<SidebarNavItem> items;
  final String currentRoute;
  final String staffName;

  const ConsoleSidebar({
    super.key,
    required this.departmentLabel,
    required this.items,
    required this.currentRoute,
    this.staffName = 'Staff',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      color: AppColors.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.navyDark, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UNIKL RCMP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(departmentLabel,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items.map((item) {
                final active = item.route == currentRoute;
                return InkWell(
                  onTap: () {
                    if (!active) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        item.route,
                        (route) => false,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    color: active
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(item.icon,
                            size: 16,
                            color: active ? AppColors.gold : Colors.white54),
                        const SizedBox(width: 10),
                        Text(item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : Colors.white70,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.gold,
                  child:
                      Icon(Icons.person, size: 14, color: AppColors.navyDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(staffName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A colored count card used in the ticket-status overview rows
/// ("All", "Open", "In Progress", "Closed", etc).
class StatCountCard extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  final bool selected;

  const StatCountCard({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Top bar for the admin/staff console screens: a title, and a right-aligned
/// date/notification cluster.
class ConsoleTopBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const ConsoleTopBar({super.key, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.notifications_none,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          const CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.navy,
            child: Icon(Icons.person, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// A simple, generic table shell with a header row and body rows.
/// [columns] are header labels; each entry in [rows] is a list of cell
/// widgets matching the column count.
class SimpleTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<int>? flexes;

  const SimpleTable(
      {super.key, required this.columns, required this.rows, this.flexes});

  @override
  Widget build(BuildContext context) {
    final f = flexes ?? List.filled(columns.length, 1);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: List.generate(columns.length, (i) {
                return Expanded(
                  flex: f[i],
                  child: Text(columns[i].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3)),
                );
              }),
            ),
          ),
          ...rows.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: List.generate(row.length, (i) {
                  return Expanded(flex: f[i], child: row[i]);
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Small "View" link button used inside table rows.
class ViewLinkButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ViewLinkButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.visibility_outlined,
          size: 13, color: AppColors.navy),
      label: const Text('View',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.navy)),
    );
  }
}

/// A dismissible top modal wrapper for confirmation dialogs like "Remove
/// this item?" and "Add Another Item".
class CenteredModal extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredModal({super.key, required this.child, this.maxWidth = 360});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A gorgeous, modern floating SnackBar helper with icons and nice padding.
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ??
                    (isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded),
                color: isSuccess ? AppColors.gold : Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.navyDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side:
              BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        elevation: 10,
      ),
    );
  }
}
