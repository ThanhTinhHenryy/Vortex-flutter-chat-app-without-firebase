import 'package:chat_app_flutter/Models/CountryModel.dart';
import 'package:chat_app_flutter/NewScreen/CoutryPage.dart';
import 'package:chat_app_flutter/NewScreen/OtpScreen.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String countryName = "Việt Nam";
  String countryCode = "+84";
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Enter your phone number",
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w700,
            wordSpacing: 1,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [Icon(Icons.more_vert, color: Colors.black)],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Text(
              "Vortex will send an sms message to verify your phone number",
              style: TextStyle(fontSize: 13.5),
            ),
            SizedBox(height: 5),
            Text(
              "What's your number?",
              style: TextStyle(fontSize: 11.9, color: Colors.cyan[800]),
            ),
            SizedBox(height: 15),
            countryCard(),
            SizedBox(height: 5),
            number(),
            Expanded(child: Container()),
            InkWell(
              onTap: () {
                if (_controller.text.length < 9) {
                  showMyDialogue_NoNumber();
                } else {
                  showMyDialogue();
                }
              },
              child: Container(
                color: Colors.tealAccent[400],
                height: 40,
                width: 110,
                child: Center(
                  child: Text(
                    "Tiếp theo",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget countryCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => CountryPage(setCountryData: setCountryData),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 1.5,
        padding: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.teal, width: 1.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                child: Center(
                  child: Text(countryName, style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.teal, size: 28),
          ],
        ),
      ),
    );
  }

  Widget number() {
    return Container(
      width: MediaQuery.of(context).size.width / 1.5,

      height: 38,
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 70,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.teal, width: 1.8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 10),
                Text("+", style: TextStyle(fontSize: 18)),
                SizedBox(width: 15),
                Text(countryCode.substring(1), style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          SizedBox(width: 30),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.teal, width: 1.8),
              ),
            ),
            width: MediaQuery.of(context).size.width / 1.5 - 100,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(8),
                hintText: "Số điện thoại",
              ),
            ),
          ),
        ],
      ),
    );
  }

  void setCountryData(CountryModel country) {
    setState(() {
      countryName = country.name;
      countryCode = country.code;
    });
    Navigator.pop(context);
  }

  Future<void> showMyDialogue() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xác minh số điện thoại của bạn",
                  style: TextStyle(fontSize: 14),
                ),
                // Text("$countryCode ${_controller.text}"),
                SizedBox(height: 10),
                Text(
                  countryCode + " " + _controller.text,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),

                Text(
                  "Hoặc thay đổi số điện thoại của bạn:",
                  style: TextStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => OtpScreen(
                      countryCode: countryCode,
                      number: _controller.text,
                    ),
                  ),
                );
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showMyDialogue_NoNumber() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Không tìm thấy số điện thoại của bạn",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
