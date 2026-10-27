# Points de spécialisation : multiplicateur de classe, calcul et persistance

Notes de recherche sur le dépôt Offline DAoC (base OpenDAoC). Aucun code modifié.
Chemins relatifs à `source/server/GameServer/` sauf mention contraire. Numéros de ligne relevés à la date de l'analyse : à revérifier.

Ne figure pas ici (non lu) : `GameBot.VerifySpecPoints` éventuel, `GetAutoTrainPoints` en entier, `CharacterClass.GetAutotrainableSkills()` par classe, `respec.cs` en détail.

## 1. Où se trouve `m_specializationMultiplier` et où est-il utilisé ?

**Définition**
- Champ de base : `gameobjects/CharacterClasses/CharacterClassBase.cs:46`, `protected int m_specializationMultiplier = 10;`
- Exposé par `SpecPointsMultiplier` (ligne 164) et `AdjustedSpecPointsMultiplier` (ligne 173, identique : « pour la nouvelle fenêtre d'entraînement »), déclarés dans `ICharacterClass.cs:65` et `:71`.
- Chaque classe le redéfinit dans son constructeur, dans `playerclasses/<royaume>/Class<Nom>.cs` et `playerclasses/base/Class<Nom>.cs`. Exemple : `ClassMercenary` (albion) = 20, `ClassTheurgist` = 10. Les classes de base (`ClassFighter`, `ClassElementalist`…) valent 10 ; une classe finale réécrit sa propre valeur.

**Valeurs relevées** (fichier trouvé par recherche, valeur lue)
- 10 : tous les lanceurs de sorts (Wizard, Sorcerer, Theurgist, Cleric, Cabalist, Necromancer, Spiritmaster, Runemaster, Healer, Shaman, Bonedancer, Warlock, Druid, Eldritch, Enchanter, Mentalist, Animist, Bainshee, Sluaghbinder) et les classes de base.
- 15 : Friar, Minstrel, Mauler (Alb/Mid/Hib), Savage, Skald, Warden, Vampiir, Valewalker, Bard.
- 20 : Armsman, Mercenary, Paladin, Reaver, Scout, Heretic, Berserker, Hunter, Thane, Valkyrie, Warrior, Blademaster, Champion, Hero, Ranger.
- 22 : Shadowblade, Nightshade.
- 25 : Infiltrator.

**Usages dans le code** (recherche de `SpecPointsMultiplier` dans tout `source/server`)
| Fichier | Ligne(s) | Rôle |
|---|---|---|
| `gameobjects/GamePlayer.cs` | 4718 | `OnLevelUp` : points gagnés en montant de niveau : `i <= 5` → `i` ; sinon `multiplicateur × i / 10` (message « vous obtenez N points ») |
| `gameobjects/GamePlayer.cs` | 4812 | `OnLevelSecondStage` (mi-niveau) : `multiplicateur × Level / 20` |
| `gameobjects/GamePlayer.cs` | 10082-10086 | `VerifySpecPoints()` : **recalcule le total de points dû pour le niveau actuel** (voir §2) |
| `bots/GameBot.cs` | 3380, 3383 | `GetSpecPointsForLevel(niveau, creationBot)` : points à dépenser pour un bot ; puis `SpendSpecPoints` les répartit selon le `BotSpec` |
| `packets/Server/PacketLib1105.cs` | 154-173 | Commentaire seulement (code désactivé) sur `AdjustedSpecPointsMultiplier` |

Aucun autre usage : le multiplicateur n'intervient donc ni dans le coût d'un niveau de compétence, ni dans les sorts.

**Formules (joueur)**
- Gain par niveau : niveaux 1 à 5 : `niveau` points ; au-delà de 5 : `mult × niveau / 10` (division entière).
- Mi-niveau (`OnLevelSecondStage`) : `mult × niveau / 20`.
- Total dû (`VerifySpecPoints`) : part de `-1`, puis pour chaque niveau `i` de 1 à `Level` : `i` si `i <= 5` ; `mult × i / 10` si `i > 5` ; plus `mult × (i-1) / 20` si `i > 40` ; plus `mult × Level / 20` si `IsLevelSecondStage` et niveau ≠ `MAX_LEVEL`.
- Coût d'un point de compétence : monter de `n` à `n+1` coûte `n+1` (voir `commands/playercommands/train.cs:131-134`). Coût total d'une ligne au niveau `L` : `(L × (L+1) − 2) / 2` (`VerifySpecPoints`, ligne 10092), moins les points d'entraînement automatique (`GetAutoTrainPoints`).

**Formules (bots)**
- `GetSpecPointsForLevel` (`GameBot.cs:3374`) : `niveau > 5` → `mult × niveau / 10` ; sinon `niveau` si ≥ 2. En création directe à un niveau élevé (`botCreation`, écart de niveau > 1) et `niveau > 40` : ajoute `mult × (niveau − 1) / 20`.
- `SpendSpecPoints` (`GameBot.cs:3307`) répartit ces points selon `BotSpec.SpecLines` (plafond `SpecCap` et ratio `levelRatio` par ligne : voir `bots/specs/*`). Les points non dépensés sont gardés dans `m_leftOverSpecPoints`.

## 2. Le total de points est-il stocké en base ou recalculé ?

**Joueur : recalculé, jamais stocké.**
- Il n'existe pas de colonne « points de spécialisation » pour un personnage. La propriété `GamePlayer.SkillSpecialtyPoints` (ligne 3537) est `get { return VerifySpecPoints(); }` : points restants = total dû pour le niveau (calculé avec le multiplicateur) moins points dépensés (somme sur les lignes de `(niveau × (niveau+1) − 2) / 2`, moins l'entraînement automatique).
- Ce qui est stocké : le **niveau de chaque ligne**, dans la chaîne `SerializedSpecs` de `DbCoreCharacter` (`CoreDatabase/Tables/DbCoreCharacter.cs:1211`). Format : `NomClé|niveau;NomClé|niveau;…`. Écrit dans `GamePlayer.cs` autour de la ligne 9943 (`DBCharacter.SerializedSpecs = sp.ToString()`, construction de `sp` juste au-dessus) pour les lignes sauvegardables (`AllowSave`), lue au chargement par `HandleCharacterSkills` (ligne 10315 : `LoadClassSpecializations(false)`, puis lecture de la chaîne et application du niveau à chaque spécialisation connue, sans contrôle de coût à ce moment).
- Même principe pour les capacités (`SerializedAbilities`) et les capacités de royaume (`SerializedRealmAbilities`).
- Les sorts et styles actifs ne sont pas stockés : `RefreshSpecDependantSkills` (appelé à chaque montée de niveau, à l'entraînement et au chargement) les redérive du niveau de chaque ligne (`spec.GetAbilitiesForLiving`, `GetStylesForLiving`, etc.).

**Contrôle de cohérence au chargement** : `LoadFromDatabaseAsync` appelle `VerifySpecPoints()` à la fin (ligne 10160). Si les points dépensés dépassent le total dû (`allpoints < 0`) :
- compte joueur (`Client.Account.PrivLevel == 1`) : avertissement dans le journal (« Spec points total for player … incorrect ») puis `RespecAllLines()` (toutes les lignes remises à zéro, points rendus) ;
- compte GM ou admin (privilège ≠ 1) : aucune correction, les niveaux restent tels que stockés.

**Bots**
- Helpers `/spawn` et bots `/bot create` : rien n'est stocké. Les lignes sont reconstruites à chaque création par `SpendSpecPoints` selon le `BotSpec` tiré au hasard (voir `bots-spawn-ia.md`).
- Gamebots autonomes (`OfflineWorldBotRecord` dans `bots/autonomous/AutonomousBotEconomy.cs:945`) : stockent `SerializedSpecs` (lignes `clé|niveau`, écrit dans `GameBot.cs:3159`), `SerializedBuildPlan` et `UnspentSpecPoints`. Rechargés par `LoadPersistedSpecs` (`GameBot.cs:2375`) puis `RefreshSpecDependantSkills`.

## 3. Comment sait-on qu'un perso a N dans telle ligne, et peut-on le forcer en SQL ?

- Niveau d'une ligne : `GamePlayer.GetBaseSpecLevel(clé)` (ligne 3259) lit `m_specialization[clé].Level` en mémoire. `GetModifiedSpecLevel` (ligne 3279) y ajoute les bonus d'objets et de royaume. En mémoire, ces niveaux viennent de `SerializedSpecs` au chargement.
- **Forcer par SQL : possible mais conditionnel.** Modifier la chaîne `SerializedSpecs` du personnage (par exemple `Sword|50;Shields|50`) **serveur arrêté** (le serveur réécrit la colonne depuis la mémoire à chaque sauvegarde du joueur).
  - Le chargement applique le niveau lu sans vérifier le coût.
  - Si le total dépasse le budget du niveau, `VerifySpecPoints` remet tout à zéro pour un compte joueur (`PrivLevel == 1`) ; il le laisse intact pour un compte GM/admin. Pour que le niveau forcé survive sur un compte normal, soit le budget le permet (niveau et multiplicateur suffisants), soit le compte doit avoir un privilège ≠ 1 (colonne `PrivLevel` de la table des comptes).
  - Seules les clés existantes et sauvegardables sont reprises (`SkillBase.GetSpecialization(clé)` non nul et `AllowSave`) ; une clé inconnue est ignorée avec une erreur dans le journal (« can't find spec »).
  - L'entraînement normal (`train.cs`) interdit en plus un niveau de ligne supérieur à `BaseLevel` du joueur ; le chargement depuis la base ne vérifie pas ce plafond (non vérifié en jeu).
- Alternatives sans toucher au SQL : monter le multiplicateur de la classe (`m_specializationMultiplier`, effet immédiat sur le total dû à la prochaine vérification), ou ajouter une vérification de contournement dans `VerifySpecPoints`. Modifier le code est la seule voie pour un changement général ; le SQL convient pour un personnage précis.
- Pour les gamebots autonomes : même principe sur `SerializedSpecs` de leur enregistrement (`OfflineWorldBotRecord`), mais `BotLifetimeBuild.Restore/AlignWithInvestedWeapons` (`GameBot.cs:2376-2388`) peut réaligner le plan de build sur les armes investies ; effet d'un changement SQL non testé.

## 3 bis. Mettre toutes les lignes à 50 : quels sorts deviennent disponibles ?

- Les sorts d'une ligne dépendent du niveau de la spécialisation : `Specialization.GetLinesSpellsForLiving` (`gameutils/Specialization.cs:311`) garde les sorts avec `item.Level <= sl.Level`, et `sl.Level` est fixé au niveau de la spécialisation (ligne 198 : `ls.Item1.Level = level`). Les lignes de base reçoivent le niveau du personnage (lignes 179 et 187).
- Donc des lignes à 50 donnent tous les sorts de ces lignes jusqu'au niveau 50 (le chargement et `RefreshSpecDependantSkills` les redérivent). Aucun plafond par niveau du personnage n'a été vu dans ces méthodes.
- Seules les lignes propres à la classe existent : `LoadClassSpecializations` (`GamePlayer.cs:9953`, boucle ≈ 10027-10068) retire les spécialisations qui ne sont pas dans la carrière de la classe ; une ligne d'une autre classe écrite dans `SerializedSpecs` est ignorée ou retirée.
- Les lignes de spécialisation (non-base) ne sont exposées que pour une classe avancée (`HasAdvancedFromBaseClass`, ligne 170), donc pas avant la promotion.
- Cela annule le choix prévu par le jeu : normalement les points ne permettent de monter qu'une ou deux lignes (coût cumulé de `(L × (L+1) − 2) / 2` par ligne). Tout est contrôlé par ce budget (`VerifySpecPoints`), jamais par le contenu de la base elle-même.

## 3 ter. Requêtes SQL pour modifier les lignes d'un personnage

Noms de tables et colonnes déduits des attributs `[DataTable]` / `[DataElement]` du code (à confirmer avec `.schema` dans le client SQLite, aucune base n'est présente dans le dépôt). Base du jeu : `runtime/data/opendaoc.sqlite3.db` (voir `AGENTS.md`). Clé primaire = `<NomTable>_ID` (`CoreDatabase/DataObject.cs`, `DatabaseUtil.cs`).

| Rôle | Table | Colonnes utiles |
|---|---|---|
| Personnages | `DOLCharacters` (`DbCoreCharacter.cs:9`) | `DOLCharacters_ID` (identifiant technique), `Name`, `AccountName`, `Class`, `Level`, `SerializedSpecs`, `SerializedAbilities`, `SerializedRealmAbilities` |
| Comptes | `Account` (`DbAccount.cs:9`) | `Account_ID`, `Name`, `PrivLevel` (1 joueur ; `ePrivLevel` : `GameServer/Enums/ePrivLevel.cs`, 2 et 3 = GM et admin) |

Le lien personnage → compte est `DOLCharacters.AccountName = Account.Name`. Il n'y a pas de table séparée pour les niveaux de lignes : tout est dans la colonne `SerializedSpecs`.

Séquence (serveur arrêté, base sauvegardée) :
```sql
-- 1) retrouver le personnage, son identifiant, son compte et ses lignes actuelles
SELECT DOLCharacters_ID, Name, AccountName, Class, Level, SerializedSpecs
FROM DOLCharacters WHERE Name = 'MonPerso';

-- 2) vérifier le privilège du compte
SELECT Account_ID, Name, PrivLevel FROM Account WHERE Name = '<AccountName du résultat 1>';

-- 3) si PrivLevel = 1, sinon VerifySpecPoints remet les lignes à zéro au chargement
UPDATE Account SET PrivLevel = 2 WHERE Name = '<AccountName>';

-- 4) forcer les niveaux de lignes (même format que la valeur lue au 1) : clé|niveau;clé|niveau
UPDATE DOLCharacters
SET SerializedSpecs = '<clé1>|50;<clé2>|50;<clé3>|50'
WHERE DOLCharacters_ID = '<identifiant du résultat 1>';
```
- Procédure sûre : lire d'abord `SerializedSpecs` (étape 1) et ne changer que les nombres, pour réutiliser les clés exactes de la classe. Les noms de lignes sont les clés de `Specialization.KeyName` (constantes dans `GameServer/gameutils/SkillConstants.cs`, classe `Specs`, par exemple `"Slash"`, `"Sword"`, `"Shields"`, `"Parry"`, `"Chants"`, `"Body Magic"`, `"Matter Magic"`, `"Spirit Magic"`). Une clé inconnue est ignorée (erreur « can't find spec » dans le journal).
- Les lignes absentes de `SerializedSpecs` mais valides pour la classe (jamais entraînées) doivent y être ajoutées (`LoadClassSpecializations` les crée à 1 sinon, ligne par ligne).
- Les sorts et styles ne sont pas des lignes de base de données : ils se recalculent au chargement (`RefreshSpecDependantSkills`).
- Étape 3 : les comptes GM ont des effets annexes (commandes `/gm`, visibilité…) ; à rétablir à `1` après le test si l'on veut garder un joueur ordinaire (le niveau de ligne forcé sera alors remis à zéro à la connexion suivante).
- Pour un gamebot autonome : table de `OfflineWorldBotRecord` (nom non relevé, voir `AutonomousBotEconomy.cs:945`), même colonne `SerializedSpecs`.

## 3 quater. Ajouter un multiplicateur global configurable (ServerProperty)

**Les propriétés serveur existent toujours en SQLite.** Table `ServerProperty` (`CoreDatabase/Tables/DbServerProperty.cs:5`), colonnes `Category`, `Key` (clé primaire), `Description`, `DefaultValue`, `Value`. Chaque propriété est un champ statique de `GameServer/serverproperty/ServerProperties.cs` (classe `Properties`) portant un attribut, par exemple :
```csharp
[ServerProperty("rates", "xp_rate", "The Experience Points Rate Modifier ...", 1.0)]
public static double XP_RATE;
```
- Au démarrage (`InitProperties`), pour chaque champ trouvé, `Load` (ligne 2627) **crée la ligne en base si elle manque** (`AddObject`, valeur = valeur par défaut de l'attribut) puis lit `Value` et l'affecte au champ (conversion selon le type de la valeur par défaut ; format décimal `en-US`, donc `1.5`).
- Un changement de valeur en SQL ou dans la table se recharge **sans redémarrer** avec la commande admin `/serverproperties refresh` (`commands/admincommands/serverproperties.cs`, niveau Admin). Elle appelle `Properties.Refresh()` → `InitProperties()`.
- Précédent dans le projet : `ENABLE_SLUAGHBINDER` (`ServerProperties.cs:2132`, catégorie `classes`, clé `enable_sluaghbinder`) et `bot_xp_rate` (ligne 737). Les réglages propres à Offline DAoC peuvent aussi être dans `offline_population_settings`, `offline_local_options` et `runtime/server/bot-goals.json` (`AGENTS.md`).

**Point d'insertion unique pour le multiplicateur des points de compétences**
- Toutes les lectures du multiplicateur passent par `CharacterClassBase.SpecPointsMultiplier` (`gameobjects/CharacterClasses/CharacterClassBase.cs:164`, et `AdjustedSpecPointsMultiplier` ligne 173) : `GamePlayer.cs` lignes 4718, 4812, 10082, 10083, 10086 et `GameBot.cs` lignes 3380, 3383. Aucune classe finale ne surcharge ces propriétés (seul le champ `m_specializationMultiplier` est modifié dans les constructeurs).
- Donc **modifier ces deux getters suffit** ; inutile de toucher les ≈ 70 fichiers `Class*.cs`. Esquisse (non appliquée) :
  1. `ServerProperties.cs` : ajouter
     ```csharp
     [ServerProperty("rates", "spec_points_rate", "Multiplier applied to the specialization points gained per level (1.0 = classic, 2.0 = double).", 1.0)]
     public static double SPEC_POINTS_RATE;
     ```
  2. `CharacterClassBase.cs` : `get { return (int)Math.Round(m_specializationMultiplier * ServerProperties.Properties.SPEC_POINTS_RATE); }` dans les deux getters (ajouter la directive `using` utile ; le nom de l'espace `DOL.GS.ServerProperties` est utilisé ailleurs, par exemple `TemporaryGroupCommands.cs`).
  3. Compiler, tester, déployer (voir `compiler-et-deployer-le-serveur.md`). Au premier démarrage la ligne `spec_points_rate` apparaît dans la table `ServerProperty` avec la valeur 1.0 ; la modifier ensuite en SQL ou via l'admin puis `/serverproperties refresh`.
- Effets à garder en tête :
  - Le total dû est **recalculé** (`VerifySpecPoints`) : monter le multiplicateur donne immédiatement des points en plus aux personnages existants, sans migration ; le baisser peut faire passer des personnages en excès et déclencher le `RespecAllLines()` (compte joueur) à leur prochaine connexion.
  - Les calculs utilisent des divisions entières (`mult × niveau / 10`) : un taux de 1,5 reste cohérent car on arrondit d'abord le multiplicateur.
  - Les bots (`GameBot.GetSpecPointsForLevel`) passent par le même getter : leurs budgets augmentent aussi, donc leur construction (`SpendSpecPoints`) et celle des gamebots autonomes s'en trouvent modifiées. Si on ne veut changer que les joueurs, tester `living is GamePlayer` ou ajouter une seconde propriété pour les bots.
  - Plafonds inchangés : une ligne ne dépasse pas `BaseLevel` à l'entraînement (`train.cs:125`) ; un taux élevé n'offre donc pas de niveaux de ligne illimités, mais permet de monter toutes les lignes plus vite.

## 4. Pistes pour la suite (autre repo)

- Lire `GetAutoTrainPoints` et `GetAutotrainableSkills()` (points offerts gratuitement : niveau / 4 sur certaines lignes).
- Vérifier le nom réel de la table et de la colonne de `SerializedSpecs` dans la base SQLite du jeu (`runtime/data/opendaoc.sqlite3.db`) avant toute requête, et sauvegarder la base avant toute modification manuelle (règle d'`AGENTS.md` : ne jamais commiter une base jouée).
- Tester en jeu un `SerializedSpecs` forcé sur un compte joueur et sur un compte GM pour confirmer le comportement de `VerifySpecPoints`.
