import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import '../../../core/di/providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<TaskModel>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() =>
      ref.watch(taskRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(taskRepositoryProvider).getAll());
  }

  Future<bool> addTask(String title, {String? description}) async {
    try {
      final task =
          await ref.read(taskRepositoryProvider).create(title, description: description);
      state = AsyncData([...?state.valueOrNull, task]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String id, TaskStatus status) async {
    try {
      final updated = await ref
          .read(taskRepositoryProvider)
          .update(id, {'status': status.name});
      state = AsyncData(
        state.valueOrNull
                ?.map((t) => t.id == id ? updated : t)
                .toList() ??
            [],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await ref.read(taskRepositoryProvider).delete(id);
      state = AsyncData(
          state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final pendingTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((t) => t.status == TaskStatus.pending).length;
});
