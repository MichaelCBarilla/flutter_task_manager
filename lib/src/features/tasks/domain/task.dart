// ignore_for_file: public_member_api_docs, sort_constructors_first
class Task {
  const Task({required this.pid, required this.name});

  final String pid;
  final String name;

  @override
  String toString() => 'Task(pid: $pid, name: $name)';

  @override
  bool operator ==(covariant Task other) {
    if (identical(this, other)) return true;

    return other.pid == pid && other.name == name;
  }

  @override
  int get hashCode => pid.hashCode ^ name.hashCode;
}
