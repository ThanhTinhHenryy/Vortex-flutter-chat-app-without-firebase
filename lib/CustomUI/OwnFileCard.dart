import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Screens/FullImageView.dart';

class OwnFileCard extends StatelessWidget {
  const OwnFileCard({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = path.startsWith('http');
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Container(
          height: MediaQuery.of(context).size.height / 2.3,
          width: MediaQuery.of(context).size.width / 1.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.teal[200],
          ),
          child: Card(
            margin: EdgeInsets.all(2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullImageView(path: path),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: isNetwork
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
