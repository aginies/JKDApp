# Aide du constructeur de combos

## Boutons

| Bouton | Action |
|--------|--------|
| **Suivant** | Ajouter une nouvelle etape numerotee au combo |
| **+** | Fusionner avec l'etape precedente (simultane) |
| **->** | Enchainer sur l'etape precedente (sequence) |
| **Repondre** | Passer en mode defense pour choisir une contre-attaque |
| **Terminer** | Ajouter le mouvement et terminer le combo |
| **Annuler** | Annuler la selection en cours |

## Roles sur les cartes de combo

- **A:** Action de l'attaquant
- **D:** Reponse du defenseur (contre)

---

## Suivant (etapes numerotees)

Utilisez **Suivant** pour creer une serie avec des etapes numerotees.

**Exemple:**
```
1. Jab (G)
2. Cross (D)
3. Nan Tek (G)
```

**Etapes:**
1. Choisir "Jab", selectionner cote **G**
2. Cliquer sur **Suivant**
3. Choisir "Cross", selectionner cote **D**
4. Cliquer sur **Suivant**
5. Choisir "Nan Tek", selectionner cote **G**
6. Cliquer sur **Terminer**

---

## + (actions simultanees)

Utilisez **+** pour fusionner une action avec l'etape precedente. Jusqu'a 3 actions peuvent etre combinees.

**Exemple:**
```
1. A: Pack Sao (D) + Jab (G)
   D: Vertical Locking (G)
```

**Etapes:**
1. Choisir "Pack Sao", selectionner cote **D**
2. Cliquer sur **Suivant**
3. Choisir "Jab", selectionner cote **G**
4. Cliquer sur **+** (fusionne Jab avec Pack Sao)
5. Cliquer sur **Repondre**
6. Choisir "Vertical Locking", selectionner cote **G**
7. Cliquer sur **Terminer**

---

## -> (enchainement / sequence)

Utilisez **->** pour enchainer des actions dans la meme etape. Cela cree une sequence fluide.

**Exemple:**
```
1. A: Bong Sao (G) -> Lop Sao (D) -> Jab (G)
```

**Etapes:**
1. Choisir "Bong Sao", selectionner cote **G**
2. Cliquer sur **Suivant**
3. Choisir "Lop Sao", selectionner cote **D**
4. Cliquer sur **->** (enchaine sur Bong Sao)
5. Choisir "Jab", selectionner cote **G**
6. Cliquer sur **->** (enchaine sur la sequence)
7. Cliquer sur **Terminer**

---

## Repondre (contre / defense)

Utilisez **Repondre** pour ajouter une reponse defensive a l'attaque en cours. Le selecteur passe en mode defense ou vous choisissez le mouvement de contre.

**Exemple:**
```
1. A: Jab (G)
   D: Inside Block (D)
```

**Etapes:**
1. Choisir "Jab", selectionner cote **G**
2. Cliquer sur **Suivant**
3. Cliquer sur **Repondre**
4. Choisir "Inside Block", selectionner cote **D**
5. Cliquer sur **Terminer**

---

## + et -> en mode defense

Apres avoir clique sur **Repondre**, vous pouvez utiliser **+** et **->** pour construire des contres complexes avec plusieurs actions.

### Contre simultane (+)

**Exemple:**
```
1. A: Jab (G)
   D: Pak Sao (D) + Jik Tek (D)
```

**Etapes:**
1. Choisir "Jab", selectionner cote **G**
2. Cliquer sur **Repondre**
3. Choisir "Pak Sao", selectionner cote **D**
4. Cliquer sur **+** (met le contre en attente)
5. Choisir "Jik Tek", selectionner cote **D**
6. Cliquer sur **Terminer**

### Contre en enchainement (->)

**Exemple:**
```
1. A: Cross (D)
   D: Pak Sao (G) -> Jik Tek (D)
```

**Etapes:**
1. Choisir "Cross", selectionner cote **D**
2. Cliquer sur **Repondre**
3. Choisir "Pak Sao", selectionner cote **G**
4. Cliquer sur **->** (met le contre en attente)
5. Choisir "Jik Tek", selectionner cote **D**
6. Cliquer sur **Terminer**

---

## Exemple complet

```
1. A: Jab (G) + Pack Sao (D)
   D: Vertical Locking (G)
2. A: Pack Sao (D) -> Jab (G)
   D: Through Locking (G)
3. A: Bong Sao (G) -> Lop Sao (D) -> Jab (G)
4. A: Cross (D)
   D: Pak Sao (G) + Jik Tek (D)
```

**Etapes:**
1. Choisir "Jab (G)" -> **Suivant**
2. Choisir "Pack Sao (D)" -> **+**
3. Cliquer sur **Repondre** -> Choisir "Vertical Locking (G)" -> **Suivant**
4. Choisir "Pack Sao (D)" -> **Suivant**
5. Choisir "Jab (G)" -> **->**
6. Cliquer sur **Repondre** -> Choisir "Through Locking (G)" -> **Suivant**
7. Choisir "Bong Sao (G)" -> **Suivant**
8. Choisir "Lop Sao (D)" -> **->**
9. Choisir "Jab (G)" -> **->** -> **Suivant**
10. Choisir "Cross (D)" -> **Repondre**
11. Choisir "Pak Sao (G)" -> **+**
12. Choisir "Jik Tek (D)" -> **Terminer**
