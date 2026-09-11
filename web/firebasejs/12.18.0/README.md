# Firebase web SDK 12.18.0

These six JavaScript modules are unmodified distributions downloaded from
https://www.gstatic.com/firebasejs/12.18.0/ (2026-09-09).
License notices are retained in the files.

The import map in web/index.html resolves FlutterFire SDK imports and their
transitive imports to these same-origin copies, avoiding a blocking CDN request
at startup. Keep that map, this folder, and flutterfire_web_sdk_version in
web/flutter_bootstrap.js on the same version. Version 12.18.0 includes the Auth
fix for "Database is closing/hidden".

Modules: firebase-app.js, firebase-auth.js, firebase-analytics.js,
firebase-app-check.js, firebase-storage.js, firebase-firestore-pipelines.js.
Firebase service API calls still require an internet connection.
