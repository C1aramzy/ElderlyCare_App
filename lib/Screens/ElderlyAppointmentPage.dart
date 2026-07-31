import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentPage extends StatefulWidget {
  final int userId;

  const AppointmentPage({super.key, required this.userId});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List appointments = [];
  bool isLoading = true;

  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final String baseUrl =
      "http://elderlym.atspace.cc/ElderlyAppointments";

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    final response = await http.get(
      Uri.parse("$baseUrl/get_appointments.php?user_id=${widget.userId}"),
    );

    final data = jsonDecode(response.body);

    setState(() {
      appointments = data["appointments"] ?? [];
      isLoading = false;
    });
  }

  Future<void> addAppointment() async {
    if (titleController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      showMessage("Please fill in title, date and time");
      return;
    }

    final date =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    final time =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00";

    final response = await http.post(
      Uri.parse("$baseUrl/add_appointment.php"),
      body: {
        "user_id": widget.userId.toString(),
        "title": titleController.text,
        "appointment_date": date,
        "appointment_time": time,
        "location": locationController.text,
        "notes": notesController.text,
      },
    );

    final data = jsonDecode(response.body);
    showMessage(data["message"]);

    if (data["success"] == true) {
      titleController.clear();
      locationController.clear();
      notesController.clear();
      selectedDate = null;
      selectedTime = null;
      fetchAppointments();
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/delete_appointment.php"),
      body: {
        "appointment_id": appointmentId,
      },
    );

    final data = jsonDecode(response.body);
    showMessage(data["message"]);
    fetchAppointments();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Appointment"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Notes"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: pickDate,
                child: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
              ),
              ElevatedButton(
                onPressed: pickTime,
                child: Text(
                  selectedTime == null
                      ? "Select Time"
                      : selectedTime!.format(context),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              addAppointment();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Appointments"),
        backgroundColor: const Color(0xFF3B5F91),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddAppointmentDialog,
        backgroundColor: const Color(0xFF3B5F91),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    "No appointments yet",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: Text(appt["title"]),
                        subtitle: Text(
                          "${appt["appointment_date"]} at ${appt["appointment_time"]}\n"
                          "${appt["location"] ?? ""}\n"
                          "${appt["notes"] ?? ""}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteAppointment(appt["appointment_id"]);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}