import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../global.dart';

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

  ExamHoleAssignment({
    required this.id,
    required this.examHoleId,
    required this.userId,
    required this.seatNumber,
  });

  factory ExamHoleAssignment.fromJson(Map<String, dynamic> json) {
    return ExamHoleAssignment(
      id: json['id'],
      examHoleId: json['examHoleId'],
      userId: json['userId'],
      seatNumber: json['seatNumber'],
    );
  }
}

// Service for API Interactions

class ExamService {
  final String baseUrl = "http://192.168.33.14:8081/api/v1";

  Future<List<ExamHole>> getAllExamHoles() async {
    final response = await http.get(Uri.parse('$baseUrl/examhole/getAllExamHoles'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamHole.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exam holes');
    }
  }

  Future<List<ExamHoleAssignment>> getExamHolesForUser(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/examhole-assignment/getExamHolesForUser/$userId'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamHoleAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user assignments');
    }
  }

  // Fetch all assignments for a specific ExamHole
  Future<List<ExamHoleAssignment>> getAssignmentsForExamHole(int examHoleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/examhole-assignment/getUsersInExamHole/$examHoleId/users'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamHoleAssignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load seat assignments');
    }
  }
}

// Main ExamTab Widget

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

// Widget for Each ExamHole Card

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
                    const Icon(Icons.person_pin_circle, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Your Seat: Teacher Position',
                      style: const TextStyle(
                        color: Colors.green,
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

// Seating Plan Screen
class SeatingPlanScreen extends StatefulWidget {
  final ExamHole examHole;
  final String? userSeatNumber;

  const SeatingPlanScreen({
    Key? key,
    required this.examHole,
    this.userSeatNumber,
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

  // Generates seat names with spaces but ensures all 96 seats are visible
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
        scrollDirection: Axis.vertical, // Enable vertical scroll
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.userSeatNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Your Seat Number: Teacher Position',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scroll
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
            _buildStageDesign(), // Stage design added here
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
          // Door section
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
          // Stage design
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
          // Teacher section
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.orange, 'Your Seat'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.red, 'Occupied Seat'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.grey, 'Available Seat'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class SeatTile extends StatelessWidget {
  final String seatName;
  final bool isCurrentUser;
  final bool isOccupied;
  final int assignedUserId;

  const SeatTile({
    Key? key,
    required this.seatName,
    required this.isCurrentUser,
    required this.isOccupied,
    this.assignedUserId = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color seatColor;
    String displayText = seatName;
    String tooltipText = 'Seat $seatName';

    if (isCurrentUser) {
      seatColor = Colors.green;
      displayText += ' (You)';
      tooltipText += ' - Your Seat';
    } else if (isOccupied) {
      seatColor = Colors.red;
      tooltipText += ' - Occupied';
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
          color: isOccupied
              ? seatColor
              : (isCurrentUser ? seatColor : Colors.grey.shade300),
          border: Border.all(
            color: isCurrentUser
                ? Colors.green.shade700
                : (isOccupied ? Colors.red.shade700 : Colors.grey),
            width: isCurrentUser || isOccupied ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCurrentUser || isOccupied ? Colors.white : Colors.black,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

