# JKD App - Notes Jeet Kune Do

Une application Flutter complète pour gérer les séries d'entraînement, techniques et combinaisons de Jeet Kune Do.

## Fonctionnalités

### Fonctionnalités principales
- **Gestion des séries** : Créez et organisez des séries d'entraînement pour Jun Fan Gung Fu, Jun Fan Kick Boxing, **Kali** et **JKD Moves** (déplacements).
- **Glossaire des mouvements** : Base de données étendue de coups de poing, de jambe, de packs, de trapping, d'angles Kali et de mouvements spécialisés JKD.
- **Créateur de combos** : Interface visuelle pour construire des combinaisons complexes avec prise en charge de la **sous-numérotation** (ex. : 1a, 1b, 1c), ainsi que les modes réponse, simultané et chaîne.
- **Mode entraînement** : Entraînement guidé par synthèse vocale (TTS) avec intervalles configurables et bouclage.
- **Programmes d'entraînement** : Régimes d'entraînement structurés sur plusieurs jours avec suivi de progression, attributions quotidiennes, statistiques de complétion et vue d'ensemble des entraînements actifs.
- **Échauffement guidé** : Sessions d'échauffement avec durées travail/repos configurables, guidage vocal TTS et fréquence cardiaque en direct depuis la montre.
- **Multilingue** : Prise en charge complète de l'anglais et du français.

### Fonctionnalités avancées
- **Support des montres connectées** : Applications compagnon dédiées pour montres **Wear OS** et **Garmin**.
- **Personnalisation du thème** : Choisissez votre propre **couleur de thème** dans une large palette (bleu, rouge, vert, etc.).
- **UI adaptative** : Les éléments d'interface ajustent automatiquement leurs couleurs pour une lisibilité maximale en modes Clair, Sombre et AMOLED.
- **Coups de riposte** : Ajoutez des réponses défensives aux attaques avec navigation automatique entre onglets pendant l'édition.
- **Angles Kali personnalisés** : Dessinez et réutilisez vos propres angles Kali dans le créateur de combos.
- **Saisie vocale** : Reconnaissance vocale pour saisir les noms de mouvements et les instructions.
- **Galerie média** : Attachez des photos explicatives aux techniques avec compression automatique et navigation par glissement.
- **Journalisation intégrée** : Système de journalisation multi-niveaux (INFO, WARN, ERROR) avec visionneuse intégrée et export/partage pour un dépannage facilité.
- **Export PDF** : Générez des fiches d'entraînement imprimables.
- **Sauvegarde & restauration** : Prise en charge complète des sauvegardes (ZIP) des séries, du glossaire et des médias.
- **Bibliothèque cloud** : Partagez et téléchargez des séries d'entraînement communautaires via le service web intégré.

## Stockage cloud web

Le projet inclut un backend web PHP complet et une interface située dans le répertoire `/web` :
- **Dépôt central** : Une bibliothèque cloud pour découvrir et partager des séries d'entraînement JKD.
- **Interface web** : Parcourez, recherchez et prévisualisez le contenu des séries dans n'importe quel navigateur web.
- **API REST** : Intégration transparente avec l'application mobile pour des téléversements et téléchargements automatisés.
- **Outils d'administration** : Outils intégrés de modération et de gestion de contenu.
- **Journalisation & débogage** : Journalisation centralisée de toutes les requêtes API, téléversements et actions administratives dans `web/logs/app.log`.

## Extensions montres connectées

### Application Wear OS
Une application compagnon entièrement native conçue pour l'entraînement mains libres sur des montres comme la Samsung Galaxy Watch 6 ou la Pixel Watch :
- **Disposition en bulles** : Chaque étape d'action est affichée dans sa propre bulle clairement définie et codée par couleur.
- **Mise en forme intelligente** : Convertit automatiquement les chaînes complexes (ex. : « L Jab -> R Cross ») en un flux vertical facile à lire.
- **Avance automatique** : Minuteur configurable (2s à 30s) permettant de s'entraîner sans toucher à la montre.
- **Compte à rebours visuel** : Un dégradé de bordure circulaire (rouge -> jaune -> vert) fournit une indication de progression en temps réel.
- **Mode double colonne** : Bascule automatiquement entre 1 et 2 colonnes selon la longueur des mouvements pour maximiser l'écran d'affichage.
- **Défilement automatique** : Fait défiler en boucle les longues descriptions vers le haut et le bas pour ne rien manquer.

### Garmin ConnectIQ
S'intègre aux montres Garmin (Fenix, Forerunner, etc.) via le SDK Garmin :
- **Synchronisation à distance** : Synchronise la série d'entraînement en cours et la progression vers l'écran de la montre.
- **Retour audio** : Fonctionne en tandem avec le moteur TTS du téléphone pour une expérience de coaching unifiée.

## Structure du projet

```
.
├── garmin_app/          # Code source Garmin ConnectIQ (Monkey C)
├── wear_os_app/         # Application Wear OS Flutter native
├── web/                 # Backend PHP et interface web pour le stockage cloud
├── lib/                 # Source principale de l'application mobile/bureau
│   ├── models/          # Modèles de données (Move, JkdSeries)
│   ├── services/        # Logique métier (DB, synchro Garmin, hachage)
│   ├── screens/         # Écrans UI et sous-dossiers spécifiques aux plateformes
│   └── ...
```

## Entraînement aux déplacements JKD (Lecteur aléatoire)

Le **Lecteur aléatoire** est un outil spécialisé situé dans l'onglet « JKD Moves ». Il est conçu pour les exercices de déplacements réactifs :
1. **Séquence** : Il annonce le nom de la série (en anglais) une fois, attend 1s, puis appelle les numéros de mouvements (1-6) dans la langue sélectionnée.
2. **Configuration** :
   - **Sélection de série** : Choisissez des schémas de déplacements spécifiques (Step and Slide, Pendulum, etc.).
   - **Garde** : Basculez entre garde gauche et garde droite.
   - **Délai** : Temporisation ajustable de 0,4s à 2,5s pour un entraînement de vitesse progressif.
3. **Visuel** : Un affichage proéminent montre le mouvement actuel en grand pour référence rapide.

## Système de sous-numérotation (hiérarchie)

Vous pouvez maintenant regrouper les variations d'un mouvement à l'aide de lettres (a, b, c...) :
- **Regroupement visuel** : Les sous-éléments sont automatiquement indentés vers la droite.
- **Numérotation propre** : Le numéro principal de la séquence est affiché une seule fois en haut du groupe, avec de grandes lettres jaunes indiquant la sous-variation.
- **Entraînement rythmique** : Le mode entraînement et le lecteur aléatoire respectent cette hiérarchie pour un flux plus naturel.

## Personnalisation & affichage

- **Couleur de thème** : Changez la couleur d'accent principale de l'application dans les paramètres.
- **Support AMOLED** : Mode « Noir profond » optimisé pour les écrans OLED.
- **Onglets adaptatifs** : Les titres d'onglets basculent dynamiquement entre le blanc (Sombre/AMOLED) et la couleur principale (Clair) pour un contraste parfait.
- **Chargement visuel** : Le logo JKD de la barre supérieure tourne pendant l'initialisation ou le chargement de la base de données.

## Support des plateformes

| Plateforme | Statut | Notes |
|----------|--------|-------|
| Android  | ✅ Complet | Plateforme mobile principale |
| Wear OS  | ✅ Complet | Application native pour Watch 4/5/6/7, Pixel Watch, etc. |
| Garmin   | ✅ Complet | Extension ConnectIQ pour plus de 80 appareils Garmin |
| Windows  | ✅ Complet | Plateforme bureau entièrement supportée |
| MacOS    | ✅ Complet | Plateforme bureau entièrement supportée |
| Linux    | ⚠️ Partiel | Reconnaissance vocale désactivée, TTS via `spd-say` |
| iOS      | ⚠️ Limité | Supporté par le code mais non officiellement compilé |

## Lignes directrices de développement

Pour maintenir la qualité et la lisibilité du code, les principes d'organisation suivants sont encouragés :
- **Taille des fichiers** : Les fichiers Dart individuels doivent rester sous **1 000 lignes** (voir `AGENTS.md` pour les règles complètes d'organisation du code).
- **Séparation des responsabilités** : Le code UI doit résider dans `screens/`, tandis que la logique réutilisable doit être extraite dans `services/` ou des `mixins/` spécifiques aux classes.
- **Modularité** : Les grands écrans doivent être découpés en widgets plus petits et ciblés situés dans des sous-dossiers (ex. : `lib/screens/series_detail/widgets/`).

## Mises à jour récentes (v2.6.1+1)

- **Bibliothèque cloud bêta** : Téléversez et partagez vos séries personnalisées avec la communauté.
- **Vue web améliorée** : Interface entièrement responsive et optimisée mobile pour parcourir la bibliothèque et télécharger les binaires.
- **Journalisation multi-niveaux** : Système de journalisation complet pour l'application Flutter et le backend PHP afin de simplifier le dépannage.
- **Support Garmin étendu** : Scripts de compilation dynamiques prenant en charge toute la gamme moderne Garmin (Fenix 8, Forerunner 965, etc.).
- **Précision Wear OS** : Application montre autonome avec compatibilité spécifique à l'architecture (arm64-v8a/armeabi-v7a).
- **Sécurité** : Téléversements cloud non écrasants avec incrémentation automatique du titre.

## Développement

### Compilation
```bash
flutter pub get
flutter run
```

## Contributeurs
- **Antoine Giniès** (Auteur & développeur principal)
