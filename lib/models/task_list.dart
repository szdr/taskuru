import 'dart:async';
import 'package:uuid/uuid.dart';
import 'task.dart';
import '../database/database_helper.dart';

class TaskList {
  final List<Task> _tasks = [];

  // タスクの変更を通知するためのStreamController
  final _taskController = StreamController<List<Task>>.broadcast();

  // タスクリストの変更を監視するためのStream
  Stream<List<Task>> get tasksStream => _taskController.stream;

  // データベースヘルパーのインスタンスを保持
  final _dbHelper = DatabaseHelper.instance;

  // 初期化時にデータベースからタスクを読み込む
  Future<void> loadTasks() async {
    final tasks = await _dbHelper.getAllTasks();
    _tasks.clear();
    _tasks.addAll(tasks);
    _taskController.add(_tasks);
  }

  // 現在のタスクリストを取得
  List<Task> get tasks => List.unmodifiable(_tasks);

  // タスクの追加時にデータベースにも保存
  Future<void> addTask({
    required String title,
    required int amount,
    required TimeUnit timeUnit,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      timeUnit: timeUnit,
    );

    await _dbHelper.insertTask(task);
    _tasks.add(task);
    _taskController.add(_tasks);
  }

  // タスクのリセット時にデータベースも更新
  Future<void> resetTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].reset();
      await _dbHelper.updateTask(_tasks[taskIndex]);
      _taskController.add(_tasks);
    }
  }

  // タスクの削除時にデータベースからも削除
  Future<void> removeTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    _taskController.add(_tasks);
  }

  // タイマーで時間を更新する際にもデータベースを更新
  void startTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      bool hasUpdates = false;

      for (var task in _tasks) {
        if (task.remainingTime > 0) {
          task.remainingTime -= 1;
          await _dbHelper.updateTask(task);
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        _taskController.add(_tasks);
      }
    });
  }

  // TaskListが不要になった時にリソースを解放
  void dispose() {
    _taskController.close();
  }
}
