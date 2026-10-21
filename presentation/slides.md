---
marp: true
theme: default
paginate: true
size: 16:9
html: true
style: |
  section { font-size: 25px; }
  section h1 { color: #1a73e8; }
  section h2 { color: #1a73e8; font-size: 38px; }
  section.lead h1 { font-size: 58px; }
  section.lead p { font-size: 28px; color: #555; }
  section strong { color: #d93025; }
  blockquote { border-left: 5px solid #1a73e8; padding-left: 18px; color: #444; }
  ul, ol { line-height: 1.5; }
  table { font-size: 0.82em; }
  table th { color: #1a73e8; }
  /* two-col layout: h2 spans, then image | text */
  section.split { display: grid; grid-template-columns: 43% 1fr; gap: 30px; place-content: center; align-items: center; }
  section.split > h2 { grid-column: 1 / -1; }
  section.split > p { margin: 0; text-align: center; }
  section.pair > p:first-of-type { text-align: center; }
---

<!-- _class: lead -->

# JKDApp

**Bibliothèque d'entraînement Jeet Kune Do**

Consulter · Composer · S'entraîner · Partager

Android / Windows / macOS / Linux / Web / Garmin / Wear OS

Version 3.0.0

Octobre 2026

---

## Le problème

- Les techniques **éparpillées** : cahiers, PDF, vidéos YouTube, captures d'écran
- Un combo noté sur papier est **illisible**
- Aucune source fiable de référence
- Les noms sont **ambigus** (Pak Sao / Pow / Wing Chun vs. Jun Fan), selon la langue et l'école
- Impossible de **partager** proprement une série avec un condisciple, ni de la faire évoluer
- Les applis de sport ne suivent pas des **séquences** d'arts martiaux

> Besoin d'un mémo **fiable** et **simple** d'utilisation

---

## Une application perso

> **Avoir une référence fiable**

| Étape | Ce que l'app apporte |
|---|---|
| **Consulter** | Glossaire bilingue, recherche, photos / vidéos |
| **Composer** | Éditeur de combos visuel, sous-numérotation, ripostes, angles Kali, etc. |
| **Enregistrement Audio** | Rapidement enregistrer une séquence en audio |
| **Partager** | Export PDF, sauvegarde ZIP, bibliothèque cloud |
| **S'entraîner** | TTS + minuteur + boucle, programmes multi-jours, échauffement |
| **Multi Plateforme** | Disponible partout, support tactile |

---

<!-- _class: pair -->

## Catégories : quatre univers

![height:360](img/main.png) ![height:360](img/serie_cards.png)

**Jun Fan Gung Fu · Jun Fan Kick Boxing · Kali · JKD Moves (déplacements)**
Séries : liste classique ou vue « carte », catégories, filtres et recherche globale instantanée

---

<!-- _class: split -->

## Glossaire : la base de données fondamentale

![height:440](img/glossaire.png)

- Tout est basé sur le glossaire
- **~211 mouvements** traduits FR/EN, avec type de frappe, hauteur (H/M/B) et direction (G/D)
- Support des mouvements **Kali** « classiques »
- Les **5 modes d'attaque** : SAA · IA/HIA · PIA · ABC · ABD
- **Recherche tolérante** : « pak sao » retrouve « Pow Sao »
- **Média attaché** : photo ou **vidéo enregistrée depuis l'app**, icône sur la fiche

---

<!-- _class: split -->

## L'éditeur de combos : composer / modifier une série

![height:330](img/editer_combo.png)

- **Sous-numérotation** 1a / 1b / 1c : les variantes s'indentent automatiquement
- 3 modes : **Réponse** (riposte) · **Simultané** · **Chaîne**
- **Ripostes** : défense attachée à l'attaque
- **Undo / Redo / édition** : corriger ou rééditer sans tout reconstruire
- **Statistiques** : les mouvements les plus utilisés apparaissent en haut de la liste
- **Angles Kali personnalisés** : on dessine l'angle, il devient réutilisable

---

<!-- _class: split -->

## S'entraîner : séance ou révision

![height:440](img/entrainement_serie.png)

- **Guidage vocal TTS** : annonce la série, puis chaque mouvement
- **Intervalles configurables** + **bouclage** de la série
- **Vue carte plein écran** : le mouvement courant
- Le rythme suit la hiérarchie 1a/1b → enchaînement naturel

- Mode **révision** pour chaque série (3 niveaux)

---

<!-- _class: split -->

## Le lecteur aléatoire : les déplacements

![height:440](img/lecture_deplacement.png)

- Annonce la série (EN) → **1 s de pause** → appelle les numéros **1-6** dans la langue choisie
- **Garde gauche / droite** commutable
- **Délai 0,4 s → 2,5 s** : progression de la vitesse de réaction

---

## Programmes journaliers

**Programmes d'entraînement**

- Régimes multi-jours, **attributions quotidiennes**, statistiques de complétion
- Calendrier visuel + vue d'ensemble des entraînements actifs
- Niveaux débutant → expert : *counts, footwork, counters, trapping*, combos sur 45 jours
- Progression suivie jour par jour dans l'app

---

<!-- _class: split -->

## L'échauffement guidé

![height:440](img/echauffement_0.png)

- Durées **travail / repos** configurables, guidage vocal TTS
- Enchaînement automatique des blocs, sans toucher au téléphone
- Mode **Tabata** avec musique de fond
- **Fréquence cardiaque en direct** remontée depuis la montre pendant la session

---

## L'écosystème des montres connectées

**Wear OS**
- Disposition en **bulles** codées par couleur, 1 ou 2 colonnes automatiques
- **Avance automatique** 2-30 s + dégradé de bordure circulaire rouge → jaune → vert
- Défilement automatique des longues descriptions

**Garmin ConnectIQ**
- **Synchronisation** de la série courante et de la progression vers la montre
- **Retour audio** couplé au moteur TTS du téléphone : un seul coach

---

<!-- _class: split -->

## La bibliothèque cloud et l'App web

![height:360](img/cloud.png)

- **Déposer / télécharger** des séries communautaires depuis l'app
- **Cloud série** parcourir, chercher, prévisualiser sans installer
- **Modération** côté admin + journalisation centralisée des requêtes
- **Série** peut être: Officielle / Perso / Cloud
- **Application Web** sur une page web, donc tout le temps accessible

---

<!-- _class: split -->

## En développement — Motion Capture

<video src="mocap_predemo.mp4" autoplay muted loop playsinline style="width: 100%; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,.2);"></video>

- Objectif : **filmer une technique**, en extraire le **mouvement**, et le rattacher aux combos
- Support **Kali** : 4 capteurs supplémentaires (2 par kali)
- **Partie logicielle : validée avec un prototype matériel** (acquisition, liaison, interprétation des capteurs)
- **En cours : fabrication de la « combinaison »** équipée des capteurs (14 sur 21 au total)

---

<!-- _class: lead -->

# Disponibilité

**Licence** : Open Source (GPLv3)
**Repo** : http://www.github.com/aginies/JKDApp
**Galerie interactive** : http://aginies.github.io/JKDApp/gallery.html
**Cloud Series** : http://jkd.guibo.com
**App disponible** : Android · Wear OS · Garmin · macOS · Windows · Linux · Web

Distribution actuellement limitée (Moi, Will et Yann)

---

<!-- _class: split -->

## Et maintenant ?

![height:320](img/parametres.png)

- L'app est un **mémo** : un jab, « c'est technique à faire », ce n'est pas juste un « nom »
- L'application n'a **aucune valeur sans les cours**
- Le glossaire est techniquement disponible partout (utilisé pour corriger la syntaxe), même s'il n'est pas catégorisé ailleurs
- Les séries **sont exportées des cours** (donc de mes notes…)

> Décision à prendre:
- Contenu de la bibliothèque : **possibilité d'accès restreint via auth** (à implémenter)
- À qui distribuer l'application ? **Avancés ? Sélection d'élèves ? Instructeurs ?**
- Idées ou fonctions à implémenter ?
