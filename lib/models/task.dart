enum TimeUnit { hour, day }

class Task {
  final String id;
  final String title;
  final int cycleTime;
  final TimeUnit timeUnit; // 表示用
  int remainingTime; // 残り時間 (分)

  Task({
    required this.id,
    required this.title,
    required int amount,
    required this.timeUnit,
  })  : cycleTime = _convertToMinutes(amount, timeUnit),
        remainingTime = _convertToMinutes(amount, timeUnit);

  static int _convertToMinutes(int amount, TimeUnit unit) {
    if (unit == TimeUnit.hour) {
      return amount * 60;
    } else {
      return amount * 24 * 60;
    }
  }

  String getDisplayRemainingTime() {
    if (timeUnit == TimeUnit.hour) {
      final hours = remainingTime ~/ 60;
      final minutes = remainingTime % 60;

      if (minutes > 0) {
        return '$hours時間 $minutes分';
      } else {
        return '$hours時間';
      }
    } else {
      final days = remainingTime ~/ (24 * 60);
      final hours = (remainingTime % (24 * 60)) ~/ 60;

      if (hours > 0) {
        return '$days日 $hours時間';
      } else {
        return '$days日';
      }
    }
  }

  String getDisplayCycleTime() {
    if (timeUnit == TimeUnit.hour) {
      final hours = cycleTime ~/ 60;
      return '$hours時間ごと';
    } else {
      final days = cycleTime ~/ (24 * 60);
      return '$days日ごと';
    }
  }

  double get progress {
    return 1 - (remainingTime / cycleTime);
  }

  void reset() {
    remainingTime = cycleTime;
  }
}
