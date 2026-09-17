import 'package:flutter/material.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';

/// 添加角色按钮组件
///
/// 包含性别按钮（女/男/其他），横向布局
/// 采用无边框+色差的简洁风格
class AddCharacterButtons extends ConsumerWidget {
  const AddCharacterButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // 女性按钮
        _GenderButton(
          icon: Icons.female,
          label: l10n.characterEditor_addFemale,
          color: const Color(0xFFEC4899), // pink-500
          onTap: () => _addCharacter(ref, CharacterGender.female),
        ),
        // 男性按钮
        _GenderButton(
          icon: Icons.male,
          label: l10n.characterEditor_addMale,
          color: const Color(0xFF3B82F6), // blue-500
          onTap: () => _addCharacter(ref, CharacterGender.male),
        ),
        // 其他按钮
        _GenderButton(
          icon: Icons.transgender,
          label: l10n.characterEditor_addOther,
          color: const Color(0xFF8B5CF6), // violet-500
          onTap: () => _addCharacter(ref, CharacterGender.other),
        ),
      ],
    );
  }

  void _addCharacter(WidgetRef ref, CharacterGender gender) {
    ref.read(characterPromptNotifierProvider.notifier).addCharacter(gender);
  }
}

/// 性别按钮组件（无边框+色差风格）
class _GenderButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GenderButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GenderButton> createState() => _GenderButtonState();
}

class _GenderButtonState extends State<_GenderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            // 无边框，常态淡背景，悬停时加深
            color: _isHovered
                ? widget.color.withValues(alpha: 0.18)
                : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 15,
                color: _isHovered
                    ? widget.color
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 2),
              Icon(widget.icon, size: 17, color: widget.color),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _isHovered
                      ? widget.color
                      : colorScheme.onSurfaceVariant,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
