{{flutter_js}}
{{flutter_build_config}}

if (
  'serviceWorker' in navigator &&
  typeof navigator.serviceWorker.getRegistrations === 'function'
) {
  navigator.serviceWorker
    .getRegistrations()
    .then((registrations) => {
      for (const registration of registrations) {
        registration.unregister();
      }
    })
    .catch(() => {});
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});