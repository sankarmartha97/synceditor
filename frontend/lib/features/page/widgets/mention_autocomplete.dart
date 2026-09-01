import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// @Mention autocomplete widget
/// Shows user suggestions when typing @ in comment input

/// User suggestion for mentions
class MentionSuggestion {
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;

  MentionSuggestion({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  /// Create from active user
  factory MentionSuggestion.fromActiveUser(Map<String, dynamic> user) {
    return MentionSuggestion(
      userId: user['userId'] ?? user['id'],
      name: user['name'],
      email: user['email'],
      avatarUrl: user['avatarUrl'] ?? user['avatar_url'],
    );
  }

  /// Get mention text
  String get mentionText => '@$name';
}

/// Mention autocomplete overlay
class MentionAutocomplete extends StatelessWidget {
  final List<MentionSuggestion> suggestions;
  final int selectedIndex;
  final Function(MentionSuggestion) onSelect;
  final Offset position;

  const MentionAutocomplete({
    super.key,
    required this.suggestions,
    required this.selectedIndex,
    required this.onSelect,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Positioned(
      left: position.dx,
      bottom: position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final isSelected = index == selectedIndex;

              return InkWell(
                onTap: () => onSelect(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : null,
                  child: Row(
                    children: [
                      // Avatar
                      _buildAvatar(suggestion),
                      const SizedBox(width: 12),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              suggestion.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Selection indicator
                      if (isSelected)
                        Icon(Icons.check, size: 16, color: theme.primaryColor),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(MentionSuggestion suggestion) {
    if (suggestion.avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(suggestion.avatarUrl!),
      );
    }

    // Fallback to initials
    final initials = suggestion.name
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: 16,
      backgroundColor: _getAvatarColor(suggestion.userId),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[userId.hashCode.abs() % colors.length];
  }
}

/// Text field controller with mention support
class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({super.text});

  /// Get current word being typed (for autocomplete)
  String? getCurrentWord() {
    final text = this.text;
    final cursorPos = selection.baseOffset;

    if (cursorPos <= 0 || cursorPos > text.length) return null;

    // Find start of current word
    int start = cursorPos - 1;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != '\n') {
      start--;
    }

    // Check if it starts with @
    if (start < text.length && text[start] == '@') {
      return text.substring(start + 1, cursorPos);
    }

    return null;
  }

  /// Check if we're in mention mode (typing after @)
  bool get isInMentionMode {
    return getCurrentWord() != null;
  }

  /// Insert mention at cursor
  void insertMention(String mention) {
    final text = this.text;
    final cursorPos = selection.baseOffset;

    // Find start of current word (should be @)
    int start = cursorPos - 1;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != '\n') {
      start--;
    }

    // Replace @word with @mention
    final before = text.substring(0, start);
    final after = text.substring(cursorPos);
    final newText = '$before$mention $after';

    this.text = newText;
    selection = TextSelection.collapsed(
      offset: before.length + mention.length + 1,
    );
  }

  /// Extract all mentions from text
  List<String> extractMentions() {
    final mentionRegex = RegExp(r'@(\w+(?:\.\w+)*@?\w*\.?\w*)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }
}

/// Comment input with mention support
class CommentInputWithMentions extends StatefulWidget {
  final String? initialContent;
  final String hintText;
  final VoidCallback? onCancel;
  final Function(String content)? onSubmit;
  final bool isReply;
  final List<MentionSuggestion> availableUsers;

  const CommentInputWithMentions({
    super.key,
    this.initialContent,
    this.hintText = 'Add a comment...',
    this.onCancel,
    this.onSubmit,
    this.isReply = false,
    this.availableUsers = const [],
  });

  @override
  State<CommentInputWithMentions> createState() =>
      _CommentInputWithMentionsState();
}

class _CommentInputWithMentionsState extends State<CommentInputWithMentions> {
  late final MentionTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  List<MentionSuggestion> _filteredSuggestions = [];
  int _selectedSuggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = MentionTextEditingController(text: widget.initialContent);
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      if (_controller.isInMentionMode) {
        final query = _controller.getCurrentWord()?.toLowerCase() ?? '';
        _filteredSuggestions = widget.availableUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
        _selectedSuggestionIndex = 0;
      } else {
        _filteredSuggestions = [];
      }
    });
  }

  void _selectSuggestion(MentionSuggestion suggestion) {
    _controller.insertMention(suggestion.mentionText);
    setState(() {
      _filteredSuggestions = [];
    });
    _focusNode.requestFocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_filteredSuggestions.isEmpty) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex + 1) % _filteredSuggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex - 1) % _filteredSuggestions.length;
          if (_selectedSuggestionIndex < 0) {
            _selectedSuggestionIndex = _filteredSuggestions.length - 1;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        if (_filteredSuggestions.isNotEmpty) {
          _selectSuggestion(_filteredSuggestions[_selectedSuggestionIndex]);
        }
      }
    }
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSubmit?.call(content);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = _controller.text.trim().isEmpty;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isReply ? Colors.grey.shade50 : null,
            border: Border.all(
              color: _isFocused ? theme.primaryColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: _isFocused ? 4 : 1,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.bodyMedium,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_isFocused) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tip: Type @ to mention someone',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.onCancel != null)
                          TextButton(
                            onPressed: widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isEmpty ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(widget.isReply ? 'Reply' : 'Comment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Mention autocomplete overlay
        if (_filteredSuggestions.isNotEmpty)
          MentionAutocomplete(
            suggestions: _filteredSuggestions,
            selectedIndex: _selectedSuggestionIndex,
            onSelect: _selectSuggestion,
            position: const Offset(0, 60), // Position above input
          ),
      ],
    );
  }
}
