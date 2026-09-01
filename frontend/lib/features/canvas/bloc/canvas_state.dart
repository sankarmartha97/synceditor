import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/canvas_widget.dart';
import '../widgets/user_presence_indicator.dart';

class CanvasState extends Equatable {
  final List<CanvasWidget> widgets;
  final String? selectedWidgetId;
  final Color canvasBackgroundColor;
  final String? currentCanvasId;
  final bool isLoading;
  final String? error;
  final List<ActiveUser> activeUsers;
  final List<List<CanvasWidget>> undoHistory;
  final List<List<CanvasWidget>> redoHistory;
  final Map<String, RemoteCursor> remoteCursors;

  const CanvasState({
    this.widgets = const [],
    this.selectedWidgetId,
    this.canvasBackgroundColor = const Color(0xFFF5F5F5),
    this.currentCanvasId,
    this.isLoading = false,
    this.error,
    this.activeUsers = const [],
    this.undoHistory = const [],
    this.redoHistory = const [],
    this.remoteCursors = const {},
  });

  CanvasWidget? get selectedWidget {
    if (selectedWidgetId == null) return null;
    try {
      return widgets.firstWhere((w) => w.id == selectedWidgetId);
    } catch (e) {
      return null;
    }
  }

  CanvasState copyWith({
    List<CanvasWidget>? widgets,
    String? selectedWidgetId,
    Color? canvasBackgroundColor,
    String? currentCanvasId,
    bool? isLoading,
    String? error,
    List<ActiveUser>? activeUsers,
    List<List<CanvasWidget>>? undoHistory,
    List<List<CanvasWidget>>? redoHistory,
    Map<String, RemoteCursor>? remoteCursors,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return CanvasState(
      widgets: widgets ?? this.widgets,
      selectedWidgetId: clearSelection
          ? null
          : (selectedWidgetId ?? this.selectedWidgetId),
      canvasBackgroundColor:
          canvasBackgroundColor ?? this.canvasBackgroundColor,
      currentCanvasId: currentCanvasId ?? this.currentCanvasId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeUsers: activeUsers ?? this.activeUsers,
      undoHistory: undoHistory ?? this.undoHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      remoteCursors: remoteCursors ?? this.remoteCursors,
    );
  }

  @override
  List<Object?> get props => [
    widgets,
    selectedWidgetId,
    canvasBackgroundColor,
    currentCanvasId,
    isLoading,
    error,
    activeUsers,
    undoHistory,
    redoHistory,
    remoteCursors,
  ];
}

class RemoteCursor {
  final String userId;
  final String userName;
  final Offset position;
  final Color color;

  const RemoteCursor({
    required this.userId,
    required this.userName,
    required this.position,
    required this.color,
  });

  RemoteCursor copyWith({Offset? position}) {
    return RemoteCursor(
      userId: userId,
      userName: userName,
      position: position ?? this.position,
      color: color,
    );
  }
}
