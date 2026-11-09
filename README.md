# Finora Expense Tracker

Finora is a Flutter expense tracker for recording and reviewing personal spending. It supports mobile and desktop layouts and uses Firebase Authentication and Cloud Firestore to keep each signed-in user's expenses separate.

## Features

- Create an account, sign in, and sign out with email and password.
- Add, edit, view, and delete expenses; deleted expenses can be restored with Undo.
- Organize expenses by category and date.
- Review monthly totals and category breakdowns in the dashboard and analytics views.
- Search and filter transactions, and sort by date or amount.
- Migrate previously saved local expenses to Firestore on first sign-in.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- A Firebase project configured for the platforms you want to run
- Android Studio/Xcode or another platform toolchain as required by your target

## Getting started

1. Clone the repository and enter the project directory:

   ```sh
   git clone https://github.com/maaz266/expense_tracker.git
   cd expense_tracker
   ```

2. Install dependencies:

   ```sh
   flutter pub get
   ```

3. Configure Firebase:
   - In Firebase Console, enable **Authentication → Email/Password** and create a **Cloud Firestore** database.
   - Configure the Flutter app for your Firebase project with the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

     ```sh
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

   - For Android, make sure the matching `google-services.json` is available at `android/app/google-services.json`.
   - Review and deploy Firestore security rules for your app. Expenses are stored at `users/{userId}/expenses/{expenseId}`. A rule should require an authenticated user whose UID matches `{userId}`; do not allow public access to user expense data.

   The checked-in Firebase options are generated client configuration, not administrative credentials. Use your own Firebase project configuration when setting up a fork or a different deployment.

4. Run the application:

   ```sh
   flutter run
   ```

Linux is not configured in the checked-in Firebase options yet. Re-run `flutterfire configure` after registering a Linux app if you want to target Linux.

## Checks

Run the analyzer and tests before submitting changes:

```sh
flutter analyze
flutter test
```

## Project layout

- `lib/dashboard.dart` — dashboard, transactions, and analytics UI
- `lib/main.dart` — app setup, authentication, and expense flows
- `lib/models/expense.dart` — expense model
- `lib/firestore_storage.dart` — Firestore persistence
- `lib/expense_storage.dart` — local storage used for migration
- `test/` — model and widget tests

## Firebase security

Firebase client configuration is not a substitute for access control. Configure Firestore rules so a user can only access documents beneath their own UID, and never deploy permissive test rules to production.
