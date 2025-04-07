import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/info_provider.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<InfoProvider>(context, listen: false);
    await provider.loadInfo();

    final info = provider.info;
    _nameController.text = info.name ?? '';
    _whatsAppController.text = info.whatsApp ?? '';
    _phoneController.text = info.phone ?? '';
    _emailController.text = info.email ?? '';
    _addressController.text = info.address ?? '';

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsAppController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    return (value == null || value.trim().isEmpty)
        ? "این فیلد ضروری است"
        : null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return "این فیلد ضروری است";
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(trimmed) ? null : "ایمیل معتبر نیست";
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedInfo =
        Provider.of<InfoProvider>(context, listen: false).info.copyWith(
              name: _nameController.text.trim(),
              whatsApp: _whatsAppController.text.trim(),
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              address: _addressController.text.trim(),
            );

    try {
      final success = await Provider.of<InfoProvider>(context, listen: false)
          .updateInfo(updatedInfo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "معلومات شرکت بروز رسانی شد"
                : "خطا در بروزرسانی اطلاعات شرکت",
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (success) Navigator.of(context).pushReplacementNamed('/settings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خطا در بروزرسانی اطلاعات شرکت"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
        ),
        validator: validator,
        autofillHints: autofillHints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اطلاعات شرکت")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.topRight,
                        child: CircleAvatar(
                          radius: 48,
                          child: Icon(Icons.apartment, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _nameController,
                        label: "نام کسب‌وکار",
                        validator: _validateRequired,
                        autofillHints: [AutofillHints.organizationName],
                      ),
                      _buildTextField(
                        controller: _whatsAppController,
                        label: "واتساپ",
                        validator: _validateRequired,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: "شماره تماس",
                        validator: _validateRequired,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: "ایمیل",
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: [AutofillHints.email],
                      ),
                      _buildTextField(
                        controller: _addressController,
                        label: "آدرس",
                        validator: _validateRequired,
                        autofillHints: [AutofillHints.fullStreetAddress],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.save),
                label: const Text("ثبت تغییرات"),
              ),
            ),
    );
  }
}
