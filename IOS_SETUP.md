# Installer Digiwearit sur iPhone avec un MacBook

Application Flutter, identifiant iOS `com.digiwearit.app`, projet Firebase
`vto-with-nano`, iOS 15.5 minimum. La configuration Firebase iOS
(`ios/Runner/GoogleService-Info.plist`) et les autorisations caméra et photos
sont déjà incluses.

> Ces étapes n'ont pas pu être exécutées depuis le poste Windows de
> développement : la compilation iOS se vérifie uniquement sur Mac.

## 1. Préparer le Mac (une seule fois)

1. Installer **Xcode** depuis l'App Store (version 16.2 ou plus récente),
   l'ouvrir une fois et accepter la licence.
2. Dans le Terminal :
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   xcode-select --install          # outils en ligne de commande, si demandé
   ```
3. Installer **Homebrew** (https://brew.sh), puis **CocoaPods** :
   ```bash
   brew install cocoapods
   ```
4. Installer **Flutter 3.41** (https://docs.flutter.dev/get-started/install/macos),
   puis vérifier :
   ```bash
   flutter doctor -v
   ```
   Corriger ce que `flutter doctor` signale pour Xcode et CocoaPods.

## 2. Récupérer le projet

```bash
git clone https://github.com/BoujnahYasmine/digiwearit-vto-mobile.git
cd digiwearit-vto-mobile
flutter pub get
cd ios && pod install && cd ..
```

La première installation des pods prend plusieurs minutes.

**Musique (facultatif).** Le fichier `assets/music/background.mp3` n'est pas
publié sur GitHub (licence de la musique). Copiez votre fichier à cet
emplacement pour avoir la musique ; sans lui, l'application fonctionne en
silence.

## 3. Installer sur un iPhone (recommandé)

La caméra, le filtre « Éclat » et la détection du visage se testent sur un
vrai iPhone.

1. Brancher l'iPhone au Mac avec un câble et accepter « Faire confiance à cet
   ordinateur » sur le téléphone.
2. Sur l'iPhone (iOS 16 ou plus) : **Réglages > Confidentialité et sécurité >
   Mode développeur** → activer, puis redémarrer le téléphone.
3. Ouvrir le projet dans Xcode :
   ```bash
   open ios/Runner.xcworkspace
   ```
   (ouvrir le fichier `.xcworkspace`, pas `.xcodeproj`).
4. Dans Xcode : cibler **Runner** > onglet **Signing & Capabilities** :
   - cocher **Automatically manage signing** ;
   - **Team** : choisir votre compte Apple (Xcode > Settings > Accounts pour
     l'ajouter ; un identifiant Apple gratuit suffit pour tester).
   - Si Xcode indique que l'identifiant `com.digiwearit.app` n'est pas
     disponible pour votre équipe, le remplacer temporairement par un
     identifiant unique, par exemple `com.votrenom.digiwearit`.
5. Lancer sur le téléphone depuis le Terminal :
   ```bash
   flutter devices                          # repérer l'iPhone
   flutter run --release --dart-define=DEMO_PAYMENT=true -d <id-de-l-iphone>
   ```
   `DEMO_PAYMENT=true` utilise le paiement de démonstration : le paiement
   réel par l'App Store demande un compte développeur payant et un produit
   configuré dans App Store Connect (voir section 5).
6. Au premier lancement, si l'iPhone refuse d'ouvrir l'application :
   **Réglages > Général > VPN et gestion de l'appareil** → faire confiance à
   votre profil développeur.

Avec un identifiant Apple gratuit, l'application installée expire au bout de
7 jours : il suffit de relancer `flutter run` pour la réinstaller.

## 4. Simulateur (sans iPhone)

```bash
bash scripts/run_ios_simulator.sh
```

Le simulateur n'a pas de caméra : utiliser **Galerie** avec une photo JPG ou
PNG glissée sur la fenêtre du simulateur. Sur un Mac à puce Apple, la
bibliothèque de détection du visage (Google ML Kit) peut refuser de se
compiler pour le simulateur ; dans ce cas, utiliser un vrai iPhone.

## 5. Publier (TestFlight ou App Store)

1. Adhérer à l'**Apple Developer Program** (99 USD par an).
2. Dans **App Store Connect**, créer l'application avec l'identifiant
   `com.digiwearit.app`, accepter l'accord des applications payantes, puis
   créer l'achat intégré **consommable** `digiwearit_tryon_unlock`
   (un essayage).
3. Dans Xcode, onglet **Signing & Capabilities**, ajouter la capacité
   **In-App Purchase**.
4. Construire et envoyer :
   ```bash
   flutter build ipa --release
   ```
   puis ouvrir le fichier produit dans `build/ios/archive/` avec Xcode
   (**Window > Organizer > Distribute App**) ou l'application **Transporter**.
5. Tester avec **TestFlight** avant la publication sur l'App Store.

## Vérifications sur l'iPhone

- Accueil → Commencer l'essayage → univers → style → catégorie.
- Autoriser la caméra ; vérifier le compte à rebours, la lumière « Éclat » et
  les conseils de lumière.
- Génération : une génération appelle le vrai service d'IA et peut être
  facturée sur le projet Firebase.
- Espace partenaire : activer avec un code créé dans l'espace entreprise du
  site d'administration.

Une autorisation caméra refusée se rétablit dans **Réglages >
Confidentialité et sécurité > Caméra**.
