import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Guide'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Exam Guide',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Exam Guide helps you manage and organize your academic activities effectively. Here is what you can do with this app:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Distribute students into appropriate exam holes.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Manage semester and exam schedules seamlessly.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Create and manage user accounts efficiently.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: Colors.purple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Add departments and courses to structure academic information.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Organize, manage, and stay on top of your academic responsibilities with Exam Guide.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
