import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/project_service.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectService _projectService;

  ProjectBloc(this._projectService) : super(ProjectState.initial()) {
    on<LoadProjects>(_onLoadProjects);
    on<CreateProject>(_onCreateProject);
    on<UpdateProject>(_onUpdateProject);
    on<DeleteProject>(_onDeleteProject);
    on<LoadProjectPages>(_onLoadProjectPages);
    on<LoadProjectMembers>(_onLoadProjectMembers);
    on<AddProjectMember>(_onAddProjectMember);
    on<RemoveProjectMember>(_onRemoveProjectMember);
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(projectsLoading: true, clearError: true));
    try {
      final projects = await _projectService.getUserProjects();
      emit(state.copyWith(projects: projects, projectsLoading: false));
    } catch (e) {
      emit(state.copyWith(
        projectsLoading: false,
        error: 'Failed to load projects: $e',
      ));
    }
  }

  Future<void> _onCreateProject(
    CreateProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final project = await _projectService.createProject(
        name: event.name,
        description: event.description,
      );
      emit(state.copyWith(
        projects: [project, ...state.projects],
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to create project: $e',
      ));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final updated = await _projectService.updateProject(
        event.projectId,
        name: event.name,
        description: event.description,
      );
      if (updated == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Project not found or permission denied',
        ));
        return;
      }
      final updatedList = state.projects
          .map((p) => p.id == event.projectId ? updated : p)
          .toList();
      emit(state.copyWith(projects: updatedList, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to update project: $e',
      ));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _projectService.deleteProject(event.projectId);
      final remaining =
          state.projects.where((p) => p.id != event.projectId).toList();
      emit(state.copyWith(projects: remaining, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to delete project: $e',
      ));
    }
  }

  Future<void> _onLoadProjectPages(
    LoadProjectPages event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(
      pagesLoading: true,
      currentProjectId: event.projectId,
      clearError: true,
    ));
    try {
      final pages = await _projectService.getProjectPages(event.projectId);
      emit(state.copyWith(currentProjectPages: pages, pagesLoading: false));
    } catch (e) {
      emit(state.copyWith(
        pagesLoading: false,
        error: 'Failed to load project pages: $e',
      ));
    }
  }

  Future<void> _onLoadProjectMembers(
    LoadProjectMembers event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(membersLoading: true, clearError: true));
    try {
      final members = await _projectService.getMembers(event.projectId);
      emit(state.copyWith(
        currentProjectMembers: members,
        membersLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        membersLoading: false,
        error: 'Failed to load members: $e',
      ));
    }
  }

  Future<void> _onAddProjectMember(
    AddProjectMember event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _projectService.addMember(
        projectId: event.projectId,
        email: event.email,
        permissionType: event.permissionType,
      );
      // Refresh member list.
      final members = await _projectService.getMembers(event.projectId);
      emit(state.copyWith(
        currentProjectMembers: members,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to add member: $e',
      ));
    }
  }

  Future<void> _onRemoveProjectMember(
    RemoveProjectMember event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _projectService.removeMember(
        projectId: event.projectId,
        userId: event.userId,
      );
      final remaining = state.currentProjectMembers
          .where((m) => m.id != event.userId)
          .toList();
      emit(state.copyWith(
        currentProjectMembers: remaining,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to remove member: $e',
      ));
    }
  }
}
