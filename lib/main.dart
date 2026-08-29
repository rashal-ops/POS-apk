import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'printer_service.dart';
import 'store_settings_screen.dart'; // استدعاء شاشة الإعدادات

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

  void _addItem(String name, double price) {
    setState(() {
      _cart.add({'name': name, 'price': price, 'qty': 1});
      _subtotal += price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Terminal (\$)"),
        actions: [
          // زر الذهاب لشاشة الإعدادات
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _addItem("Sample Product", 10.0),
              child: const Text("Add Sample Item (\$10.00)"),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal: \$${_subtotal.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _cart.isEmpty ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order Completed!")));
                    setState(() { _cart.clear(); _subtotal = 0.0; });
                  },
                  child: const Text("Checkout"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
