import 'package:flutter/material.dart';

class TotalDisplayBox extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const TotalDisplayBox({
    Key? key,
    required this.text,
    this.borderColor = const Color(0xFF93c5fd), // border-dark
    this.backgroundColor = const Color(0xFFeff6ff), // background-light
    this.textColor = const Color(0xFF1e3a8a), // primary-dark
    this.fontSize = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
           BoxShadow(
            color: const Color(0xFF1e40af).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
