import 'package:flutter/material.dart';
import 'package:erp_tool/services/customer_database_service.dart';

class CustomerAddEditPage extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const CustomerAddEditPage({super.key, this.customer});

  @override
  _CustomerAddEditPageState createState() => _CustomerAddEditPageState();
}

class _CustomerAddEditPageState extends State<CustomerAddEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dbService = CustomerDatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!['name'];
      _emailController.text = widget.customer!['email'];
      _phoneController.text = widget.customer!['phone'];
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customer = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      try {
        if (widget.customer == null) {
          await _dbService.addCustomer(customer);
        } else {
          final customerId = widget.customer!['id'] ?? widget.customer!['customerId'];
          if (customerId != null) {
            await _dbService.updateCustomer(customerId, customer);
          } else {
            print("Error: Customer ID is missing!");
            return;
          }
        }
        Navigator.pop(context);
      } catch (e) {
        print("Error saving customer: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🟢 Blob Background Effect
          Positioned(
            top: -100,
            left: -50,
            child: _buildBlob(Colors.orangeAccent.withOpacity(0.3)),
          ),
          Positioned(
            top: 500,
            right: -50,
            child: _buildBlob(Colors.deepPurpleAccent.withOpacity(0.2)),
          ),

          // 🔹 Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🏠 Logo at the Top
                    Image.asset(
                      'assets/Black logo on White-01.jpg',
                      height: 100,
                    ),
                    const SizedBox(height: 10),

                    // 📌 Title
                    Text(
                      widget.customer == null ? "Add Customer" : "Edit Customer",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📝 Form
                    _buildCustomerForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Blob Effect Builder
  Widget _buildBlob(Color color) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }

  /// 📋 Customer Form UI
  Widget _buildCustomerForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 🏷 Name Input
          _buildTextField(
            controller: _nameController,
            label: "Full Name",
            icon: Icons.person,
            validator: (value) => value!.isEmpty ? 'Name is required' : null,
          ),

          const SizedBox(height: 16),

          // 📧 Email Input
          _buildTextField(
            controller: _emailController,
            label: "Email",
            icon: Icons.email,
            validator: (value) {
              if (value!.isEmpty) return 'Email is required';
              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                  .hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 📞 Phone Input
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number",
            icon: Icons.phone,
            validator: (value) =>
            value!.isEmpty ? 'Phone number is required' : null,
          ),

          const SizedBox(height: 30),

          // ✅ Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveCustomer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
                elevation: 4,
              ),
              child: const Text(
                "Save Customer",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Reusable TextField with Icon
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
    );
  }
}
