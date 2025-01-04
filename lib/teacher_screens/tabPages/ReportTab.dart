import 'package:exam_guide/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TeacherReport extends StatefulWidget {
  final int? userId;
  const TeacherReport({super.key, required this.userId});

  @override
  _TeacherReportState createState() => _TeacherReportState();
}

class _TeacherReportState extends State<TeacherReport> {
  List<dynamic> reports = [];
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  TextEditingController reportHeaderController = TextEditingController();
  TextEditingController reportBodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  @override
  void dispose() {
    reportHeaderController.dispose();
    reportBodyController.dispose();
    super.dispose();
  }

  Future<void> fetchReports() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$api/teacher-reports/getTeacherReportsByUserId/user/${widget.userId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          reports = json.decode(response.body);
          reports.sort((a, b) => DateTime.parse(b['createdAt'] ?? DateTime.now().toString())
              .compareTo(DateTime.parse(a['createdAt'] ?? DateTime.now().toString())));
        });
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      showErrorDialog("Failed to load reports: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$api/teacher-reports/addTeacherReport/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reportHeader': reportHeaderController.text.trim(),
          'reportBody': reportBodyController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        reportHeaderController.clear();
        reportBodyController.clear();
        await fetchReports();
        showSuccessDialog("Report added successfully");
      } else {
        throw Exception('Failed to add report');
      }
    } catch (e) {
      showErrorDialog("Failed to add report: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Reports"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchReports,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: reportHeaderController,
                      decoration: const InputDecoration(
                        labelText: 'Report Header',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a header';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reportBodyController,
                      decoration: const InputDecoration(
                        labelText: 'Report Body',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter report content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : addReport,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Report"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: reports.isEmpty
                  ? const Center(
                child: Text(
                  "No reports available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : const Text(
                "Previous Reports",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final report = reports[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.article),
                      ),
                      title: Text(
                        report['reportHeader'] ?? "No header",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy - HH:mm')
                            .format(DateTime.parse(report['createdAt'] ?? DateTime.now().toString())),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            report['reportBody'] ?? "No content",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: reports.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}