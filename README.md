# EduSync Student Records

Flutter student-record management app for Android, using Firebase Authentication
and Cloud Firestore.

## Features

- Register and sign in with email and password, reset a forgotten password, or
  sign in with Google.
- View a dashboard with the signed-in account and student count.
- Create, list, search, edit, and delete student records.
- Reject duplicate student numbers within each account, including concurrent
  saves from multiple devices.
- Keep each account's records in `users/{uid}/students`.
- Change an email/password account's password or sign out.

Student records contain student number, full name, course, year level, email,
and server-managed creation/update timestamps.

## Firebase setup

The Android app uses `android/app/google-services.json` and the Google Services
Gradle plugin. Before running it:

1. In Firebase Authentication, enable Email/Password and Google providers.
2. In Firebase Console, add the app's Android SHA-1/SHA-256 signing
   fingerprints to its Android app settings. The Android package name is
   `com.example.edusync_pre_finals`.
3. After enabling Google, download the updated `google-services.json` and
   replace `android/app/google-services.json`. It must contain a web OAuth
   client entry for the Google Sign-In plugin.
4. Create a Cloud Firestore database and publish the current rules in
   `firestore.rules`. Re-publish the rules whenever they change; the app uses
   a protected student-number index to prevent duplicate IDs.

Run `flutter pub get` and then `flutter run` from the project directory.
