import 'package:flutter/material.dart';

class BorrowSummary extends StatelessWidget {
  const BorrowSummary({
    super.key,
    required this.history,
    required this.extraLabel,
    required this.extraValue,
    required this.extraIcon,
  });

  final List history;
  final String extraLabel;
  final int extraValue;
  final IconData extraIcon;

  @override
  Widget build(BuildContext context) {
    int countAction(String action) => history
        .where((entry) =>
            entry is Map &&
            entry['action']?.toString().toLowerCase() == action)
        .length;

    final borrowed = countAction('borrowed');
    final returned = countAction('returned');
    final active = borrowed > returned ? borrowed - returned : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 610
                ? 2
                : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        final stats = [
          _BorrowStat(
            label: 'Borrowed in total',
            value: borrowed,
            icon: Icons.bookmark_added_rounded,
            accent: const Color(0xFFDCEBE2),
          ),
          _BorrowStat(
            label: 'Currently out',
            value: active,
            icon: Icons.menu_book_rounded,
            accent: const Color(0xFFFFE9B9),
          ),
          _BorrowStat(
            label: 'Returned',
            value: returned,
            icon: Icons.assignment_turned_in_rounded,
            accent: const Color(0xFFE6E5F7),
          ),
          _BorrowStat(
            label: extraLabel,
            value: extraValue,
            icon: extraIcon,
            accent: const Color(0xFFF7E2D9),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(width: width, child: _BorrowStatCard(stat: stat)),
          ],
        );
      },
    );
  }
}

class _BorrowStat {
  const _BorrowStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
}

class _BorrowStatCard extends StatelessWidget {
  const _BorrowStatCard({required this.stat});

  final _BorrowStat stat;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: stat.accent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  stat.icon,
                  color: const Color(0xFF1D5744),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stat.value}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: Color(0xFF173E33),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stat.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B796F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
