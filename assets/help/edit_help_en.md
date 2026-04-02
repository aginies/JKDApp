# Combo Builder Help

## Buttons

| Button | Action |
|--------|--------|
| **Next** | Add a new numbered step to the combo |
| **+** | Merge with the previous step (simultaneous) |
| **->** | Chain onto the previous step (sequence) |
| **Answer** | Switch to defense mode to pick a counter |
| **Finish** | Add the move and finish the combo |
| **Cancel** | Discard current selection |

## Roles on Combo Cards

- **A:** Attacker action
- **D:** Defender response (counter)

---

## Next (numbered steps)

Use **Next** to create a series with numbered steps.

**Example:**
```
1. Jab (L)
2. Cross (R)
3. Nan Tek (L)
```

**Steps:**
1. Choose "Jab", select side **L**
2. Click **Next**
3. Choose "Cross", select side **R**
4. Click **Next**
5. Choose "Nan Tek", select side **L**
6. Click **Finish**

---

## + (simultaneous actions)

Use **+** to merge an action with the previous step. Up to 3 actions can be combined.

**Example:**
```
1. A: Pack Sao (R) + Jab (L)
   D: Vertical Locking (L)
```

**Steps:**
1. Choose "Pack Sao", select side **R**
2. Click **+**
3. Choose "Jab", select side **L**
4. Click **Answer**
5. Choose "Vertical Locking", select side **L**
6. Click **Finish**

---

## -> (chain / sequence)

Use **->** to chain actions within the same step. This creates a flowing sequence.

**Example:**
```
1. A: Bong Sao (L) -> Lop Sao (R) -> Jab (L)
```

**Steps:**
1. Choose "Bong Sao", select side **L**
2. Click **->**
3. Choose "Lop Sao", select side **R**
4. Click **->** (chains onto Bong Sao)
5. Choose "Jab", select side **L**
6. Click **Finish**

---

## Answer (counter / defense)

Use **Answer** to add a defensive response to the current attack. The picker switches to defense mode where you pick the counter move.

**Example:**
```
1. A: Jab (L)
   D: Inside Block (R)
```

**Steps:**
1. Choose "Jab", select side **L**
2. Click **Answer**
3. Choose "Inside Block", select side **R**
4. Click **Finish**

---

## + and -> in defense mode

After pressing **Answer**, you can use **+** and **->** to build complex counters with multiple actions.

### Simultaneous counter (+)

**Example:**
```
1. A: Jab (L)
   D: Pak Sao (R) + Jik Tek (R)
```

**Steps:**
1. Choose "Jab", select side **L**
2. Click **Answer**
3. Choose "Pak Sao", select side **R**
4. Click **+** (buffers the counter)
5. Choose "Jik Tek", select side **R**
6. Click **Finish**

### Chain counter (->)

**Example:**
```
1. A: Cross (R)
   D: Pak Sao (L) -> Jik Tek (R)
```

**Steps:**
1. Choose "Cross", select side **R**
2. Click **Answer**
3. Choose "Pak Sao", select side **L**
4. Click **->** (buffers the counter)
5. Choose "Jik Tek", select side **R**
6. Click **Finish**

---

## Full example

```
1. A: Jab (L) + Pack Sao (R)
   D: Vertical Locking (L)
2. A: Pack Sao (R) -> Jab (L)
   D: Through Locking (L)
3. A: Bong Sao (L) -> Lop Sao (R) -> Jab (L)
4. A: Cross (R)
   D: Pak Sao (L) + Jik Tek (R)
```

**Steps:**
1. Choose "Jab (L)"
2. Click **+**
3. Choose "Pack Sao (R)"
4. Click **Answer**
5. Choose "Vertical Locking (L)"
6. Click **Next**
7. Choose "Pack Sao (R)"
8. Click **->**
9. Choose "Jab (L)"
10. Click **Answer**
11. Choose "Through Locking (L)"
12. Click **Next**
13. Choose "Bong Sao (L)"
14. Click **->**
15. Choose "Lop Sao (R)"
16. Click **->**
17. Choose "Jab (L)"
18. Click **Next**
19. Choose "Cross (R)"
20. Click **Answer**
21. Choose "Pak Sao (L)"
22. Click **+**
23. Choose "Jik Tek (R)"
24. Click **Finish**
