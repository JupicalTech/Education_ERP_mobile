---
name: education-erp-development
description: Blueprint, architecture decisions, database schema, RLS policies, and setup procedures for the Flutter + Supabase Education ERP project.
---

# Education ERP - Architecture & Implementation Guide

This guide documents the architecture, database schema, Row-Level Security (RLS) rules, setup steps, and current implementation status for the **Education ERP** built with **Flutter** and **Supabase**.

---

## 1. Project Overview & Tech Stack

* **Platform**: Cross-platform Flutter (Mobile for parents, students, and teachers; Responsive Web/Desktop for school management & fee clerks).
* **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions).
* **Key Planned Integrations**: FCM (Push Notifications), Razorpay (Online Fee Payments).
* **Architectural Principle**: **Smart Backend, Dumb Client**. Business rules (ID generation, transactional multi-table writes, attendance validation, fee calculations) and security constraints reside in PostgreSQL functions, triggers, and RLS policies rather than the Flutter client.
* **Multi-Institute (Multi-Tenant) Model**: Every table includes an `institute_id` column protected by RLS. Multiple schools can share the same Supabase database while remaining completely isolated from each other.

---

## 2. Roles & Access Matrix

| Role | Primary User Interface | Responsibilities |
| :--- | :--- | :--- |
| **`super_admin`** | Web Dashboard | System configuration, multi-tenant setup, school onboarding. |
| **`principal`** | Web & Mobile | Full academic management, approvals, analytics, school notices. |
| **`fee_clerk`** | Web Dashboard | Fee structure setup, offline collection, receipts, dues tracking. |
| **`teacher`** | Mobile / Tablet | Section attendance, subject marks, student performance, homework. |
| **`parent`** | Mobile App | Tracking multi-child attendance, fee payments, receipts, notices. |
| **`student`** | Mobile / Web | Viewing personal attendance, report cards, fees, assignments. |

---

## 3. Database Architecture & Migrations

All SQL migrations live in `supabase/migrations/` and **must be run in order**:

### Migration 1: `supabase/migrations/0001_v1_schema.sql`
Creates the foundational enums, tables, RLS helper functions, and base RLS policies:
* **Enums**:
  * `user_role`: `'super_admin'`, `'principal'`, `'fee_clerk'`, `'teacher'`, `'student'`, `'parent'`
  * `attendance_status`: `'present'`, `'absent'`, `'late'`, `'half_day'`
  * `fee_payment_mode`: `'cash'`, `'upi'`, `'cheque'`, `'bank_transfer'`, `'online'`
  * `fee_status`: `'pending'`, `'partial'`, `'paid'`, `'overdue'`
* **Core Tables**:
  1. `institutes`: Master tenant table (`id`, `name`, `code`, `phone`, `email`, `address`, `logo_url`).
  2. `academic_years`: Session tracker (`id`, `institute_id`, `name`, `start_date`, `end_date`, `is_current`).
  3. `profiles`: Extends `auth.users` (`id -> auth.users.id`, `institute_id`, `role`, `first_name`, `last_name`, `phone`, `avatar_url`, `is_active`).
  4. `classes` & `sections`: Academic hierarchy (`classes`: `name`, `display_order`; `sections`: `class_id`, `name`, `class_teacher_id`).
  5. `subjects` & `class_subject_teachers`: Subject definitions and teacher-to-section allocations per academic year.
  6. `students`, `student_enrollments`, `student_parents`: Core student records, yearly class/section enrollments, and parent/guardian links.
  7. `student_attendance`: Daily attendance ledger (`student_id`, `section_id`, `date`, `status`, `marked_by`), unique on `(student_id, date)`.
  8. `fee_heads`, `fee_structures`, `student_fees`, `fee_payments`: Fee categories, class-level templates, student invoices/dues, and payment receipts.
  9. `notices`: School announcements filtered by `target_role` and `target_class_id`.

### Migration 2: `supabase/migrations/0002_student_admission.sql`
Extends student admissions with full demographics and transactional creation:
* Extends `students` with personal, admission, address, emergency contact, transport, and `sibling_ids` fields.
* Adds `guardians` (supports parents without auth profiles at admission time), `student_previous_schools`, `student_documents`, and `student_medical_info` (isolated with stricter RLS excluding `fee_clerk` reads).
* Adds `create_student_admission(payload jsonb)` RPC to insert the student, enrollment, guardians, previous schools, medical info, and documents in a single transaction and auto-generate `ADM-YYYY-NNNN`.

### Migration 3: `supabase/migrations/0003_teachers.sql`
Adds staff/teacher management and transactional RPCs:
* Adds `teacher_employment_type` and `teacher_status` enums.
* Adds `teachers` (1:1 with `profiles`), `teacher_qualifications`, `teacher_experience`, `teacher_documents`, `teacher_subjects`, `teacher_bank_details` (strictly `principal` / `super_admin` only), and `teacher_directory` view.
* Adds `create_teacher(payload jsonb)` RPC (auto-generates `EMP-YYYY-NNN`, upserts `profiles`, creates teacher + related records, and updates `sections.class_teacher_id`) and `set_teacher_active(p_teacher_id, p_is_active)` RPC for soft activation/deactivation.

### Edge Function: `supabase/functions/create-teacher-account/index.ts`
Uses the Supabase Service Role key to create an `auth.users` account for a new teacher and invoke `create_teacher`.

---

## 4. Row-Level Security (RLS) Blueprint

To keep policies fast and maintainable, three `SECURITY DEFINER` helper functions are defined in `0001_v1_schema.sql`:

* `public.get_my_institute_id()`: Returns the logged-in user's `institute_id` from `profiles`.
* `public.get_my_role()`: Returns the logged-in user's `user_role` from `profiles`.
* `public.get_my_student_ids()`: Returns all `student_id`s linked to the logged-in parent via `student_parents`, plus the user's own student record if `students.profile_id = auth.uid()`. Use `student_id IN (SELECT public.get_my_student_ids())` in policies.

### Access Rules Summary
* **Super Admins & Principals**: Full read/write access to all records within their `institute_id`.
* **Fee Clerks**: Full CRUD on fee tables and student admissions; read-only on student profiles; excluded from reading `student_medical_info` and `teacher_bank_details`.
* **Teachers**: Read/write `student_attendance` only for their assigned sections (as class teacher or subject teacher); read-only access to students and their own teacher record.
* **Parents & Students**: Scoped read-only access strictly to records belonging to `get_my_student_ids()`.

---

## 5. Setup & Onboarding Guide (For New Developers)

### A. Flutter App Setup
1. **Environment file**: Create `.env` in the project root with your Supabase credentials (listed in `pubspec.yaml` assets and ignored in `.gitignore`):
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
2. **Startup order** (`lib/main.dart`):
   `WidgetsFlutterBinding.ensureInitialized()` → `dotenv.load()` → `Supabase.initialize()` → `runApp(ProviderScope(child: App()))`.
3. **App root** (`lib/app.dart`): `ConsumerWidget` returning `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark` and `routerProvider`.
4. **Supabase client** (`lib/core/network/supabase_client.dart`): Exposes `supabaseProvider`. All repositories read the client from this provider, never `Supabase.instance` directly.

### B. Folder Structure
```text
lib/
  main.dart, app.dart
  core/
    config/env.dart
    network/supabase_client.dart
    router/app_router.dart
    theme/{app_colors,app_spacing,app_text_styles,app_theme}.dart
    widgets/ (ResponsiveScaffold, AppCard, StatCard, StatusChip, AppButton, AppTextField, etc.)
  features/
    auth/{data,presentation,providers}
    home/{data,providers} + 6 role home screens
    admissions/{data,presentation,providers}
    students/{data,presentation,providers}
    teachers/{data,presentation,providers}
    attendance/{data,presentation,providers}
    fees/{data,presentation,providers}
```

### C. Backend Setup Order (Fresh Supabase Project)
1. In **Supabase SQL Editor**, run the 3 migrations in exact order:
   1. `supabase/migrations/0001_v1_schema.sql`
   2. `supabase/migrations/0002_student_admission.sql`
   3. `supabase/migrations/0003_teachers.sql`
2. Deploy Edge Function: `supabase/functions/create-teacher-account/index.ts`.
3. **Seed initial data**:
   - Create an Auth user in **Authentication → Users** (with Auto Confirm enabled) and copy their UID.
   - Insert at least one row into `institutes`, `academic_years` (`is_current = TRUE`), `classes`, `sections`, `subjects`, and a `profiles` row mapping the Auth user's UID to that `institute_id` with role `'principal'` or `'super_admin'`.

---

## 6. Implementation Status

### Completed Frontend & Architecture
1. `UserRole` enum + `Profile` model matching `user_role` DB enum.
2. `AuthRepository` (`StubAuthRepository` + `SupabaseAuthRepository`) and Riverpod auth providers (`authStateProvider`, `currentProfileProvider`, `loginControllerProvider`).
3. `go_router` (`routerProvider`) with role-based redirect guards (logged out → `/login`, logged in → role home, cross-role routes blocked).
4. Design system (`core/theme/`), shared widgets (`core/widgets/`), and `ResponsiveScaffold` (bottom `NavigationBar` < 900px, `NavigationRail` ≥ 900px).
5. `LoginScreen` (automatically shows 6 quick-login role buttons only when `authRepositoryProvider` is in stub mode) + 6 role home screens.
6. V1 feature UIs: Students (directory, detail/edit, multi-step admission), Teachers (directory, 7-step form, detail/edit, activate/deactivate), Attendance (section roll-call), Fees (dues & collection), Admissions.

### Backend Wiring Status
* **Live on Supabase**:
  * **Auth** (`lib/features/auth/providers/auth_providers.dart` → `SupabaseAuthRepository`)
  * **Students** (`lib/features/students/providers/students_providers.dart` → `SupabaseStudentsRepository`)
  * **Teachers** (`lib/features/teachers/providers/teachers_providers.dart` → `SupabaseTeachersRepository`)
* **Still using Stub / Dummy Data**:
  * **Attendance** (`features/attendance/`)
  * **Fees** (`features/fees/`)
  * **Admissions** (`features/admissions/`)
  * **Home Dashboard Stats** (`features/home/`)
  * **Notices**

### Next Steps
1. Wire **Attendance**, **Fees**, **Admissions**, **Home**, and **Notices** repositories to Supabase.
2. Add `update_student_admission` and `update_teacher` RPCs in SQL migrations to match the edit flows in `SupabaseStudentsRepository` and `SupabaseTeachersRepository`.
3. Build a `super_admin` **Institute Onboarding** flow to create new schools and initial principals without manual SQL.

---

## 7. Conventions
* **State management**: Riverpod (`Notifier`, `AsyncNotifier`, `Provider`). No `setState` for app-level state.
* **Navigation**: `go_router`.
* **Structure**: Feature-first folders (`data/`, `providers/`, `presentation/`).
* **Database writes**: Multi-table writes go through PostgreSQL functions called via `.rpc()`, not multiple sequential client inserts.
