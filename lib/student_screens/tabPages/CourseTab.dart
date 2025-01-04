import 'package:flutter/material.dart';
import 'package:exam_guide/global.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CourseTab extends StatefulWidget {
  const CourseTab({super.key});

  @override
  _CourseTabState createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  List<dynamic> courses = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (globalUserId == null) {
      setState(() {
        errorMessage = 'User ID is not available. Please log in again.';
        isLoading = false;
      });
    } else {
      _fetchDepartmentAndCourses(globalUserId!);
    }
  }

  Future<void> _fetchDepartmentAndCourses(int userId) async {
    var baseUrl = api;

    try {
      final userResponse = await http.get(Uri.parse('$baseUrl/user/getUserById/$userId'));
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        setState(() {
          departmentName = userData['department']['name'];
        });
      } else {
        throw Exception('Failed to fetch user department');
      }

      final coursesResponse = await http.get(Uri.parse('$baseUrl/course/user/$userId'));
      if (coursesResponse.statusCode == 200) {
        setState(() {
          courses = json.decode(coursesResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch courses');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching data: ${e.toString()}';
      });
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoRow(course) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildInfoChip(
              Icons.calendar_today,
              'Year ${course['year']}',
            ),
            if (course['semesterSchedule'] != null) ...[
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.schedule,
                course['semesterSchedule']['semesterName'],
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.date_range,
                'Starts: ${_formatDate(course['semesterSchedule']['startDate'])}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.event_busy,
                'Ends: ${_formatDate(course['semesterSchedule']['endDate'])}',
              ),
            ],
            if (course['examSchedule'] != null) ...[
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.event,
                'Exam: ${_formatDate(course['examSchedule']['examDate'])}',
                backgroundColor: Colors.deepPurple.shade100,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard() {
    return Card(
      elevation: 4,
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: Colors.deepPurple, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Department: $departmentName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Your Courses',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildCourseCard(course) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showCourseDetails(context, course),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.book, color: Colors.deepPurple, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCourseInfoRow(course),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  void _showCourseDetails(BuildContext context, course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book, color: Colors.deepPurple, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        course['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course['description'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Text(
                  'Schedule Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCourseInfoRow(course),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (globalUserId != null) {
                    setState(() {
                      isLoading = true;
                      errorMessage = '';
                    });
                    _fetchDepartmentAndCourses(globalUserId!);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Courses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildDepartmentCard(),
          ),
          const SizedBox(height: 8),
          _buildCoursesTitle(),
          const SizedBox(height: 8),
          _buildCourseList(),
        ],
      ),
    );
  }
}