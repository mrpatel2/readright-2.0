import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_repository.dart';

class ClassManagementScreen extends StatefulWidget {
  final String teacherId;
  final String classId;
  final String className;

  const ClassManagementScreen({
    super.key,
    required this.teacherId,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final StudentRepository _repo = StudentRepository();
  late Future<List<Student>> _futureStudents;

  @override
  void initState() {
    super.initState();
    _futureStudents = _repo.getStudents(
      teacherId: widget.teacherId,
      classId: widget.classId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futureStudents = _repo.getStudents(
        teacherId: widget.teacherId,
        classId: widget.classId,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // ADD STUDENT DIALOG
  // ---------------------------------------------------------------------------

  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    String selectedAvatar = 'tiger';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Add Student to ${widget.className}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN (optional, 2–4 digits)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose an avatar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _avatarChip('tiger', '🐯', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('fox', '🦊', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('bear', '🐻', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('panda', '🐼', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('bunny', '🐰', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('frog', '🐸', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    await _repo.addStudent(
                      teacherId: widget.teacherId,
                      classId: widget.classId,
                      name: name,
                      avatar: selectedAvatar,
                      pin: pinController.text.trim(),
                    );

                    if (!mounted) return;
                    Navigator.pop(context);
                    _refresh();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EDIT STUDENT DIALOG
  // ---------------------------------------------------------------------------

  void _showEditStudentDialog(Student student) {
    final nameController = TextEditingController(text: student.name);
    final pinController = TextEditingController(text: student.pin);
    String selectedAvatar = student.avatar;
    bool isAudioEnabled = student.isAudioRecordingEnabled;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit ${student.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN (optional, 2–4 digits)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose an avatar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _avatarChip('tiger', '🐯', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('fox', '🦊', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('bear', '🐻', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('panda', '🐼', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('bunny', '🐰', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                        _avatarChip('frog', '🐸', selectedAvatar, (v) {
                          setModalState(() => selectedAvatar = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Audio Recording'),
                      value: isAudioEnabled,
                      onChanged: (bool value) {
                        setModalState(() {
                          isAudioEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                // --- CANCEL ---
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                // --- DELETE STUDENT ---
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Delete ${student.name}?'),
                        content: const Text(
                          'This will permanently remove the student from this class.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await _repo.deleteStudent(
                        teacherId: widget.teacherId,
                        classId: widget.classId,
                        studentId: student.id,
                      );

                      if (!mounted) return;

                      Navigator.pop(context); // close edit dialog
                      _refresh();
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                // --- SAVE ---
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    await _repo.updateStudent(
                      studentId: student.id,
                      teacherId: widget.teacherId,
                      classId: widget.classId,
                      name: name,
                      avatar: selectedAvatar,
                      pin: pinController.text.trim(),
                      isAudioRecordingEnabled: isAudioEnabled,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);
                    _refresh();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // IMPORT LIST DIALOG
  // ---------------------------------------------------------------------------

  void _showImportDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Class List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste one student name per line.\nExample:\nAlice\nBobby\nChloe\nDaniel',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Alice\nBobby\nChloe\nDaniel',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final raw = textController.text;
                final names = raw.split('\n');

                await _repo.importStudents(
                  teacherId: widget.teacherId,
                  classId: widget.classId,
                  names: names,
                );

                if (!mounted) return;
                Navigator.pop(context);
                _refresh();
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AVATAR CHIP (used for Add + Edit)
  // ---------------------------------------------------------------------------

  Widget _avatarChip(
    String value,
    String emoji,
    String selected,
    void Function(String) onSelected,
  ) {
    final bool isSelected = value == selected;

    return ChoiceChip(
      label: Text(emoji),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage ${widget.className}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add + Import
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddStudentDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Student'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import List'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Student grid
            Expanded(
              child: FutureBuilder<List<Student>>(
                future: _futureStudents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading students.'));
                  }

                  final students = snapshot.data ?? [];

                  if (students.isEmpty) {
                    return const Center(
                      child: Text(
                        'No students yet.\nUse "Add Student" or "Import List".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _buildStudentTile(s);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Student tile
  // ---------------------------------------------------------------------------

  Widget _buildStudentTile(Student s) {
    final emoji = _emojiForAvatar(s.avatar);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditStudentDialog(s), // <-- EDIT ACTION
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                s.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (s.pin.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'PIN: ${s.pin}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar emoji mapping
  // ---------------------------------------------------------------------------

  String _emojiForAvatar(String avatar) {
    switch (avatar) {
      case 'tiger':
        return '🐯';
      case 'fox':
        return '🦊';
      case 'bear':
        return '🐻';
      case 'panda':
        return '🐼';
      case 'bunny':
        return '🐰';
      case 'frog':
        return '🐸';
      case 'lion':
        return '🦁';
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐶';
      default:
        return '🙂';
    }
  }
}
