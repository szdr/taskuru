import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_list.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskList _taskList = TaskList();

  @override
  void initState() {
    super.initState();
    _taskList.loadTasks().then((_) {
      // データの読み込みが完了したらタイマーを開始
      _taskList.startTimer();
    });
  }

  @override
  void dispose() {
    // 画面が破棄されるときにリソースを解放
    _taskList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('たすくる'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context),
            ),
          ],
        ),
        body: SafeArea(
            child: StreamBuilder<List<Task>>(
                stream: _taskList.tasksStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!;
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text('タスクがありません。\n右上の＋ボタンから追加してください。'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  );
                })));
  }

  Widget _buildTaskCard(Task task) {
    Color getProgressColor(double progress) {
      if (progress >= 0.9) return Colors.red;
      if (progress >= 0.5) return Colors.orange;
      return Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showResetConfirmationDialog(task),
                  child: const Text('タイマーリセット'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(task),
                  tooltip: 'タスクを削除',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.getDisplayCycleTime()),
            const SizedBox(height: 8),
            // プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  getProgressColor(task.progress),
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text('残り: ${task.getDisplayRemainingTime()}'),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    String title = '';
    TimeUnit timeUnit = TimeUnit.hour;
    int amount = 1;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text('新しいタスク'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'タイトル'),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: '時間'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                amount = int.tryParse(value) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<TimeUnit>(
                          value: timeUnit,
                          items: TimeUnit.values.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit == TimeUnit.hour ? '時間' : '日'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              if (value != null) timeUnit = value;
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                      onPressed: () {
                        if (title.isNotEmpty && amount > 0) {
                          _taskList.addTask(
                            title: title,
                            amount: amount,
                            timeUnit: timeUnit,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('追加'))
                ],
              );
            }));
  }

  void _showResetConfirmationDialog(Task task) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('タイマーのリセット'),
                content: Text('「${task.title}」のタイマーをリセットしてもよろしいですか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                      onPressed: () {
                        _taskList.resetTask(task.id);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('「${task.title}」のタイマーをリセットしました'),
                          duration: const Duration(seconds: 3),
                        ));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('リセット'))
                ]));
  }

  void _showDeleteConfirmationDialog(Task task) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('タスクの削除'),
                content: Text('「${task.title}」を削除してもよろしいですか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                      onPressed: () {
                        _taskList.removeTask(task.id);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('「${task.title}」を削除しました'),
                          duration: const Duration(seconds: 3),
                        ));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('削除'))
                ]));
  }
}
