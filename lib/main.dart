import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TextInputScreen(),
    );
  }
}

class TextInputScreen extends StatefulWidget {
  @override
  _TextInputScreenState createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final TextEditingController _attendeesController = TextEditingController();
  final TextEditingController _winnersController = TextEditingController();
  String _result = '';

  Future<void> _saveText() async {
    String attendeesInput = _attendeesController.text;
    String winnersInput = _winnersController.text;
    List<String> attendees = attendeesInput.split('/');
    List<String> winners = winnersInput.split('/');

    final prefs = await SharedPreferences.getInstance();

    // Load previous counts
    Map<String, int> totalCounts = {};
    Map<String, int> winCounts = {};

    Set<String> allNames = {};

    // Retrieve existing data from SharedPreferences
    prefs.getKeys().forEach((key) {
      if (key.startsWith('total_')) {
        String name = key.substring(6);
        totalCounts[name] = prefs.getInt(key) ?? 0;
        allNames.add(name);
      } else if (key.startsWith('win_')) {
        String name = key.substring(4);
        winCounts[name] = prefs.getInt(key) ?? 0;
        allNames.add(name);
      }
    });

    // Update with new data
    for (String attendee in attendees) {
      attendee = attendee.trim();
      if (attendee.isNotEmpty) {
        totalCounts[attendee] = (totalCounts[attendee] ?? 0) + 1;
        allNames.add(attendee);
      }
    }

    for (String winner in winners) {
      winner = winner.trim();
      if (winner.isNotEmpty) {
        winCounts[winner] = (winCounts[winner] ?? 0) + 1;
        allNames.add(winner);
      }
    }

    // Save updated counts
    for (String name in allNames) {
      await prefs.setInt('total_$name', totalCounts[name] ?? 0);
      await prefs.setInt('win_$name', winCounts[name] ?? 0);
    }

    // Generate result string
    _generateResult(totalCounts, winCounts, allNames);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Texts saved and displayed successfully!')),
    );
  }

  void _generateResult(Map<String, int> totalCounts, Map<String, int> winCounts, Set<String> allNames) {
    List<String> resultLines = [];
    for (String name in allNames) {
      int total = totalCounts[name] ?? 0;
      int wins = winCounts[name] ?? 0;
      double percentage = total > 0 ? (wins / total) * 100 : 0;
      resultLines.add('$name $wins/$total ${percentage.toStringAsFixed(1)}%');
    }

    setState(() {
      _result = resultLines.join('\n');
    });
  }

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      _result = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data cleared successfully!')),
    );
  }

  Future<void> _showCurrentResult() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, int> totalCounts = {};
    Map<String, int> winCounts = {};

    Set<String> allNames = {};

    // Retrieve existing data from SharedPreferences
    prefs.getKeys().forEach((key) {
      if (key.startsWith('total_')) {
        String name = key.substring(6);
        totalCounts[name] = prefs.getInt(key) ?? 0;
        allNames.add(name);
      } else if (key.startsWith('win_')) {
        String name = key.substring(4);
        winCounts[name] = prefs.getInt(key) ?? 0;
        allNames.add(name);
      }
    });

    // Generate result string
    _generateResult(totalCounts, winCounts, allNames);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('커피 내기 리스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _attendeesController,
              decoration: InputDecoration(
                hintText: '참석자 (/구분)',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _winnersController,
              decoration: InputDecoration(
                hintText: '패배자 (/구분)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveText,
              child: Text('저장'),
            ),
            ElevatedButton(
              onPressed: _clearData,
              child: Text('초기화'),
            ),
            ElevatedButton(
              onPressed: _showCurrentResult,
              child: Text('결과보기'),
            ),
            SizedBox(height: 20),
            Text(_result),
          ],
        ),
      ),
    );
  }
}
