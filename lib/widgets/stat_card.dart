import 'package:fatora_pro/utils/formatters.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  }) : super(key: key);
  
  // لصفحة الفواتير
  const StatCard.small({
    Key? key,
    required this.label,
    required String value,
    required this.color,
  }) : value = value, icon = null, super(key: key);

  @override
  Widget build(BuildContext context) {
    // هذا التصميم لصفحة التقارير والحسابات
    if (icon == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // هذا التصميم لصفحة الفواتير
    return FittedBox(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
