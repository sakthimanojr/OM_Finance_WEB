# Finance App — Frontend (Flutter)

A single Flutter codebase serving both **Admin** (Super Admin / View Admin) and
**Customer** roles, with role-based routing after login.

## Quick start

This folder contains the Dart source (`lib/`), `pubspec.yaml`, and tests —
but **not** the native `android/`, `ios/`, `web/`, etc. platform folders,
since those are large, auto-generated, and machine-specific. Generate them
once with the Flutter SDK:

```bash
cd frontend
flutter create --org com.financeapp --project-name finance_app .
```

This scaffolds `android/`, `ios/`, `web/`, etc. **without overwriting**
`lib/`, `pubspec.yaml`, or `test/` (Flutter only fills in missing platform
folders when run inside an existing project directory — but as a safety net,
commit your work or copy this folder first if you're unsure).

Then install dependencies and run:

```bash
flutter pub get
flutter run
```

## Connecting to the backend

Edit `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:4000/api/v1';
```

- `10.0.2.2` is the Android emulator's alias for your host machine's
  `localhost` — use this if the backend is running locally and you're
  testing on an Android emulator.
- On a real device, use your computer's LAN IP (e.g. `http://192.168.1.5:4000/api/v1`)
  and make sure your phone is on the same network.
- On iOS simulator, `http://localhost:4000/api/v1` works directly.
- For a deployed backend, use its public HTTPS URL.

## Project structure

```
lib/
  core/
    constants/    API endpoints, app-wide constants
    network/      Dio client (auto token refresh), secure token storage
    router/        go_router config with auth-based redirects
    theme/         Material 3 theme
    utils/         formatters
    widgets/       shared loading/error/empty state widgets, status badge
  models/          plain Dart model classes (User, Customer, Loan, Due, Payment, ...)
  services/        API service classes (one per backend module)
  providers/       Riverpod state — auth session, dashboard, customers, loans, dues
  screens/
    auth/          login, OTP login, forgot password
    admin/         dashboard, customer list/detail/create, loan create/detail, dues, reports
    customer/      dashboard, loan list/detail, UPI payment screen, profile
  main.dart
test/
  widget_test.dart
```

## Notes on what's stubbed vs. fully wired

- **Login (password + OTP), customer & loan CRUD, due schedules, UPI payment
  (Razorpay Checkout when the backend has it configured, static QR fallback
  otherwise), receipts, reports download, dashboards, KYC document
  upload/delete, and the customer's own profile (`/customers/me`)** are all
  fully wired to the real backend endpoints.
- **Razorpay Checkout requires one native setup step per platform** —
  `razorpay_flutter` needs Android's `minSdkVersion` at 19+ (default in
  recent Flutter templates) and, on iOS, no extra config beyond what
  `flutter create` already scaffolds. If the backend has no Razorpay keys
  configured, the app automatically falls back to the static UPI QR flow, so
  this only matters if you turn Razorpay on.
- **Push notifications (FCM)** are intentionally left out of this scaffold —
  wiring them up requires a Firebase project and platform config files
  (`google-services.json` / `GoogleService-Info.plist`) that only you can
  generate from your own Firebase console. Add `firebase_core` +
  `firebase_messaging` back to `pubspec.yaml` once you have those files.

## Running tests

```bash
flutter test
```
