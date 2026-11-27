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
* **Architectural Principle**: **Smart Backend, Dumb Client**. Business rules (ID generation, transactional multi-table writes, validation) and security constraints reside in PostgreSQL functions, triggers, and RLS policies rather than the Flutter client.
* **Tenancy Scope (Current)**: **Single-Institute**. Multi-institute (`institutes` / `institute_id`) was intentionally removed so V1 stays simple and focused on one school first.

---

## 2. Roles & Access Matrix

| Role | Primary User Interface | Responsibilities |
| :--- | :--- | :--- |
| **`super_admin`** | Web Dashboard | System configuration and admin oversight. |
| **`principal`** | Web & Mobile | Full academic management, classes & sections, students, teachers, approvals, notices. |
| **`fee_clerk`** | Web Dashboard | Fee structure setup, offline collection, receipts, dues tracking. |
| **`teacher`** | Mobile / Tablet | Section attendance, subject marks, student performance, homework. |
| **`parent`** | Mobile App | Tracking multi-child attendance, fee payments, receipts, notices. |
| **`student`** | Mobile / Web | Viewing personal attendance, report cards, fees, assignments. |

---

## 3. Database Architecture & Migrations

We build the database **incrementally** — tables and RPCs for each module are added only when that module is wired. All SQL migrations live in `supabase/migrations/` and **must be run in order**:

### Migration 1: `supabase/migrations/0001_v1_schema.sql`
Creates the foundational enum, core tables, RLS helper functions, and base RLS policies for **Auth, Classes/Subjects, and Students**:
* **Enum**: `user_role` (`'super_admin'`, `'principal'`, `'fee_clerk'`, `'teacher'`, `'student'`, `'parent'`)
* **Core Tables**:
  1. `academic_years`: Session tracker (`id`, `name`, `start_date`, `end_date`, `is_current`).
  2. `profiles`: Extends `auth.users` (`id -> auth.users.id`, `role`, `first_name`, `last_name`, `phone`, `avatar_url`, `is_active`).
  3. `classes` & `sections`: Academic hierarchy (`classes`: `name`, `display_order`; `sections`: `class_id`, `name`, `class_teacher_id`).
  4. `subjects` & `class_subject_teachers`: Subject definitions and teacher-to-section allocations per academic year.
  5. `students`, `student_enrollments`, `student_parents`: Core student records, yearly class/section enrollments, and parent/guardian links.

*(Attendance, Fees, and Notices tables are not in `0001` yet — they will be added in dedicated migrations when those modules are wired.)*

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

Two `SECURITY DEFINER` helper functions are defined in `0001_v1_schema.sql`:

* `public.get_my_role()`: Returns the logged-in user's `user_role` from `profiles`.
* `public.get_my_student_ids()`: Returns all `student_id`s linked to the logged-in parent via `student_parents`, plus the user's own student record if `students.profile_id = auth.uid()`. Use `student_id IN (SELECT public.get_my_student_ids())` in policies.

### Access Rules Summary
* **Super Admins & Principals**: Full read/write access to all tables (`profiles`, `classes`, `sections`, `subjects`, `students`, `teachers`, etc.).
* **Fee Clerks**: Full CRUD on student admissions (`students`, `guardians`, `student_parents`, `student_previous_schools`, `student_documents`); excluded from reading `student_medical_info` and `teacher_bank_details`.
* **Teachers**: Read-only access to students and their own teacher record.
* **Parents & Students**: Scoped read-only access strictly to records belonging to `get_my_student_ids()`.

---

## 5. Setup & Onboarding Guide (For New Developers)

### A. Flutter App Setup
1. **Environment file**: Create `.env` in the project root with your Supabase credentials (use the base project URL without `/rest/v1/`):
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
    classes/{data,presentation,providers}
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
3. **Create your first login user** (no seed/demo data required):
   - Create an Auth user in **Authentication → Users** (with Auto Confirm enabled) and copy their UID.
   - Insert their `profiles` row:
     ```sql
     INSERT INTO public.profiles (id, role, first_name, last_name)
     VALUES ('YOUR_USER_UID_HERE'::UUID, 'principal', 'Admin', 'User');
     ```
   - Log in as Principal and create Classes & Sections directly from the **Classes** tab in the app.

---

## 6. Implementation Status

### Completed Frontend & Architecture
1. `UserRole` enum + `Profile` model matching `user_role` DB enum.
2. `AuthRepository` (`StubAuthRepository` + `SupabaseAuthRepository`) and Riverpod auth providers (`authStateProvider`, `currentProfileProvider`, `loginControllerProvider`).
3. `go_router` (`routerProvider`) with role-based redirect guards (logged out → `/login`, logged in → role home, cross-role routes blocked).
4. Design system (`core/theme/`), shared widgets (`core/widgets/`), and `ResponsiveScaffold` (bottom `NavigationBar` < 900px, `NavigationRail` ≥ 900px).
5. `LoginScreen` (email/password + 5 quick-login role buttons for `Principal`, `Fee Clerk`, `Teacher`, `Student`, `Parent` signing in via `<role>@school.edu` / `password123`) + 6 role home screens.
6. V1 feature UIs: **Classes & Sections** (add class with common-name quick-fill, multi-select sections + custom section `+` button, add/delete sections inside each class), **Students** (directory, detail/edit, multi-step admission), **Teachers** (directory, 7-step form, detail/edit, activate/deactivate), **Attendance** (section roll-call), **Fees** (dues & collection), **Admissions**.

### Backend Wiring Status
* **Live on Supabase**:
  * **Auth** (`lib/features/auth/providers/auth_providers.dart` → `SupabaseAuthRepository`)
  * **Classes & Sections** (`lib/features/classes/providers/classes_providers.dart` → `SupabaseClassesRepository`)
  * **Students** (`lib/features/students/providers/students_providers.dart` → `SupabaseStudentsRepository`)
  * **Teachers** (`lib/features/teachers/providers/teachers_providers.dart` → `SupabaseTeachersRepository`)
* **Still using Stub / Dummy Data**:
  * **Attendance** (`features/attendance/`)
  * **Fees** (`features/fees/`)
  * **Admissions** (`features/admissions/`)
  * **Home Dashboard Stats** (`features/home/`)
  * **Notices**

### Next Steps
1. Wire **Attendance** (add `student_attendance` migration + RPCs, then wire `SupabaseAttendanceRepository`).
2. Wire **Fees** (add fee tables + payment RPC, then wire `SupabaseFeesRepository`).
3. Wire **Admissions**, **Home**, and **Notices** to Supabase.
4. Add `update_student_admission` and `update_teacher` RPCs in SQL migrations to match the edit flows in `SupabaseStudentsRepository` and `SupabaseTeachersRepository`.

---

## 7. Conventions
* **State management**: Riverpod (`Notifier`, `AsyncNotifier`, `Provider`). No `setState` for app-level state.
* **Navigation**: `go_router`.
* **Structure**: Feature-first folders (`data/`, `providers/`, `presentation/`).
* **Database writes**: Multi-table writes go through PostgreSQL functions called via `.rpc()`, not multiple sequential client inserts.
