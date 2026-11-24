import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../models/customer_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerFormControllers — holds every TextEditingController for the form
// ─────────────────────────────────────────────────────────────────────────────

class CustomerFormControllers {
  final name = TextEditingController();
  final fatherName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final aadhaar = TextEditingController();
  final pan = TextEditingController();
  final occupation = TextEditingController();
  final monthlyIncome = TextEditingController();
  final emergencyContact = TextEditingController();
  final guarantorName = TextEditingController();
  final guarantorPhone = TextEditingController();
  final password = TextEditingController();

  /// Dispose all controllers at once.
  void dispose() {
    name.dispose();
    fatherName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    aadhaar.dispose();
    pan.dispose();
    occupation.dispose();
    monthlyIncome.dispose();
    emergencyContact.dispose();
    guarantorName.dispose();
    guarantorPhone.dispose();
    password.dispose();
  }

  /// Pre-fill all controllers from an existing [Customer] (edit mode).
  void populateFrom(Customer customer) {
    name.text = customer.name;
    fatherName.text = customer.fatherName ?? '';
    phone.text = customer.phone;
    email.text = customer.email ?? '';
    address.text = customer.address ?? '';
    // aadhaarLast4 is stored masked — we leave the field blank so the user
    // can optionally re-enter the full number.
    aadhaar.text = '';
    pan.text = customer.pan ?? '';
    occupation.text = customer.occupation ?? '';
    monthlyIncome.text =
        customer.monthlyIncome != null ? customer.monthlyIncome.toString() : '';
    emergencyContact.text = customer.emergencyContact ?? '';
    guarantorName.text = customer.guarantorName ?? '';
    guarantorPhone.text = customer.guarantorPhone ?? '';
    // Password is always left blank in edit mode.
    password.text = '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomerFormWidget — shared stateful form used by both create & edit screens
// ─────────────────────────────────────────────────────────────────────────────

class CustomerFormWidget extends StatefulWidget {
  const CustomerFormWidget({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.isEditMode,
    required this.isLoading,
    required this.onSubmit,
    this.currentPhone,
    this.onStatusChanged,
    this.currentStatus,
  });

  final GlobalKey<FormState> formKey;
  final CustomerFormControllers controllers;
  final bool isEditMode;
  final bool isLoading;
  final VoidCallback onSubmit;

  /// In edit mode, shown in the password hint so admin knows the login username.
  final String? currentPhone;

  /// Called whenever the status dropdown changes (edit mode only).
  final void Function(String)? onStatusChanged;

  /// Current status value for the dropdown (edit mode only).
  final String? currentStatus;

  @override
  State<CustomerFormWidget> createState() => _CustomerFormWidgetState();
}

class _CustomerFormWidgetState extends State<CustomerFormWidget> {
  bool _obscurePassword = true;

  // In CREATE mode we auto-sync the password field to the phone field until
  // the user manually types something different.
  bool _autoSyncPassword = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditMode) {
      widget.controllers.phone.addListener(_onPhoneChanged);
      widget.controllers.password.addListener(_onPasswordManuallyChanged);
    }
  }

  void _onPhoneChanged() {
    if (_autoSyncPassword) {
      final phone = widget.controllers.phone.text.trim();
      // Only sync if the user hasn't diverged the password value yet.
      widget.controllers.password.text = phone;
    }
  }

  void _onPasswordManuallyChanged() {
    if (!widget.isEditMode && _autoSyncPassword) {
      final phone = widget.controllers.phone.text.trim();
      if (widget.controllers.password.text != phone) {
        // User has started typing their own password — stop auto-syncing.
        setState(() => _autoSyncPassword = false);
      }
    }
  }

  @override
  void dispose() {
    if (!widget.isEditMode) {
      widget.controllers.phone.removeListener(_onPhoneChanged);
      widget.controllers.password.removeListener(_onPasswordManuallyChanged);
    }
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (v.trim().length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  String? _optionalPhoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length != 10) return 'Must be a 10-digit number';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (widget.isEditMode) {
      // Optional in edit mode — but if provided must be ≥ 6 chars.
      if (v != null && v.trim().isNotEmpty && v.trim().length < 6) {
        return 'Password must be at least 6 characters';
      }
      return null;
    } else {
      // Required in create mode.
      if (v == null || v.trim().isEmpty) return 'Password is required';
      if (v.trim().length < 6) return 'Password must be at least 6 characters';
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Section 1: Identity ──────────────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.person_outline,
            title: 'IDENTITY',
            children: [
              _buildField(
                controller: c.name,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: _required,
                isRequired: true,
              ),
              _buildField(
                controller: c.fatherName,
                label: "Father's Name",
                icon: Icons.people_outline,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 2: Contact ───────────────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.phone_outlined,
            title: 'CONTACT',
            children: [
              _buildField(
                controller: c.phone,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _phoneValidator,
                isRequired: true,
              ),
              _buildField(
                controller: c.email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 3: Address ───────────────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.location_on_outlined,
            title: 'ADDRESS',
            children: [
              _buildField(
                controller: c.address,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 4: KYC ───────────────────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.fingerprint,
            title: 'KYC',
            children: [
              _buildField(
                controller: c.aadhaar,
                label: 'Aadhaar Number',
                icon: Icons.fingerprint,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                helperText: '12 digits',
              ),
              _buildField(
                controller: c.pan,
                label: 'PAN Number',
                icon: Icons.credit_card_outlined,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
                helperText: 'e.g. ABCDE1234F',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 5: Financial Profile ─────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.work_outline,
            title: 'FINANCIAL PROFILE',
            children: [
              _buildField(
                controller: c.occupation,
                label: 'Occupation',
                icon: Icons.work_outline,
              ),
              _buildField(
                controller: c.monthlyIncome,
                label: 'Monthly Income ₹',
                icon: Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 6: Emergency & Guarantor ─────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.emergency_outlined,
            title: 'EMERGENCY & GUARANTOR',
            children: [
              _buildField(
                controller: c.emergencyContact,
                label: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _optionalPhoneValidator,
                helperText: '10 digits',
              ),
              _buildField(
                controller: c.guarantorName,
                label: 'Guarantor Name',
                icon: Icons.shield_outlined,
              ),
              _buildField(
                controller: c.guarantorPhone,
                label: 'Guarantor Phone',
                icon: Icons.phone_forwarded_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _optionalPhoneValidator,
                helperText: '10 digits',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Section 7: Account ───────────────────────────────────────────
          _buildSectionCard(
            sectionIcon: Icons.manage_accounts_outlined,
            title: 'ACCOUNT',
            children: [
              // Status dropdown — only in edit mode
              if (widget.isEditMode) ...[
                _buildStatusDropdown(),
                const SizedBox(height: 4),
              ],

              // Info banner
              _buildPasswordInfoBanner(),

              const SizedBox(height: 12),

              // Password field
              _buildPasswordField(),
            ],
          ),

          const SizedBox(height: 20),

          // Required fields note
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '* Required fields',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Submit button
          AnimatedGradientButton(
            onPressed: widget.isLoading ? null : widget.onSubmit,
            isLoading: widget.isLoading,
            gradient: AppTheme.primaryGradient,
            icon: widget.isEditMode
                ? Icons.save_rounded
                : Icons.person_add_outlined,
            child: Text(
              widget.isEditMode ? 'Save Changes' : 'Create Customer',
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Section card ────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData sectionIcon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(sectionIcon, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 14,
              thickness: 1,
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: children
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic text field ───────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = false,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        counterText: '',
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  // ── Status dropdown (edit only) ──────────────────────────────────────────────

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.currentStatus ?? 'ACTIVE',
      decoration: const InputDecoration(
        labelText: 'Account Status',
        prefixIcon: Icon(Icons.toggle_on_outlined, size: 20, color: AppTheme.primaryColor),
      ),
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
        DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
        DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
      ],
      onChanged: (v) {
        if (v != null) widget.onStatusChanged?.call(v);
      },
    );
  }

  // ── Password info banner ─────────────────────────────────────────────────────

  Widget _buildPasswordInfoBanner() {
    final String message;
    if (widget.isEditMode) {
      final phone = widget.currentPhone ?? widget.controllers.phone.text;
      message =
          'Customer logs in using their Phone Number ($phone). '
          'Leave password blank to keep the current password, or enter a new one to reset it.';
    } else {
      message =
          'Customer can log in to the Customer App using their Phone Number as '
          'username and this password. By default the password matches the phone number.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password field ───────────────────────────────────────────────────────────

  Widget _buildPasswordField() {
    final isEdit = widget.isEditMode;
    final label = isEdit ? 'New Password (optional)' : 'Login Password *';
    final hint = isEdit
        ? 'Leave blank to keep existing password'
        : 'Default: same as mobile number';

    return TextFormField(
      controller: widget.controllers.password,
      obscureText: _obscurePassword,
      validator: _passwordValidator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.primaryColor),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.controllers.password.text =
                      widget.controllers.phone.text.trim();
                  if (!isEdit) _autoSyncPassword = true;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Use Mobile',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: auto-uppercase text formatter (for PAN)
// ─────────────────────────────────────────────────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

