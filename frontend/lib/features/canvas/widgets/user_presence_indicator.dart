import 'package:flutter/material.dart';

class UserPresenceIndicator extends StatelessWidget {
  final List<ActiveUser> activeUsers;

  const UserPresenceIndicator({
    super.key,
    required this.activeUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (activeUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 8),
                const SizedBox(width: 4),
                Text(
                  '${activeUsers.length} online',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // User avatars
          ...activeUsers.take(5).map((user) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Tooltip(
              message: user.name,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _getColorForUser(user.userId),
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildInitials(user.name);
                          },
                        ),
                      )
                    : _buildInitials(user.name),
              ),
            ),
          )),
          
          // Show "+X more" if there are more than 5 users
          if (activeUsers.length > 5)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '+${activeUsers.length - 5}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join('').toUpperCase();
    return Text(
      initials.substring(0, initials.length > 2 ? 2 : initials.length),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Color _getColorForUser(String userId) {
    // Generate consistent color based on userId
    final hash = userId.hashCode;
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
}

class ActiveUser {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;

  const ActiveUser({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
