import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Custom application text field widget
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.fillColor,
    this.borderRadius,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Label text
  final String? label;

  /// Hint text
  final String? hint;

  /// Error text
  final String? errorText;

  /// Helper text
  final String? helperText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Callback for suffix icon tap
  final VoidCallback? onSuffixIconPressed;

  /// Whether text is obscured (for passwords)
  final bool obscureText;

  /// Whether field is enabled
  final bool enabled;

  /// Whether field is read only
  final bool readOnly;

  /// Whether to autofocus
  final bool autofocus;

  /// Maximum number of lines
  final int maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Maximum character length
  final int? maxLength;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Validator function
  final String? Function(String?)? validator;

  /// On changed callback
  final ValueChanged<String>? onChanged;

  /// On submitted callback
  final ValueChanged<String>? onSubmitted;

  /// On tap callback
  final VoidCallback? onTap;

  /// Focus node
  final FocusNode? focusNode;

  /// Custom fill color
  final Color? fillColor;

  /// Custom border radius
  final double? borderRadius;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            filled: true,
            fillColor: widget.fillColor ?? AppColors.grey100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.grey500,
                    size: 20,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            border: _buildBorder(),
            enabledBorder: _buildBorder(),
            focusedBorder: _buildBorder(isFocused: true),
            errorBorder: _buildBorder(isError: true),
            focusedErrorBorder: _buildBorder(isError: true, isFocused: true),
            disabledBorder: _buildBorder(isDisabled: true),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.grey500,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: AppColors.grey500,
          size: 20,
        ),
        onPressed: widget.onSuffixIconPressed,
      );
    }

    return null;
  }

  OutlineInputBorder _buildBorder({
    bool isFocused = false,
    bool isError = false,
    bool isDisabled = false,
  }) {
    Color borderColor;
    double borderWidth = 1;

    if (isDisabled) {
      borderColor = Colors.transparent;
    } else if (isError) {
      borderColor = AppColors.error;
      borderWidth = isFocused ? 2 : 1;
    } else if (isFocused) {
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else {
      borderColor = Colors.transparent;
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius ?? AppSpacing.radiusMd),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    );
  }
}
