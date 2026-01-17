import 'package:flutter/material.dart';

/// Material 3 Enhanced Components for the Label Designer
/// These components showcase the latest Material 3 design principles
class Material3Components {
  /// Material 3 Enhanced Card with tonal elevation and surface tints
  static Widget enhancedCard({
    required Widget child,
    VoidCallback? onTap,
    bool isSelected = false,
    double? elevation,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Card(
          elevation: elevation ?? (isSelected ? 6 : 2),
          shadowColor: colorScheme.shadow,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Material 3 Enhanced Button with modern styling
  static Widget enhancedButton({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    ButtonStyle? style,
    bool isPrimary = true,
  }) {
    if (isPrimary) {
      return icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: Text(label),
              style: style,
            )
          : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            );
    } else {
      return icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: Text(label),
              style: style,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            );
    }
  }

  /// Material 3 Enhanced Chip with better visual hierarchy
  static Widget enhancedChip({
    required String label,
    Widget? avatar,
    VoidCallback? onSelected,
    VoidCallback? onDeleted,
    bool isSelected = false,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        if (onSelected != null) {
          return FilterChip(
            label: Text(label),
            avatar: avatar,
            selected: isSelected,
            onSelected: (_) => onSelected(),
            backgroundColor: backgroundColor,
            selectedColor: colorScheme.secondaryContainer,
            checkmarkColor: colorScheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        return Chip(
          label: Text(label),
          avatar: avatar,
          onDeleted: onDeleted,
          backgroundColor: backgroundColor ?? colorScheme.surfaceVariant,
          deleteIconColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  /// Material 3 Enhanced List Tile with better typography
  static Widget enhancedListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return ListTile(
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer.withOpacity(0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          selected: isSelected,
          selectedTileColor: colorScheme.secondaryContainer,
          selectedColor: colorScheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      },
    );
  }

  /// Material 3 Enhanced Input Field with modern styling
  /// Supports controller, validator, and other standard TextFormField properties
  static Widget enhancedTextField({
    required String label,
    String? hint,
    String? initialValue,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool enabled = true,
    int? maxLines = 1,
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helperText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  /// Material 3 Enhanced Progress Indicator
  static Widget enhancedProgressIndicator({
    double? value,
    String? label,
    bool isLinear = true,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isLinear)
              LinearProgressIndicator(
                value: value,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              )
            else
              CircularProgressIndicator(
                value: value,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Material 3 Enhanced Bottom Sheet with drag handle
  static void showEnhancedBottomSheet({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Flexible(child: child),
            ],
          ),
        );
      },
    );
  }
}
