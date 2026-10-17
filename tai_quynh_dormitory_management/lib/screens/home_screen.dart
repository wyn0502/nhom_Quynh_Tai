
import 'package:flutter/material.dart';
import 'generic_screen.dart';

// Kế thừa GenericScreen<String>
class HomeScreen extends GenericScreen<String> {
  const HomeScreen({Key? key})
      : super(
          key: key,
          title: 'Trang chủ KTX',
          items: const [
            'Thông báo ký túc xá',
            'Thông tin sinh viên',
            'Báo cáo sự cố',
          ],
          itemBuilder: buildHomeItem,
        );

  // Giao diện riêng của HomeScreen
  static Widget buildHomeItem(
    BuildContext context,
    String item,
  ) {
    IconData iconData;

    if (item == 'Thông báo ký túc xá') {
      iconData = Icons.notifications;
    } else if (item == 'Thông tin sinh viên') {
      iconData = Icons.person;
    } else {
      iconData = Icons.build;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          iconData,
          color: Colors.blue,
          size: 32,
        ),
        title: Text(
          item,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}
