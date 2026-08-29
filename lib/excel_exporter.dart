import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

class ExcelExporter {
  static Future<String?> exportSalesAndLogsToExcel() async {
    // 1. طلب أذونات التخزين للهاتف
    if (await Permission.storage.request().isDenied) {
      await Permission.manageExternalStorage.request();
    }

    final db = await DatabaseHelper.instance.database;

    // 2. جلب البيانات من SQLite
    List<Map<String, dynamic>> sales = await db.query('sales', orderBy: 'id DESC');
    List<Map<String, dynamic>> settings = await db.query('store_settings', where: 'id = 1');

    // 3. إنشاء كائن Excel جديد
    var excel = Excel.createExcel();

    // --- ورقة العمل الأولى: ملخص المبيعات (Sales Report) ---
    Sheet salesSheet = excel['Sales Report'];
    salesSheet.appendRow([
      TextCellValue('Sale ID'),
      TextCellValue('Subtotal (\$)'),
      TextCellValue('Tax (\$)'),
      TextCellValue('Card Fee (\$)'),
      TextCellValue('Grand Total (\$)'),
      TextCellValue('Cash Paid (\$)'),
      TextCellValue('Card Paid (\$)'),
      TextCellValue('Date')
    ]);

    for (var sale in sales) {
      salesSheet.appendRow([
        IntCellValue(sale['id']),
        DoubleCellValue(sale['subtotal'] ?? 0.0),
        DoubleCellValue(sale['tax_amount'] ?? 0.0),
        DoubleCellValue(sale['card_fee_amount'] ?? 0.0),
        DoubleCellValue(sale['total_amount'] ?? 0.0),
        DoubleCellValue(sale['cash_paid'] ?? 0.0),
        DoubleCellValue(sale['card_paid'] ?? 0.0),
        TextCellValue(sale['date'] ?? '')
      ]);
    }

    // --- ورقة العمل الثانية: معلومات المتجر (Store Info) ---
    Sheet infoSheet = excel['Store Settings'];
    infoSheet.appendRow([TextCellValue('Property'), TextCellValue('Value')]);

    if (settings.isNotEmpty) {
      var s = settings[0];
      infoSheet.appendRow([TextCellValue('Store Name'), TextCellValue(s['store_name'] ?? '')]);
      infoSheet.appendRow([TextCellValue('Address'), TextCellValue(s['address'] ?? '')]);
      infoSheet.appendRow([TextCellValue('Phone'), TextCellValue(s['phone'] ?? '')]);
      infoSheet.appendRow([TextCellValue('Tax Rate (%)'), DoubleCellValue(s['tax_rate'] ?? 0.0)]);
      infoSheet.appendRow([TextCellValue('Card Fee Type'), TextCellValue(s['card_fee_type'] ?? '')]);
      infoSheet.appendRow([TextCellValue('Card Fee Value'), DoubleCellValue(s['card_fee_value'] ?? 0.0)]);
    }

    // حذف الورقة الافتراضية
    excel.delete('Sheet1');

    // 4. حفظ الملف في مجلد المستندات بالهاتف
    Directory? directory = await getExternalStorageDirectory();
    String filePath = "${directory!.path}/POS_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    File file = File(filePath);
    await file.writeAsBytes(excel.save()!);

    return filePath;
  }
}
