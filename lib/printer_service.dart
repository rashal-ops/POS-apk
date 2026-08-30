import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    bool? isConnected = await bluetooth.isConnected;
    if (!isConnected!) {
      await bluetooth.connect(device);
    }
    return true;
  }

  void printReceipt({
    required Map<String, dynamic> storeInfo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxAmount,
    required double cardFeeAmount,
    required double cashPaid,
    required double cardPaid,
    required double grandTotal,
  }) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected ?? false) {
      bluetooth.printCustom(storeInfo['store_name'] ?? 'POS Store', 2, 1);
      if (storeInfo['address'] != null) bluetooth.printCustom(storeInfo['address'], 1, 1);
      if (storeInfo['phone'] != null) bluetooth.printCustom("Tel: ${storeInfo['phone']}", 1, 1);
      
      bluetooth.printCustom("--------------------------------", 1, 1);

      for (var item in items) {
        double itemTotal = item['price'] * item['qty'];
        bluetooth.printCustom("${item['name']} x${item['qty']}  \$${itemTotal.toStringAsFixed(2)}", 1, 0);
      }

      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printLeftRight("Subtotal:", "\$${subtotal.toStringAsFixed(2)}", 1);
      bluetooth.printLeftRight("Tax:", "\$${taxAmount.toStringAsFixed(2)}", 1);
      
      if (cardFeeAmount > 0) {
        String feeLabel = storeInfo['card_fee_label'] ?? "Card Fee";
        bluetooth.printLeftRight("$feeLabel:", "\$${cardFeeAmount.toStringAsFixed(2)}", 1);
      }

      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printLeftRight("TOTAL:", "\$${grandTotal.toStringAsFixed(2)}", 2);
      
      if (cashPaid > 0) bluetooth.printLeftRight("Cash Paid:", "\$${cashPaid.toStringAsFixed(2)}", 1);
      if (cardPaid > 0) bluetooth.printLeftRight("Card Paid:", "\$${cardPaid.toStringAsFixed(2)}", 1);

      bluetooth.printNewLine();
      bluetooth.printCustom("Thank you for your business!", 1, 1);
      bluetooth.printNewLine();
    }
  }
}
