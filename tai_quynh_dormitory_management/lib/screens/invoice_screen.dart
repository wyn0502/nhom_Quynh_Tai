import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/invoice.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'main_navigator.dart';

/// Màn hình Quản lý Hóa đơn Tài chính & Cổng thanh toán VietQR PayOS
/// - Phân quyền:
///   + Sinh viên: Xem hóa đơn phòng của mình, thanh toán trực tuyến qua VietQR PayOS
///   + Admin: Lập hóa đơn mới (CRUD - Create), đổi trạng thái đã thu tiền (Update), Xóa hóa đơn (Delete)
/// - Đồng bộ trực tiếp với Firebase Firestore & CSDL quan_ly_ktx.sql
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color brandNavy = const Color(0xFF1E3A8A);
    final Color brandOrange = const Color(0xFFF97316);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final bool isAdmin = AuthController.instance.isAdmin;
        final User currentUser = AuthController.instance.currentUser;
        final bool hasApprovedRoom = currentUser.roomStatus == RoomStatus.approved && currentUser.pendingRoomName != null;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F8),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            title: Text(
              isAdmin ? 'Quản lý Hóa đơn KTX (Admin)' : 'Hóa đơn & Thanh toán KTX',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Lập hóa đơn mới',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: brandNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  onPressed: () => _showCreateInvoiceDialog(context, isDark, brandNavy),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<Invoice>>(
            stream: FirestoreService().getInvoicesStream(
              roomName: isAdmin ? null : (hasApprovedRoom ? currentUser.pendingRoomName : 'none_unassigned'),
            ),
            builder: (context, snapshot) {
              List<Invoice> invoices = [];
              if (isAdmin) {
                invoices = snapshot.data ?? [];
              } else if (hasApprovedRoom) {
                invoices = snapshot.data ?? [];
              } else {
                invoices = [];
              }

              final totalPending = invoices.where((i) => !i.isPaid).fold<double>(0, (sum, i) => sum + i.totalAmount);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Thẻ tổng quan thanh toán
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [brandNavy, const Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: brandNavy.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAdmin
                                    ? 'TỔNG CÔNG NỢ KTX CHƯA THU'
                                    : (hasApprovedRoom
                                        ? 'CẦN THANH TOÁN (${currentUser.pendingRoomName!.toUpperCase()})'
                                        : 'CHƯA CÓ PHÒNG NỘI TRÚ'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAdmin
                                      ? '${invoices.length} HÓA ĐƠN'
                                      : (hasApprovedRoom ? 'KỲ 06/2026' : 'CHƯA PHÁT SINH'),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalPending.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin
                                ? 'Hệ thống đối soát tự động qua cổng PayOS VietQR'
                                : (hasApprovedRoom
                                    ? 'Vui lòng hoàn thành chuyển khoản trước ngày 20 hàng tháng'
                                    : 'Bạn chưa được duyệt phòng ở KTX nên chưa phát sinh hóa đơn'),
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      isAdmin ? 'Danh sách hóa đơn toàn KTX' : 'Lịch sử hóa đơn phòng bạn',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                    ),

                    const SizedBox(height: 10),

                    // 2. Danh sách hóa đơn
                    if (invoices.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                isAdmin
                                    ? 'Chưa có hóa đơn nào trong hệ thống.'
                                    : (hasApprovedRoom
                                        ? 'Phòng bạn hiện không có hóa đơn nào cần thanh toán.'
                                        : 'Bạn chưa có phòng ở KTX nên chưa phát sinh hóa đơn.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textSecondary, fontSize: 13),
                              ),
                              if (!isAdmin && !hasApprovedRoom) ...[
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => MainNavigator.switchToTab(context, 1),
                                  icon: const Icon(Icons.meeting_room_outlined, size: 16),
                                  label: const Text('Đăng ký phòng KTX ngay'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandNavy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = invoices[index];
                          return _buildInvoiceCard(
                            item: item,
                            isAdmin: isAdmin,
                            isDark: isDark,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                            brandNavy: brandNavy,
                            brandOrange: brandOrange,
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Thẻ hóa đơn
  Widget _buildInvoiceCard({
    required Invoice item,
    required bool isAdmin,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color brandNavy,
    required Color brandOrange,
  }) {
    final bool isPaid = item.isPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                      color: isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hóa đơn ${item.roomName}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      Text(
                        'Kỳ tháng ${item.month}/${item.year}',
                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Chi tiết các khoản phí
          _buildFeeRow('Tiền phòng cố định:', '${item.roomFee.toInt()} đ', textPrimary, textSecondary),
          const SizedBox(height: 4),
          _buildFeeRow('Tiền điện tiêu thụ:', '${item.electricityFee.toInt()} đ', textPrimary, textSecondary),
          const SizedBox(height: 4),
          _buildFeeRow('Tiền nước sinh hoạt:', '${item.waterFee.toInt()} đ', textPrimary, textSecondary),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Tổng tiền + Nút hành động
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TỔNG CỘNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary)),
                  Text(
                    '${item.totalAmount.toInt()} đ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isPaid ? const Color(0xFF059669) : brandOrange),
                  ),
                ],
              ),
              if (!isPaid && !isAdmin)
                // Sinh viên bấm thanh toán PayOS
                ElevatedButton.icon(
                  onPressed: () => _showPayOSDialog(context, item, isDark),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('Thanh toán PayOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else if (isAdmin)
                // Admin quản lý trạng thái hóa đơn (CRUD - Update / Delete)
                Row(
                  children: [
                    if (!isPaid)
                      OutlinedButton(
                        onPressed: () async {
                          await FirestoreService().updateInvoiceStatus(item.id, 'paid');
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật: Hóa đơn đã thanh toán!')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFFA7F3D0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('Thu tiền mặt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Xóa hóa đơn',
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () => _confirmDeleteInvoice(context, item),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
      ],
    );
  }

  // Modal Thanh toán VietQR PayOS
  void _showPayOSDialog(BuildContext context, Invoice item, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.payment_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Cổng VietQR PayOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quét mã QR bằng ứng dụng ngân hàng bất kỳ để thanh toán tự động đối soát.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_scanner_rounded, size: 64, color: Color(0xFF1E3A8A)),
                              SizedBox(height: 8),
                              Text('VIETQR PRO', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                              Text('PAYOS GATEWAY', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Số tiền: ${item.totalAmount.toInt()} VNĐ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFF97316)),
                      ),
                      Text('Nội dung: KTX ${item.roomName} T${item.month}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await FirestoreService().updateInvoiceStatus(item.id, 'paid');
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Thanh toán qua PayOS thành công! Dữ liệu đã đồng bộ.'),
                      ],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Xác nhận đã chuyển khoản'),
            ),
          ],
        );
      },
    );
  }

  // Admin Lập hóa đơn mới (CRUD - Create)
  void _showCreateInvoiceDialog(BuildContext context, bool isDark, Color brandNavy) {
    String selectedRoom = 'Phòng B101';
    int selectedMonth = 6;
    int selectedYear = 2026;
    final roomFeeCtrl = TextEditingController(text: '1500000');
    final eleFeeCtrl = TextEditingController(text: '450000');
    final waterFeeCtrl = TextEditingController(text: '150000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Lập hóa đơn KTX mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(labelText: 'Chọn phòng'),
                  items: const [
                    DropdownMenuItem(value: 'Phòng 101', child: Text('Phòng 101 - Tòa A')),
                    DropdownMenuItem(value: 'Phòng 102', child: Text('Phòng 102 - Tòa A')),
                    DropdownMenuItem(value: 'Phòng 201', child: Text('Phòng 201 - Tòa A')),
                    DropdownMenuItem(value: 'Phòng B101', child: Text('Phòng B101 - Tòa B')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedRoom = val ?? 'Phòng B101'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: const InputDecoration(labelText: 'Tháng'),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('T${i + 1}'))),
                        onChanged: (val) => setDlgState(() => selectedMonth = val ?? 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'Năm'),
                        items: const [
                          DropdownMenuItem(value: 2026, child: Text('2026')),
                          DropdownMenuItem(value: 2027, child: Text('2027')),
                        ],
                        onChanged: (val) => setDlgState(() => selectedYear = val ?? 2026),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roomFeeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiền phòng (VNĐ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eleFeeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiền điện (VNĐ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: waterFeeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiền nước (VNĐ)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final rFee = double.tryParse(roomFeeCtrl.text.trim()) ?? 1500000;
                final eFee = double.tryParse(eleFeeCtrl.text.trim()) ?? 0;
                final wFee = double.tryParse(waterFeeCtrl.text.trim()) ?? 0;
                final total = rFee + eFee + wFee;

                final newInv = Invoice(
                  id: 'inv_${selectedRoom}_${selectedMonth}_$selectedYear'.replaceAll(' ', '_'),
                  roomName: selectedRoom,
                  month: selectedMonth,
                  year: selectedYear,
                  roomFee: rFee,
                  electricityFee: eFee,
                  waterFee: wFee,
                  totalAmount: total,
                  status: 'unpaid',
                  orderCode: DateTime.now().millisecondsSinceEpoch % 1000000000,
                );

                await FirestoreService().createInvoice(newInv);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Text('Đã lập thành công Hóa đơn $selectedRoom tháng $selectedMonth!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: brandNavy, foregroundColor: Colors.white),
              child: const Text('Lập hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }

  // Admin Xóa hóa đơn (CRUD - Delete)
  void _confirmDeleteInvoice(BuildContext context, Invoice item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn ${item.roomName} (Kỳ ${item.month}/${item.year})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().deleteInvoice(item.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFDC2626),
                  content: Text('Đã xóa hóa đơn khỏi hệ thống!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }
}
