import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool isLoading;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    final effectiveTextStyle = textStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: effectiveForegroundColor,
          fontWeight: FontWeight.w600,
        );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          elevation: 2,
          disabledBackgroundColor: effectiveBackgroundColor.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: effectiveTextStyle,
                  ),
                ],
              ),
      ),
    );
  }
}

class CustomOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool isLoading;
  final TextStyle? textStyle;

  const CustomOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ?? theme.colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? theme.colorScheme.primary;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    final effectiveTextStyle = textStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: effectiveForegroundColor,
          fontWeight: FontWeight.w600,
        );

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveForegroundColor,
          padding: effectivePadding,
          side: BorderSide(color: effectiveBorderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: effectiveTextStyle,
                  ),
                ],
              ),
      ),
    );
  }
}