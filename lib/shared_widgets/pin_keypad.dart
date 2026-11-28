import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_typography.dart';

/// Row of boxed digit slots showing how much of a PIN has been entered.
class PinDigitBoxes extends StatelessWidget {
  const PinDigitBoxes({super.key, required this.pin, required this.length});

  final String pin;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          _PinBox(isFilled: i < pin.length),
          if (i != length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.isFilled});

  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFilled ? AppColors.surfaceHighlight : AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(
          color: isFilled ? AppColors.primary : AppColors.border,
          width: isFilled ? 2 : 1,
        ),
      ),
      child: isFilled
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// Phone-dialer-style numeric keypad with a Clear / 0 / Delete bottom row,
/// used anywhere a PIN needs in-app entry instead of the OS keyboard.
class PinNumericKeypad extends StatelessWidget {
  const PinNumericKeypad({
    super.key,
    required this.onDigit,
    required this.onClear,
    required this.onDelete,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  static const _letters = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '',
  };

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  _KeypadButton(
                    label: row[i],
                    letters: _letters[row[i]]!,
                    onTap: () => onDigit(row[i]),
                  ),
                  if (i != row.length - 1)
                    const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KeypadButton(
              label: 'Clear',
              letters: 'Reset',
              isSmallLabel: true,
              onTap: onClear,
            ),
            const SizedBox(width: AppSpacing.md),
            _KeypadButton(label: '0', letters: '', onTap: () => onDigit('0')),
            const SizedBox(width: AppSpacing.md),
            _KeypadButton(
              icon: Icons.backspace_outlined,
              letters: 'Delete',
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.letters,
    this.isSmallLabel = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String letters;
  final bool isSmallLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceInput,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 75,
          height: 75,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, color: AppColors.textPrimary, size: 24)
                else if (isSmallLabel)
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMd(color: AppColors.textPrimary),
                  )
                else
                  Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSm(
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
