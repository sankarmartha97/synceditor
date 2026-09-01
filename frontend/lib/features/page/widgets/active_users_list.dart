import 'package:flutter/material.dart';

/// Model for active user data
class ActiveUser {
  final String userId;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String permission;
  final Color color;
  final DateTime joinedAt;

  ActiveUser({
    required this.userId,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.permission,
    required this.color,
    required this.joinedAt,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      permission: json['permission'] as String? ?? 'view',
      color: _parseColor(json['color'] as String? ?? '#3B82F6'),
      joinedAt: DateTime.parse(
        json['joinedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  IconData get permissionIcon {
    switch (permission) {
      case 'owner':
        return Icons.star;
      case 'edit':
        return Icons.edit;
      case 'view':
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  String get permissionLabel {
    switch (permission) {
      case 'owner':
        return 'Owner';
      case 'edit':
        return 'Editor';
      case 'view':
        return 'Viewer';
      default:
        return 'Unknown';
    }
  }
}

/// Widget that displays the list of active users
class ActiveUsersList extends StatelessWidget {
  final List<ActiveUser> users;
  final String? currentUserId;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const ActiveUsersList({
    Key? key,
    required this.users,
    this.currentUserId,
    this.isCollapsed = false,
    this.onToggleCollapse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 60 : 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: isCollapsed
                ? _buildCollapsedList()
                : _buildExpandedList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed) ...[
            const Text(
              'Active Users',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${users.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (onToggleCollapse != null)
            IconButton(
              icon: Icon(
                isCollapsed ? Icons.chevron_left : Icons.chevron_right,
                size: 20,
              ),
              onPressed: onToggleCollapse,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.userId == currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Tooltip(
            message: '${user.name} (${user.permissionLabel})',
            child: _buildAvatar(user, isCurrentUser, size: 40),
          ),
        );
      },
    );
  }

  Widget _buildExpandedList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.userId == currentUserId;

        return _buildUserTile(context, user, isCurrentUser);
      },
    );
  }

  Widget _buildUserTile(BuildContext context, ActiveUser user, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: Colors.blue.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          _buildAvatar(user, isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isCurrentUser ? FontWeight.bold : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(You)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      user.permissionIcon,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.permissionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Color indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: user.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ActiveUser user, bool isCurrentUser, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: user.color,
        shape: BoxShape.circle,
        border: isCurrentUser
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(user.initials, size);
                },
              ),
            )
          : _buildInitialsAvatar(user.initials, size),
    );
  }

  Widget _buildInitialsAvatar(String initials, double size) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Compact version of active users (just avatars)
class ActiveUsersAvatars extends StatelessWidget {
  final List<ActiveUser> users;
  final String? currentUserId;
  final int maxVisible;
  final double avatarSize;

  const ActiveUsersAvatars({
    Key? key,
    required this.users,
    this.currentUserId,
    this.maxVisible = 5,
    this.avatarSize = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxVisible).toList();
    final remainingCount = users.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleUsers.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          final isCurrentUser = user.userId == currentUserId;

          return Transform.translate(
            offset: Offset(-index * (avatarSize * 0.3), 0),
            child: Tooltip(
              message: '${user.name} (${user.permissionLabel})',
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: user.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: avatarSize * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        if (remainingCount > 0)
          Transform.translate(
            offset: Offset(-visibleUsers.length * (avatarSize * 0.3), 0),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
