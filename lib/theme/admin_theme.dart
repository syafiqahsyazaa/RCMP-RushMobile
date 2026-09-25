import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../main.dart';

/// Extra design tokens + shared widgets for the Admin (IT Department) and
/// Staff portals. Kept separate from app_theme.dart to keep files focused;
/// screens import both.

class AdminNavItem {
  final IconData icon;
  final String label;
  final String route;
  const AdminNavItem(this.icon, this.label, this.route);
}

/// Slide-out navigation drawer used by every Admin/Staff screen.
/// Tapping an item swaps to that section (pushReplacement so the nav
/// stack doesn't grow endlessly as the user hops between sections).
class PortalNavDrawer extends StatelessWidget {
  final String departmentLabel;
  final String currentRoute;
  final List<AdminNavItem> items;
  final String? fullName;
  final String? role;
  final String staffName;

  const PortalNavDrawer({
    super.key,
    required this.departmentLabel,
    required this.currentRoute,
    required this.items,
    this.fullName, // 🔒 Optional! Tidak wajib diisi oleh skrin luar!
    this.role, // 🔒 Optional! Tidak wajib diisi oleh skrin luar!
    this.staffName = "", // 🚀 Default to empty to allow proper fallback logic!
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  // =========================================================================
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'lib/assets/images/unikl_logo.png',
                      width: 50,
                      fit: BoxFit
                          .contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.red, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UniKL RCMP',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        Text(departmentLabel,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 10)),
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
                  return ListTile(
                    leading: Icon(item.icon,
                        size: 19,
                        color: active ? AppColors.gold : Colors.white70),
                    title: Text(item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: active ? Colors.white : Colors.white70,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        )),
                    tileColor:
                        active ? Colors.white.withValues(alpha: 0.06) : null,
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      if (!active) {
                        Navigator.pushReplacementNamed(context, item.route,
                            // 🚀 SUNTIKAN UTAMA: Kita pass bungkusan arguments tulin yang dipegang oleh constructor drawer!
                            arguments: {
                              "email": ((ModalRoute.of(context)
                                              ?.settings
                                              .arguments
                                          as Map<String, dynamic>?)?['email'] ??
                                      currentLoggedInUserEmail)
                                  .toString(),
                              "full_name": staffName.isNotEmpty
                                  ? staffName
                                  : (((ModalRoute.of(context)
                                                      ?.settings
                                                      .arguments
                                                  as Map<String, dynamic>?)?[
                                              'full_name'] ??
                                          (ModalRoute.of(context)
                                                      ?.settings
                                                      .arguments
                                                  as Map<String, dynamic>?)?[
                                              'name'] ??
                                          fullName) ??
                                      "User UniKL"),
                              "role": role ?? "Admin",
                              "departmentLabel":
                                  departmentLabel, // 🔒 FIX DYNAMIC: Kita hantar label jabatan ke skrin seterusnya!
                            });
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            // =========================================================================
            // 🔒 PERISAI KEBEL MUKTAMAD: FORMULA PROFIL PARAMETER INDEPENDENT 🔒
            // 100% KALIS ERROR COMPILE & AUTO-SEDUT DATA ASLI HANTARAN STAFFNAME!
            // =========================================================================
            const Divider(color: Colors.white12, height: 1),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 🔵 Bulatan Avatar Biru: Huruf pertama mengikut nama tulin hantaran skrin!
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(
                      ((staffName.isNotEmpty)
                              ? staffName
                              : (((ModalRoute.of(context)?.settings.arguments
                                              as Map<String, dynamic>?)?[
                                          'full_name'] ??
                                      (ModalRoute.of(context)
                                              ?.settings
                                              .arguments
                                          as Map<String, dynamic>?)?['name'] ??
                                      fullName) ??
                                  'U'))
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Bahagian Teks Profil Tengah: Nama Penuh Database + Teks Peranan Dinamik 3 Pangkat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          // 🚀 FIX MUKTAMAD: Cuba cari nama dari 3 sumber: staffName -> Route Arguments -> fullName
                          (staffName.isNotEmpty)
                              ? staffName
                              : (((ModalRoute.of(context)?.settings.arguments
                                              as Map<String, dynamic>?)?[
                                          'full_name'] ??
                                      (ModalRoute.of(context)
                                              ?.settings
                                              .arguments
                                          as Map<String, dynamic>?)?['name'] ??
                                      fullName) ??
                                  'User UniKL'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        const SizedBox(height: 1),
                        Text(
                          // =========================================================================
                          // 🔒 FIX KEBEL PORTAL: MEMBACA LANGSUNG DARI PARAMETER HANTARAN SKRIN LUAR 🔒
                          // Tak kisahlah Maintenance Admin atau IT Staff, role auto-keluar tepat ikut screen!
                          // =========================================================================
                          (role != null && role!.trim().isNotEmpty)
                              ? role!.trim()
                              : 'Staff', // Fallback default jika screen luar terlupa suap parameter murni!
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // 🚪 Butang Ikon Pintu Sign Out
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white60, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/helpdesk_home_screen', (route) => false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Logged out successfully.')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Compact stat card used in dashboard/all-tickets top rows
/// (e.g. "16 All Tickets", "0 Open", "4.9 Avg Rating").
class StatMiniCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const StatMiniCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.navy,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Small colored priority chip: Low / Medium / High.
class PriorityChip extends StatelessWidget {
  final String priority;
  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    late Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = const Color(0xFFD64545);
        break;
      case 'medium':
        color = const Color(0xFFC9A227);
        break;
      default:
        color = const Color(0xFF2E9E52);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 11, color: color),
        const SizedBox(width: 4),
        Text(priority,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// Mobile-friendly ticket card (replaces a desktop table row).
class TicketCard extends StatelessWidget {
  final String ticketId;
  final String title;
  final String submittedBy;
  final String department;
  final String category;
  final String priority;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onView;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.title,
    required this.submittedBy,
    required this.department,
    required this.category,
    required this.priority,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ticketId,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
              const Spacer(),
              StatusTag(
                  label: status, background: statusBg, foreground: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('$submittedBy · $department',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(category,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              PriorityChip(priority: priority),
              const Spacer(),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onView,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A search box + filter row, visual only (no filtering logic wired).
class SearchFilterBar extends StatelessWidget {
  final String hint;
  const SearchFilterBar(
      {super.key, this.hint = 'Search by ID, title or category'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _FilterChipBox(label: 'All Status')),
            const SizedBox(width: 8),
            Expanded(child: _FilterChipBox(label: 'All Categories')),
          ],
        ),
      ],
    );
  }
}

class _FilterChipBox extends StatelessWidget {
  final String label;
  const _FilterChipBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Simple vertical bar chart (no external chart package needed).
class SimpleBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> bars; // label -> value 0..1
  final List<Color> colors;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.bars,
    required this.colors,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          final entry = bars[i];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (height - 30) * entry.value.clamp(0.02, 1.0),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(entry.key,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Simple donut chart drawn with CustomPainter — no chart package required.
class SimpleDonutChart extends StatelessWidget {
  final List<MapEntry<String, double>> slices; // label -> value
  final List<Color> colors;
  final double size;

  const SimpleDonutChart({
    super.key,
    required this.slices,
    required this.colors,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, e) => sum + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
            slices: slices, colors: colors, total: total <= 0 ? 1 : total),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> slices;
  final List<Color> colors;
  final double total;

  _DonutPainter(
      {required this.slices, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 14.0;
    double startAngle = -1.5708; // -90deg
    for (int i = 0; i < slices.length; i++) {
      final sweep = (slices[i].value / total) * 6.28319;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep <= 0 ? 0.001 : sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Legend row used alongside SimpleBarChart / SimpleDonutChart.
class ChartLegend extends StatelessWidget {
  final List<MapEntry<String, Color>> items;
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: items.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: e.value, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(e.key,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

/// Generic labeled data-row used on table-like screens (Manage Users,
/// Manage Vendors, Categories) rendered as mobile cards.
class DataRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MapEntry<String, String>> fields;
  final Widget? trailingTag;
  final List<Widget> actions;

  const DataRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.fields = const [],
    this.trailingTag,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              if (trailingTag != null) trailingTag!,
            ],
          ),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: fields
                  .map((f) => ReviewField(label: f.key, value: f.value))
                  .toList(),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Small icon-only action button used in DataRowCard actions row.
class IconTextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const IconTextAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8)),
      icon: Icon(icon, size: 14, color: color),
      label: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// A gorgeous, modern floating bottom navigation bar for Admin and Staff portals.
class PortalBottomNav extends StatelessWidget {
  final List<AdminNavItem> items;
  final String currentRoute;

  const PortalBottomNav({
    super.key,
    required this.items,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.map((item) {
                final active = item.route == currentRoute;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      if (!active) {
                        final args = ModalRoute.of(context)?.settings.arguments;
                        Navigator.pushReplacementNamed(
                          context,
                          item.route,
                          arguments: args,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.gold.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: active
                            ? Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                width: 1)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: active ? AppColors.gold : Colors.white60,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? Colors.white : Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
