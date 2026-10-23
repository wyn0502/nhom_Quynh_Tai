import 'package:flutter/material.dart';

// Generic Class dùng chung cho các màn hình theo chuẩn OOP, tự động thích ứng Light / Dark Mode
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: appBarBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      // Bố cục chung
      body: items.isEmpty
          ? Center(
              child: Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
