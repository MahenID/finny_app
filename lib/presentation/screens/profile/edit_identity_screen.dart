import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EditIdentityScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;

  const EditIdentityScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
  });

  @override
  State<EditIdentityScreen> createState() =>
      _EditIdentityScreenState();
}

class _EditIdentityScreenState
    extends State<EditIdentityScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.initialName);

    _emailController =
        TextEditingController(text: widget.initialEmail);

    _phoneController =
        TextEditingController(text: widget.initialPhone);

    // supaya header ikut berubah realtime
    _nameController.addListener(() {
      setState(() {});
    });

    _emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    Navigator.pop(context, {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                //------------------------------------------------
                // HEADER
                //------------------------------------------------

                Row(
                  children: [

                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.arrow_back),
                      ),
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          "Edit Identitas",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 42),
                  ],
                ),

                const SizedBox(height: 30),

                //------------------------------------------------
                // FOTO PROFIL
                //------------------------------------------------

                Stack(
                  alignment: Alignment.bottomRight,
                  children: [

                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            AppColors.accentGreen
                                .withValues(alpha: .15),

                        child: Text(
                          _nameController.text.isEmpty
                              ? "U"
                              : _nameController.text[0]
                                  .toUpperCase(),

                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color:
                                AppColors.accentGreen,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(8),
                      decoration:
                          const BoxDecoration(
                        color:
                            AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  _nameController.text.isEmpty
                      ? "Nama User"
                      : _nameController.text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _emailController.text,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),
                                //------------------------------------------------
                // CARD FORM
                //------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      _buildTextField(
                        controller: _nameController,
                        label: "Nama Lengkap",
                        hint: "Masukkan nama lengkap",
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return "Nama tidak boleh kosong";
                          }

                          if (value.trim().length < 3) {
                            return "Nama minimal 3 karakter";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _emailController,
                        label: "Alamat Email",
                        hint: "Masukkan email",

                        icon: Icons.email_outlined,

                        keyboardType:
                            TextInputType.emailAddress,

                        validator: (value) {

                          if (value == null ||
                              value.trim().isEmpty) {
                            return "Email tidak boleh kosong";
                          }

                          if (!value.contains("@")) {
                            return "Format email salah";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _phoneController,

                        label: "Nomor Handphone",

                        hint: "81234567890",

                        icon: Icons.phone_android,

                        keyboardType:
                            TextInputType.phone,

                        prefix: const Padding(
                          padding: EdgeInsets.only(
                            left: 18,
                            right: 10,
                          ),
                          child: Text(
                            "+62",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        validator: (value) {

                          if (value == null ||
                              value.trim().isEmpty) {
                            return "Nomor HP wajib diisi";
                          }

                          if (value.length < 10) {
                            return "Nomor HP terlalu pendek";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        width: double.infinity,
                        height: 56,

                        child: ElevatedButton(
                          onPressed:
                              _isSaving ? null : _saveData,

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.accentGreen,

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      18),
                            ),
                          ),

                          child: _isSaving

                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )

                              : const Text(
                                  "Simpan Perubahan",

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),
                              ],
            ),
          ),
        ),
      ),
    );
  }

  //------------------------------------------------
  // TEXTFIELD MODERN
  //------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? prefix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,

          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: prefix == null
                ? Icon(icon, color: AppColors.accentGreen)
                : null,

            prefix: prefix,

            suffixIcon: Icon(
              Icons.edit_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),

            filled: true,
            fillColor: Colors.grey.shade50,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.accentGreen,
                width: 2,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.red),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
