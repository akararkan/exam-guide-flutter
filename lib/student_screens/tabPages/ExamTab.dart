import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../global.dart';

class User {
  final int id;
  final String fname;
  final String lname;
  final String username;
  final String phone;
  final String email;
  final String role;
  final int departmentId;
  final DateTime joinDate;
  final DateTime? lastLoginDate;

  User({
    required this.id,
    required this.fname,
    required this.lname,
    required this.username,
    required this.phone,
    required this.email,
    required this.role,
    required this.departmentId,
    required this.joinDate,
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
      joinDate: DateTime.parse(json['joinDate']),
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
    );
  }
}


// Department Model and Colors
class Department {
  final int id;
  final String name;
  final Color color;

  Department({
    required this.id,
    required this.name,
    required this.color,
  });
}

// Department Color Configuration
class DepartmentConfig {
  static final Map<int, Department> departments = {
    1: Department(id: 1, name: 'IT: Level 2', color: Colors.deepOrange), // More visible than yellow
    2: Department(id: 2, name: 'IT: Level 4', color: Colors.orange), // A clearer orange for better visibility
    3: Department(id: 3, name: 'Gasht w Guzar: Level 2', color: Colors.blueAccent), // A brighter blue for better distinction
    4: Department(id: 4, name: 'Gasht w Guzar: Level 4', color: Colors.cyan), // Lighter cyan for contrast
    5: Department(id: 5, name: 'Darayy w Bank: Level 2', color: Colors.greenAccent), // Brighter green for better visibility
    6: Department(id: 6, name: 'Darayy w Bank: Level 4', color: Colors.lightGreenAccent), // A vivid light green
  };

  static Color getColorForDepartment(int departmentId) {
    return departments[departmentId]?.color ?? Colors.grey;
  }

  static String getDepartmentName(int departmentId) {
    return departments[departmentId]?.name ?? 'Unknown Department';
  }
}


class ExamHole {
  final int id;
  final int number;
  final String holeName;
  final int capacity;
  final int availableSlots;
  final int row;
  final int col;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamHole({
    required this.id,
    required this.number,
    required this.holeName,
    required this.capacity,
    required this.availableSlots,
    required this.row,
    required this.col,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamHole.fromJson(Map<String, dynamic> json) {
    return ExamHole(
      id: json['id'],
      number: json['number'],
      holeName: json['holeName'],
      capacity: json['capacity'],
      availableSlots: json['availableSlots'],
      row: json['row'],
      col: json['col'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class ExamHoleAssignment {
  final int id;
  final int examHoleId;
  final int userId;
  final String seatNumber;
  final int departmentId;

  ExamHoleAssignment({
    required this.id,
    required this.examHoleId,
    required this.userId,
    required this.seatNumber,
    required this.departmentId,
  });

  factory ExamHoleAssignment.fromJson(Map<String, dynamic> json) {
    return ExamHoleAssignment(
      id: json['id'],
      examHoleId: json['examHoleId'],
      userId: json['userId'],
      seatNumber: json['seatNumber'],
      departmentId: json['departmentId'],
    );
  }
}

class ExamService {
  final String baseUrl = api;

  Future<List<ExamHole>> getAllExamHoles() async {
    final response = await http.get(Uri.parse('$baseUrl/examhole/getAllExamHoles'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamHole.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exam holes');
    }
  }

  Map<int, User> userCache = {};

  // New method to fetch user data
  Future<User> getUser(int userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/getAllUsers'),
    );

    if (response.statusCode == 200) {
      List<dynamic> users = json.decode(response.body);
      for (var userData in users) {
        User user = User.fromJson(userData);
        userCache[user.id] = user;
      }

      if (userCache.containsKey(userId)) {
        return userCache[userId]!;
      } else {
        throw Exception('User not found');
      }
    } else {
      throw Exception('Failed to load user data');
    }
  }


  // Modify getExamHolesForUser to include department information
  Future<List<ExamHoleAssignment>> getExamHolesForUser(int userId) async {
    final user = await getUser(userId);
    final response = await http.get(
      Uri.parse('$baseUrl/examhole-assignment/getExamHolesForUser/$userId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamHoleAssignment(
        id: json['id'],
        examHoleId: json['examHoleId'],
        userId: json['userId'],
        seatNumber: json['seatNumber'],
        departmentId: user.departmentId, // Use department ID from user data
      )).toList();
    } else {
      throw Exception('Failed to load user assignments');
    }
  }


  // Modify getAssignmentsForExamHole to include department information
  Future<List<ExamHoleAssignment>> getAssignmentsForExamHole(int examHoleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/examhole-assignment/getUsersInExamHole/$examHoleId/users'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<ExamHoleAssignment> assignments = [];

      for (var json in data) {
        try {
          final user = await getUser(json['userId']);
          assignments.add(ExamHoleAssignment(
            id: json['id'],
            examHoleId: json['examHoleId'],
            userId: json['userId'],
            seatNumber: json['seatNumber'],
            departmentId: user.departmentId, // Use department ID from user data
          ));
        } catch (e) {
          print('Error fetching user data for assignment: $e');
          // Skip this assignment if user data cannot be fetched
          continue;
        }
      }
      return assignments;
    } else {
      throw Exception('Failed to load seat assignments');
    }
  }


}

class ExamTab extends StatefulWidget {
  const ExamTab({Key? key}) : super(key: key);

  @override
  _ExamTabState createState() => _ExamTabState();
}

class _ExamTabState extends State<ExamTab> {
  final ExamService _examService = ExamService();
  List<ExamHole> examHoles = [];
  List<ExamHoleAssignment> userAssignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final holes = await _examService.getAllExamHoles();
      final assignments = await _examService.getExamHolesForUser(globalUserId!);
      setState(() {
        examHoles = holes;
        userAssignments = assignments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Holes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Holes'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: examHoles.length,
        itemBuilder: (context, index) {
          final examHole = examHoles[index];
          final userAssignment = userAssignments.firstWhere(
                (a) => a.examHoleId == examHole.id,
            orElse: () => ExamHoleAssignment(
              id: -1,
              examHoleId: examHole.id,
              userId: -1,
              seatNumber: '',
              departmentId: -1,
            ),
          );
          return ExamHoleCard(
            examHole: examHole,
            userAssignment: userAssignment,
          );
        },
      ),
    );
  }
}

class ExamHoleCard extends StatelessWidget {
  final ExamHole examHole;
  final ExamHoleAssignment userAssignment;

  const ExamHoleCard({
    Key? key,
    required this.examHole,
    required this.userAssignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final departmentName = userAssignment.userId != -1
        ? DepartmentConfig.getDepartmentName(userAssignment.departmentId)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeatingPlanScreen(
                examHole: examHole,
                userSeatNumber: userAssignment.userId != -1 ? userAssignment.seatNumber : null,
                userDepartmentId: userAssignment.userId != -1 ? userAssignment.departmentId : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                examHole.holeName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoItem(
                    Icons.event_seat,
                    'Capacity',
                    '${examHole.capacity}',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    Icons.check_circle_outline,
                    'Available',
                    '${examHole.availableSlots}',
                  ),
                ],
              ),
              if (userAssignment.userId != -1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_pin_circle,
                        color: DepartmentConfig.getColorForDepartment(userAssignment.departmentId)),
                    const SizedBox(width: 4),
                    Text(
                      'Your Seat: ${userAssignment.seatNumber} ($departmentName)',
                      style: TextStyle(
                        color: DepartmentConfig.getColorForDepartment(userAssignment.departmentId),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text('$label: $value'),
      ],
    );
  }
}

class SeatingPlanScreen extends StatefulWidget {
  final ExamHole examHole;
  final String? userSeatNumber;
  final int? userDepartmentId;

  const SeatingPlanScreen({
    Key? key,
    required this.examHole,
    this.userSeatNumber,
    this.userDepartmentId,
  }) : super(key: key);

  @override
  _SeatingPlanScreenState createState() => _SeatingPlanScreenState();
}

class _SeatingPlanScreenState extends State<SeatingPlanScreen> {
  final ExamService _examService = ExamService();
  List<ExamHoleAssignment> allAssignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final assignments = await _examService.getAssignmentsForExamHole(widget.examHole.id);
      setState(() {
        allAssignments = assignments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seat assignments: $e')),
        );
      }
    }
  }

  List<List<String?>> _generateSeatGrid() {
    List<List<String?>> seatGrid = [];

    for (int row = 8; row >= 1; row--) {
      List<String?> seatsInRow = [];
      for (int col = 1; col <= 12; col++) {
        if (col == 4 || col == 9) {
          seatsInRow.add(null); // Space
        } else {
          String seatName = '${_getSeatLetter(col)}$row';
          seatsInRow.add(seatName);
        }
      }
      seatGrid.add(seatsInRow);
    }

    return seatGrid;
  }

  String _getSeatLetter(int col) {
    if (col <= 3) {
      return String.fromCharCode(64 + col); // A, B, C for left section
    } else if (col >= 5 && col <= 8) {
      return String.fromCharCode(64 + (col - 1)); // D, E, F, G for center section
    } else if (col >= 10) {
      return String.fromCharCode(64 + (col - 2)); // H, I, J for right section
    } else {
      return ''; // Empty for gaps
    }
  }

  @override
  Widget build(BuildContext context) {
    final seatGrid = _generateSeatGrid();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examHole.holeName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(16),
          child: Column(
              children: [
              if (widget.userSeatNumber != null)
          Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Your Seat Number: ${widget.userSeatNumber}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.userDepartmentId != null
              ? DepartmentConfig.getColorForDepartment(widget.userDepartmentId!)
              : Colors.green,
        ),
      ),
    ),
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
    children: List.generate(
    seatGrid.length,
    (rowIndex) {
    final rowSeats = seatGrid[rowIndex];
    return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: rowSeats.map((seatName) {
    if (seatName == null) {
    return const SizedBox(width: 40, height: 40);
    }

    final assignment = allAssignments.firstWhere(
    (a) => a.seatNumber.toUpperCase() == seatName.toUpperCase(),
    orElse: () => ExamHoleAssignment(
    id: -1,
    examHoleId: widget.examHole.id,
    userId: -1,
    seatNumber: '',
    departmentId: -1,
    ),
    );

    final isCurrentUser = seatName.toUpperCase() == widget.userSeatNumber?.toUpperCase();
    final isOccupied = assignment.userId != -1;

    return Padding(
    padding: const EdgeInsets.all(4.0),
    child: SeatTile(
      seatName: seatName,
      isCurrentUser: isCurrentUser,
      isOccupied: isOccupied,
      assignedUserId: assignment.userId,
      departmentId: assignment.departmentId,
      userDepartmentId: widget.userDepartmentId,
    ),
    );
    }).toList(),
    ),
    );
    },
    ),
    ),
    ),
                const SizedBox(height: 16),
                _buildStageDesign(),
                const SizedBox(height: 16),
                _buildLegend(),
              ],
          ),
      ),
    );
  }

  Widget _buildStageDesign() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: const [
              Icon(Icons.door_front_door, size: 40, color: Colors.brown),
              SizedBox(height: 8),
              Text(
                'Entrance Door',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            height: 60,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Stage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Column(
            children: const [
              Icon(Icons.person, size: 40, color: Colors.orange),
              SizedBox(height: 8),
              Text(
                'Teacher',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          runSpacing: 8.0,
          children: [
            for (var dept in DepartmentConfig.departments.values)
              _buildLegendItem(
                dept.color,
                dept.name,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegendItem(Colors.grey.shade300, 'Available Seat'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class SeatTile extends StatelessWidget {
  final String seatName;
  final bool isCurrentUser;
  final bool isOccupied;
  final int assignedUserId;
  final int departmentId;
  final int? userDepartmentId;

  const SeatTile({
    Key? key,
    required this.seatName,
    required this.isCurrentUser,
    required this.isOccupied,
    this.assignedUserId = -1,
    required this.departmentId,
    this.userDepartmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color seatColor;
    String displayText = seatName;
    String tooltipText = 'Seat $seatName';
    String departmentName = DepartmentConfig.getDepartmentName(departmentId);

    if (isCurrentUser) {
      seatColor = DepartmentConfig.getColorForDepartment(departmentId);
      displayText += ' (You)';
      tooltipText += ' - Your Seat ($departmentName)';
    } else if (isOccupied) {
      seatColor = DepartmentConfig.getColorForDepartment(departmentId);
      tooltipText += ' - Occupied ($departmentName)';
    } else {
      seatColor = Colors.grey.shade300;
      tooltipText += ' - Available';
    }

    return Tooltip(
      message: tooltipText,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor.withOpacity(0.8),
          border: Border.all(
            color: isCurrentUser ? Colors.black : Colors.grey.shade600,
            width: isCurrentUser ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCurrentUser || isOccupied ? Colors.black : Colors.black87,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}