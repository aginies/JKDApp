# Aide du constructeur de combos

## Boutons

| Bouton | Action |
|--------|--------|
| **Suivant** | Ajouter une nouvelle étape numérotée au combo |
| **+** | Fusionner avec l'étape précédente (simultané) |
| **->** | Enchaîner sur l'étape précédente (séquence) |
| **Répondre** | Passer en mode défense pour choisir un contre |
| **Terminer** | Ajouter le mouvement et terminer le combo |
| **Annuler** | Abandonner la sélection en cours |

## Rôles sur les cartes de combo

- **A :** Action de l'attaquant
- **D :** Réponse du défenseur (contre)

---

## Suivant (étapes numérotées)

Utilisez **Suivant** pour créer une série avec des étapes numérotées.

**Exemple :**
```
1. Jab (G)
2. Cross (D)
3. Nan Tek (G)
```

**Étapes :**
1. Choisir "Jab", sélectionner le côté **G**
2. Cliquer sur **Suivant**
3. Choisir "Cross", sélectionner le côté **D**
4. Cliquer sur **Suivant**
5. Choisir "Nan Tek", sélectionner le côté **G**
6. Cliquer sur **Terminer**

---

## + (actions simultanées)

Utilisez **+** pour fusionner une action avec l'étape précédente. Jusqu'à 3 actions peuvent être combinées.

**Exemple :**
```
1. A : Pack Sao (D) + Jab (G)
   D : Vertical Locking (G)
```

**Étapes :**
1. Choisir "Pack Sao", sélectionner le côté **D**
2. Cliquer sur **+**
3. Choisir "Jab", sélectionner le côté **G**
4. Cliquer sur **Répondre**
5. Choisir "Vertical Locking", sélectionner le côté **G**
6. Cliquer sur **Terminer**

---

## -> (enchaînement / séquence)

Utilisez **->** pour enchaîner des actions au sein de la même étape. Cela crée une séquence fluide.

**Exemple :**
```
1. A : Bong Sao (G) -> Lop Sao (D) -> Jab (G)
```

**Étapes :**
1. Choisir "Bong Sao", sélectionner le côté **G**
2. Cliquer sur **->**
3. Choisir "Lop Sao", sélectionner le côté **D**
4. Cliquer sur **->** (s'enchaîne sur Bong Sao)
5. Choisir "Jab", sélectionner le côté **G**
6. Cliquer sur **Terminer**

---

## Répondre (contre / défense)

Utilisez **Répondre** pour ajouter une réponse défensive à l'attaque en cours. Le sélecteur passe en mode défense où vous choisissez le mouvement de contre.

**Exemple :**
```
1. A : Jab (G)
   D : Inside Block (D)
```

**Étapes :**
1. Choisir "Jab", sélectionner le côté **G**
2. Cliquer sur **Répondre**
3. Choisir "Inside Block", sélectionner le côté **D**
4. Cliquer sur **Terminer**

---

## + et -> en mode défense

Après avoir appuyé sur **Répondre**, vous pouvez utiliser **+** et **->** pour construire des contres complexes avec plusieurs actions.

### Contre simultané (+)

**Exemple :**
```
1. A : Jab (G)
   D : Pak Sao (D) + Jik Tek (D)
```

**Étapes :**
1. Choisir "Jab", sélectionner le côté **G**
2. Cliquer sur **Répondre**
3. Choisir "Pak Sao", sélectionner le côté **D**
4. Cliquer sur **+** (met le contre en mémoire)
5. Choisir "Jik Tek", sélectionner le côté **D**
6. Cliquer sur **Terminer**

### Contre en enchaînement (->)

**Exemple :**
```
1. A : Cross (D)
   D : Pak Sao (G) -> Jik Tek (D)
```

**Étapes :**
1. Choisir "Cross", sélectionner le côté **D**
2. Cliquer sur **Répondre**
3. Choisir "Pak Sao", sélectionner le côté **G**
4. Cliquer sur **->** (met le contre en mémoire)
5. Choisir "Jik Tek", sélectionner le côté **D**
6. Cliquer sur **Terminer**

---

## Exemple complet

```
1. A : Jab (G) + Pack Sao (D)
   D : Vertical Locking (G)
2. A : Pack Sao (D) -> Jab (G)
   D : Through Locking (G)
3. A : Bong Sao (G) -> Lop Sao (D) -> Jab (G)
4. A : Cross (D)
   D : Pak Sao (G) + Jik Tek (D)
```

**Étapes :**
1. Choisir "Jab (G)"
2. Cliquer sur **+**
3. Choisir "Pack Sao (D)"
4. Cliquer sur **Répondre**
5. Choisir "Vertical Locking (G)"
6. Cliquer sur **Suivant**
7. Choisir "Pack Sao (D)"
8. Cliquer sur **->**
9. Choisir "Jab (G)"
10. Cliquer sur **Répondre**
11. Choisir "Through Locking (G)"
12. Cliquer sur **Suivant**
13. Choisir "Bong Sao (G)"
14. Cliquer sur **->**
15. Choisir "Lop Sao (D)"
16. Cliquer sur **->**
17. Choisir "Jab (G)"
18. Cliquer sur **Suivant**
19. Choisir "Cross (D)"
20. Cliquer sur **Répondre**
21. Choisir "Pak Sao (G)"
22. Cliquer sur **+**
23. Choisir "Jik Tek (D)"
24. Cliquer sur **Terminer**
