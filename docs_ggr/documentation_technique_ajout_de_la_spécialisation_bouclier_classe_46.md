# Compte-rendu d'investigation et modifications SQL : Ajout de la Spécialisation Bouclier pour la Classe 46

## 1. Contexte & Problématique
Lors de l'attribution de la spécialisation **Shields (Boucliers)** à la classe ID **46** (Warden/Protecteur), le personnage pouvait voir et augmenter la ligne de compétence avec des points, mais **aucun style de combat** (coup spécial de bouclier) n'apparaissait dans le grimoire de combat.

---

## 2. Investigations & Découvertes sur l'Architecture
L'analyse du schéma et des données de la base SQLite `opendaoc.sqlite3.db` a révélé le fonctionnement interne du serveur :

1. **Aptitudes & Équipement de base (`SpecXAbility`)** :
   * Cette table gère les capacités d'utiliser le matos/passifs selon la ligne de carrière (ex: `WardenCareer` débloque l'utilisation du `Shield` au niveau 5).
   * Elle associe les prérequis de niveau de classe/carrière aux aptitudes génériques.

2. **Spécialisations (`ClassXSpecialization`)** :
   * Autorise une classe à dépenser des points de compétence dans une branche (`SpecKeyName = 'Shields'`).

3. **Styles de Combat (`Style`)** :
   * **`ID` (ID Logique)** : Représente le style de combat lui-même (ex: `221` pour *Numb*, `228` pour *Slam*). Cet ID est universel.
   * **`StyleID` (Clé Primaire SQL)** : Unique pour chaque enregistrement.
   * **`ClassId` (ID de Classe)** : Indique quelle classe a droit à ce style.
   * **Constat** : Les styles de combat sont **dupliqués pour chaque classe** (`ClassId`). Sans entrée explicite associant la ligne de style à la classe `46`, aucun coup n'est débloqué en jeu, même avec 50 points en spé Bouclier.

---

## 3. Modifications Effectuées

### Requête SQL exécutée
Duplication de l'ensemble de la chaîne de styles de bouclier depuis la classe **44** (Hero) vers la classe **46** :

```sql
INSERT INTO Style (
    ID, ClassId, Name, SpecKeyName, SpecLevelRequirement, Icon, 
    EnduranceCost, StealthRequirement, OpeningRequirementType, 
    OpeningRequirementValue, AttackResultRequirement, WeaponTypeRequirement, 
    GrowthOffset, GrowthRate, BonusToHit, BonusToDefense, 
    TwoHandAnimation, RandomProc, ArmorHitLocation, LastTimeRowUpdated
)
SELECT 
    ID, 46, Name, SpecKeyName, SpecLevelRequirement, Icon, 
    EnduranceCost, StealthRequirement, OpeningRequirementType, 
    OpeningRequirementValue, AttackResultRequirement, WeaponTypeRequirement, 
    GrowthOffset, GrowthRate, BonusToHit, BonusToDefense, 
    TwoHandAnimation, RandomProc, ArmorHitLocation, datetime('now')
FROM Style 
WHERE ClassId = 44 AND SpecKeyName = 'Shields';
```

### Styles ajoutés à la classe 46 :
* **Numb** (Req: Nv 3 | ID: 221)
* **Stun** (Req: Nv 8 | ID: 222)
* **Disable** (Req: Nv 13 | ID: 223)
* **Incapacitate** (Req: Nv 18 | ID: 224)
* **Paralyze** (Req: Nv 23 | ID: 225)
* **Bash** (Req: Nv 29 | ID: 226)
* **Mangle** (Req: Nv 35 | ID: 227)
* **Slam** (Req: Nv 42 | ID: 228)
* **Brutalize** (Req: Nv 50 | ID: 229)

---

## 4. Procédure de Vérification après Redémarrage
1. Relancer le serveur DAoC.
2. Se connecter avec un personnage de **Classe 46**.
3. Allouer des points dans la spécialisation **Shields**.
4. Ouvrir le livre de styles/compétences de combat pour vérifier la présence des coups de bouclier (ex: *Numb*, *Stun*, *Slam*).