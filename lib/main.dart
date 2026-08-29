import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'printer_service.dart';
import 'store_settings_screen.dart';
import 'pdf_exporter.dart';
import 'excel_exporter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: PosHomeScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class PosHomeScreen extends StatefulWidget {
  const PosHomeScreen({super.key});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  final PrinterService _printerService = PrinterService();
  final List<Map<String, dynamic>> _cart = [];
  double _subtotal = 0.0;
  Map<String, dynamic> _storeSettings = {};

  @override
  void initState() {
    super.initState();
    _loadStoreSettings();
  }

  void _loadStoreSettings() async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> res = await db.query('store_settings', where: 'id = 1');
    if (res.isNotEmpty) {
      setState(() {
        _storeSettings = res[0];
      });
    }
  }

  void _addItem(String name, double price) {
    setState(() {
      _cart.add({'name': name, 'price': price, 'qty': 1});
      _subtotal += price;
    });
  }

  void _openPaymentDialog() {
    double taxRate = _storeSettings['tax_rate'] ?? 0.0;
    double taxAmount = _subtotal * (taxRate / 100);
    double totalWithTax = _subtotal + taxAmount;

    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        orderTotalWithTax: totalWithTax,
        subtotal: _subtotal,
        taxAmount: taxAmount,
        storeSettings: _storeSettings,
        cart: _cart,
        printerService: _printerService,
        onPaymentComplete: () {
          setState(() {
            _cart.clear();
            _subtotal = 0.0;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Terminal (\$)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "Export Excel",
            onPressed: () async {
              String? path = await ExcelExporter.exportSalesAndLogsToExcel();
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Excel saved: $path")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Store Settings",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
              );
              _loadStoreSettings(); // إعادة تحميل الإعدادات عند العودة
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text("Cart is empty. Add products below."))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_cart[index]['name']),
                        subtitle: Text("Qty: ${_cart[index]['qty']}"),
                        trailing: Text("\$${(_cart[index]['price'] * _cart[index]['qty']).toStringAsFixed(2)}"),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _addItem("Coffee", 3.50),
                  child: const Text("Add Coffee (\$3.50)"),
                ),
                ElevatedButton(
                  onPressed: () => _addItem("Sandwich", 6.50),
                  child: const Text("Add Sandwich (\$6.50)"),
                ),
                ElevatedButton(
                  onPressed: () => _addItem("Water", 1.00),
                  child: const Text("Add Water (\$1.00)"),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subtotal: \$${_subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _cart.isEmpty ? null : _openPaymentDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Checkout", style: TextStyle(fontSize: 16)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- نافذة اختيار الدفع وحساب الرسوم (Payment Dialog) ---
class PaymentDialog extends StatefulWidget {
  final double orderTotalWithTax;
  final double subtotal;
  final double taxAmount;
  final Map<String, dynamic> storeSettings;
  final List<Map<String, dynamic>> cart;
  final PrinterService printerService;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.orderTotalWithTax,
    required this.subtotal,
    required this.taxAmount,
    required this.storeSettings,
    required this.cart,
    required this.printerService,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();

  double _cardFeeAmount = 0.0;
  double _finalTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _finalTotal = widget.orderTotalWithTax;
  }

  void _calculateCardFee(double cardPaidAmount) {
    if (cardPaidAmount <= 0) {
      setState(() {
        _cardFeeAmount = 0.0;
        _finalTotal = widget.orderTotalWithTax;
      });
      return;
    }

    String feeType = widget.storeSettings['card_fee_type'] ?? 'percent';
    double feeValue = widget.storeSettings['card_fee_value'] ?? 0.0;

    setState(() {
      if (feeType == 'percent') {
        _cardFeeAmount = cardPaidAmount * (feeValue / 100);
      } else {
        _cardFeeAmount = feeValue;
      }
      _finalTotal = widget.orderTotalWithTax + _cardFeeAmount;
    });
  }

  void _processPayment() async {
    double cashPaid = double.tryParse(_cashController.text) ?? 0.0;
    double cardPaid = double.tryParse(_cardController.text) ?? 0.0;

    // 1. حفظ المبيعات في قاعدة البيانات
    final db = await DatabaseHelper.instance.database;
    await db.insert('sales', {
      'subtotal': widget.subtotal,
      'tax_amount': widget.taxAmount,
      'card_fee_amount': _cardFeeAmount,
      'total_amount': _finalTotal,
      'cash_paid': cashPaid,
      'card_paid': cardPaid,
      'date': DateTime.now().toIso8601String(),
    });

    // 2. طباعة الفاتورة عبر البلوتوث
    widget.printerService.printReceipt(
      storeInfo: widget.storeSettings,
      items: widget.cart,
      subtotal: widget.subtotal,
      taxAmount: widget.taxAmount,
      cardFeeAmount: _cardFeeAmount,
      cashPaid: cashPaid,
      cardPaid: cardPaid,
      grandTotal: _finalTotal,
    );

    // 3. إنشاء نسخة PDF للفاتورة
    await PdfExporter.generateReceiptPdf(
      storeInfo: widget.storeSettings,
      items: widget.cart,
      subtotal: widget.subtotal,
      taxAmount: widget.taxAmount,
      cardFeeAmount: _cardFeeAmount,
      cashPaid: cashPaid,
      cardPaid: cardPaid,
      grandTotal: _finalTotal,
    );

    widget.onPaymentComplete();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful & Receipt Generated!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double cashPaid = double.tryParse(_cashController.text) ?? 0.0;
    double cardPaid = double.tryParse(_cardController.text) ?? 0.0;
    double remaining = _finalTotal - (cashPaid + cardPaid);

    return AlertDialog(
      title: const Text("Payment Terminal"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text("Subtotal + Tax: \$${widget.orderTotalWithTax.toStringAsFixed(2)}"),
            if (_cardFeeAmount > 0)
              Text(
                "${widget.storeSettings['card_fee_label'] ?? 'Card Fee'}: +\$${_cardFeeAmount.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
              ),
            const Divider(),
            Text(
              "Final Total: \$${_finalTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cash Amount Paid (\$)"),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Card Amount Paid (\$)"),
              onChanged: (val) {
                _calculateCardFee(double.tryParse(val) ?? 0.0);
              },
            ),
            const SizedBox(height: 10),
            Text(
              remaining <= 0
                  ? "Change: \$${(-remaining).toStringAsFixed(2)}"
                  : "Remaining: \$${remaining.toStringAsFixed(2)}",
              style: TextStyle(
                color: remaining <= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: remaining <= 0 ? _processPayment : null,
          child: const Text("Complete Payment"),
        ),
      ],
    );
  }
}
