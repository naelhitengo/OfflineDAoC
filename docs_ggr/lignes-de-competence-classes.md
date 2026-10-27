# Donner une ligne de compétence à une classe (exemple : bouclier pour le Warden)

Question : une version ultérieure a donné aux Warden (`ClassWarden`) une ligne de compétence de bouclier ; comment le faire ici ? Est-ce dans le SQL, ou dans la classe `SpellLine` de `Skills.cs` ?
Lu : `GameServer/gameutils/Skill/Skill.cs` (`SpellLine`), `gameutils/SkillBase.cs` (≈ 545-710, 2660), `CoreDatabase/Tables/DbClassXSpecialization.cs`, `DbSpecXAbility.cs`, `playerclasses/hibernia/ClassWarden.cs`, `bots/specs/Hibernia/Warden.cs`, `gameobjects/GameLiving.cs` (≈ 1283), `serverrules/AbstractServerRules.cs` (883), `tools/claude-version/seed_sluaghbinder.py` (exemple de projet).
Rien exécuté ni modifié. Pas de base dans le dépôt : l'état actuel des Warden en base **n'a pas été vu**. Je n'ai pas pu vérifier ce que la « version ultérieure » (d'OpenDAoC ?) a changé exactement.

## 1. Réponse courte : c'est dans le SQL, pas dans `SpellLine`

- `SpellLine` (`Skill.cs:186`) est une **ligne de sorts** (`eSkillPage.Spells`), par ex. la ligne de sorts d'une spécialisation. Ce n'est pas une ligne de compétence (spécialisation) : ce n'est pas là qu'on donne « Shields » à une classe.
- Une **ligne de compétence** (spécialisation, ex. `Shields`, `Parry`, `Nurture`) est un objet `Specialization`. Quelles lignes une classe possède est décrit par la **table `ClassXSpecialization`**, lue au démarrage par `SkillBase.LoadClassSpecializations()` (`SkillBase.cs:679`) dans `m_specsByClass`. La classe C# `ClassWarden` ne liste pas ses spécialisations : elle ne contient que profession, stats, multiplicateur (15), races.
- Le joueur reçoit sa liste via `GamePlayer.LoadClassSpecializations` (≈ 9953) qui appelle `SkillBase.GetSpecializationCareer(CharacterClass.ID)` ; la ligne `ClassID = 0` est une carrière « tout le monde » (`SkillBase.cs:2692`). Les `GameBot` font de même (`GameBot.cs:3274`).

## 2. Les tables en jeu

| Table | Colonnes utiles | Rôle |
|---|---|---|
| `ClassXSpecialization` | `ClassID`, `SpecKeyName`, `LevelAcquired` | Quelle ligne la classe possède, et à quel niveau elle s'ouvre (0 = d'emblée). `ClassID` du Warden = **46** (`eCharacterClass.Warden`) |
| `SpecXAbility` | `Spec`, `SpecLevel`, `AbilityKey`, `AbilityLevel`, `ClassId` | Capacités acquises en montant la ligne. `ClassId = 0` : pour toutes les classes ayant cette ligne |
| `Style` | `ClassId`, `SpecKeyName`, `SpecLevelRequirement` | Styles de la ligne, filtrés par classe (`SkillBase.cs:2101-2106`) |
| `Specialization` | `KeyName` | Définition de la ligne. `Shields` existe déjà (constante `Specs.Shields`) |

## 3. « Bouclier » = deux choses distinctes

1. **Pouvoir porter et utiliser un bouclier** : capacité `Shield` (`Abilities.Shield`), avec un niveau 1/2/3 (petit, moyen, grand ; `AbstractServerRules.cs:883` compare `GetAbilityLevel("Shield")` à `Type_Damage` de l'objet). Sans `HasAbility(Abilities.Shield)`, la chance de bloquer vaut 0 (`GameLiving.cs:1283`, joueurs et `GameBot`). Elle vient d'une ligne `SpecXAbility`.
2. **La ligne `Shields`** (entraînable) : augmente le score de bouclier, donc le blocage, et ouvre des styles de bouclier.

Pour un Warden : vérifier d'abord, en base, ce qu'il a déjà (voir 5). Selon le cas il faut la capacité, la ligne, ou les deux.

## 4. Exemple du projet : le Sluaghbinder (classe 63)

`tools/claude-version/seed_sluaghbinder.py` est le modèle déjà écrit dans ce dépôt (SQL via Python, sauvegarde, une transaction) :
- `INSERT INTO ClassXSpecialization (ClassID,SpecKeyName,LevelAcquired,LastTimeRowUpdated) VALUES (?,?,?,?)` : ligne ajoutée à la classe ;
- `INSERT INTO SpecXAbility (Spec,SpecLevel,AbilityKey,AbilityLevel,ClassId,LastTimeRowUpdated) VALUES (?,?,?,?,?,?)` avec `('<ligne>', 1, 'Shield', 1)`, `(…, 5, 'Shield', 2)`, `(…, 10, 'Shield', 3)` : le bouclier accordé par niveau ;
- `UPDATE Style SET SpecKeyName=? WHERE ClassId=? AND ID IN (…)` : styles de bouclier rattachés à la ligne **de cette classe seulement**.
Le script fait aussi remarquer que mettre les trois rangs de `Shield` sur la carrière évite des capacités « apprendre à utiliser un bouclier » redondantes.

## 5. Procédure d'investigation (dans l'ordre, serveur arrêté, sur une copie de la base)

```sql
SELECT * FROM ClassXSpecialization WHERE ClassID = 46;           -- lignes actuelles du Warden
SELECT * FROM SpecXAbility WHERE Spec IN (SELECT SpecKeyName FROM ClassXSpecialization WHERE ClassID = 46) OR AbilityKey = 'Shield';
SELECT * FROM SpecXAbility WHERE Spec = 'Shields';              -- ce que donne la ligne Shields à d'autres classes
SELECT DISTINCT ClassId, SpecKeyName FROM Style WHERE SpecKeyName = 'Shields';  -- styles de bouclier : pour quelles classes
```
(Noms de colonnes d'après les classes C# ; confirmer avec `exemples_sqlite.py DB schema ClassXSpecialization`.)

Modèle d'ajout, **non testé** (à adapter après les lectures ci-dessus) :
```sql
INSERT INTO ClassXSpecialization (ClassID,SpecKeyName,LevelAcquired,LastTimeRowUpdated) VALUES (46,'Shields',1,datetime('now'));
-- seulement si le Warden n'a pas déjà la capacité Shield :
-- INSERT INTO SpecXAbility (Spec,SpecLevel,AbilityKey,AbilityLevel,ClassId,LastTimeRowUpdated) VALUES ('Shields',1,'Shield',1,46,datetime('now'));
```
Points d'attention :
- La table `SpecXAbility` ligne `Spec='Shields'` existe vraisemblablement déjà (autres classes) : ne pas la dupliquer ; l'ajout d'un `ClassId = 46` est à choisir après lecture (SkillBase transmet `specx.ClassId`, `SkillBase.cs:557`).
- Le format de `LastTimeRowUpdated` doit suivre celui des lignes existantes.
- `SkillBase.LoadClassSpecializations` est lu **au démarrage** : redémarrer le serveur ; les personnages existants récupèrent la ligne à la connexion (`LoadClassSpecializations`), à 0 point : à dépenser ou à ajuster (`points-de-competences.md`).
- Styles de bouclier : sans lignes `Style` pour la classe 46, la ligne apparaît sans styles (acceptable pour un simple score de bouclier).
- Le **client 1.65** affiche les lignes envoyées par le serveur ; je n'ai pas vérifié ses limites (nombre de lignes, icônes) : voir `docs/CLIENT-MODDING-GUIDE.txt` avant de conclure.
- Bots : `WardenBotSpec` (`bots/specs/Hibernia/Warden.cs`) ne connaît ni bouclier ni `Specs.Shields` : un bot Warden n'utiliserait pas la nouvelle ligne tant que la spec du bot n'a pas `Add(Specs.Shields, …)` ; l'équipement (`BotEquipment`, `EquipOffhand`) dépend de `BestShieldLevel`. Distinguer joueurs, compagnons `/spawn`, gamebots autonomes (`AGENTS.md`).
- Bouclier de Warden : `Is2H = false` dans `WardenBotSpec`, donc compatible une main + bouclier.
- Sauvegarde, une seule transaction, serveur arrêté (règle 4 de `CLIENT-MODDING-GUIDE.txt`).

## 6. Les styles de la ligne (blocage, face à l'adversaire, sur le côté…)

Lu : `CoreDatabase/Tables/DbStyle.cs`, `DbSpecialization.cs`, `SkillBase.cs` (≈ 596-640, 2085-2125, 2715-2740), `gameutils/Specialization.cs` (≈ 420-450), `styles/Style.cs`, `styles/StyleProcessor.cs` (≈ 525-580).

**Ajouter la ligne ne suffit pas : les styles sont des lignes de la table `Style`.** Ce ne sont pas des `SpellLine`.

- `DbSpecialization.Styles` relie la spécialisation à ses styles par `KeyName` = `Style.SpecKeyName` (`DbSpecialization.cs:98`). Au démarrage, `SkillBase` les range par ligne **puis par `ClassId`** (`m_specsStyles[ligne][ClassId]`).
- Colonnes de `Style` (`DbStyle`) : `ID`, `ClassId`, `Name`, `SpecKeyName`, `SpecLevelRequirement` (niveau de la ligne), `Icon`, `EnduranceCost`, `OpeningRequirementType` / `OpeningRequirementValue` (conditions d'ouverture : style précédent, position, etc.), `AttackResultRequirement` (par ex. après un blocage), `WeaponTypeRequirement`, `GrowthOffset`, `GrowthRate`, `BonusToHit`, `BonusToDefense`, `StealthRequirement`, `TwoHandAnimation`, `RandomProc`, `ArmorHitLocation`. Les effets associés (stun, dégâts de zone…) sont dans la table `StyleXSpell` (`DbStyleXSpell`, lue via `AttachedProcs`).
- Un style de bouclier a `WeaponTypeRequirement` = type d'objet **Shield** : `StyleProcessor` regarde alors la main gauche (`ActiveLeftWeapon`), et exige une arme active en main droite (une main) ou gauche (`StyleProcessor.cs:168`, `:561`).
- **Clé importante : `Style.ID` + `ClassId`** (`m_styleIndex`, avertissement « Duplicate Style Key » sinon). Les conditions d'ouverture qui visent un style précédent (`OpeningRequirementValue`) se réfèrent à un ID de style.

### Quel `ClassId` choisir pour les styles du Warden

`Specialization.GetStylesForLiving` (`gameutils/Specialization.cs:428`) :
1. cherche les styles de la ligne pour **la classe du joueur** (`ClassId` = 46) ;
2. si **aucun**, repasse à `ClassId = 0` (« styles communs ») ;
3. puis filtre sur `SpecLevelRequirement <= niveau` dans la ligne et trie par niveau puis ID.

Deux cas selon la base (à lire, section 7) :
- **Les styles de bouclier existants sont à `ClassId = 0`** : donner la ligne `Shields` au Warden (`ClassXSpecialization`) suffit, ses styles viendront seuls via le repli. Aucune ligne `Style` à ajouter.
- **Ils sont par classe** (`ClassId` = 1, 2, 3…, comme les styles d'arme) : il faut **copier** les lignes `Style` d'une classe de référence vers `ClassId = 46`, avec de **nouveaux `StyleID` (clé primaire auto)** ; conserver `ID` (identifiant de style attendu par le client) ; copier aussi les lignes `StyleXSpell` rattachées (nouveau `StyleID`). Le même principe est utilisé dans le projet : `seed_sluaghbinder.py` re-rattache seulement les styles de la classe 63 (`UPDATE Style SET SpecKeyName=? WHERE ClassId=? AND ID IN (…)`).
- Si **un seul** des deux ensembles existe, le repli s'applique ; si le Warden a des styles propres même pour une seule ligne, le repli à 0 ne se déclenche plus pour cette ligne (c'est tout ou rien par ligne).

### Une ligne `Shields` commune aux royaumes ?

- Dans le code, il n'existe qu'**une** clé `Specs.Shields = "Shields"` (`SkillConstants.cs:528`), utilisée par `ObjectTypeToSpec(eObjectType.Shield)` (`SkillBase.cs:991`). Les armes, elles, ont une clé par arme et par royaume : `Slash`/`Crush`/`Thrust` (Albion), `Blades`/`Blunt`/`Piercing` (Hibernia), `Sword`/`Axe`/`Hammer` (Midgard).
- Donc la ligne est **une seule ligne partagée** au niveau des clés ; ce qui change par classe, ce sont les rangs dans `ClassXSpecialization`, les capacités `Shield` (`SpecXAbility`) et les styles (`ClassId`). Votre souvenir « possible qu'elle existe en triple » ne se voit pas dans le code (une clé) ; la **base** peut contenir d'autres clés : `SELECT KeyName FROM Specialization WHERE KeyName LIKE '%hield%';`.

## 7. Requêtes à lancer pour trancher (serveur arrêté, copie de la base)

```sql
SELECT ClassId, COUNT(*) AS styles, MIN(SpecLevelRequirement), MAX(SpecLevelRequirement)
  FROM Style WHERE SpecKeyName = 'Shields' GROUP BY ClassId;      -- 0 = communs, sinon par classe
SELECT StyleID, ID, ClassId, Name, SpecLevelRequirement, OpeningRequirementType, OpeningRequirementValue,
       AttackResultRequirement, WeaponTypeRequirement, GrowthRate, BonusToDefense
  FROM Style WHERE SpecKeyName = 'Shields' ORDER BY ClassId, SpecLevelRequirement;
SELECT * FROM StyleXSpell WHERE StyleID IN (SELECT StyleID FROM Style WHERE SpecKeyName = 'Shields');
SELECT KeyName FROM Specialization WHERE KeyName LIKE '%hield%';
```
(Noms de colonnes d'après `DbStyle` ; `exemples_sqlite.py DB schema Style` pour confirmer. `StyleXSpell` : voir `DbStyleXSpell.cs`, non lu en détail.)

Mise en garde : le client 1.65 reconnaît les styles par `ID` et leur icône ; l'ajout de styles à une classe qui n'en avait pas pour cette ligne n'a pas été validé côté client (voir `CLIENT-MODDING-GUIDE.txt`). Non testé.

## 8. Où creuser ensuite

- Lire la base d'une installation 0.37 (les requêtes de la section 5) et comparer avec `ClassXSpecialization` d'une classe qui a `Shields` (la requête `SELECT DISTINCT ClassID FROM ClassXSpecialization WHERE SpecKeyName='Shields'` donne la liste).
- Retrouver ce que la version ultérieure a vraiment changé (sources OpenDAoC amont, non présentes ici).
- Lire `Specialization` / `Specs` (`SkillConstants.cs`) et la construction de `GetSpecializationCareer` (`SkillBase.cs:2660`).
