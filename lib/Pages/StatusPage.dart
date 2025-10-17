import 'package:chat_app_flutter/CustomUI/statuspage/HeadOwnStatus.dart';
import 'package:chat_app_flutter/CustomUI/statuspage/OtherStatus.dart';
import 'package:flutter/material.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 48,
            child: FloatingActionButton(
              onPressed: () {},
              elevation: 8,
              backgroundColor: Colors.blueGrey[100],
              child: Icon(Icons.edit, color: Colors.blueGrey[900]),
            ),
          ),
          SizedBox(height: 13),
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.greenAccent[700],
            elevation: 5,
            child: Icon(Icons.camera_alt, color: Colors.blueGrey[900]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeadOwnStatus(),
            label("Recent Updates"),

            OtherStatus(
              name: "Tram An",
              imageName: "assets/images/test_1.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Khung",
              imageName: "assets/images/test_2.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Tung",
              imageName: "assets/images/test_3.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An chuoi chien",
              imageName: "assets/images/test_4.jpg",
              time: "01:12",
            ),
            SizedBox(height: 10),
            label("Viewed Updates"),
            OtherStatus(
              name: "Tram An",
              imageName: "assets/images/test_1.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Khung",
              imageName: "assets/images/test_2.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Tung",
              imageName: "assets/images/test_3.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An chuoi chien",
              imageName: "assets/images/test_4.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "Tram An",
              imageName: "assets/images/test_1.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Khung",
              imageName: "assets/images/test_2.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An Tung",
              imageName: "assets/images/test_3.jpg",
              time: "01:12",
            ),
            OtherStatus(
              name: "An chuoi chien",
              imageName: "assets/images/test_4.jpg",
              time: "01:12",
            ),
          ],
        ),
      ),
    );
  }

  Widget label(String labelName) {
    return Container(
      height: 33,
      width: MediaQuery.of(context).size.width,
      color: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          labelName,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
