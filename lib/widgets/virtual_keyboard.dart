import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';

enum KeyboardMode { lowercase, uppercase, numbers }

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClose;

  const VirtualKeyboard({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onClose,
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  KeyboardMode _mode = KeyboardMode.lowercase;

  void _onKeyPress(String char) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, char);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );

    if (_mode == KeyboardMode.uppercase) {
      setState(() => _mode = KeyboardMode.lowercase);
    }
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (text.isEmpty) return;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  void _onClear() {
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Dynamically scale keyboard geometry based on screen resolution
    // Clamped for extreme low-res (e.g. 800x480) up to high-res (e.g. 1920x1080)
    final double keyHeight = (screenHeight * 0.075).clamp(34.0, 56.0);
    final double keyFontSize = (keyHeight * 0.38).clamp(12.0, 20.0);
    final double labelFontSize = (keyHeight * 0.28).clamp(10.0, 14.0);
    final double iconSize = (keyHeight * 0.45).clamp(16.0, 24.0);
    final double horizontalPadding = (screenWidth * 0.015).clamp(6.0, 16.0);
    final double verticalPadding = (screenHeight * 0.012).clamp(4.0, 12.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF12141D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: const Border(
          top: BorderSide(color: AutomotiveColors.electricCyan, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keyboard Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.keyboard_hide_rounded, color: AutomotiveColors.electricCyan, size: iconSize + 2),
                onPressed: widget.onClose,
              ),
            ],
          ),
          SizedBox(height: verticalPadding * 0.5),
          // Keyboard Rows
          ..._buildKeyboardRows(keyHeight, keyFontSize, labelFontSize, iconSize),
        ],
      ),
    );
  }

  List<Widget> _buildKeyboardRows(double keyHeight, double keyFontSize, double labelFontSize, double iconSize) {
    if (_mode == KeyboardMode.numbers) {
      return [
        _buildRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], keyHeight, keyFontSize),
        const SizedBox(height: 5),
        _buildRow(['@', '#', '\$', '%', '&', '*', '-', '+', '(', ')'], keyHeight, keyFontSize),
        const SizedBox(height: 5),
        _buildRow(['=', '\\', '/', ':', ';', '!', '?', '\'', '"'], keyHeight, keyFontSize),
        const SizedBox(height: 5),
        _buildBottomRow(isNumbers: true, keyHeight: keyHeight, keyFontSize: keyFontSize, labelFontSize: labelFontSize, iconSize: iconSize),
      ];
    }

    final isUpper = _mode == KeyboardMode.uppercase;
    final row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    final row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
    final row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

    return [
      _buildRow(row1.map((c) => isUpper ? c.toUpperCase() : c).toList(), keyHeight, keyFontSize),
      const SizedBox(height: 5),
      _buildRow(row2.map((c) => isUpper ? c.toUpperCase() : c).toList(), keyHeight, keyFontSize),
      const SizedBox(height: 5),
      Row(
        children: [
          // Shift Key
          Expanded(
            flex: 3,
            child: _buildSpecialKey(
              icon: Icons.arrow_upward_rounded,
              isActive: isUpper,
              keyHeight: keyHeight,
              labelFontSize: labelFontSize,
              iconSize: iconSize,
              onTap: () {
                setState(() {
                  _mode = _mode == KeyboardMode.uppercase
                      ? KeyboardMode.lowercase
                      : KeyboardMode.uppercase;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          ...row3.map((c) {
            final char = isUpper ? c.toUpperCase() : c;
            return Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildKey(char, keyHeight, keyFontSize),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Backspace Key
          Expanded(
            flex: 3,
            child: _buildSpecialKey(
              icon: Icons.backspace_outlined,
              keyHeight: keyHeight,
              labelFontSize: labelFontSize,
              iconSize: iconSize,
              onTap: _onBackspace,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      _buildBottomRow(isNumbers: false, keyHeight: keyHeight, keyFontSize: keyFontSize, labelFontSize: labelFontSize, iconSize: iconSize),
    ];
  }

  Widget _buildRow(List<String> keys, double keyHeight, double keyFontSize) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildKey(key, keyHeight, keyFontSize),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow({
    required bool isNumbers,
    required double keyHeight,
    required double keyFontSize,
    required double labelFontSize,
    required double iconSize,
  }) {
    return Row(
      children: [
        // Mode Switch Key (?123 / ABC)
        Expanded(
          flex: 3,
          child: _buildSpecialKey(
            label: isNumbers ? "ABC" : "?123",
            keyHeight: keyHeight,
            labelFontSize: labelFontSize,
            iconSize: iconSize,
            onTap: () {
              setState(() {
                _mode = isNumbers ? KeyboardMode.lowercase : KeyboardMode.numbers;
              });
            },
          ),
        ),
        const SizedBox(width: 4),
        // Clear Key
        Expanded(
          flex: 2,
          child: _buildSpecialKey(
            label: "Clear",
            keyHeight: keyHeight,
            labelFontSize: labelFontSize,
            iconSize: iconSize,
            onTap: _onClear,
          ),
        ),
        const SizedBox(width: 4),
        // Spacebar
        Expanded(
          flex: 9,
          child: Container(
            height: keyHeight,
            decoration: BoxDecoration(
              color: AutomotiveColors.glassPanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onKeyPress(' '),
                child: Center(
                  child: Text(
                    "SPACE",
                    style: GoogleFonts.inter(
                      color: AutomotiveColors.textMuted,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Done / Submit Key
        Expanded(
          flex: 4,
          child: Container(
            height: keyHeight,
            decoration: BoxDecoration(
              color: AutomotiveColors.electricCyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (widget.onSubmitted != null) {
                    widget.onSubmitted!();
                  } else if (widget.onClose != null) {
                    widget.onClose!();
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.black, size: iconSize - 2),
                      const SizedBox(width: 4),
                      Text(
                        "DONE",
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label, double keyHeight, double keyFontSize) {
    return Container(
      height: keyHeight,
      decoration: BoxDecoration(
        color: AutomotiveColors.glassPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onKeyPress(label),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AutomotiveColors.textPrimary,
                fontSize: keyFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    String? label,
    IconData? icon,
    bool isActive = false,
    required double keyHeight,
    required double labelFontSize,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return Container(
      height: keyHeight,
      decoration: BoxDecoration(
        color: isActive ? AutomotiveColors.electricCyan.withAlpha(50) : AutomotiveColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AutomotiveColors.electricCyan : AutomotiveColors.stroke,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: isActive ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary, size: iconSize)
                : Text(
                    label!,
                    style: GoogleFonts.inter(
                      color: isActive ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
