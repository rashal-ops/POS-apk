import 'package:flutter/material.dart';
import 'database_helper.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxController = TextEditingController();
  final _cardFeeValueController = TextEditingController();
  final _cardFeeLabelController = TextEditingController();

  String _cardFeeType = 'percent'; // 'percent' or 'fixed'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> res = await db.query('store_settings', where: 'id = 1');
    if (res.isNotEmpty) {
      setState(() {
        _nameController.text = res[0]['store_name'] ?? '';
        _addressController.text = res[0]['address'] ?? '';
        _phoneController.text = res[0]['phone'] ?? '';
        _emailController.text = res[0]['email'] ?? '';
        _taxController.text = (res[0]['tax_rate'] ?? 0.0).toString();
        _cardFeeType = res[0]['card_fee_type'] ?? 'percent';
        _cardFeeValueController.text = (res[0]['card_fee_value'] ?? 0.0).toString();
        _cardFeeLabelController.text = res[0]['card_fee_label'] ?? 'Card Service Fee';
      });
    }
  }

  void _saveSettings() async {
    final db = await DatabaseHelper.instance.database;
    await db.update('store_settings', {
      'store_name': _nameController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'tax_rate': double.tryParse(_taxController.text) ?? 0.0,
      'card_fee_type': _cardFeeType,
      'card_fee_value': double.tryParse(_cardFeeValueController.text) ?? 0.0,
      'card_fee_label': _cardFeeLabelController.text,
    }, where: 'id = 1');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store & Fee Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Store Header Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Store Name")),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email / Website")),
            
            const SizedBox(height: 25),
            const Text("Tax & Surcharge Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _taxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tax Rate (%)", suffixText: "%"),
            ),
            const SizedBox(height: 15),
            
            DropdownButtonFormField<String>(
              value: _cardFeeType,
              items: const [
                DropdownMenuItem(value: 'percent', child: Text("Percentage Fee (%)")),
                DropdownMenuItem(value: 'fixed', child: Text("Fixed Amount (\$)")),
              ],
              onChanged: (val) => setState(() => _cardFeeType = val!),
              decoration: const InputDecoration(labelText: "Card Surcharge Type"),
            ),
            
            TextField(
              controller: _cardFeeValueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Card Fee Value"),
            ),
            
            TextField(
              controller: _cardFeeLabelController,
              decoration: const InputDecoration(
                labelText: "Printed Receipt Label",
                hintText: "e.g., Card Processing Fee",
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text("Save All Settings", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
