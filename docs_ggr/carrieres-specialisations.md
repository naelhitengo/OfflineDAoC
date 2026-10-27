# « Career » (carrière) : ce que c'est dans le code

Question : en base on voit des « careers » (`ClassXSpecialization`), mais côté code `Specialization.cs` c'est flou.
Lu : `GameServer/gameutils/Specialization.cs` (en entier), `gameutils/Specializations/*.cs` (signatures), `gameutils/SkillBase.cs` (≈ 520-540, 540-660, 678-723, 2131-2145, 2606-2713, 3096-3137), `CoreDatabase/Tables/DbClassXSpecialization.cs`, `DbSpecialization.cs` (`Implementation`), `gameobjects/GamePlayer.cs` (≈ 9857-9875, 9953-10070, 10325-10340), `gameutils/GamePlayerUtils.cs` (≈ 505-530), `bots/GameBot.cs` (≈ 3279-3290), `scripts/quests/Hibernia/SluaghbinderEpicQuests.cs` (en-tête seulement).
Rien exécuté ni modifié. Pas de base dans le dépôt : les valeurs de `Implementation` réellement présentes en base **n'ont pas été vues**. Suite directe de [lignes-de-competence-classes.md](lignes-de-competence-classes.md).

## 1. Le mot « career » désigne deux choses différentes

| Sens | Où | Ce que c'est |
|---|---|---|
| **Carrière d'une classe** (données) | table `ClassXSpecialization`, `SkillBase.m_specsByClass`, `SkillBase.GetSpecializationCareer(classID)` | La **liste des lignes** qu'une classe possède, avec le niveau d'ouverture. Vaut pour toutes les lignes, entraînables ou non. |
| **`CareerSpecialization`** (type C#) | `Specialization.cs:492` | Un **type de ligne** : non entraînable, non sauvegardée, niveau = niveau du personnage. |

Une ligne figurant dans la carrière d'une classe n'est donc **pas forcément** une `CareerSpecialization` : `Slash` ou `Shields` sont dans la carrière de la classe mais sont des lignes entraînables.

## 2. Hiérarchie des types (`Specialization.cs`)

```
Specialization            (:40)   Trainable = true,  AllowSave = true,  niveau = Level (points dépensés)
└─ UntrainableSpecialization (:473) Trainable = false
   └─ CareerSpecialization    (:492) AllowSave = false, GetSpecLevelForLiving = living.Level
      ├─ LiveCareerSpecialization      (Specializations/LiveCareerSpecialization.cs:27) coquille vide
      │  └─ LiveWideCareerSpecialization (:38) coquille vide (« sprint », capacités de base pour tous)
      ├─ LiveMasterLevelsSpecialization  (+ IMasterLevelsSpecialization)
      ├─ LiveChampionsSpecialization
      ├─ LiveRealmAbilitiesSpecialization
      └─ SluaghbinderEpicSpellsSpecialization (scripts/quests/Hibernia/SluaghbinderEpicQuests.cs:53)
```
Les autres types « Live » (`LiveWeaponSpecialization`, `LiveSpellLineSpecialization`, `LiveAbilitySpecialization`, `LiveSpellHybridSpecialization`) héritent directement de `Specialization` : **entraînables**. `MiniLineSpecialization` / `LiveCL…Spec` (lignes de Champion) héritent d'`UntrainableSpecialization`, pas de `CareerSpecialization`.

Les trois propriétés virtuelles qui font la différence (`Specialization.cs`) :

| Propriété | `Specialization` | `CareerSpecialization` | Effet |
|---|---|---|---|
| `Trainable` (:86) | `true` | `false` | Apparaît (ou non) dans la liste d'entraînement envoyée au client et dans les points à dépenser. |
| `AllowSave` (:94) | `true` | `false` | Écrite (ou non) dans `DBCharacter.SerializedSpecs`. |
| `GetSpecLevelForLiving` (:466) | `Level` | `max(0, living.Level)` | Niveau utilisé pour filtrer sorts, capacités, styles. |

Conséquence : une `CareerSpecialization` **n'est jamais stockée** dans le personnage ; elle est reconstruite à chaque connexion à partir de la table, et son niveau suit celui du personnage sans coûter de points.

## 3. D'où vient le type d'une ligne

1. Table `Specialization` : colonne `Implementation` (nom de type C#, `DbSpecialization.cs:90`).
2. Au démarrage `SkillBase` instancie chaque ligne pour connaître son type (`SkillBase.cs:530`, `GetNewSpecializationInstance`, :3133, qui passe par `ResolveType`) et met dans `m_specsByName[KeyName]` un tuple `(Type, Name, Icon, ID)` (:540, :653).
3. Chaque appel à `SkillBase.GetSpecialization(key, …)` (:2606) **crée une nouvelle instance** de ce type via un constructeur compilé à 4 arguments `(string, string, ushort, int)` (:3112). Tout type de ligne doit donc exposer ce constructeur. Si le type est introuvable : repli sur `Specialization` simple, avec une erreur au journal (:3100-3130).

Donc : **changer la colonne `Implementation` en base change le comportement de la ligne** (entraînable ou non, sauvegardée ou non, niveau). *Non vérifié* : quelles valeurs de `Implementation` sont réellement en base pour quelles lignes (requête en §6).

## 4. Chargement de la carrière d'une classe

- `SkillBase.LoadClassSpecializations()` (:678) lit toute la table `ClassXSpecialization` dans `m_specsByClass[ClassID][SpecKeyName] = LevelAcquired`. Un doublon `(classe, ligne)` est ignoré avec un avertissement (:709).
- `GetSpecializationCareer(classID)` (:2660) renvoie `Dictionary<Specialization, int>` : les lignes de la classe **plus** celles de `ClassID = 0` (« tout le monde », :2692). Elle fixe aussi `spec.LevelRequired`. Les lignes dont la clé est inconnue de `GetSpecialization` sont **ignorées en silence** (`catch { }`, :2684 et :2709) : une faute de frappe dans `SpecKeyName` ne produit ni erreur ni ligne.

## 5. Ce que fait le joueur de cette carrière (`GamePlayer.LoadClassSpecializations`, ≈ 9953)

1. Récupère `careers = GetSpecializationCareer(CharacterClass.ID)`.
2. **Cas particuliers du Sluaghbinder** (code propre au fork) :
   - Acolyte hibernien (niveaux 1-4) : retire `Rejuvenation` et `Enhancement` de la carrière, retire ces lignes de sorts, et ajoute trois `CareerSpecialization` créées à la main (`Sluagh Host`, `Abhartach's Rot`, `Cairn Oath`, `LevelRequired = -3`), donc sans points dépensés.
   - Classe 63 ayant la première récompense d'épique : ajoute `Epic Spells` (type `SluaghbinderEpicSpellsSpecialization`).
3. **Nettoyage** (≈ 10026) : retire du joueur toute ligne `Trainable` **ou** `!AllowSave` qui n'est plus dans la carrière. C'est pourquoi les carrières ne sont pas persistées : elles sont purgées/recréées à chaque chargement (promotion de classe, changement de table).
4. Tri des lignes de Maître (ML) : une seule ligne ML est gardée selon `MLLine`, et seulement si `MLGranted` et `MLLevel ≥ 1`.
5. Pour chaque `(ligne, niveau)` : si `Level >= niveau` et le joueur ne l'a pas, `AddSpecialization` ; sinon, si il l'a, `RemoveSpecialization`. Donc `LevelAcquired` s'applique à **toutes** les lignes, même entraînables. Une valeur négative (-3 ici) revient à « toujours là » : elle sert au tri (`LevelRequired` « peut être négatif pour trier », `Specialization.cs:43`).

Sauvegarde (`SaveSkillsToCharacter`, ≈ 9866) : ne sérialise que `AllowSave`, au format `Clé|niveau;…`. Rechargement (≈ 10332) : une ligne lue avec `AllowSave = false` est ignorée, ce qui est le comportement voulu.
Envoi au client (`GamePlayerUtils.cs:520`) : `if (!spec.Trainable) continue;` : les carrières ne sont **pas** affichées comme lignes entraînables ; leurs sorts/capacités/styles le sont via les boucles suivantes.

## 6. `GameBot`

`GameBot.cs:3279` répète la même logique (carrière, puis suppression des lignes `Trainable || !AllowSave` absentes). Les compagnons sauvegardent seulement les lignes `Trainable` (`GameBot.cs:3159`). Ne pas confondre joueurs, compagnons `/spawn` et gamebots autonomes (`AGENTS.md`).

## 7. Pièges et pistes

- Ajouter une ligne à la carrière d'une classe (SQL) ne suffit pas à la rendre « career » : tout dépend de `Specialization.Implementation`. Une ligne entraînable donnée à une classe apparaît avec 0 point.
- `LevelAcquired` > niveau du personnage : la ligne est retirée (et ses points perdus pour une ligne entraînable, *non vérifié* si les points sont restitués : voir `points-de-competences.md`).
- Les deux classes `LiveCareerSpecialization` / `LiveWideCareerSpecialization` sont **vides** : elles servent de marqueurs de type (valeur de `Implementation`). La différence « Wide » (sprint, évènements pour tous) n'est pas dans le code de la classe ; elle vient des lignes `ClassID = 0`. *Non vérifié* : où `LiveWideCareerSpecialization` est référencée (aucune référence C# trouvée hors sa définition, donc probablement uniquement via la colonne `Implementation`).
- `AddSpecialization` / `RemoveSpecialization` / `GetSpecList` (`GamePlayer`) non lus en détail.

Requêtes à lancer (serveur arrêté, copie de la base) :
```sql
SELECT Implementation, COUNT(*) FROM Specialization GROUP BY Implementation;
SELECT KeyName, Implementation FROM Specialization WHERE Implementation LIKE '%Career%';
SELECT ClassID, SpecKeyName, LevelAcquired FROM ClassXSpecialization WHERE ClassID = 0;
SELECT c.ClassID, c.SpecKeyName FROM ClassXSpecialization c
  LEFT JOIN Specialization s ON s.KeyName = c.SpecKeyName WHERE s.KeyName IS NULL;  -- clés orphelines, ignorées en silence
```
(Noms de colonnes d'après `DbSpecialization` / `DbClassXSpecialization` ; `exemples_sqlite.py DB schema Specialization` pour confirmer.)
