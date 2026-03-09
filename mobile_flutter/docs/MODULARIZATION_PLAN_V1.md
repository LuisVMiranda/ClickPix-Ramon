# ClickPix Modularization Plan (v1)

Date: 2026-03-09
Scope files:
- `lib/main.dart`
- `lib/presentation/recent_photos_page.dart`
- `lib/presentation/manage_contacts_page.dart`

## 1) Goals
- Split by feature and responsibility, not by widget type only.
- Keep Android and iOS behavior identical while refactoring.
- Avoid regressions in Pix, combos, contacts, and gallery flow.
- Reduce rebuild cost and navigation side effects.

## 2) Target architecture
- `lib/app/`
  - `bootstrap/` (db init, settings init, schedulers)
  - `routing/` (named routes and route builders)
  - `theme/` (theme tokens, accent mapping, theme factory)
- `lib/features/quick_service/`
  - `presentation/` (page shell + small widgets)
  - `application/` (controllers/use-cases for order creation, pricing)
  - `domain/` (pricing models, payment selection)
- `lib/features/contacts/`
  - `presentation/` (contacts list, editor sheet/dialog)
  - `application/` (export xlsx, device contacts bridge)
- `lib/features/settings/`
  - `presentation/` (profile, pix integration, combos sections)
  - `application/` (settings orchestrators)
- `lib/shared/`
  - `widgets/` (generic cards, chips, form helpers)
  - `utils/` (formatters, safe navigation helpers)

## 3) File-by-file split plan

### A. `main.dart` (current monolith)
Move to:
- `lib/app/bootstrap/app_bootstrap.dart`
  - `_bootstrapDatabase`, app startup wiring.
- `lib/app/theme/app_theme_factory.dart`
  - `_buildTheme`, accent maps, family labels.
- `lib/features/dashboard/presentation/dashboard_page.dart`
- `lib/features/settings/presentation/app_configuration_page.dart`
- `lib/features/stats/presentation/statistics_page.dart`
- `lib/features/quick_service/presentation/quick_service_module_page.dart`

Performance notes:
- Keep top-level `MaterialApp` state minimal.
- Keep `ThemeData` creation memoized by settings key.
- Avoid passing heavy dependencies deep in widget trees; use small scoped providers.

### B. `recent_photos_page.dart`
Move to:
- `lib/features/quick_service/presentation/recent_photos_page.dart` (shell only)
- `lib/features/quick_service/application/recent_photos_controller.dart`
  - gallery loading, lazy paging, combo selection state, payment action state.
- `lib/features/quick_service/application/pix_checkout_service.dart`
  - pix payload + API create charge + status polling.
- `lib/features/quick_service/presentation/widgets/`
  - `payment_parameters_card.dart`
  - `photo_filters_bar.dart`
  - `photo_grid.dart`
  - `delivery_actions_sheet.dart`
  - `pix_payment_card.dart`
  - `client_selector_sheet.dart`

Performance notes:
- Keep image grid isolated with `ValueListenableBuilder` or controller streams.
- Keep polling lifecycle bound to bottom sheet only.
- Keep photo list immutable snapshots to avoid full-grid churn.

### C. `manage_contacts_page.dart`
Move to:
- `lib/features/contacts/presentation/manage_contacts_page.dart` (shell only)
- `lib/features/contacts/presentation/contact_editor_page.dart`
- `lib/features/contacts/application/contacts_export_service.dart`
  - xlsx generation + share payload.
- `lib/features/contacts/application/device_contacts_service.dart`
  - permission + insert on phone contacts.

Performance notes:
- Debounce expensive list refresh after create/update/delete bursts.
- Keep export in isolate if list size grows significantly (>5k rows).

## 4) Migration order (safe rollout)
1. Extract pure helpers first (theme/pix/formatters), no UI changes.
2. Extract services/controllers with same method signatures.
3. Replace internal page blocks by imported widgets section by section.
4. Switch routing to modular pages.
5. Delete dead code only after all tests/build checks pass.

## 5) Quality gates per step
- `flutter analyze --no-pub` with zero errors.
- `flutter build apk --debug --no-pub` success.
- iOS build sanity in Xcode (`Runner` debug build).
- Manual smoke tests:
  - Quick service with Pix local and Pix API mode.
  - Combo selection and total calculation.
  - Contact CRUD + export + save to device contacts.

## 6) Regression checklist (Android + iOS)
- Permissions:
  - Gallery/photo permission behavior.
  - Contacts permission behavior.
- Deep links/launchers:
  - WhatsApp, mailto, share sheet.
- Pix:
  - QR render, copy/paste payload, status refresh.
- Navigation:
  - No red screens when saving editors/sheets.

## 7) Estimated implementation slices
- Slice 1 (1-2 days): main.dart extraction + routing/theme split.
- Slice 2 (2-3 days): recent_photos_page split + controller/services.
- Slice 3 (1-2 days): manage_contacts_page split + export/device contacts services.
- Slice 4 (1 day): cleanup + docs + final QA matrix Android/iOS.

## 8) Done criteria
- Each module has focused files (<350 lines target, <500 hard max).
- No feature loss.
- No new runtime exceptions in save/create/edit flows.
- Android debug build and iOS debug build pass.
