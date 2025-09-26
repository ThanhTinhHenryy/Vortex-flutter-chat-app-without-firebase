import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: SvgPicture.asset(
                'assets/svg/person.svg',
                width: 28,
                height: 28,
                // color: Color(#fff),
              ),
            ),
            title: Text(
              'Yarushi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.done_all),
                SizedBox(width: 3),
                Text('Hello', style: TextStyle(fontSize: 13)),
              ],
            ),
            trailing: Text('18:04'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1.5, color: Colors.black12),
          ),
        ],
      ),
    );
  }
}
