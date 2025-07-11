import 'package:flutter/material.dart';

class TodoListSection extends StatefulWidget {
  const TodoListSection({super.key});

  @override
  State<TodoListSection> createState() => _TodoListSectionState();
}

class _TodoListSectionState extends State<TodoListSection> {
  final List<_TodoItem> _todos = [
    _TodoItem('Prepare pitch deck'),
  ];

  final TextEditingController _controller = TextEditingController();

  void _toggleDone(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _todos.insert(0, _TodoItem(text));
      _controller.clear();
    });
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header outside container
        Text(
          'Your To-Do List',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),

        // Main container with fixed height
        Container(
          height: screenHeight * 0.4,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add new task...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addTodo,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable list of to-do items
              Expanded(
                child: ListView.separated(
                  itemCount: _todos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final todo = _todos[index];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(vertical: 4),   // smaller margin
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // smaller padding
                      decoration: BoxDecoration(
                        color: todo.isDone
                            ? Colors.greenAccent.withOpacity(0.3)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleDone(index),
                            child: Icon(
                              todo.isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: todo.isDone ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 14,  // smaller font size
                                color: Colors.black87,
                                decoration: todo.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.black26),
                            onPressed: () => _deleteTodo(index),
                            tooltip: 'Delete task',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoItem {
  final String title;
  bool isDone;

  _TodoItem(this.title, {this.isDone = false});
}
