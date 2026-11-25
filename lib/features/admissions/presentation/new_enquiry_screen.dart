import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admission_model.dart';
import '../providers/admissions_providers.dart';

class NewEnquiryScreen extends ConsumerStatefulWidget {
  const NewEnquiryScreen({super.key});

  @override
  ConsumerState<NewEnquiryScreen> createState() => _NewEnquiryScreenState();
}

class _NewEnquiryScreenState extends ConsumerState<NewEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _prevSchoolCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _applyingClass = 'Class 6';
  bool _docsAttached = false;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _guardianCtrl.dispose();
    _phoneCtrl.dispose();
    _prevSchoolCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(admissionsProvider.notifier).addEnquiry(
          AdmissionEnquiry(
            id: 'enq-${DateTime.now().millisecondsSinceEpoch}',
            studentName: _studentCtrl.text.trim(),
            applyingForClass: _applyingClass,
            guardianName: _guardianCtrl.text.trim(),
            guardianPhone: _phoneCtrl.text.trim(),
            previousSchool: _prevSchoolCtrl.text.trim().isEmpty
                ? 'Not specified'
                : _prevSchoolCtrl.text.trim(),
            followUpNote: _noteCtrl.text.trim().isEmpty
                ? 'New enquiry submitted'
                : _noteCtrl.text.trim(),
            status: LeadStatus.newLead,
            dateLabel: 'Just now',
            documentsAttached: _docsAttached,
          ),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enquiry added for ${_studentCtrl.text.trim()}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const classes = ['Class 3', 'Class 6', 'Class 7', 'Class 8', 'Class 9'];

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Admissions',
                onTap: () => Navigator.of(context).pop(),
              ),
              const BreadcrumbItem(label: 'New Enquiry'),
            ],
          ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Student Details'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _studentCtrl,
                        label: 'Student Full Name',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _applyingClass,
                        decoration: const InputDecoration(
                          labelText: 'Applying for Class',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        items: classes
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _applyingClass = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _prevSchoolCtrl,
                        label: 'Previous School (optional)',
                        prefixIcon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Guardian & Contact'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _guardianCtrl,
                        label: 'Parent / Guardian Name',
                        prefixIcon: Icons.family_restroom_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Documents & Follow-up'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Documents attached (TC / Birth Cert)',
                        ),
                        value: _docsAttached,
                        onChanged: (v) => setState(() => _docsAttached = v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _noteCtrl,
                        label: 'Follow-up Note (optional)',
                        prefixIcon: Icons.notes_outlined,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Submit Enquiry',
                  icon: Icons.send_outlined,
                  fullWidth: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
