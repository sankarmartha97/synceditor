import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/canvas_widget.dart';
import '../widgets/user_presence_indicator.dart';

abstract class CanvasEvent extends Equatable {
  const CanvasEvent();

  @override
  List<Object?> get props => [];
}

class AddWidgetToCanvas extends CanvasEvent {
  final CanvasWidget widget;

  const AddWidgetToCanvas(this.widget);

  @override
  List<Object?> get props => [widget];
}

class UpdateWidgetPosition extends CanvasEvent {
  final String widgetId;
  final Offset position;

  const UpdateWidgetPosition(this.widgetId, this.position);

  @override
  List<Object?> get props => [widgetId, position];
}

class UpdateWidgetSize extends CanvasEvent {
  final String widgetId;
  final Size size;

  const UpdateWidgetSize(this.widgetId, this.size);

  @override
  List<Object?> get props => [widgetId, size];
}

class UpdateWidgetColor extends CanvasEvent {
  final String widgetId;
  final Color color;

  const UpdateWidgetColor(this.widgetId, this.color);

  @override
  List<Object?> get props => [widgetId, color];
}

class SelectWidget extends CanvasEvent {
  final String? widgetId;

  const SelectWidget(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

class DeleteWidget extends CanvasEvent {
  final String widgetId;

  const DeleteWidget(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

class UpdateWidgetText extends CanvasEvent {
  final String widgetId;
  final String text;

  const UpdateWidgetText(this.widgetId, this.text);

  @override
  List<Object?> get props => [widgetId, text];
}

class UpdateWidgetBorderRadius extends CanvasEvent {
  final String widgetId;
  final double borderRadius;

  const UpdateWidgetBorderRadius(this.widgetId, this.borderRadius);

  @override
  List<Object?> get props => [widgetId, borderRadius];
}

class UpdateWidgetOpacity extends CanvasEvent {
  final String widgetId;
  final double opacity;

  const UpdateWidgetOpacity(this.widgetId, this.opacity);

  @override
  List<Object?> get props => [widgetId, opacity];
}

class UpdateWidgetRotation extends CanvasEvent {
  final String widgetId;
  final double rotation;

  const UpdateWidgetRotation(this.widgetId, this.rotation);

  @override
  List<Object?> get props => [widgetId, rotation];
}

class BringWidgetToFront extends CanvasEvent {
  final String widgetId;

  const BringWidgetToFront(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

class SendWidgetToBack extends CanvasEvent {
  final String widgetId;

  const SendWidgetToBack(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}

class UndoAction extends CanvasEvent {
  const UndoAction();
}

class RedoAction extends CanvasEvent {
  const RedoAction();
}

class UserJoined extends CanvasEvent {
  final String userId;
  final String userName;
  final String? email;
  final String? avatarUrl;

  const UserJoined(this.userId, this.userName, {this.email, this.avatarUrl});

  @override
  List<Object?> get props => [userId, userName, email, avatarUrl];
}

class UserLeft extends CanvasEvent {
  final String userId;

  const UserLeft(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateActiveUsers extends CanvasEvent {
  final List<ActiveUser> activeUsers;

  const UpdateActiveUsers(this.activeUsers);

  @override
  List<Object?> get props => [activeUsers];
}

class UpdateCursorPosition extends CanvasEvent {
  final String userId;
  final String userName;
  final Offset position;

  const UpdateCursorPosition(this.userId, this.userName, this.position);

  @override
  List<Object?> get props => [userId, userName, position];
}

class RemoveCursor extends CanvasEvent {
  final String userId;

  const RemoveCursor(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadCanvas extends CanvasEvent {
  final String canvasId;

  const LoadCanvas(this.canvasId);

  @override
  List<Object?> get props => [canvasId];
}

class CreateNewCanvas extends CanvasEvent {
  final String name;
  final String? description;

  const CreateNewCanvas({required this.name, this.description});

  @override
  List<Object?> get props => [name, description];
}

class RemoteWidgetAdded extends CanvasEvent {
  final String widgetId;
  final Map<String, dynamic> widgetData;

  const RemoteWidgetAdded({required this.widgetId, required this.widgetData});

  @override
  List<Object?> get props => [widgetId, widgetData];
}

class RemoteWidgetUpdated extends CanvasEvent {
  final String widgetId;
  final Map<String, dynamic> updates;

  const RemoteWidgetUpdated({required this.widgetId, required this.updates});

  @override
  List<Object?> get props => [widgetId, updates];
}

class RemoteWidgetDeleted extends CanvasEvent {
  final String widgetId;

  const RemoteWidgetDeleted(this.widgetId);

  @override
  List<Object?> get props => [widgetId];
}
