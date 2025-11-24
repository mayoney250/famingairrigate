import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return _buildOutlinedButton(context);
    }
    return _buildElevatedButton(context);
  }

  Widget _buildElevatedButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? scheme.primary,
          foregroundColor: textColor ?? scheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: textColor ?? scheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor ?? scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
      ),
    );
  }
}

