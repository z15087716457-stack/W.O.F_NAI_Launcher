import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/models/auth/saved_account.dart';

/// 账户头像统一品牌底（FEAT-30）：W.O.F logo 主蓝 #0160FB。
/// 静拍板「深蓝色内部字体为白色」——所有账号同底色、按首字区分。
const Color kAvatarBackground = Color(0xFF0160FB);

/// 头像字色：深蓝底恒白
const Color kAvatarForeground = Colors.white;

/// 微圆角方形：非锐利直角，半径 = 边长 × 0.2（40px→8、32px→6.4、100px→20）
BorderRadius avatarBorderRadius(double size) =>
    BorderRadius.circular(size * 0.2);

/// 账号头像组件
/// 支持显示自定义头像或昵称首字
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.account,
    this.size = 48,
    this.onTap,
    this.showEditBadge = true,
    this.muted = false,
    this.neutral = false,
  });

  final SavedAccount account;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final bool muted;

  /// Settings can use a neutral fallback while preserving custom avatars.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final radius = avatarBorderRadius(size);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.2),
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        child: Padding(
          padding: EdgeInsets.all(showEditBadge ? size * 0.15 : 0),
          child: Stack(
            children: [
              _buildAvatar(context),
              if (showEditBadge) _buildEditBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final avatarPath = account.avatarPath;

    // 如果有头像路径且文件存在，显示图片
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final avatarFile = File(avatarPath);
      if (avatarFile.existsSync()) {
        // 使用 Image.memory 绕过 FileImage 缓存问题
        // 因为 FileImage 会缓存同一路径的图片，导致更新后显示旧图片
        return FutureBuilder<Uint8List>(
          future: avatarFile.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: avatarBorderRadius(size),
                child: Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              );
            }
            // 加载中或失败时显示默认头像
            return _buildDefaultAvatar(theme);
          },
        );
      }
    }

    // 默认头像：显示昵称首字
    return _buildDefaultAvatar(theme);
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    final firstChar = account.displayName.isNotEmpty
        ? account.displayName.characters.first.toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: neutral
            ? theme.colorScheme.onSurface.withValues(alpha: .07)
            : muted
            ? theme.colorScheme.primary.withValues(alpha: .12)
            : kAvatarBackground,
        borderRadius: avatarBorderRadius(size),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: neutral
                ? theme.colorScheme.onSurfaceVariant
                : muted
                ? theme.colorScheme.primary
                : kAvatarForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildEditBadge(BuildContext context) {
    final theme = Theme.of(context);
    final badgeSize = size * 0.3;

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.surface, width: 2),
        ),
        child: Icon(
          Icons.camera_alt,
          size: badgeSize * 0.6,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// 简化版头像组件，用于列表项
class AccountAvatarSmall extends StatelessWidget {
  const AccountAvatarSmall({
    super.key,
    required this.account,
    this.size = 40,
    this.isSelected = false,
  });

  final SavedAccount account;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarPath = account.avatarPath;

    // 如果有头像路径且文件存在，显示图片
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final avatarFile = File(avatarPath);
      if (avatarFile.existsSync()) {
        // 使用 Image.memory 绕过 FileImage 缓存问题
        return FutureBuilder<Uint8List>(
          future: avatarFile.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: avatarBorderRadius(size),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: avatarBorderRadius(size),
                  child: Image.memory(
                    snapshot.data!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            // 加载中或失败时显示默认头像
            return _buildDefaultAvatar(theme, isSelected);
          },
        );
      }
    }

    // 默认头像：显示昵称首字
    return _buildDefaultAvatar(theme, isSelected);
  }

  Widget _buildDefaultAvatar(ThemeData theme, bool isSelected) {
    final firstChar = account.displayName.isNotEmpty
        ? account.displayName.characters.first.toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kAvatarBackground,
        borderRadius: avatarBorderRadius(size),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: kAvatarForeground,
          ),
        ),
      ),
    );
  }
}
