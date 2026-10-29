import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final Color color;

  const SectionHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 1,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge.trim().isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}