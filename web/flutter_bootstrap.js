{{flutter_js}}
{{flutter_build_config}}

// Firebase Auth 12.18.0 fixes IndexedDB errors when a browser tab is hidden.
// Keep this ahead of loader.load so every FlutterFire service uses the same SDK.
// https://firebase.google.com/support/release-notes/js#version_12180_-_august_19_2026
window.flutterfire_web_sdk_version = '12.18.0';

const startDigiwearit = () => {
  _flutter.loader.load({
    config: {
      canvasKitBaseUrl: 'canvaskit/',
    },
  });
};

(async () => {
  try {
    const cleanup = async () => {
      if (
        'serviceWorker' in navigator &&
        typeof navigator.serviceWorker.getRegistrations === 'function'
      ) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        await Promise.all(
          registrations.map((registration) => registration.unregister()),
        );
      }
      if ('caches' in window && typeof caches.keys === 'function') {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map((name) => caches.delete(name)));
      }
    };

    await Promise.race([
      cleanup(),
      new Promise((resolve) => setTimeout(resolve, 1500)),
    ]);
  } catch (_) {
    // Cache APIs can be unavailable in private or restricted browser modes.
  } finally {
    startDigiwearit();
  }
})();