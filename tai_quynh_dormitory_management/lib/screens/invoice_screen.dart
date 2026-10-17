
import 'package:flutter/material.dart';
import 'generic_screen.dart';

// Kế thừa GenericScreen<String>
class InvoiceScreen extends GenericScreen<String> {
  const InvoiceScreen({Key? key})
      : super(
          key: key,
          title: 'Hóa đơn & Thanh toán',
          items: const [
            'Hóa đơn tháng 10',
            'Hóa đơn tháng 9',
            'Lịch sử thanh toán',
          ],
          itemBuilder: buildInvoiceItem,
        );

  // Giao diện riêng của InvoiceScreen
  static Widget buildInvoiceItem(
    BuildContext context,
    String item,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.receipt_long,
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
        subtitle: const Text(
          'Thông tin hóa đơn ký túc xá',
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}
