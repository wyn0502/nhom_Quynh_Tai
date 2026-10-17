
import 'package:flutter/material.dart';

// Generic Class dùng chung cho các màn hình
class GenericScreen<T> extends StatelessWidget {
  // Thuộc tính chung
  final String title;
  final List<T> items;

  // Hàm xây dựng giao diện từng phần tử
  final Widget Function(BuildContext, T) itemBuilder;

  // Constructor
  const GenericScreen({
    Key? key,
    required this.title,
    required this.items,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // Bố cục chung
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return itemBuilder(
                  context,
                  items[index],
                );
              },
            ),
    );
  }
}
