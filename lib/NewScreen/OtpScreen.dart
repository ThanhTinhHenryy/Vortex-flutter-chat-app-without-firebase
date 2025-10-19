import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.number, required this.countryCode});
  final String number;
  final String countryCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Xác nhận ${widget.countryCode} ${widget.number}",
          style: TextStyle(color: Colors.teal[800], fontSize: 16.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          children: [
            SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Chúng tui sẽ gửi mã OTP đến ",
                    style: TextStyle(color: Colors.teal[800], fontSize: 14.5),
                  ),
                  TextSpan(
                    text: widget.countryCode + " " + widget.number,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: " Wrong number?",
                    style: TextStyle(color: Colors.cyan, fontSize: 15),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            OTPTextField(
              length: 6,
              width: MediaQuery.of(context).size.width,
              fieldWidth: 30,
              style: TextStyle(fontSize: 17),
              textFieldAlignment: MainAxisAlignment.spaceAround,
              fieldStyle: FieldStyle.underline,
              onCompleted: (pin) {
                print("Completed: " + pin);
              },
            ),
            SizedBox(height: 20),
            Text(
              "Enter 6-digit code",
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            SizedBox(height: 30),
            bottomButton("Gửi lại SMS", Icons.message),
            SizedBox(height: 12),
            Divider(thickness: 1.5, color: Colors.grey[200]),
            SizedBox(height: 12),
            bottomButton("Gọi tôi", Icons.message),
          ],
        ),
      ),
    );
  }

  Widget bottomButton(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        SizedBox(width: 25),
        Text(text, style: TextStyle(color: Colors.teal[800], fontSize: 14.5)),
      ],
    );
  }
}
