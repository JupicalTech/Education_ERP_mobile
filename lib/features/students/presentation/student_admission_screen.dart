import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/student_admission_model.dart';
import '../data/student_model.dart';
import '../providers/students_providers.dart';
import 'widgets/admission_step_widgets.dart';

class StudentAdmissionScreen extends ConsumerStatefulWidget {
  const StudentAdmissionScreen({super.key, this.editingStudent});

  final Student? editingStudent;

  @override
  ConsumerState<StudentAdmissionScreen> createState() =>
      _StudentAdmissionScreenState();
}

class _StudentAdmissionScreenState
    extends ConsumerState<StudentAdmissionScreen> {
  final List<GlobalKey<FormState>> _stepFormKeys = List.generate(
    StudentAdmissionNotifier.totalSteps,
    (_) => GlobalKey<FormState>(),
  );

  @override
  void initState() {
    super.initState();
    final student = widget.editingStudent;
    if (student != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(studentAdmissionProvider.notifier).initForEdit(student);
        }
      });
    }
  }

  static const _stepTitles = [
    'Basic Details',
    'Admission Details',
    'Contact & Address',
    'Parent / Guardian',
    'Previous School',
    'Other Info',
    'Documents',
    'Review & Submit',
  ];

  static const _classes = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  static const _sections = ['A', 'B', 'C', 'D'];
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
  static const _academicYears = ['2025-2026', '2026-2027', '2027-2028'];

  bool _validateCurrentStep(int step) {
    final formState = _stepFormKeys[step].currentState;
    if (formState != null && !formState.validate()) {
      return false;
    }
    final extraError =
        ref.read(studentAdmissionProvider.notifier).validateStepExtra(step);
    if (extraError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extraError)),
      );
      return false;
    }
    return true;
  }

  void _onNext(int currentStep) {
    if (!_validateCurrentStep(currentStep)) return;
    ref.read(studentAdmissionProvider.notifier).nextStep();
  }

  Future<void> _onSubmit() async {
    final isEditing = widget.editingStudent != null;
    final saved = await ref.read(studentAdmissionProvider.notifier).submit();
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Updated ${saved.fullName} (${saved.admissionNo})'
                : 'Admitted ${saved.fullName} (${saved.admissionNo})',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(studentAdmissionProvider);
    final notifier = ref.read(studentAdmissionProvider.notifier);
    final editing = widget.editingStudent;
    if (editing != null && formState.editingStudentId != editing.id) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const LoadingView(message: 'Loading student details...'),
      );
    }
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: KeyedSubtree(
        key: ValueKey(formState.editingStudentId ?? 'new'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: BreadcrumbBar(
                items: [
                  BreadcrumbItem(
                    label: 'Students',
                    onTap: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                  if (editing != null)
                    BreadcrumbItem(
                      label: editing.fullName,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  BreadcrumbItem(
                    label: editing != null
                        ? 'Edit Record'
                        : 'New Student Admission',
                  ),
                ],
              ),
            ),
          if (formState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: MaterialBanner(
                content: Text(formState.errorMessage!),
                actions: [
                  TextButton(
                    onPressed: () =>
                        notifier.goToStep(formState.currentStep),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isWide
                ? _buildWebLayout(formState, notifier)
                : _buildMobileStepper(formState, notifier),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMobileStepper(
    AdmissionFormState formState,
    StudentAdmissionNotifier notifier,
  ) {
    return Stepper(
      type: StepperType.vertical,
      currentStep: formState.currentStep,
      onStepTapped: (target) {
        if (target < formState.currentStep ||
            _validateCurrentStep(formState.currentStep)) {
          notifier.goToStep(target);
        }
      },
      controlsBuilder: (context, details) {
        final isLast =
            formState.currentStep == StudentAdmissionNotifier.totalSteps - 1;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Row(
            children: [
              if (formState.currentStep > 0) ...[
                AppButton(
                  label: 'Back',
                  variant: AppButtonVariant.outlined,
                  onPressed:
                      formState.isSubmitting ? null : notifier.previousStep,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              AppButton(
                label: isLast
                    ? (formState.isEditing ? 'Save Changes' : 'Submit Admission')
                    : 'Next',
                isLoading: isLast && formState.isSubmitting,
                onPressed: isLast
                    ? _onSubmit
                    : () => _onNext(formState.currentStep),
              ),
            ],
          ),
        );
      },
      steps: List.generate(_stepTitles.length, (index) {
        return Step(
          title: Text(_stepTitles[index]),
          isActive: formState.currentStep >= index,
          state: formState.currentStep > index
              ? StepState.complete
              : StepState.indexed,
          content: Form(
            key: _stepFormKeys[index],
            child: _buildStepBody(index, formState.payload, notifier),
          ),
        );
      }),
    );
  }

  Widget _buildWebLayout(
    AdmissionFormState formState,
    StudentAdmissionNotifier notifier,
  ) {
    final step = formState.currentStep;
    final isLast = step == StudentAdmissionNotifier.totalSteps - 1;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _stepTitles.length,
                itemBuilder: (context, index) {
                  final selected = index == step;
                  final completed = index < step;
                  return ListTile(
                    selected: selected,
                    selectedTileColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.45),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: selected || completed
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      child: completed
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              '${index + 1}',
                              style: textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    title: Text(
                      _stepTitles[index],
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      if (index < step || _validateCurrentStep(step)) {
                        notifier.goToStep(index);
                      }
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step ${step + 1} of ${_stepTitles.length}: ${_stepTitles[step]}',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        'Fields marked * are mandatory',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _stepFormKeys[step],
                        child: _buildStepBody(
                          step,
                          formState.payload,
                          notifier,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (step > 0) ...[
                        AppButton(
                          label: 'Back',
                          variant: AppButtonVariant.outlined,
                          onPressed: formState.isSubmitting
                              ? null
                              : notifier.previousStep,
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      AppButton(
                        label: isLast
                            ? (formState.isEditing
                                ? 'Save Changes'
                                : 'Submit Admission')
                            : 'Next',
                        icon: isLast ? Icons.check_circle_outline : null,
                        isLoading: isLast && formState.isSubmitting,
                        onPressed: isLast ? _onSubmit : () => _onNext(step),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody(
    int step,
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    switch (step) {
      case 0:
        return _buildBasicDetails(payload, notifier);
      case 1:
        return _buildAdmissionDetails(payload, notifier);
      case 2:
        return _buildContactAddress(payload, notifier);
      case 3:
        return _buildParentGuardian(payload, notifier);
      case 4:
        return _buildPreviousSchool(payload, notifier);
      case 5:
        return _buildOtherInfo(payload, notifier);
      case 6:
        return _buildDocuments(payload, notifier);
      default:
        return AdmissionReviewSection(onEditStep: notifier.goToStep);
    }
  }

  Widget _buildBasicDetails(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                payload.photoUrl != null
                    ? Icons.person
                    : Icons.add_a_photo_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  label: payload.photoUrl == null
                      ? 'Upload Photo'
                      : 'Change Photo',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.upload_file,
                  onPressed: () => notifier.updatePayload(
                    (p) => p.copyWith(
                      photoUrl:
                          'stub://student-photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
                    ),
                  ),
                ),
                if (payload.photoUrl != null)
                  Text(
                    'Photo attached (stub)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FormFieldGrid(
          children: [
            TextFormField(
              initialValue: payload.firstName,
              decoration: const InputDecoration(labelText: 'First Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(firstName: v)),
            ),
            TextFormField(
              initialValue: payload.middleName,
              decoration: const InputDecoration(labelText: 'Middle Name'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(middleName: v)),
            ),
            TextFormField(
              initialValue: payload.lastName,
              decoration: const InputDecoration(labelText: 'Last Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(lastName: v)),
            ),
            DatePickerField(
              label: 'Date of Birth',
              value: payload.dateOfBirth,
              onPicked: (date) =>
                  notifier.updatePayload((p) => p.copyWith(dateOfBirth: date)),
            ),
            DropdownButtonFormField<String>(
              initialValue: payload.gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: _genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(gender: v)),
            ),
            DropdownButtonFormField<String>(
              initialValue: payload.bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: _bloodGroups
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(bloodGroup: v)),
            ),
            TextFormField(
              initialValue: payload.nationality,
              decoration: const InputDecoration(labelText: 'Nationality'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(nationality: v)),
            ),
            TextFormField(
              initialValue: payload.religion,
              decoration: const InputDecoration(labelText: 'Religion'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(religion: v)),
            ),
            TextFormField(
              initialValue: payload.motherTongue,
              decoration: const InputDecoration(labelText: 'Mother Tongue'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(motherTongue: v)),
            ),
            DropdownButtonFormField<StudentCategory>(
              initialValue: payload.category,
              decoration:
                  const InputDecoration(labelText: 'Category (Optional)'),
              items: StudentCategory.values
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                  )
                  .toList(),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(category: v)),
            ),
            TextFormField(
              initialValue: payload.aadhaarNumber,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'Aadhaar Number (Optional)',
                counterText: '',
              ),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(aadhaarNumber: v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdmissionDetails(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return FormFieldGrid(
      children: [
        TextFormField(
          initialValue: payload.admissionNumber,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Admission Number (Auto-generated)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        DatePickerField(
          label: 'Admission Date',
          value: payload.admissionDate,
          onPicked: (date) =>
              notifier.updatePayload((p) => p.copyWith(admissionDate: date)),
        ),
        TextFormField(
          initialValue: payload.grNumber,
          decoration: const InputDecoration(labelText: 'GR Number'),
          onChanged: (v) =>
              notifier.updatePayload((p) => p.copyWith(grNumber: v)),
        ),
        DropdownButtonFormField<String>(
          initialValue: payload.academicYear,
          decoration: const InputDecoration(labelText: 'Academic Year'),
          items: _academicYears
              .map((y) => DropdownMenuItem(value: y, child: Text(y)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              notifier.updatePayload((p) => p.copyWith(academicYear: v));
            }
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: payload.className,
          decoration: const InputDecoration(labelText: 'Class'),
          items: _classes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) =>
              notifier.updatePayload((p) => p.copyWith(className: v)),
        ),
        DropdownButtonFormField<String>(
          initialValue: payload.sectionName,
          decoration: const InputDecoration(labelText: 'Section'),
          items: _sections
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) =>
              notifier.updatePayload((p) => p.copyWith(sectionName: v)),
        ),
        TextFormField(
          initialValue: payload.rollNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Roll Number'),
          onChanged: (v) =>
              notifier.updatePayload((p) => p.copyWith(rollNumber: v)),
        ),
        DropdownButtonFormField<AdmissionType>(
          initialValue: payload.admissionType,
          decoration: const InputDecoration(labelText: 'Admission Type'),
          items: AdmissionType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              notifier.updatePayload((p) => p.copyWith(admissionType: v));
            }
          },
        ),
        DropdownButtonFormField<StudentType>(
          initialValue: payload.studentType,
          decoration: const InputDecoration(labelText: 'Student Type'),
          items: StudentType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              notifier.updatePayload((p) => p.copyWith(studentType: v));
            }
          },
        ),
        TextFormField(
          initialValue: payload.mediumOfInstruction,
          decoration:
              const InputDecoration(labelText: 'Medium of Instruction'),
          onChanged: (v) => notifier.updatePayload(
            (p) => p.copyWith(mediumOfInstruction: v),
          ),
        ),
      ],
    );
  }

  Widget _buildContactAddress(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: payload.currentAddress,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Current Address'),
          onChanged: (v) =>
              notifier.updatePayload((p) => p.copyWith(currentAddress: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: payload.sameAsCurrentAddress,
          title: const Text('Permanent address same as current address'),
          onChanged: (checked) => notifier.updatePayload(
            (p) => p.copyWith(sameAsCurrentAddress: checked ?? false),
          ),
        ),
        if (!payload.sameAsCurrentAddress) ...[
          TextFormField(
            initialValue: payload.permanentAddress,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Permanent Address'),
            onChanged: (v) => notifier.updatePayload(
              (p) => p.copyWith(permanentAddress: v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FormFieldGrid(
          children: [
            TextFormField(
              initialValue: payload.city,
              decoration: const InputDecoration(labelText: 'City'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(city: v)),
            ),
            TextFormField(
              initialValue: payload.state,
              decoration: const InputDecoration(labelText: 'State'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(state: v)),
            ),
            TextFormField(
              initialValue: payload.pincode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Pincode',
                counterText: '',
              ),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(pincode: v)),
            ),
            TextFormField(
              initialValue: payload.studentPhone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Student Phone (Optional)',
                counterText: '',
              ),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(studentPhone: v)),
            ),
            TextFormField(
              initialValue: payload.studentEmail,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Student Email (Optional)'),
              onChanged: (v) =>
                  notifier.updatePayload((p) => p.copyWith(studentEmail: v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentGuardian(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Primary Contact'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    selected:
                        payload.primaryContact == PrimaryContactRole.father,
                    label: const Text('Father'),
                    onSelected: (_) => notifier.updatePayload(
                      (p) =>
                          p.copyWith(primaryContact: PrimaryContactRole.father),
                    ),
                  ),
                  ChoiceChip(
                    selected:
                        payload.primaryContact == PrimaryContactRole.mother,
                    label: const Text('Mother'),
                    onSelected: (_) => notifier.updatePayload(
                      (p) =>
                          p.copyWith(primaryContact: PrimaryContactRole.mother),
                    ),
                  ),
                  if (payload.hasSeparateGuardian)
                    ChoiceChip(
                      selected: payload.primaryContact ==
                          PrimaryContactRole.guardian,
                      label: const Text('Guardian'),
                      onSelected: (_) => notifier.updatePayload(
                        (p) => p.copyWith(
                          primaryContact: PrimaryContactRole.guardian,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GuardianSectionCard(
          title: 'Father Details',
          guardian: payload.father,
          onChanged: (g) => notifier.updatePayload((p) => p.copyWith(father: g)),
        ),
        const SizedBox(height: AppSpacing.md),
        GuardianSectionCard(
          title: 'Mother Details',
          guardian: payload.mother,
          onChanged: (g) => notifier.updatePayload((p) => p.copyWith(mother: g)),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: payload.hasSeparateGuardian,
          title: const Text('Guardian is different from parents'),
          onChanged: (checked) => notifier.updatePayload(
            (p) => p.copyWith(
              hasSeparateGuardian: checked ?? false,
              primaryContact: !(checked ?? false) &&
                      p.primaryContact == PrimaryContactRole.guardian
                  ? PrimaryContactRole.father
                  : p.primaryContact,
            ),
          ),
        ),
        if (payload.hasSeparateGuardian) ...[
          GuardianSectionCard(
            title: 'Guardian Details',
            guardian: payload.guardian,
            includeIncomeAndOccupation: false,
            includeRelationshipInput: true,
            onChanged: (g) =>
                notifier.updatePayload((p) => p.copyWith(guardian: g)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Emergency Contact'),
              const SizedBox(height: AppSpacing.md),
              FormFieldGrid(
                children: [
                  TextFormField(
                    initialValue: payload.emergencyContactName,
                    decoration: const InputDecoration(labelText: 'Contact Name'),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(emergencyContactName: v),
                    ),
                  ),
                  TextFormField(
                    initialValue: payload.emergencyContactPhone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      counterText: '',
                    ),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(emergencyContactPhone: v),
                    ),
                  ),
                  TextFormField(
                    initialValue: payload.emergencyContactRelationship,
                    decoration: const InputDecoration(labelText: 'Relationship'),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(emergencyContactRelationship: v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousSchool(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < payload.previousSchools.length; i++) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Previous School ${i + 1}',
                  actionLabel:
                      payload.previousSchools.length > 1 ? 'Remove' : null,
                  onAction: payload.previousSchools.length > 1
                      ? () => notifier.removePreviousSchool(i)
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                FormFieldGrid(
                  children: [
                    TextFormField(
                      initialValue: payload.previousSchools[i].schoolName,
                      decoration:
                          const InputDecoration(labelText: 'School Name'),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(schoolName: v),
                      ),
                    ),
                    DropdownButtonFormField<SchoolBoard>(
                      initialValue: payload.previousSchools[i].board,
                      decoration: const InputDecoration(labelText: 'Board'),
                      items: SchoolBoard.values
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          notifier.updatePreviousSchool(
                            i,
                            (s) => s.copyWith(board: v),
                          );
                        }
                      },
                    ),
                    TextFormField(
                      initialValue:
                          payload.previousSchools[i].lastClassAttended,
                      decoration: const InputDecoration(
                        labelText: 'Last Class Attended',
                      ),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(lastClassAttended: v),
                      ),
                    ),
                    TextFormField(
                      initialValue: payload.previousSchools[i].yearOfPassing,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Year of Passing'),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(yearOfPassing: v),
                      ),
                    ),
                    TextFormField(
                      initialValue:
                          payload.previousSchools[i].percentageOrGrade,
                      decoration: const InputDecoration(
                        labelText: 'Percentage / Grade',
                      ),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(percentageOrGrade: v),
                      ),
                    ),
                    TextFormField(
                      initialValue: payload.previousSchools[i].tcNumber,
                      decoration: const InputDecoration(labelText: 'TC Number'),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(tcNumber: v),
                      ),
                    ),
                    DatePickerField(
                      label: 'TC Date',
                      value: payload.previousSchools[i].tcDate,
                      onPicked: (date) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(tcDate: date),
                      ),
                    ),
                    TextFormField(
                      initialValue: payload.previousSchools[i].reasonForLeaving,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Leaving',
                      ),
                      onChanged: (v) => notifier.updatePreviousSchool(
                        i,
                        (s) => s.copyWith(reasonForLeaving: v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Add Another Previous School',
            icon: Icons.add,
            variant: AppButtonVariant.tonal,
            onPressed: notifier.addPreviousSchool,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherInfo(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Medical Notes'),
              const SizedBox(height: AppSpacing.md),
              FormFieldGrid(
                children: [
                  TextFormField(
                    initialValue: payload.allergies,
                    decoration: const InputDecoration(labelText: 'Allergies'),
                    onChanged: (v) =>
                        notifier.updatePayload((p) => p.copyWith(allergies: v)),
                  ),
                  TextFormField(
                    initialValue: payload.medicalConditions,
                    decoration:
                        const InputDecoration(labelText: 'Medical Conditions'),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(medicalConditions: v),
                    ),
                  ),
                  TextFormField(
                    initialValue: payload.doctorContact,
                    decoration:
                        const InputDecoration(labelText: 'Doctor Contact'),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(doctorContact: v),
                    ),
                  ),
                  TextFormField(
                    initialValue: payload.specialNeeds,
                    decoration:
                        const InputDecoration(labelText: 'Special Needs'),
                    onChanged: (v) => notifier.updatePayload(
                      (p) => p.copyWith(specialNeeds: v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: payload.transportNeeded,
                title: const Text('School Transport Needed'),
                onChanged: (v) => notifier.updatePayload(
                  (p) => p.copyWith(transportNeeded: v),
                ),
              ),
              if (payload.transportNeeded) ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  initialValue: payload.transportRouteStop,
                  decoration: const InputDecoration(
                    labelText: 'Route / Stop',
                    prefixIcon: Icon(Icons.directions_bus_outlined),
                  ),
                  onChanged: (v) => notifier.updatePayload(
                    (p) => p.copyWith(transportRouteStop: v),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SiblingPickerSection(),
      ],
    );
  }

  Widget _buildDocuments(
    StudentAdmissionPayload payload,
    StudentAdmissionNotifier notifier,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payload.documents.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final doc = payload.documents[index];
          return ListTile(
            leading: Icon(
              doc.isUploaded
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
              color: doc.isUploaded
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(doc.docType.label),
            subtitle: Text(
              doc.isUploaded ? doc.fileName! : 'Not uploaded (stubbed)',
            ),
            trailing: doc.isUploaded
                ? TextButton(
                    onPressed: () => notifier.clearDocument(doc.docType),
                    child: const Text('Remove'),
                  )
                : AppButton(
                    label: 'Upload',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => notifier.stubUploadDocument(doc.docType),
                  ),
          );
        },
      ),
    );
  }
}
