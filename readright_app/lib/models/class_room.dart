class ClassRoom {
  final String id;
  final String name; // e.g. "Mr. Burney - 2A"

  ClassRoom({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
