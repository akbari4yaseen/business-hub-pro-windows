import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/info_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        ? AppLocalizations.of(context)!.fieldRequired
        : null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty)
      return AppLocalizations.of(context)!.fieldRequired;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(trimmed)
        ? null
        : AppLocalizations.of(context)!.invalidEmail;
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
                ? AppLocalizations.of(context)!.companyInfoUpdated
                : AppLocalizations.of(context)!.companyInfoUpdateError,
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (success) Navigator.of(context).pushReplacementNamed('/settings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.companyInfoUpdateError),
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
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior:
              FloatingLabelBehavior.auto, // Let it float naturally
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.companyInfo),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.apartment,
                                  size: 40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nameController,
                            label: AppLocalizations.of(context)!.businessName,
                            validator: _validateRequired,
                            autofillHints: [AutofillHints.organizationName],
                            icon: Icons.business,
                          ),
                          _buildTextField(
                            controller: _whatsAppController,
                            label: AppLocalizations.of(context)!.whatsApp,
                            validator: _validateRequired,
                            keyboardType: TextInputType.phone,
                            icon: Icons.chat,
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: AppLocalizations.of(context)!.phone,
                            validator: _validateRequired,
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone,
                          ),
                          _buildTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)!.email,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                            icon: Icons.email,
                          ),
                          _buildTextField(
                            controller: _addressController,
                            label: AppLocalizations.of(context)!.address,
                            validator: _validateRequired,
                            autofillHints: [AutofillHints.fullStreetAddress],
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.save),
                  label: Text(
                    AppLocalizations.of(context)!.saveChanges,
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
    );
  }
}
