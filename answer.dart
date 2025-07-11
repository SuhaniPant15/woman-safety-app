import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnswerPage extends StatefulWidget {
  final String questionId;
  final String question;

  AnswerPage({required this.questionId, required this.question});

  @override
  _AnswerPageState createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> {
  final TextEditingController _answerController = TextEditingController();

  void _postAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('community')
        .doc(widget.questionId)
        .collection('answers')
        .add({
      'answer': _answerController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _answerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[200],
        title: Text('Answers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            width: double.infinity,
            color: lilac.withOpacity(0.2),
            child: Text(
              widget.question,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: 'Write your answer...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: deepPurple),
                  onPressed: _postAnswer,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community')
                  .doc(widget.questionId)
                  .collection('answers')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('No answers yet. Be the first!'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(data['answer'] ?? 'No Answer'),
                        subtitle: data['timestamp'] != null
                            ? Text(timeAgo(data['timestamp'].toDate()), style: TextStyle(color: Colors.grey))
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Colors
const lilac = Color(0xFFC8A2C8);
const deepPurple = Color(0xFF673AB7);

// Time Ago Helper
String timeAgo(DateTime date) {
  Duration diff = DateTime.now().difference(date);
  if (diff.inDays > 1) return '${diff.inDays} days ago';
  if (diff.inHours > 1) return '${diff.inHours} hours ago';
  if (diff.inMinutes > 1) return '${diff.inMinutes} minutes ago';
  return 'Just now';
}
