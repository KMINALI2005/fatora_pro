import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SectionCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(28.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF1e40af).withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
