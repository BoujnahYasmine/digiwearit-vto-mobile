# Digiwearit — essayage virtuel (application mobile)

Application Flutter d'essayage virtuel de tenues par intelligence artificielle,
pour Android, iOS et le web.

- **Parcours simple** : le client choisit une tenue, se prend en photo avec la
  lumière « Éclat » et un maquillage léger automatique, paie l'essayage
  (Google Play / App Store, ou paiement de démonstration sur le web) puis
  reçoit son résultat par e-mail.
- **Parcours miroir** : en boutique, un miroir ou une tablette activé avec un
  code de l'entreprise propose les catalogues de cette entreprise, sans
  paiement, dans la limite de ses crédits.

Le site d'administration (super administrateur et espace entreprise) et les
fonctions serveur Firebase sont dans un projet séparé.

## Démarrer

```bash
flutter pub get
flutter run                                   # téléphone ou émulateur
flutter run -d web-server --web-port 8095     # web : http://localhost:8095
flutter test
```

- **iPhone avec un MacBook** : voir [IOS_SETUP.md](IOS_SETUP.md).
- Options : `--dart-define=DEMO_PAYMENT=true` (paiement de démonstration),
  `--dart-define=USE_FIREBASE_EMULATOR=true` (émulateurs Firebase locaux).
- La musique d'ambiance (`assets/music/background.mp3`) n'est pas publiée ;
  sans elle, l'application fonctionne en silence.

## Organisation

| Dossier | Contenu |
|---|---|
| `lib/` | Parcours simple, caméra, filtres, paiement, résultat |
| `lib/mirror/` | Parcours miroir (activation, catalogues, génération serveur) |
| `web/` | Page web, SDK Firebase local, lissage du visage MediaPipe |
| `android/`, `ios/` | Projets natifs (identifiant `com.digiwearit.app`) |
| `test/` | Tests automatisés |

Les règles Firestore et Storage sont gérées par le projet d'administration ;
`firebase deploy` depuis ce dossier ne publie que la version web.

## Configuration Firebase

Les fichiers `google-services.json`, `GoogleService-Info.plist` et
`lib/firebase_options.dart` contiennent les clés client Firebase du projet
`vto-with-nano`. Ces clés identifient l'application et sont destinées à être
embarquées dans l'application publiée ; la sécurité des données repose sur les
règles Firestore et Storage et sur les fonctions serveur.
