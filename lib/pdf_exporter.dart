import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfExporter {
  static Future<File> generateReceiptPdf({
    required Map<String, dynamic> storeInfo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxAmount,
    required double cardFeeAmount,
    required double cashPaid,
    required double cardPaid,
    required double grandTotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. ترويسة متجر المبيعات
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        storeInfo['store_name'] ?? 'POS Store',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      if (storeInfo['address'] != null) pw.Text(storeInfo['address']),
                      if (storeInfo['phone'] != null) pw.Text("Tel: ${storeInfo['phone']}"),
                      if (storeInfo['email'] != null) pw.Text(storeInfo['email']),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                // 2. جدول المنتجات
                pw.Text("Order Details", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Item Name', 'Qty', 'Unit Price', 'Total'],
                  data: items.map((item) {
                    double itemTotal = item['price'] * item['qty'];
                    return [
                      item['name'],
                      item['qty'].toString(),
                      '\$${item['price'].toStringAsFixed(2)}',
                      '\$${itemTotal.toStringAsFixed(2)}'
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                // 3. المجموع والرسوم والضريبة
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Subtotal: \$${subtotal.toStringAsFixed(2)}"),
                        pw.Text("Tax: \$${taxAmount.toStringAsFixed(2)}"),
                        if (cardFeeAmount > 0)
                          pw.Text(
                            "${storeInfo['card_fee_label'] ?? 'Card Fee'}: \$${cardFeeAmount.toStringAsFixed(2)}",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          "GRAND TOTAL: \$${grandTotal.toStringAsFixed(2)}",
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                // 4. طرق الدفع المشتركة Split Payments
                pw.Text("Payment Method", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                if (cashPaid > 0) pw.Text("Cash Paid: \$${cashPaid.toStringAsFixed(2)}"),
                if (cardPaid > 0) pw.Text("Card Paid: \$${cardPaid.toStringAsFixed(2)}"),
                
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    "Thank you for shopping with us!",
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // حفظ الملف في ذاكرة الهاتف ليكون جاهزاً للمشاركة أو التنزيل
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Receipt_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
