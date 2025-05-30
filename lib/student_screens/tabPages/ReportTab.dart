import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../global.dart';
import 'package:http_parser/http_parser.dart';


// User Model
class User {
  final int id;
  final String? fname;
  final String? lname;
  final String username;
  final String? phone;
  final String email;
  final String? role;
  final int? departmentId;
  final DateTime? joinDate;
  final DateTime? lastLoginDate;

  User({
    required this.id,
    this.fname,
    this.lname,
    required this.username,
    this.phone,
    required this.email,
    this.role,
    this.departmentId,
    this.joinDate,
    this.lastLoginDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fname: json['fname'],
      lname: json['lname'],
      username: json['username'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      departmentId: json['departmentId'],
      joinDate: json['joinDate'] != null ? DateTime.parse(json['joinDate']) : null,
      lastLoginDate: json['lastLoginDate'] != null ? DateTime.parse(json['lastLoginDate']) : null,
    );
  }
}

// Updated StudentRequest Model
class StudentRequest {
  final int id;
  final String requestHeader;
  final String requestBody;
  final DateTime? requestDate;
  final String requestStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? attachmentFile;
  final User user;

  StudentRequest({
    required this.id,
    required this.requestHeader,
    required this.requestBody,
    this.requestDate,
    required this.requestStatus,
    this.createdAt,
    this.updatedAt,
    this.attachmentFile,
    required this.user,
  });

  factory StudentRequest.fromJson(Map<String, dynamic> json) {
    return StudentRequest(
      id: json['id'],
      requestHeader: json['requestHeader'],
      requestBody: json['requestBody'],
      requestDate: json['requestDate'] != null ? DateTime.parse(json['requestDate']) : null,
      requestStatus: json['requestStatus'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      attachmentFile: json['attachmentFile'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestHeader': requestHeader,
      'requestBody': requestBody,
      'requestStatus': requestStatus,
      'requestDate': DateTime.now().toIso8601String(),
      'attachmentFile': attachmentFile,
    };
  }
}
class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudentRequest> requests = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    // Return early if globalUserId is null
    if (globalUserId == null) {
      setState(() {
        error = 'User ID not found. Please log in again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Modified endpoint to fetch only the current user's requests
      final response = await http.get(
        Uri.parse('$api/student-requests/getStudentRequestsByUserId/$globalUserId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          requests = data.map((json) => StudentRequest.fromJson(json)).toList();
        });
      } else {
        setState(() {
          error = 'Failed to load requests: Server error';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load requests: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Student Requests'), // Updated title to reflect it's user-specific
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NewRequestForm(onRequestSubmitted: fetchRequests),
          RequestsList(
            requests: requests,
            isLoading: isLoading,
            error: error,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class NewRequestForm extends StatefulWidget {
  final VoidCallback onRequestSubmitted;

  const NewRequestForm({super.key, required this.onRequestSubmitted});

  @override
  State<NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<NewRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  PlatformFile? _selectedFile;
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = _selectedFile!.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user ID is available
    if (globalUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in again.')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$api/student-requests/addStudentRequest/$globalUserId'),
      );

      // Add file if selected
      if (_selectedFile != null) {
        final file = await http.MultipartFile.fromPath(
          'attachmentFile',
          _selectedFile!.path!,
          // Set the content type for the file
          contentType: MediaType('image', 'jpeg'), // Adjust based on your file type
        );
        request.files.add(file);
      }

      // Create the student request JSON
      final requestData = {
        'requestHeader': _headerController.text,
        'requestBody': _bodyController.text,
        'requestStatus': 'PENDING',
        'requestDate': DateTime.now().toIso8601String(),
      };

      // Add the JSON part with correct content type
      final studentRequestPart = http.MultipartFile.fromString(
        'studentRequest',
        json.encode(requestData),
        contentType: MediaType('application', 'json'),
      );
      request.files.add(studentRequestPart);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _headerController.clear();
        _bodyController.clear();
        setState(() {
          _selectedFile = null;
          _fileName = null;
        });
        widget.onRequestSubmitted();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully')),
          );
        }
      } else {
        throw Exception('Failed to submit request: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _headerController,
              decoration: const InputDecoration(
                labelText: 'Request Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Request Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter request details';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // File attachment section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fileName ?? 'No file selected',
                          style: TextStyle(
                            color: _fileName != null ? Colors.black87 : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose File'),
                      ),
                    ],
                  ),
                  if (_fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                          setState(() {
                            _selectedFile = null;
                            _fileName = null;
                          });
                        },
                        child: const Text('Remove File'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}

class RequestsList extends StatelessWidget {
  final List<StudentRequest> requests;
  final bool isLoading;
  final String? error;

  const RequestsList({
    super.key,
    required this.requests,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (context is _ReportTabState) {
                  (context as _ReportTabState).fetchRequests();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: EdgeInsets.zero,
            title: Text(
              request.requestHeader,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.requestStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    request.requestStatus,
                    style: TextStyle(
                      color: _getStatusColor(request.requestStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestBody,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.user.email,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (request.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(request.createdAt!),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green[600]!;
      case 'REJECTED':
        return Colors.red[600]!;
      case 'PENDING':
        return Colors.orange[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}