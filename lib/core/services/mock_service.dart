import 'dart:math';
import '../../features/dashboard/domain/activity_model.dart';
import '../../features/dashboard/domain/task_model.dart';
import '../../features/settings/domain/user_profile.dart';
import '../../features/settings/domain/user_settings.dart';

class MockService {
  MockService._();

  static Future<void> delay() async {
    final ms = 300 + Random().nextInt(500);
    await Future.delayed(Duration(milliseconds: ms));
  }

  static Future<List<ActivityItem>> getActivity() async {
    await delay();
    final now = DateTime.now();
    return [
      ActivityItem(
        id: 'a1',
        type: ActivityType.message,
        title: 'New message from Alice Chen',
        description: 'Hey, loved your digital card! Can we connect?',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityItem(
        id: 'a2',
        type: ActivityType.meeting,
        title: 'Meeting scheduled',
        description: 'Product Team Sync · Tomorrow 10:00 AM',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      ActivityItem(
        id: 'a3',
        type: ActivityType.connection,
        title: 'Connection request',
        description: 'Bob Smith (CTO at TechCorp) wants to connect',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityItem(
        id: 'a4',
        type: ActivityType.view,
        title: 'Card viewed',
        description: 'Sarah Johnson viewed your "Professional" card',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      ActivityItem(
        id: 'a5',
        type: ActivityType.task,
        title: 'Task completed',
        description: 'Q4 Report · Marked as done',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      ActivityItem(
        id: 'a6',
        type: ActivityType.message,
        title: 'New message',
        description: 'Dev Team: Stand-up notes are ready',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityItem(
        id: 'a7',
        type: ActivityType.meeting,
        title: 'Meeting updated',
        description: 'Design Review rescheduled to Friday 2 PM',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      ActivityItem(
        id: 'a8',
        type: ActivityType.connection,
        title: 'Connection accepted',
        description: 'Michael Lee accepted your request',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      ActivityItem(
        id: 'a9',
        type: ActivityType.view,
        title: 'Card shared',
        description: 'Your card was shared via LinkedIn',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      ActivityItem(
        id: 'a10',
        type: ActivityType.task,
        title: 'Task completed',
        description: 'Profile update · Marked as done',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static Future<List<TaskModel>> getTasks() async {
    await delay();
    final now = DateTime.now();
    return [
      TaskModel(
        id: 't1',
        title: 'Review Q4 marketing materials',
        description: 'Go through deck and provide feedback',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TaskModel(
        id: 't2',
        title: 'Schedule team standup',
        description: null,
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TaskModel(
        id: 't3',
        title: 'Update digital card',
        description: 'Add new role and LinkedIn URL',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        dueDate: null,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      TaskModel(
        id: 't4',
        title: 'Send connection requests',
        description: null,
        status: TaskStatus.pending,
        priority: TaskPriority.low,
        dueDate: null,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      TaskModel(
        id: 't5',
        title: 'Prepare client demo',
        description: 'Showcase new networking features',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<int> getTaskCount() async {
    final tasks = await getTasks();
    return tasks.where((t) => t.status != TaskStatus.completed).length;
  }

  static Future<UserProfile> getUserProfile() async {
    await delay();
    return const UserProfile(
      id: 'mock_user_001',
      email: 'john.doe@digitalcard.io',
      fullName: 'John Doe',
      phone: '+880 1234-567890',
      designation: 'Software Engineer',
      department: 'Engineering',
      company: 'DigitalCard Inc',
    );
  }

  static Future<UserSettings> getUserSettings() async {
    await delay();
    return UserSettings.defaults;
  }

  static Future<UserProfile> updateUserProfile(UserProfile profile) async {
    await delay();
    return profile;
  }

  static Future<UserSettings> updateUserSettings(UserSettings settings) async {
    await delay();
    return settings;
  }
}
