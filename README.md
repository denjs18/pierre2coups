# Pierre2coups

Application Android pour analyser vos sessions de tir à la cible.

## Fonctionnalités

- Capture ou import de photos de cibles
- Détection automatique des impacts de balles
- Correction manuelle des impacts (ajout/suppression)
- Calculs statistiques : écart-type, rayon moyen, diamètre du groupement
- Sauvegarde de toutes les sessions d'entraînement
- Historique complet avec visualisation des performances

## Installation de Flutter

Pour compiler cette application, vous devez d'abord installer Flutter sur votre système.

### Windows

1. Téléchargez Flutter SDK depuis : https://docs.flutter.dev/get-started/install/windows
2. Extrayez le fichier ZIP dans un dossier (par exemple `C:\src\flutter`)
3. Ajoutez Flutter au PATH :
   - Ouvrez "Variables d'environnement système"
   - Dans "Variables système", trouvez "Path" et cliquez sur "Modifier"
   - Ajoutez le chemin `C:\src\flutter\bin`
4. Installez Android Studio : https://developer.android.com/studio
5. Ouvrez Android Studio et installez :
   - Android SDK
   - Android SDK Command-line Tools
   - Android SDK Build-Tools
   - Android SDK Platform-Tools

6. Vérifiez l'installation :
```bash
flutter doctor
```

### Configuration supplémentaire

1. Acceptez les licences Android :
```bash
flutter doctor --android-licenses
```

2. Créez un fichier `local.properties` dans le dossier `android/` :
```properties
sdk.dir=C:\\Users\\VotreNom\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\src\\flutter
```
(Remplacez les chemins par vos chemins réels)

## Compilation de l'application

### 1. Installation des dépendances

Ouvrez un terminal dans le dossier du projet et exécutez :

```bash
flutter pub get
```

Cette commande télécharge toutes les bibliothèques nécessaires.

### 2. Test en mode développement (optionnel)

Si vous avez un téléphone Android connecté en USB avec le débogage USB activé :

```bash
flutter run
```

### 3. Génération de l'APK

Pour créer un fichier APK installable :

```bash
flutter build apk --release
```

L'APK sera généré dans : `build\app\outputs\flutter-apk\app-release.apk`

### 4. Installation sur votre téléphone

1. Copiez le fichier `app-release.apk` sur votre téléphone
2. Sur votre téléphone, allez dans Paramètres > Sécurité
3. Activez "Sources inconnues" ou "Installer des applications inconnues"
4. Ouvrez le fichier APK et installez l'application

## Utilisation de l'application

### Nouvelle session

1. Appuyez sur "Nouvelle Session"
2. Prenez une photo de votre cible ou importez-en une
3. L'application détecte automatiquement les impacts
4. Corrigez manuellement si nécessaire :
   - Tap sur la photo pour ajouter un impact
   - Tap sur un impact existant pour le supprimer
5. Remplissez les informations (arme, distance, notes)
6. Appuyez sur "Calculer et sauvegarder"

### Consulter l'historique

- Sur l'écran d'accueil, consultez les sessions récentes
- Appuyez sur "Voir tout" pour voir l'historique complet
- Appuyez sur une session pour voir les détails et statistiques

## Architecture du projet

```
pierre2coups/
├── lib/
│   ├── main.dart                          # Point d'entrée
│   ├── models/                            # Modèles de données
│   │   ├── session.dart
│   │   ├── impact.dart
│   │   └── target.dart
│   ├── database/
│   │   └── database_helper.dart           # Gestion SQLite
│   ├── services/
│   │   ├── impact_detector.dart           # Détection d'impacts
│   │   └── statistics_calculator.dart     # Calculs statistiques
│   ├── screens/                           # Écrans de l'application
│   │   ├── home_screen.dart
│   │   ├── capture_screen.dart
│   │   ├── analysis_screen.dart
│   │   ├── results_screen.dart
│   │   └── history_screen.dart
│   └── widgets/                           # Widgets réutilisables
│       ├── impact_overlay.dart
│       ├── stats_card.dart
│       └── session_list_item.dart
├── android/                               # Configuration Android
└── pubspec.yaml                           # Dépendances Flutter
```

## Technologies utilisées

- **Flutter** : Framework de développement
- **Dart** : Langage de programmation
- **SQLite** : Base de données locale (sqflite)
- **Image Processing** : Package `image` pour la détection
- **Camera** : Accès à la caméra (camera + image_picker)

## Détection des impacts

L'algorithme de détection fonctionne en 3 étapes :

1. **Prétraitement** : Conversion en niveaux de gris et amélioration du contraste
2. **Détection adaptative** :
   - Détection des trous sombres (sur fond blanc)
   - Détection des trous clairs (sur fond noir)
   - Fusion des résultats et élimination des doublons
3. **Calibration** : Détection de la cible pour calculer l'échelle

## Calculs statistiques

- **Centre du groupement** : Moyenne des positions (x, y) des impacts
- **Rayon moyen** : Distance moyenne de chaque impact au centre
- **Écart-type** : Mesure de la dispersion des impacts
- **Diamètre du groupement** : 2 × écart-type

## Améliorations futures

- Graphiques d'évolution des performances
- Export PDF des sessions
- Support de plusieurs types de cibles
- Détection de la zone de score (10, 9, 8...)
- Statistiques avancées (groupement horizontal vs vertical)

## Dépannage

### Flutter n'est pas reconnu
- Vérifiez que Flutter est bien ajouté au PATH
- Redémarrez votre terminal/invite de commande

### Erreur lors de flutter pub get
- Vérifiez votre connexion internet
- Essayez : `flutter pub cache repair`

### Erreur lors de la compilation Android
- Vérifiez que Android SDK est installé
- Vérifiez le fichier `android/local.properties`
- Essayez : `flutter clean` puis `flutter pub get`

### L'APK ne s'installe pas
- Vérifiez que "Sources inconnues" est activé
- Vérifiez que l'APK n'est pas corrompu (retéléchargez-le)

## Support

Pour toute question ou problème, consultez la documentation Flutter : https://docs.flutter.dev/

## Licence

Projet personnel - Utilisation libre
