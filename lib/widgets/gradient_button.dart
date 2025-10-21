import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final List<Color>? colors;
  final double borderRadius;
  final EdgeInsets padding;
  final double? minWidth;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.colors,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.minWidth,
  }) : super(key: key);
  
  // تدرجات الألوان الافتراضية
  static const List<Color> primaryGradient = [Color(0xFF1e40af), Color(0xFF3b82f6), Color(0xFF60a5fa)];
  static const List<Color> successGradient = [Color(0xFF10b981), Color(0xFF34d399)];
  static const List<Color> dangerGradient = [Color(0xFFef4444), Color(0xFFf87171)];
  static const List<Color> warningGradient = [Color(0xFFf59e0b), Color(0xFFfbbf24)];

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? primaryGradient;
    
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
