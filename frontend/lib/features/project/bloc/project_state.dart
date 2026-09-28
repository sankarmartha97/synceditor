import 'package:equatable/equatable.dart';
import '../../../core/models/project.dart';
import '../../../core/models/page.dart' show PageListItem;

class ProjectState extends Equatable {
  final List<ProjectListItem> projects;
  final bool projectsLoading;

  final List<PageListItem> currentProjectPages;
  final bool pagesLoading;

  final List<ProjectMember> currentProjectMembers;
  final bool membersLoading;

  final String? currentProjectId;

  final bool isLoading;
  final String? error;

  const ProjectState({
    this.projects = const [],
    this.projectsLoading = false,
    this.currentProjectPages = const [],
    this.pagesLoading = false,
    this.currentProjectMembers = const [],
    this.membersLoading = false,
    this.currentProjectId,
    this.isLoading = false,
    this.error,
  });

  factory ProjectState.initial() => const ProjectState();

  ProjectListItem? get currentProject {
    if (currentProjectId == null) return null;
    try {
      return projects.firstWhere((p) => p.id == currentProjectId);
    } catch (_) {
      return null;
    }
  }

  ProjectState copyWith({
    List<ProjectListItem>? projects,
    bool? projectsLoading,
    List<PageListItem>? currentProjectPages,
    bool? pagesLoading,
    List<ProjectMember>? currentProjectMembers,
    bool? membersLoading,
    String? currentProjectId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearCurrentProject = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      projectsLoading: projectsLoading ?? this.projectsLoading,
      currentProjectPages: currentProjectPages ?? this.currentProjectPages,
      pagesLoading: pagesLoading ?? this.pagesLoading,
      currentProjectMembers:
          currentProjectMembers ?? this.currentProjectMembers,
      membersLoading: membersLoading ?? this.membersLoading,
      currentProjectId: clearCurrentProject
          ? null
          : (currentProjectId ?? this.currentProjectId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    projects,
    projectsLoading,
    currentProjectPages,
    pagesLoading,
    currentProjectMembers,
    membersLoading,
    currentProjectId,
    isLoading,
    error,
  ];
}
