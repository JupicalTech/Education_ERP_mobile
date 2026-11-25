---
name: education-erp-development
description: Blueprint, architecture decisions, database schema, RLS policies, and setup procedures for the Flutter + Supabase Education ERP project.
---

# Education ERP - Architecture & Implementation Guide

This skill documents the foundational design, database schema, Row-Level Security (RLS) rules, and client setup established for the **Education ERP** built with Flutter and Supabase.

---

## 1. Project Overview & Tech Stack

* **Platform**: Cross-platform Flutter (Mobile for parents, students, and teachers; Responsive Web for school management & fee clerks).
* **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions).
* **Key Integrations**: FCM (Push Notifications), Razorpay (Online Fee Payments).
* **Architectural Principle**: **Smart Backend, Dumb Client**. Business rules (fee generation, attendance status validation, results) and security constraints reside in PostgreSQL functions, triggers, and RLS policies rather than the Flutter client.
* **Tenancy Model**: Multi-tenant by design. Every table includes an `institute_id` column protected by RLS, allowing single-institute or multi-institute SaaS deployment without refactoring.

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

## 3. V1 Database Architecture

### Custom PostgreSQL Enums
* `user_role`: `'super_admin'`, `'principal'`, `'fee_clerk'`, `'teacher'`, `'student'`, `'parent'`
* `attendance_status`: `'present'`, `'absent'`, `'late'`, `'half_day'`
* `fee_payment_mode`: `'cash'`, `'upi'`, `'cheque'`, `'bank_transfer'`, `'online'`
* `fee_status`: `'pending'`, `'partial'`, `'paid'`, `'overdue'`

### Core Tables & Relationships

1. **`institutes`**: Master tenant table (`id`, `name`, `code`, `phone`, `email`, `address`, `logo_url`).
2. **`academic_years`**: Session tracker (`id`, `institute_id`, `name`, `start_date`, `end_date`, `is_current`).
3. **`profiles`**: User identity table extending `auth.users` (`id -> auth.users.id`, `institute_id`, `role`, `first_name`, `last_name`, `phone`, `avatar_url`, `is_active`).
4. **`classes` & `sections`**: Academic hierarchy (`classes`: `name`, `display_order`; `sections`: `class_id`, `name`, `class_teacher_id`).
5. **`subjects` & `class_subject_teachers`**: Subject definitions and teacher-to-section allocations.
6. **`students` & `student_enrollments`**: Student profile records linked with yearly academic class/section enrollments.
7. **`student_parents`**: Many-to-many relationship linking parents to multiple children (`student_id`, `parent_profile_id`, `relationship`, `is_primary`).
8. **`student_attendance`**: Daily attendance ledger (`student_id`, `section_id`, `date`, `status`, `marked_by`). Unique constraint on `(student_id, date)`.
9. **`fee_heads`, `fee_structures`, `student_fees`, `fee_payments`**:
   * `fee_heads`: Fee categories (Tuition, Lab, Exam).
   * `fee_structures`: Class-level fee templates per academic year.
   * `student_fees`: Student fee invoices/dues (`original_amount`, `discount_amount`, `fine_amount`, `paid_amount`, `status`).
   * `fee_payments`: Receipts and payment ledger with transaction references (`receipt_number`, `amount_paid`, `payment_mode`, `collected_by`).
10. **`notices`**: School announcements with target audience filters (`target_role`, `target_class_id`).

---

## 4. Row-Level Security (RLS) Blueprint

To avoid complex, slow SQL joins in individual RLS policies, PostgreSQL helper functions are used:

* `get_my_institute_id()`: Returns user's `institute_id` from their `profiles` row using `auth.uid()`.
* `get_my_role()`: Returns user's `user_role` using `auth.uid()`.
* `get_my_student_ids()`: Returns a list of `student_id`s linked to the logged-in parent via `student_parents`.

### Access Rules
* **Admins & Principals**: Full read/write access to all records within their `institute_id`.
* **Fee Clerks**: Full CRUD on `fee_heads`, `fee_structures`, `student_fees`, and `fee_payments`. Read-only access to student profiles.
* **Teachers**: Insert/update access to `student_attendance` for their assigned sections; read-only access to their students.
* **Parents**: Scoped read access to attendance, fee dues, and receipts belonging **only** to students in `get_my_student_ids()`.
* **Students**: Scoped read access strictly to their own profile, attendance, and fee history.

---

## 5. Development & Run Instructions

### Flutter setup (DONE)
1. Dependencies: `supabase_flutter`, `flutter_dotenv`, `flutter_riverpod`, `go_router`, `google_fonts`.
2. `.env` is listed under `flutter: assets:` in `pubspec.yaml` and added to `.gitignore`.
3. `main.dart` order: `WidgetsFlutterBinding.ensureInitialized()` -> `dotenv.load()` -> `Supabase.initialize()` -> `runApp(ProviderScope(child: App()))`.
4. `app.dart` is a `ConsumerWidget` returning `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark` (`ThemeMode.system`, Inter font, `AppSemanticColors` extension) and watching `routerProvider`.
5. `core/network/supabase_client.dart` exposes `supabaseProvider` (Riverpod `Provider<SupabaseClient>`). All repositories read the client from this provider, never `Supabase.instance` directly.
6. `core/theme/` defines the design system (`app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`) and `core/widgets/` provides reusable components (`ResponsiveScaffold`, `AppCard`, `StatCard`, `StatusChip`, `AppButton`, `AppTextField`, `SectionHeader`, `EmptyState`, `LoadingView`, `ErrorView`).

### Folder structure (created)
lib/
  main.dart, app.dart
  core/config/env.dart
  core/network/supabase_client.dart
  core/router/app_router.dart
  core/theme/{app_colors,app_spacing,app_text_styles,app_theme}.dart
  core/widgets/ (shared UI components + ResponsiveScaffold)
  features/auth/{data,presentation,providers}
  features/home/{data,providers} + 6 role home screens
  features/students/{data,presentation,providers}
  features/attendance/{data,presentation,providers}
  features/fees/{data,presentation,providers}

### Build order decision
Flutter is being built BEFORE the SQL migration. Auth (`StubAuthRepository`) and V1 frontend modules (Students, Attendance, Fees, Home dashboards) use stubbed/dummy data behind Riverpod repositories/providers, then get swapped to real Supabase queries once the migration is run.

### SQL migration (PENDING)
Run the consolidated V1 migration in Supabase SQL Editor (tables, enums, helper
functions, RLS, profile trigger on auth.users, seed data).

---

## 6. Implementation Status & Next Steps

### Done (Frontend + Stubs)
1. `UserRole` enum + `Profile` model (matches `user_role` enum in DB).
2. `AuthRepository` (`StubAuthRepository` + `SupabaseAuthRepository`) & Riverpod providers (`authStateProvider`, `currentProfileProvider`, `loginControllerProvider`).
3. `go_router` (`routerProvider`) with role-based redirect guard: logged out -> `/login`, logged in -> role home, cross-role routes blocked.
4. Design system (`core/theme/`), reusable widgets (`core/widgets/`), and `ResponsiveScaffold` (bottom `NavigationBar` < 900px, `NavigationRail` >= 900px).
5. `LoginScreen` (with 6 quick-login role buttons in stub mode) + 6 role home dashboards.
6. Stubbed V1 frontend modules: Students (search, class filter, detail sheet, add student), Attendance (section roll-call), and Fees (dues list + fee collection sheet).

### Next
1. Run V1 SQL migration in Supabase SQL Editor.
2. Swap `StubAuthRepository` -> `SupabaseAuthRepository` in `features/auth/providers/auth_providers.dart`.
3. Wire Students, Attendance, Fees, and Notices repositories to Supabase.

## 7. Conventions
- State management: Riverpod. Navigation: go_router. No setState for app-level state.
- Feature-first folders; each feature has data/ (repositories), providers/, presentation/.
- Multi-table writes go through Postgres functions called with `rpc()`, not multiple client inserts.