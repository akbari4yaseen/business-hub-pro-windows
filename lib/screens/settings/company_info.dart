import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/info_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

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

  File? _logoFile;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _logoFile = file;
        _logoBase64 = base64Encode(bytes);
      });
    }
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

  String? _validateRequired(String? value) =>
      (value == null || value.trim().isEmpty)
          ? AppLocalizations.of(context)!.fieldRequired
          : null;

  String? _validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(trimmed)
        ? null
        : AppLocalizations.of(context)!.invalidEmail;
  }

  ImageProvider? _getLogoImage(String? base64) {
    if (base64 == null) return null;
    try {
      return MemoryImage(base64Decode(base64));
    } catch (_) {
      return null;
    }
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
              logo: _logoBase64,
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
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<String>? autofillHints,
    IconData? icon,
    bool isLTR = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: isLTR ? TextDirection.ltr : null,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.companyInfo),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 950),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2),
                                    backgroundImage: _logoFile != null
                                        ? FileImage(_logoFile!)
                                        : _getLogoImage(
                                            Provider.of<InfoProvider>(context)
                                                .info
                                                .logo),
                                    child: (_logoFile == null &&
                                            Provider.of<InfoProvider>(context)
                                                    .info
                                                    .logo ==
                                                null)
                                        ? const Icon(Icons.apartment,
                                            size: 50, color: Colors.white)
                                        : null,
                                  ),
                                  FloatingActionButton(
                                    mini: true,
                                    onPressed: _pickLogo,
                                    child: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            LayoutBuilder(builder: (context, constraints) {
                              if (isWide) {
                                return GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 3.5,
                                  children: [
                                    _buildModernTextField(
                                      controller: _nameController,
                                      label: loc.businessName,
                                      validator: _validateRequired,
                                      icon: Icons.business,
                                    ),
                                    _buildModernTextField(
                                      controller: _whatsAppController,
                                      label: loc.whatsApp,
                                      validator: _validateRequired,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.chat,
                                      isLTR: true,
                                    ),
                                    _buildModernTextField(
                                      controller: _phoneController,
                                      label: loc.phone,
                                      validator: _validateRequired,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone,
                                      isLTR: true,
                                    ),
                                    _buildModernTextField(
                                      controller: _emailController,
                                      label: loc.email,
                                      validator: _validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      icon: Icons.email,
                                      isLTR: true,
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildModernTextField(
                                      controller: _nameController,
                                      label: loc.businessName,
                                      validator: _validateRequired,
                                      icon: Icons.business,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildModernTextField(
                                      controller: _whatsAppController,
                                      label: loc.whatsApp,
                                      validator: _validateRequired,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.chat,
                                      isLTR: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildModernTextField(
                                      controller: _phoneController,
                                      label: loc.phone,
                                      validator: _validateRequired,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone,
                                      isLTR: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildModernTextField(
                                      controller: _emailController,
                                      label: loc.email,
                                      validator: _validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      icon: Icons.email,
                                      isLTR: true,
                                    ),
                                  ],
                                );
                              }
                            }),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _addressController,
                              label: loc.address,
                              validator: _validateRequired,
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _handleSubmit,
                                icon: const Icon(Icons.save),
                                label: Text(
                                  loc.saveChanges,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
