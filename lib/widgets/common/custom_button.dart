import 'package:flutter/material.dart';
import '../../config/colors.dart';

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
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? FamingaBrandColors.primaryButton,
          foregroundColor: textColor ?? FamingaBrandColors.white,
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FamingaBrandColors.white,
                  ),
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
                                  color: textColor ?? FamingaBrandColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor ?? FamingaBrandColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: FamingaBrandColors.primaryOrange,
          side: const BorderSide(
            color: FamingaBrandColors.primaryOrange,
            width: 2,
          ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FamingaBrandColors.primaryOrange,
                  ),
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
                                  color: FamingaBrandColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: FamingaBrandColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
      ),
    );
  }
}

