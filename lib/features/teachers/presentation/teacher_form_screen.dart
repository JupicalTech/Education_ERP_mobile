import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/data/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/teacher_model.dart';
import '../providers/teachers_providers.dart';

class TeacherFormScreen extends ConsumerStatefulWidget {
  const TeacherFormScreen({super.key, this.editingTeacher});

  final Teacher? editingTeacher;

  @override
  ConsumerState<TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends ConsumerState<TeacherFormScreen> {
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());

  // Basic
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _nationalityCtrl;
  late final TextEditingController _religionCtrl;
  late final TextEditingController _aadhaarCtrl;
  late final TextEditingController _panCtrl;

  // Contact & Address
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _altPhoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _currAddrCtrl;
  late final TextEditingController _permAddrCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _emgNameCtrl;
  late final TextEditingController _emgPhoneCtrl;
  late final TextEditingController _emgRelCtrl;

  // Employment
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _licenseCtrl;

  // Salary & Bank
  late final TextEditingController _basicSalaryCtrl;
  late final TextEditingController _allowancesCtrl;
  late final TextEditingController _deductionsCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNoCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _holderNameCtrl;
  late final TextEditingController _pfCtrl;
  late final TextEditingController _esiCtrl;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  static const _maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];
  static const _designations = [
    'PGT',
    'TGT',
    'PRT',
    'Lab Assistant',
    'Sports Coach',
    'Counselor',
  ];
  static const _subjects = [
    'Physics',
    'Chemistry',
    'Biology',
    'Mathematics',
    'English',
    'Hindi',
    'Social Studies',
    'History',
    'Computer Science',
  ];
  static const _classes = [
    'Class 3',
    'Class 6',
    'Class 8',
    'Class 9',
    'Class 10',
  ];
  static const _sections = ['A', 'B', 'C'];
  static const _docSlots = [
    'ID Proof',
    'Address Proof',
    'Degree Certificates',
    'Experience Letters',
    'Joining Letter',
    'Passport Photo',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.editingTeacher;
    _firstNameCtrl = TextEditingController(text: t?.firstName ?? '');
    _middleNameCtrl = TextEditingController(text: t?.middleName ?? '');
    _lastNameCtrl = TextEditingController(text: t?.lastName ?? '');
    _nationalityCtrl = TextEditingController(text: t?.nationality ?? 'Indian');
    _religionCtrl = TextEditingController(text: t?.religion ?? '');
    _aadhaarCtrl = TextEditingController(text: t?.aadhaarNumber ?? '');
    _panCtrl = TextEditingController(text: t?.panNumber ?? '');

    _phoneCtrl = TextEditingController(text: t?.phone ?? '');
    _altPhoneCtrl = TextEditingController(text: t?.alternatePhone ?? '');
    _emailCtrl = TextEditingController(text: t?.email ?? '');
    _currAddrCtrl = TextEditingController(text: t?.currentAddress ?? '');
    _permAddrCtrl = TextEditingController(text: t?.permanentAddress ?? '');
    _cityCtrl = TextEditingController(text: t?.city ?? '');
    _stateCtrl = TextEditingController(text: t?.state ?? '');
    _pincodeCtrl = TextEditingController(text: t?.pincode ?? '');
    _emgNameCtrl = TextEditingController(text: t?.emergencyContactName ?? '');
    _emgPhoneCtrl = TextEditingController(text: t?.emergencyContactPhone ?? '');
    _emgRelCtrl = TextEditingController(
      text: t?.emergencyContactRelationship ?? '',
    );

    _departmentCtrl = TextEditingController(text: t?.department ?? '');
    _licenseCtrl = TextEditingController(
      text: t?.teachingLicenseNumber ?? '',
    );

    final bank = t?.bankDetails;
    _basicSalaryCtrl = TextEditingController(
      text: bank != null && bank.basicSalary > 0
          ? bank.basicSalary.toStringAsFixed(0)
          : '',
    );
    _allowancesCtrl = TextEditingController(
      text: bank != null && bank.allowances > 0
          ? bank.allowances.toStringAsFixed(0)
          : '',
    );
    _deductionsCtrl = TextEditingController(
      text: bank != null && bank.deductions > 0
          ? bank.deductions.toStringAsFixed(0)
          : '',
    );
    _bankNameCtrl = TextEditingController(text: bank?.bankName ?? '');
    _accountNoCtrl = TextEditingController(text: bank?.accountNumber ?? '');
    _ifscCtrl = TextEditingController(text: bank?.ifscCode ?? '');
    _holderNameCtrl = TextEditingController(
      text: bank?.accountHolderName ?? '',
    );
    _pfCtrl = TextEditingController(text: bank?.pfNumber ?? '');
    _esiCtrl = TextEditingController(text: bank?.esiNumber ?? '');

    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(teacherFormProvider.notifier);
      if (t != null) {
        notifier.initForEdit(t);
      } else {
        notifier.reset();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _middleNameCtrl,
      _lastNameCtrl,
      _nationalityCtrl,
      _religionCtrl,
      _aadhaarCtrl,
      _panCtrl,
      _phoneCtrl,
      _altPhoneCtrl,
      _emailCtrl,
      _currAddrCtrl,
      _permAddrCtrl,
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
      _emgNameCtrl,
      _emgPhoneCtrl,
      _emgRelCtrl,
      _departmentCtrl,
      _licenseCtrl,
      _basicSalaryCtrl,
      _allowancesCtrl,
      _deductionsCtrl,
      _bankNameCtrl,
      _accountNoCtrl,
      _ifscCtrl,
      _holderNameCtrl,
      _pfCtrl,
      _esiCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<_StepDef> _visibleSteps(bool canEditSalary) => [
    const _StepDef(0, 'Basic Details', Icons.person_outline),
    const _StepDef(1, 'Contact & Address', Icons.contact_mail_outlined),
    const _StepDef(2, 'Employment Details', Icons.badge_outlined),
    const _StepDef(3, 'Qualifications & Exp.', Icons.school_outlined),
    const _StepDef(4, 'Academic Assignment', Icons.menu_book_outlined),
    if (canEditSalary)
      const _StepDef(5, 'Salary & Bank', Icons.account_balance_outlined),
    const _StepDef(6, 'Documents', Icons.folder_outlined),
  ];

  void _syncControllersToDraft() {
    ref.read(teacherFormProvider.notifier).updateDraft((d) {
      return d.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        nationality: _nationalityCtrl.text.trim().isEmpty
            ? 'Indian'
            : _nationalityCtrl.text.trim(),
        religion: _religionCtrl.text.trim(),
        aadhaarNumber: _aadhaarCtrl.text.trim(),
        panNumber: _panCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        alternatePhone: _altPhoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        currentAddress: _currAddrCtrl.text.trim(),
        permanentAddress: _permAddrCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        emergencyContactName: _emgNameCtrl.text.trim(),
        emergencyContactPhone: _emgPhoneCtrl.text.trim(),
        emergencyContactRelationship: _emgRelCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        teachingLicenseNumber: _licenseCtrl.text.trim(),
        bankDetails: TeacherBankDetails(
          basicSalary: double.tryParse(_basicSalaryCtrl.text.trim()) ?? 0,
          allowances: double.tryParse(_allowancesCtrl.text.trim()) ?? 0,
          deductions: double.tryParse(_deductionsCtrl.text.trim()) ?? 0,
          bankName: _bankNameCtrl.text.trim(),
          accountNumber: _accountNoCtrl.text.trim(),
          ifscCode: _ifscCtrl.text.trim(),
          accountHolderName: _holderNameCtrl.text.trim(),
          pfNumber: _pfCtrl.text.trim(),
          esiNumber: _esiCtrl.text.trim(),
        ),
      );
    });
  }

  bool _validateStep(int stepId) {
    final form = _formKeys[stepId].currentState;
    if (form != null && !form.validate()) return false;
    _syncControllersToDraft();
    return true;
  }

  Future<void> _onSubmit() async {
    for (final key in _formKeys) {
      if (key.currentState != null && !key.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the highlighted validation errors.'),
          ),
        );
        return;
      }
    }
    _syncControllersToDraft();
    final saved = await ref.read(teacherFormProvider.notifier).submit();
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editingTeacher != null
                ? 'Updated ${saved.fullName} (${saved.employeeId})'
                : 'Added ${saved.fullName} (${saved.employeeId})',
          ),
        ),
      );
    }
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2040),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(teacherFormProvider);
    final role = ref.watch(currentProfileProvider).value?.role;
    final canEditSalary =
        role == UserRole.principal || role == UserRole.superAdmin;
    final steps = _visibleSteps(canEditSalary);
    final activeIdx = formState.currentStep.clamp(0, steps.length - 1);
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingTeacher != null ? 'Edit Teacher' : 'Add Teacher',
        ),
      ),
      body: isWide
          ? _buildWideLayout(steps, activeIdx, formState, canEditSalary)
          : _buildMobileStepper(steps, activeIdx, formState, canEditSalary),
    );
  }

  Widget _buildWideLayout(
    List<_StepDef> steps,
    int activeIdx,
    TeacherFormState formState,
    bool canEditSalary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeStep = steps[activeIdx];
    final isLast = activeIdx == steps.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 260,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: steps.length,
            itemBuilder: (context, i) {
              final s = steps[i];
              final selected = i == activeIdx;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  selected: selected,
                  selectedTileColor: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  leading: Icon(s.icon),
                  title: Text('${i + 1}. ${s.title}'),
                  onTap: () =>
                      ref.read(teacherFormProvider.notifier).goToStep(i),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        activeStep.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStepBody(activeStep.id, formState, canEditSalary),
                      if (formState.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          formState.error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (activeIdx > 0)
                            AppButton(
                              label: 'Back',
                              variant: AppButtonVariant.outlined,
                              onPressed: () => ref
                                  .read(teacherFormProvider.notifier)
                                  .goToStep(activeIdx - 1),
                            ),
                          const SizedBox(width: AppSpacing.md),
                          AppButton(
                            label: isLast ? 'Save Teacher' : 'Continue',
                            isLoading: formState.isSubmitting,
                            onPressed: () {
                              if (!_validateStep(activeStep.id)) return;
                              if (isLast) {
                                _onSubmit();
                              } else {
                                ref
                                    .read(teacherFormProvider.notifier)
                                    .goToStep(activeIdx + 1);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStepper(
    List<_StepDef> steps,
    int activeIdx,
    TeacherFormState formState,
    bool canEditSalary,
  ) {
    final isLast = activeIdx == steps.length - 1;
    return Stepper(
      currentStep: activeIdx,
      onStepTapped: (i) => ref.read(teacherFormProvider.notifier).goToStep(i),
      onStepContinue: () {
        if (!_validateStep(steps[activeIdx].id)) return;
        if (isLast) {
          _onSubmit();
        } else {
          ref.read(teacherFormProvider.notifier).goToStep(activeIdx + 1);
        }
      },
      onStepCancel: activeIdx > 0
          ? () => ref.read(teacherFormProvider.notifier).goToStep(activeIdx - 1)
          : null,
      controlsBuilder: (context, details) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            AppButton(
              label: isLast ? 'Save Teacher' : 'Continue',
              isLoading: formState.isSubmitting,
              onPressed: details.onStepContinue,
            ),
            if (activeIdx > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Back',
                variant: AppButtonVariant.outlined,
                onPressed: details.onStepCancel,
              ),
            ],
          ],
        ),
      ),
      steps: steps
          .map(
            (s) => Step(
              title: Text(s.title),
              isActive: steps.indexOf(s) <= activeIdx,
              content: _buildStepBody(s.id, formState, canEditSalary),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStepBody(
    int stepId,
    TeacherFormState formState,
    bool canEditSalary,
  ) {
    return switch (stepId) {
      0 => _buildBasicStep(formState),
      1 => _buildContactStep(formState),
      2 => _buildEmploymentStep(formState),
      3 => _buildQualificationsStep(formState),
      4 => _buildAssignmentStep(formState),
      5 when canEditSalary => _buildSalaryStep(),
      6 => _buildDocumentsStep(formState),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBasicStep(TeacherFormState formState) {
    final d = formState.draft;
    final notifier = ref.read(teacherFormProvider.notifier);

    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(
                  d.photoUrl != null
                      ? Icons.check_circle_outline
                      : Icons.person_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppButton(
                label: d.photoUrl != null ? 'Photo Selected' : 'Upload Photo',
                icon: Icons.upload_outlined,
                variant: AppButtonVariant.tonal,
                onPressed: () {
                  notifier.updateDraft(
                    (cur) => cur.copyWith(photoUrl: 'stub://teacher_photo.jpg'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _firstNameCtrl,
            label: 'First Name *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'First name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _middleNameCtrl, label: 'Middle Name'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _lastNameCtrl,
            label: 'Last Name *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Date of Birth',
                  value: d.dateOfBirth,
                  onTap: () => _pickDate(
                    initial: d.dateOfBirth ?? DateTime(1990, 1, 1),
                    lastDate: DateTime.now(),
                    onPicked: (dt) =>
                        notifier.updateDraft((c) => c.copyWith(dateOfBirth: dt)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: d.gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      notifier.updateDraft((c) => c.copyWith(gender: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: d.bloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                  items: _bloodGroups
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) =>
                      notifier.updateDraft((c) => c.copyWith(bloodGroup: v)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: d.maritalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Marital Status',
                  ),
                  items: _maritalStatuses
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      notifier.updateDraft((c) => c.copyWith(maritalStatus: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _nationalityCtrl,
                  label: 'Nationality',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _religionCtrl,
                  label: 'Religion (Optional)',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _aadhaarCtrl,
                  label: 'Aadhaar Number (Optional)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _panCtrl,
                  label: 'PAN (Optional)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep(TeacherFormState formState) {
    final notifier = ref.read(teacherFormProvider.notifier);

    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailCtrl,
            label: 'Login Email *',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final email = (v ?? '').trim();
              if (email.isEmpty) return 'Email is required for login';
              final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!regex.hasMatch(email)) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _phoneCtrl,
                  label: 'Phone (Optional)',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _altPhoneCtrl,
                  label: 'Alternate Phone',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _currAddrCtrl,
            label: 'Current Address',
          ),
          const SizedBox(height: AppSpacing.xs),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: formState.sameAsCurrentAddress,
            title: const Text('Permanent address same as current'),
            onChanged: (v) {
              final checked = v ?? false;
              notifier.setSameAsCurrentAddress(checked);
              if (checked) _permAddrCtrl.text = _currAddrCtrl.text;
            },
          ),
          AppTextField(
            controller: _permAddrCtrl,
            label: 'Permanent Address',
            enabled: !formState.sameAsCurrentAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(controller: _cityCtrl, label: 'City'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(controller: _stateCtrl, label: 'State'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _pincodeCtrl,
                  label: 'Pincode',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Emergency Contact'),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: _emgNameCtrl, label: 'Contact Name'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _emgPhoneCtrl,
                  label: 'Contact Phone',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _emgRelCtrl,
                  label: 'Relationship',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentStep(TeacherFormState formState) {
    final d = formState.draft;
    final notifier = ref.read(teacherFormProvider.notifier);
    final staffList = ref.watch(teachersProvider).value ?? const [];

    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: TextEditingController(text: d.employeeId),
            label: 'Employee ID (Auto-generated)',
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _designations.contains(d.designation)
                      ? d.designation
                      : _designations.first,
                  decoration: const InputDecoration(labelText: 'Designation *'),
                  items: _designations
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Designation is required' : null,
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateDraft((c) => c.copyWith(designation: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _departmentCtrl,
                  label: 'Department',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EmploymentType>(
                  initialValue: d.employmentType,
                  decoration: const InputDecoration(
                    labelText: 'Employment Type *',
                  ),
                  items: EmploymentType.values
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateDraft((c) => c.copyWith(employmentType: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: 'Joining Date *',
                  value: d.joiningDate,
                  onTap: () => _pickDate(
                    initial: d.joiningDate,
                    onPicked: (dt) =>
                        notifier.updateDraft((c) => c.copyWith(joiningDate: dt)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Probation End Date (Optional)',
                  value: d.probationEndDate,
                  onTap: () => _pickDate(
                    initial: d.probationEndDate ?? d.joiningDate,
                    onPicked: (dt) => notifier.updateDraft(
                      (c) => c.copyWith(probationEndDate: dt),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: d.reportingToName,
                  decoration: const InputDecoration(labelText: 'Reporting To'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Principal'),
                    ),
                    ...staffList
                        .where((t) => t.id != d.id)
                        .map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.fullName,
                            child: Text(t.fullName),
                          ),
                        ),
                  ],
                  onChanged: (v) => notifier.updateDraft(
                    (c) => c.copyWith(reportingToName: v ?? 'Principal'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TeacherStatus>(
                  initialValue: d.status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TeacherStatus.values
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateDraft((c) => c.copyWith(status: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (d.status == TeacherStatus.resigned)
                Expanded(
                  child: _DateField(
                    label: 'Resignation Date',
                    value: d.resignationDate,
                    onTap: () => _pickDate(
                      initial: d.resignationDate ?? DateTime.now(),
                      onPicked: (dt) => notifier.updateDraft(
                        (c) => c.copyWith(resignationDate: dt),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationsStep(TeacherFormState formState) {
    final d = formState.draft;
    final notifier = ref.read(teacherFormProvider.notifier);

    return Form(
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _licenseCtrl,
            label: 'Teaching Licence / TET / CTET / B.Ed No. (Optional)',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: TextEditingController(text: d.totalExperienceLabel),
            label: 'Total Previous Experience (Calculated)',
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Qualifications',
            actionLabel: 'Add Qualification',
            onAction: () => _showAddQualificationDialog(notifier),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (d.qualifications.isEmpty)
            const Text('No qualifications added yet.')
          else
            ...d.qualifications.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${e.value.degree} (${e.value.specialization ?? '-'})'),
                subtitle: Text(
                  '${e.value.institution} • ${e.value.yearOfPassing ?? '-'} • ${e.value.percentageOrGrade ?? '-'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.removeQualification(e.key),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Previous Experience',
            actionLabel: 'Add Experience',
            onAction: () => _showAddExperienceDialog(notifier),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (d.experiences.isEmpty)
            const Text('No previous experience added yet.')
          else
            ...d.experiences.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${e.value.organization} • ${e.value.designation ?? '-'}'),
                subtitle: Text(
                  '${_fmtDate(e.value.fromDate)} - ${_fmtDate(e.value.toDate)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.removeExperience(e.key),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentStep(TeacherFormState formState) {
    final d = formState.draft;
    final notifier = ref.read(teacherFormProvider.notifier);
    final allTeachers = ref.watch(teachersProvider).value ?? const [];

    final sectionOptions = [
      for (final c in _classes)
        for (final s in _sections) '$c-$s',
    ];

    final existingHolder = d.classTeacherSection == null
        ? null
        : allTeachers.cast<Teacher?>().firstWhere(
            (t) =>
                t != null &&
                t.id != d.id &&
                t.classTeacherSection == d.classTeacherSection,
            orElse: () => null,
          );

    return Form(
      key: _formKeys[4],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Subjects Teacher Can Teach'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _subjects
                .map(
                  (subj) => FilterChip(
                    label: Text(subj),
                    selected: d.teachableSubjects.contains(subj),
                    onSelected: (_) => notifier.toggleTeachableSubject(subj),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String?>(
            initialValue: d.classTeacherSection,
            decoration: const InputDecoration(
              labelText: 'Class Teacher of Section (Optional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None'),
              ),
              ...sectionOptions.map(
                (sec) => DropdownMenuItem<String?>(value: sec, child: Text(sec)),
              ),
            ],
            onChanged: (v) {
              notifier.updateDraft(
                (c) => v == null
                    ? c.copyWith(clearClassTeacher: true)
                    : c.copyWith(classTeacherSection: v),
              );
            },
          ),
          if (existingHolder != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Note: ${existingHolder.fullName} is currently class teacher of ${d.classTeacherSection} and will be replaced on save.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Class & Subject Allocations (Current Year)',
            actionLabel: 'Add Assignment',
            onAction: () => _showAddAssignmentDialog(notifier),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (d.assignments.isEmpty)
            const Text('No class-subject assignments added yet.')
          else
            ...d.assignments.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text('${e.value.classSection} — ${e.value.subject}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.removeAssignment(e.key),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSalaryStep() {
    return Form(
      key: _formKeys[5],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _basicSalaryCtrl,
                  label: 'Basic Salary',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _allowancesCtrl,
                  label: 'Allowances',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _deductionsCtrl,
                  label: 'Deductions',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _bankNameCtrl, label: 'Bank Name'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _accountNoCtrl,
                  label: 'Account Number',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(controller: _ifscCtrl, label: 'IFSC Code'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _holderNameCtrl,
            label: 'Account Holder Name',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _pfCtrl,
                  label: 'PF Number (Optional)',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _esiCtrl,
                  label: 'ESI Number (Optional)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(TeacherFormState formState) {
    final notifier = ref.read(teacherFormProvider.notifier);
    final docs = formState.draft.documents;

    return Form(
      key: _formKeys[6],
      child: Column(
        children: _docSlots.map((slot) {
          final existing = docs.cast<TeacherDocument?>().firstWhere(
            (d) => d?.docType == slot,
            orElse: () => null,
          );
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              existing != null
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
            ),
            title: Text(slot),
            subtitle: Text(
              existing?.fileName ?? 'Stub upload (Supabase Storage later)',
            ),
            trailing: existing != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.removeDocument(slot),
                  )
                : AppButton(
                    label: 'Upload',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => notifier.setDocument(
                      slot,
                      '${slot.toLowerCase().replaceAll(' ', '_')}.pdf',
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAddQualificationDialog(TeacherFormNotifier notifier) async {
    final degreeCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final instCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Qualification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: degreeCtrl, label: 'Degree *'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: specCtrl, label: 'Specialization'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: instCtrl, label: 'University / Board *'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: yearCtrl, label: 'Year of Passing'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: gradeCtrl, label: 'Percentage / Grade'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true &&
        degreeCtrl.text.trim().isNotEmpty &&
        instCtrl.text.trim().isNotEmpty) {
      notifier.addQualification(
        TeacherQualification(
          degree: degreeCtrl.text.trim(),
          specialization: specCtrl.text.trim(),
          institution: instCtrl.text.trim(),
          yearOfPassing: yearCtrl.text.trim(),
          percentageOrGrade: gradeCtrl.text.trim(),
        ),
      );
    }
    degreeCtrl.dispose();
    specCtrl.dispose();
    instCtrl.dispose();
    yearCtrl.dispose();
    gradeCtrl.dispose();
  }

  Future<void> _showAddExperienceDialog(TeacherFormNotifier notifier) async {
    final orgCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    var fromDate = DateTime(2018, 6, 1);
    var toDate = DateTime(2022, 4, 30);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Previous Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: orgCtrl,
                  label: 'School / Organisation *',
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: desigCtrl, label: 'Designation'),
                const SizedBox(height: AppSpacing.sm),
                _DateField(
                  label: 'From Date',
                  value: fromDate,
                  onTap: () => _pickDate(
                    initial: fromDate,
                    onPicked: (d) => setDlgState(() => fromDate = d),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DateField(
                  label: 'To Date',
                  value: toDate,
                  onTap: () => _pickDate(
                    initial: toDate,
                    onPicked: (d) => setDlgState(() => toDate = d),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: reasonCtrl,
                  label: 'Reason for Leaving',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && orgCtrl.text.trim().isNotEmpty) {
      notifier.addExperience(
        TeacherExperience(
          organization: orgCtrl.text.trim(),
          designation: desigCtrl.text.trim(),
          fromDate: fromDate,
          toDate: toDate,
          reasonForLeaving: reasonCtrl.text.trim(),
        ),
      );
    }
    orgCtrl.dispose();
    desigCtrl.dispose();
    reasonCtrl.dispose();
  }

  Future<void> _showAddAssignmentDialog(TeacherFormNotifier notifier) async {
    var cls = _classes.first;
    var sec = _sections.first;
    var subj = _subjects.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Assign Class & Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: cls,
                decoration: const InputDecoration(labelText: 'Class'),
                items: _classes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => cls = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: sec,
                decoration: const InputDecoration(labelText: 'Section'),
                items: _sections
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => sec = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: subj,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => subj = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      notifier.addAssignment(
        TeacherAssignment(className: cls, sectionName: sec, subject: subj),
      );
    }
  }
}

class _StepDef {
  const _StepDef(this.id, this.title, this.icon);
  final int id;
  final String title;
  final IconData icon;
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value != null ? _fmtDate(value!) : 'Select date'),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
