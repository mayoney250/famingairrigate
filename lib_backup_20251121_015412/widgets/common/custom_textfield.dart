import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.titleSmall?.color ?? scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color ?? scheme.onSurface,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? scheme.surface : scheme.surfaceVariant,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: scheme.primary,
                  )
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

