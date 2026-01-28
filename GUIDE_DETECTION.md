# Guide d'amélioration de la détection des impacts

## Comment utiliser la correction manuelle

L'application permet de corriger facilement les erreurs de détection :

### Sur l'écran d'analyse :
1. **Ajouter un impact manquant** : Tapez sur la photo où se trouve l'impact
2. **Supprimer un faux positif** : Tapez sur le cercle rouge à supprimer

Les impacts ajoutés manuellement sont sauvegardés et inclus dans les statistiques.

## Paramètres de détection actuels

### Taille des impacts
- **Minimum** : 30 pixels (environ 6x6 pixels)
- **Maximum** : 800 pixels (environ 28x28 pixels)
- Un trou de balle fait généralement 5-15mm, soit 50-150 pixels selon la résolution

### Forme des impacts
- **Circularité minimale** : 0.55 (1.0 = cercle parfait)
- **Ratio largeur/hauteur** : < 2.5 (rejette les lignes et formes allongées)
- **Rayon** : entre 3 et 20 pixels

### Seuils de luminance
- **Trous sombres** : luminance < 60 (sur 255)
- **Trous clairs** : luminance > 195 (sur 255)

## Si la détection reste imparfaite

### Option 1 : Correction manuelle (recommandé)
- C'est rapide et intuitif
- Les corrections sont sauvegardées avec la session
- Parfait pour 5-20 corrections par photo

### Option 2 : Ajuster les paramètres (développeur)
Modifiez les constantes dans `lib/services/impact_detector.dart` :

```dart
// Ligne 236-237 : Taille des impacts
const minSize = 30;   // Augmenter pour ignorer les petits artefacts
const maxSize = 800;  // Réduire si de grosses zones sont détectées

// Ligne 246 : Rayon
if (avgRadius < 3 || avgRadius > 20) return false;

// Ligne 250 : Circularité
final circularityThreshold = 0.55;  // Augmenter (max 1.0) pour être plus strict

// Ligne 268 : Aspect ratio
if (aspectRatio > 2.5) return false;  // Réduire pour rejeter plus de formes

// Ligne 114 : Seuil trous sombres
final threshold = 60;  // Réduire pour détecter moins de zones grises

// Ligne 154 : Seuil trous clairs
final threshold = 195;  // Augmenter pour détecter moins de zones grises
```

### Option 3 : Machine Learning (avancé, futur)
Pour une détection vraiment optimale, il faudrait :
1. Collecter des centaines de photos annotées (marquer les vrais impacts)
2. Entraîner un modèle TensorFlow Lite
3. Intégrer le modèle dans l'application

Cette option nécessite beaucoup de données et du temps de développement.

## Conseils pour de meilleures photos

Pour améliorer la détection automatique :
1. **Éclairage uniforme** : Éviter les ombres et reflets
2. **Contraste élevé** : Cible bien nette, impacts bien visibles
3. **Photo perpendiculaire** : Éviter les angles qui déforment
4. **Bonne résolution** : Minimum 1920x1080 pixels
5. **Cible propre** : Éviter les taches et déchirures
6. **Focus net** : Pas de flou

## Limitations actuelles

L'algorithme actuel est basé sur :
- Détection de pixels sombres/clairs (pas de ML)
- Analyse de forme (circularité, taille)
- Seuils fixes (pas d'adaptation automatique)

Il peut confondre :
- Les lignes noires de la cible avec des impacts
- Les taches et imperfections du papier
- Les ombres et reflets

**Solution recommandée** : Utiliser la correction manuelle pour corriger rapidement les erreurs (c'est l'approche la plus pratique).
