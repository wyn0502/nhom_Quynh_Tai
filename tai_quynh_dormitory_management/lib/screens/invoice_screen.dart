import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/invoice.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

import 'record_editor.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final service = FirestoreService();

  String filter = 'all';

  Future<void> _paymentHelp(Invoice invoice) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Hướng dẫn thanh toán'),
          content: Text(
            '${invoice.roomName}\n'
            'Kỳ: ${invoice.month}/${invoice.year}\n'
            'Số tiền: ${AppUi.money(invoice.totalAmount)}\n\n'
            'Vui lòng thanh toán theo hướng dẫn '
            'của ban quản lý.\n\n'
            'Sau khi nhận được tiền, admin sẽ xác nhận '
            'trạng thái hóa đơn.\n\n'
            'Ứng dụng chưa kết nối cổng thanh toán trực tuyến.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markPaid(Invoice invoice) async {
    final confirmed = await AppUi.confirm(
      context,
      'Xác nhận đã nhận ${AppUi.money(invoice.totalAmount)} '
      'cho ${invoice.roomName}, '
      'kỳ ${invoice.month}/${invoice.year}?',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () => service.updateInvoiceStatus(
        invoice.id,
        'paid',
      ),
      success: 'Đã xác nhận thanh toán.',
    );
  }

  Future<void> _delete(Invoice invoice) async {
    final confirmed = await AppUi.confirm(
      context,
      'Xóa hóa đơn ${invoice.roomName}, '
      'kỳ ${invoice.month}/${invoice.year}?',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () => service.deleteInvoice(invoice.id),
      success: 'Đã xóa hóa đơn.',
    );
  }

  Widget _invoiceCard(Invoice invoice, bool admin) {
    return AppUi.card(
      context,
      title: invoice.roomName,
      icon: Icons.receipt_long_outlined,
      badge: '${invoice.month}/${invoice.year}',
      color: invoice.isPaid ? AppUi.green : AppUi.orange,
      children: [
        AppUi.badge(
          AppUi.status(invoice.status),
          color: invoice.isPaid ? AppUi.green : AppUi.orange,
        ),
        const SizedBox(height: 12),
        AppUi.info(
          'Tiền phòng',
          AppUi.money(invoice.roomFee),
        ),
        AppUi.info(
          'Tiền điện',
          AppUi.money(invoice.electricityFee),
        ),
        AppUi.info(
          'Tiền nước',
          AppUi.money(invoice.waterFee),
        ),
        const Divider(),
        AppUi.info(
          'Tổng thanh toán',
          AppUi.money(invoice.totalAmount),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (admin) ...[
              OutlinedButton.icon(
                onPressed: () {
                  RecordEditor.edit(
                    context,
                    'invoices',
                    id: invoice.id,
                    data: invoice.toJson(),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa'),
              ),
              if (!invoice.isPaid)
                FilledButton(
                  onPressed: () => _markPaid(invoice),
                  child: const Text('Xác nhận đã thu'),
                ),
              TextButton.icon(
                onPressed: () => _delete(invoice),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppUi.red,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(color: AppUi.red),
                ),
              ),
            ] else if (!invoice.isPaid)
              FilledButton.icon(
                onPressed: () => _paymentHelp(invoice),
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Hướng dẫn thanh toán'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final auth = AuthController.instance;
        final user = auth.currentUser;

        final approved =
            user.roomStatus == RoomStatus.approved;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Hóa đơn KTX',
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              if (auth.isAdmin)
                IconButton(
                  tooltip: 'Lập hóa đơn',
                  onPressed: () {
                    RecordEditor.edit(context, 'invoices');
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!auth.isAdmin && !approved)
                AppUi.card(
                  context,
                  title: 'Chưa có phòng nội trú',
                  icon: Icons.home_work_outlined,
                  children: const [
                    Text(
                      'Hóa đơn sẽ hiển thị khi bạn '
                      'được duyệt cư trú tại một phòng.',
                    ),
                  ],
                )
              else
                AppUi.data<List<Invoice>>(
                  stream: service.getInvoicesStream(
                    roomName: auth.isAdmin
                        ? null
                        : user.pendingRoomName,
                  ),
                  builder: (invoices) {
                    final unpaid = invoices
                        .where((invoice) => !invoice.isPaid)
                        .fold<double>(
                          0,
                          (sum, invoice) =>
                              sum + invoice.totalAmount,
                        );

                    final visible = invoices.where((invoice) {
                      return filter == 'all' ||
                          invoice.status == filter;
                    }).toList()
                      ..sort((a, b) {
                        final first = a.year * 12 + a.month;
                        final second = b.year * 12 + b.month;
                        return second.compareTo(first);
                      });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppUi.card(
                          context,
                          title: auth.isAdmin
                              ? 'Tổng tiền chưa thanh toán'
                              : 'Khoản cần thanh toán',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppUi.orange,
                          children: [
                            Text(
                              AppUi.money(unpaid),
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppUi.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ban quản lý xác nhận '
                              'sau khi nhận thanh toán.',
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: filter == 'all',
                              onSelected: (_) {
                                setState(() => filter = 'all');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Chưa thanh toán'),
                              selected: filter == 'unpaid',
                              onSelected: (_) {
                                setState(() => filter = 'unpaid');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Đã thanh toán'),
                              selected: filter == 'paid',
                              onSelected: (_) {
                                setState(() => filter = 'paid');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (visible.isEmpty)
                          const Text('Chưa có hóa đơn phù hợp.'),
                        ...visible.map(
                          (invoice) => _invoiceCard(
                            invoice,
                            auth.isAdmin,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}