# Bots invoqués par `/spawn` : commande, IA et points de modification

Notes de recherche sur le dépôt Offline DAoC (fork OpenDAoC, .NET 10, SQLite).
But : servir de base pour des recherches futures sur un autre repo. Aucun code du dépôt n'a été modifié.
Chemins relatifs à la racine du dépôt. Numéros de ligne relevés sur le dépôt à la date de l'analyse (commit `abb58da`) : à revérifier.

Non lu en détail : la machine à états `FSM` (états IDLE, AGGRO…), `AttackMostWanted`, `GameBot` hors constructeur.

## 1. La commande `/spawn`

| Élément | Fichier |
|---|---|
| `/spawn [classe]` (joueur) | `source/server/GameServer/commands/playercommands/TemporaryGroupCommands.cs:181`, classe `SpawnTemporaryGroupBotCommandHandler` |
| `/classes` (liste des classes invocables) | même fichier, ligne 166 |
| Catalogue des classes autorisées (Classic + SI) | `TemporaryGroupClassCatalog` |
| Menu de choix sans argument | `TemporaryGroupSpawnMenu` |
| `/bot create\|spawn\|despawn\|follow\|stay\|hold\|resume\|stance\|invite\|list\|delete` | `source/server/GameServer/bots/BotCommand.cs` |
| `/raid`, `/defensive`, `/aggressive` | `commands/playercommands/CompanionRaidCommand.cs`, `CompanionEngagementCommands.cs` |

Les commandes sont des classes avec l'attribut `[CmdAttribute("&nom", ePrivLevel, description, usage)]`, implémentant `ICommandHandler` (dossiers `playercommands/`, `gmcommands/`, `admincommands/`).

`SpawnTemporaryGroupBotCommandHandler.Spawn(...)` (ligne 210) :
1. Vérifie que la classe est dans le catalogue du royaume du joueur et que le groupe n'est pas plein.
2. Tire une identité : `AutonomousBotIdentityGenerator.GenerateForClass(realm, gender, class)`.
3. Choisit le niveau d'équipement : entre `niveau-10` et `niveau` du joueur, ou 50 si le joueur est niveau 50.
4. Crée `new GameBot(player, classId, name, race, gender, temporaryGroupHelper: true, equipmentLevel: gearLevel)`.
5. Calcule une position à 110–220 unités du joueur, ramenée sur le navmesh (`PathfindingProvider.Instance.GetMoveAlongSurface`).
6. `AddToWorld()`, puis ajoute le bot au groupe du joueur (création du `Group` si besoin).

Un `/spawn` crée un « helper temporaire » (`IsTemporaryGroupHelper`), distinct des compagnons persistants et des gamebots autonomes.

## 2. Classes qui portent l'IA

- **`GameBot`** (`source/server/GameServer/bots/GameBot.cs:32`) : hérite de `GameNPC`, implémente `IGamePlayer`. Corps du bot : stats, spécialisations, styles, sorts, équipement. Le constructeur (≈ lignes 2285–2318) appelle `SetBotSpells()`, `SortStyles()`, `SortSpells()`, `EquipBot()`, puis installe le cerveau :
  `SetOwnBrain(temporaryClass == Sluaghbinder ? new SluaghbinderBotBrain() : new BotBrain())`.
  `InitControlledBrainArray(1)` est réservé à un vrai familier de classe.
- **`BotBrain`** (`bots/BotBrain.cs:21`, classe `partial`, hérite de `ABrain`) : le cerveau. `ThinkInterval = 500`, `AggroRange = 3600`. Extensions : `BotBrain.PvpCrowdControl.cs`, `BotBrain.BardPveCrowdControl.cs`, `BotBrain.ShamanPveRoot.cs`.
- **`SluaghbinderBotBrain`** (`bots/Sluaghbinder/SluaghbinderBotBrain.cs`) : exemple de cerveau dérivé de `BotBrain`.
- **Politiques statiques par sujet** (`bots/`) : `BotMeleeStylePolicy`, `BotCasterPriority`, `BotRangedCombat`, `BotPvpCrowdControl`, `BotSongTwistPolicy`, `BardBotCrowdControlPolicy`, `ShamanBotCombatPolicy`, `SavageBotCombatPolicy`, `MinstrelBotCombatPolicy`, `SluaghbinderBotPolicy`, `BotGroupSupport`, `BotPartyRoles`, `BotRestRecovery`, `CompanionFollowPolicy`, `CompanionEngagementMode`, `BotBuffReservations`, `BotSpellPower`, `BotWeaponStats`.
- **Spécifique aux helpers `/spawn`** : `TemporaryCompanionBalance`, `TemporaryCompanionRecovery`, `TemporaryCompanionPetHealing`, `TemporaryGroupStableTravel`.
- **Gamebots autonomes** (hors `/spawn`) : `bots/autonomous/` (≈ 160 fichiers : buts, camps, groupes, déplacement, watchdog). `AutonomousFidelityPolicy` et `AutonomousAiBudget` y règlent la cadence de réflexion.

Les trois populations partagent `BotBrain`. Drapeaux à tester pour limiter la portée d'un changement : `IsTemporaryGroupHelper`, `IsAutonomousWorldBot`, `IsPlayerLedGroup`.

## 3. Boucle de décision : `BotBrain.Think()` (`BotBrain.cs:1198`)

Exécutée toutes les `ThinkInterval` ms. Chaque étape peut faire `return`. Ordre de priorité :

1. Suivi et annulation de buffs (`CompanionFollowPolicy.ObserveAndCancelBuffs`), portée d'engagement (`EnforceCompanionEngagementRange`).
2. Aide au joueur : `CompanionEngagementMode.NearbyPull` puis `AssistPlayerAttack`.
3. Fourniture de poison, récupération de l'invocateur, cible d'un animiste, activité du chef.
4. Watchdog anti-blocage (`AutonomousStuckWatchdog.Observe`), capacités de royaume (`AutonomousBotRealmAbilities.UseActives`).
5. Trajet de stablemaster : prend la main sur tout le reste tant qu'il dure.
6. `CompanionPvpEngagement`, siège de raid (`CompanionRaidSiege.Think`).
7. Menace frontalière (gamebots seulement), pull défensif (`AutonomousDefensivePull.Hold`).
8. Helpers `/spawn` : retour vers le chef, résurrection du propriétaire.
9. Attente de pull (`PlayerLedPullCoordinator`), assistance sur la cible du chef.
10. Repos des helpers parqués (`TryMaintainTemporaryCompanionRest`), puis détermination du mode et de la fidélité (`CurrentThinkMode`, `CurrentFidelity`) et calcul de `ThinkInterval`.
11. Chants de barde (`TryMaintainClassicSongTwist`, `TryMaintainTankChant`), entretien des buffs de voyage et de classe (`TryMaintainTravelAndClassBuffs`), familiers (`AutonomousPetSupport`).
12. Combat via `FSM.Think()`.

Méthodes de combat à connaître (`BotBrain.cs`) : `AttackMostWanted()` (2954), `CheckSpells(eCheckSpellType)` (3777), `CheckOffensiveSpells` (4123), `CheckDefensiveSpells` (4263), `CheckHeals()` (4740).

## 4. Où modifier quoi

**Réactivité**
- Cadence : `AutonomousFidelityPolicy.IntervalMilliseconds(mode, fidelity, onlineBots)` (`bots/autonomous/AutonomousFidelityPolicy.cs:30`).
  - Combat : `baseline` (de `AutonomousAiBudget`) près d'un humain, 350 ms en `Standard`, 500 ms sinon.
  - Hors combat : `baseline` × 1,0 / 1,6 / 2,6 selon la fidélité, plus un ralentissement en cas de forte population (> 300 bots).
- Distances : `AggroRange` (3600), `GROUP_DEFENSE_ASSIST_RADIUS`.

**Styles de mêlée** : `BotMeleeStylePolicy` (`bots/BotMeleeStylePolicy.cs`)
- `IsEligible` exclut les styles positionnels et furtifs.
- `Usable` vérifie niveau, arme, endurance, étourdissement et enchaînement.
- `Better` préfère le plus fort `GrowthRate`, puis le plus haut niveau.
- `Select` conserve le style déjà en file (`preserveQueued`) et fixe un style de secours « anytime ».

**Sorts** : `BotCasterPriority` (`IsDamage`, `AllowInstant`), `CheckOffensiveSpells`, `CheckDefensiveSpells`. Le tri vient de `SortSpells()` / `SortStyles()` dans `GameBot`.

**Soins et buffs** : `CheckHeals`, `BotGroupSupport`, `TryMaintainTravelAndClassBuffs`.

**Comportement propre à une classe** : soit une politique dédiée (modèle `ShamanBotCombatPolicy`), soit un cerveau dérivé de `BotBrain` branché au `SetOwnBrain` de `GameBot` (modèle `SluaghbinderBotBrain`).

## 5. Contraintes du projet (extraits d'`AGENTS.md`)

- Ne jamais démarrer un serveur ni déployer sans permission ; un seul serveur sur le port 10300.
- Build et tests séparés : `dotnet build "source/server/Dawn of Light.sln" -c Release`, puis `dotnet test source/server/Tests/Tests.csproj -c Release`. Déployer `GameServer.dll` après sauvegarde, dans `runtime/server`, `runtime/server/lib`, `runtime/server/win-x64`.
- Règles de jeu à préserver : loot et inventaires réels, Realm Exchange, routes de stablemaster, vente seulement aux pauses naturelles, gamebots sans armure au départ, Darkness Falls ouvert aux bots solo.
- Distinguer joueurs réels, compagnons et gamebots autonomes.
- Rapports honnêtes : tests automatisés et vérifications en jeu séparés.

## 6. Observation en jeu : les mages sans mana frappent au bâton

Constat (test en jeu) : les lanceurs de sorts dépensent leur mana, puis vont au corps à corps avec leur bâton. Souhait : rester en retrait, éventuellement s'asseoir, pour régénérer. Risque de s'asseoir : coups reçus toujours critiques, plus de parade/esquive/blocage.

**Ce n'est pas un bug : c'est un comportement codé volontairement** (`bots/BotBrain.cs`).

Chaîne de décision dans `AttackMostWanted()` :
- `PrefersCurrentSpellRange()` (ligne 783, via `PrefersSpellRange` ligne 775) : vrai pour tout `eClassType.ListCaster` sauf Valewalker, Vampiir et Shaman (le Shaman alterne déjà sorts et mêlée, voir `ShamanBotCombatPolicy`).
- `OutOfPowerForOffense()` (ligne 3390) : vrai si le bot connaît des sorts offensifs utilisables (niveau, cible ennemie, hors charme/amnésie/confusion/taunt, hors sorts « surclassés » `IsOutclassedDamageSpell`) et que **le coût de chacun dépasse le mana actuel** (`OutOfPower(costs, mana)`, ligne 3378, statique et testée).
- `TryOutOfPowerMelee(target)` (ligne 3440) : appelée à la ligne 3148 pour un lanceur sans mana. Elle équipe l'arme de mêlée (`SwitchToUsableMeleeWeapon`), utilise les capacités offensives, envoie le familier, file un style (`QueueUsableMeleeStyle`) et lance `StartAttack(target)`, ce qui fait courir le mage vers la cible. Exclut le Nécromancien (l'ombre n'a pas de mêlée). Commentaire du code : « walks in and fights with its staff … then casts again as soon as it can pay for a spell ».
- Lignes 3069 et 3079 : le chemin « sans mana » désactive aussi le `StopFollowing()` et le `StopAttack()` appliqués aux mages normaux.
- Test existant : `source/server/Tests/UnitTests/UT_OutOfPowerCasterMelee.cs` (à lire avant toute modification).

Deuxième déclencheur, distinct : `TryEngageUnderMeleePressure(target)` (ligne 3336). Si la cible est à portée de mêlée + 35 et que le mage est réellement attaqué (`IsBeingInterruptedByOther`, ou attaquant direct dans les 5 s), il arrête son incantation et se bat au bâton. Ce comportement défensif n'est pas lié au mana.

**S'asseoir : ce qui existe déjà**
- Les `GameBot` ne s'asseyent jamais visuellement. Commentaire dans `GameBot.cs` (≈ 275 et 2506) : « never expose GameLiving.IsSitting to clients ». Le repos est un verrou logique `_recoveryRestLocked` (`IsRecoveryResting`).
- `IsEnhancedResting` (`GameBot.cs:289`) = repos verrouillé, immobile, et `!BotRestRecovery.BlocksRest(this)` ; ou `ShouldAutonomousPlayerBotRecover` (gamebots autonomes seulement). Il règle l'intervalle de régénération (1 s) et `BotRestRecovery.RecoveryAmount` donne au minimum 10 % du maximum par tick.
- `BotRestRecovery.BlocksRest` interdit le repos si le bot est en combat, a de l'aggro, incante, est contrôlé (CC), ou si un membre proche du groupe est en combat (fenêtre de calme : 2 s, `QuietMilliseconds`).
- Entrée en repos : `BeginRecoveryRest()` / `BeginTemporaryCompanionRest()` (helpers `/spawn`, seulement quand le joueur est immobile et que le bot est près de lui). Sortie : `WakeRecoveryRest()`, appelée dès qu'un combat survient.
- Conséquence : **en plein combat, le repos amélioré est impossible par construction** (`BlocksRest`). Un mage sans mana ne peut donc pas régénérer plus vite sans modifier cette règle.
- Comme le bot n'est jamais « assis » côté jeu, le risque cité (coups critiques, pas de parade/esquive/blocage) ne s'applique pas à un repos logique. Il ne s'appliquerait que si on introduisait une vraie posture assise.

**Pistes de modification (dans un autre repo, pour étude)**
1. Remplacer `TryOutOfPowerMelee` par un repli : `StopAttack()`, reculer hors de portée de la cible ou rester près du groupe, et attendre la régénération. Garder `TryEngageUnderMeleePressure` pour se défendre.
2. Limiter la mêlée sans mana à certains cas (groupe sans tank, bot seul, cible presque morte) plutôt que tous les cas.
3. Pour un repos en combat : assouplir `BotRestRecovery.BlocksRest` pour les lanceurs sans mana dont la cible est éloignée ou engagée par un tank. Nécessite de décider du gain de régénération en combat (`GetHealthAndPowerRegenerationInterval`, `ClassicRestRegeneration.HealthAndPowerInterval`).
4. Une vraie posture assise (`GameLiving.IsSitting`) est exclue aujourd'hui côté client. L'introduire demanderait de gérer les malus de défense et de relever le bot dès qu'une menace s'approche.
5. Distinguer les trois populations : `IsTemporaryGroupHelper` (`/spawn`), `IsPlayerLedGroup`, `IsAutonomousWorldBot`. `PrefersCurrentSpellRange` passe déjà `grouped` et `autonomous` en paramètres.

Hypothèse non vérifiée : l'observation « 95 % inutile » dépend des dégâts réels du bâton ; je n'ai pas mesuré cela dans le code ni en jeu.

## 7. Observation en jeu : les soigneurs collés au joueur en mêlée

Constat : en jouant une classe de mêlée, les soigneurs restent collés au joueur dès que le combat s'engage et attirent les monstres. Question : peut-on les configurer pour qu'ils restent un peu en retrait ?

**Réponse courte : aucun réglage existant ne fait cela.** La distance au joueur est codée en dur et appliquée même en combat.

Ce qui fixe la position (`bots/BotBrain.cs`) :
- Un soigneur ou un support (`BotPartyRoles.IsSupport`, `HoldsExclusiveSupportRole()` ligne 796) passe par `PerformGroupSupport()` (ligne 3561) : `HoldSupportCombat()` (arrête ses attaques), soins, sorts défensifs, puis, s'il n'incante pas, `FollowFormation()` (ligne 1090). Ce suivi est donc exécuté **à chaque pulsation, y compris en plein combat**.
- `FollowFormation()` envoie le bot vers un point à `AutonomousFormation.For(nom, donjon)` du joueur (`bots/autonomous/AutonomousBotDecisionEngine.cs:439`) : distance = 30 % de l'ancienne valeur, soit 63 à 156 unités en extérieur, 40 à 81 en donjon, avec un angle fixé par le hachage du nom du bot. Tolérance d'arrivée : 20 unités.
- Raid de compagnons (`CompanionRaid.IsMember`) : autres emplacements via `TemporaryGroupStableTravel.FormationPoint` (rayon 180, constante `FormationRadius`, ligne 25) ou `CompanionRaidFormation.Slot`.
- `CompanionFollowPolicy` (`bots/CompanionFollowPolicy.cs`) ne gère que les buffs différés et la vitesse de rattrapage ; il ne contient aucune distance de sécurité.
- `BotSupportReach` : un support marche vers un membre hors de portée de sort, jusqu'à 2500 unités (`SupportRadius`).

Réglages existants et leurs limites :
- `/bot stance <auto|melee|ranged|passive> [nom]` (`BotCommand.HandleStance`, `eBotStance` dans `GameBot.cs:24`). Seul `Passive` a un effet visible dans le cerveau : dans l'état de combat (≈ `BotBrain.cs:2907`), le bot ne fait que `CheckHeals()` puis revient, sans attaque, sans sorts défensifs et sans appeler `PerformGroupSupport`/`FollowFormation`. Je n'ai pas vérifié si un bot en `Passive` reste sur place ou si un autre état le fait suivre. Ce n'est de toute façon pas un réglage de distance. Reste à vérifier : si `/bot stance` agit sur les helpers `/spawn` (la résolution de cible exige `bot.Owner == joueur`).
- `/defensive` et `/aggressive` (`CompanionEngagementMode`, `DefensiveRadius = 350`) ne limitent que les cibles que les helpers acceptent d'attaquer, pas leur position.

Les monstres choisissent leur cible côté mob (aggro). Un soigneur proche du joueur reçoit les coups des monstres qui visent le joueur ou qui sont attirés par les soins. `FindProtectionTarget()` (ligne 3644) fait déjà réagir les tanks bots pour protéger les alliés, mais pas les soigneurs eux-mêmes.

**Pistes de modification (pour l'autre repo)**
1. Dans `FollowFormation()`, quand le bot est un support et que `Body.InCombat` ou que le joueur est en combat, utiliser un décalage plus grand, dans le dos du joueur (opposé à la cible ou au cap du joueur), en restant sous la portée des soins. Il faut lire la portée réelle des soins (`Spell.Range`) pour ne pas laisser le soigneur hors de portée, et `BotSupportReach` qui le ramène vers le groupe.
2. Ajouter une valeur configurable par joueur (comme `CompanionEngagementMode` : table faible par `GamePlayer`) et une commande dédiée (par ex. `/bot stance` étendu, ou `/backline`).
3. Tester avec les trois populations : le décalage ne doit s'appliquer qu'à `IsPlayerLedGroup` (les gamebots autonomes ont leur propre formation dans `AutonomousBotGroupCoordinator`).
4. Vérifier les chemins de repli : repos, retour au chef (`TryReturnTemporaryCompanionToLeader`), résurrection du propriétaire, qui peuvent aussi ramener le bot près du joueur.

À vérifier (non lu) : la machine à états `FOLLOW` (ce qu'elle fait entre deux combats), la portée réelle des sorts de soin, et le test `UT_*` éventuel sur la formation.

## 8. Influencer le « template » d'une classe au spawn (Warrior/Paladin et bouclier)

Question : peut-on forcer un Warrior ou un Paladin à avoir un score de bouclier élevé et à jouer avec bouclier plutôt qu'avec une deux-mains ?

**Oui, c'est faisable et le point d'entrée est unique.** Le « template » est la spécialisation tirée au hasard à la création du bot.

Chaîne au spawn d'un helper `/spawn` :
1. `GameBot` (constructeur, `bots/GameBot.cs` ≈ 2285-2296) : `BotSpec.GetSpec(classe, BotSpec.ChooseRandomSpecialization(classe))`, puis `LoadClassSpecializations`, `SpendSpecPoints(Level, 0)`, `RefreshSpecDependantSkills`, `SetBotSpells`, `SortStyles`, `EquipBot(niveauEquipement)`.
2. `BotSpec.ChooseRandomSpecialization` (`bots/specs/BotSpec.cs:114`) tire uniformément dans `GetSpecializationChoices(classe)` (ligne 79). Pour Warrior : `[OneHandAndShield, TwoHanded]` (50/50). Pour Paladin : `[OneHandAndShield, TwoHandHybrid]` (50/50). Même principe pour Armsman, Hero, Champion, Thane, Skald, etc. Les bots persistants utilisent `ChoosePersistentSpecialization(classe, botId)` (hachage stable de l'identifiant).
3. Le constructeur de spec détermine les lignes de compétences et le drapeau `Is2H` :
   - `bots/specs/Midgard/Warrior.cs` : si `spec == TwoHanded`, variante 2 (pas de bouclier, Parry 49). Sinon `Util.Random(1)` : variante 0 = Shields 42 / Parry 39, variante 1 = Shields 50 / Parry 28. Donc **avec `OneHandAndShield`, 50 % des Warriors ont Shields 50, 50 % ont 42**. L'arme de base (Sword/Axe/Hammer) est tirée au hasard.
   - `bots/specs/Albion/Paladin.cs` : `OneHandAndShield` donne `Util.Random(2, 7)` : cas 2, 3, 6, 7 = Shields 42 ; cas 5 = Shields 42 ; cas 4 = **Shields 50** (arme 29, Chants 46). Soit environ 1 Paladin sur 6 avec Shields 50. Les cas 0 et 1 sont les deux-mains (`TwoHandHybrid`, `Is2H = true`).
4. Équipement (`GameBot.EquipBot`, ≈ 3877-3914 et `SetWeapons` ≈ 3975-4042) : pour `OneHandAndShield`, seule une arme à une main est équipée en main droite (`BotEquipment.SetMeleeWeapon(..., oneHand)`). Le bouclier est ajouté si `includeOffhand`, calculé par `TemporaryCompanionBalance.EquipOffhand(temporaire, niveau, permis, jet)` = `!temporaire || permis`, avec `permis = ... || BestShieldLevel > 0` (`BestShieldLevel => GetAbilityLevel("Shield")`, ligne 3875). La taille du bouclier vient de `BestShieldLevel` via `BotEquipment.SetShield` (`bots/BotEquipment.cs:280`).
5. Choix de l'arme active en combat : `BotBrain.SwitchToUsableMeleeWeapon()` (ligne 3487) utilise `PreferTwoHandedSlot` avec `BotSpec.Is2H`. Avec une spec bouclier (`Is2H = false`), le bot garde l'emplacement standard (une main + bouclier) tant qu'il a une arme à une main utilisable, et ne passe à la deux-mains que si celle-ci est la seule utilisable.

**Où modifier pour imposer bouclier, pour l'autre repo**
- Option la plus simple : restreindre `GetSpecializationChoices` (ou `ChooseRandomSpecialization`) pour Warrior et Paladin à `OneHandAndShield`. Rien d'autre n'est à changer côté équipement ou IA.
- Option « bouclier au maximum » : dans `WarriorBotSpec`, n'accepter que la variante 1 (Shields 50) ; dans `PaladinBotSpec`, forcer le cas 4 (au prix de Chants 46 et de l'arme à 29, ce qui change l'équilibre : les chants sont le cœur du Paladin).
- Option configurable : ajouter un paramètre au `/spawn` (ex. `/spawn warrior shield`) en prolongeant `SpawnTemporaryGroupBotCommandHandler.Spawn` (`TemporaryGroupCommands.cs:210`) et le constructeur de `GameBot` (paramètre `eSpecType` optionnel) pour remplacer le tirage au hasard.
- Les trois populations n'ont pas le même chemin : helpers `/spawn` (`ChooseRandomSpecialization`), bots persistants (`ChoosePersistentSpecialization`), gamebots autonomes (générés par `AutonomousBotIdentityGenerator`, non lu ici). Vérifier lesquels sont visés.

**Points à vérifier avant de modifier** (non lus) : `SpendSpecPoints` et `LoadClassSpecializations` (comment les plafonds de 42/50 se traduisent aux niveaux inférieurs à 50), `UT_TemporaryCompanionBalance.cs` (test existant sur `EquipOffhand`), et les tests sur les specs.

## 9. Choisir la spécialisation dans `/spawn` (fenêtre) ou via `/bot create`

**Menu `/spawn` actuel** (`commands/playercommands/TemporaryGroupCommands.cs`) :
- `TemporaryGroupSpawnMenu` (ligne 53) est un PNJ invisible créé pour le joueur. `BuildMenuText(realm)` écrit les noms de classe entre crochets, que le client 1.65 transforme en liens cliquables (fenêtre de dialogue de PNJ, `CL_PopupWindow`).
- Un clic envoie le texte du lien en chuchotement au PNJ : `WhisperReceive(source, text)` (ligne 113) résout la classe avec `TemporaryGroupClassCatalog.TryResolve(royaume, texte, out classe)` puis appelle `SpawnTemporaryGroupBotCommandHandler.Spawn(client, classe)`, et rouvre le menu (le client le ferme après un clic).
- `Spawn(client, classe)` (ligne 210) ne transmet **aucune spécialisation**. Le constructeur `GameBot(owner, classId, name, raceId, genderId, temporaryGroupHelper, equipmentLevel, botLevel)` (`GameBot.cs:2252`) tire ensuite la spécialisation au hasard (lignes 2284-2289).

**Ajouter un second écran « spécialisation » : faisable, sans changement côté client**
1. Dans `WhisperReceive`, mémoriser la classe cliquée (champ du PNJ de menu, par exemple `_pendingClass`) et envoyer un second texte de liens construit à partir de `BotSpec.GetSpecializationChoices(classe)` (`bots/specs/BotSpec.cs:79`). Exemple pour Warrior : `[OneHandAndShield] [TwoHanded]`.
2. Au chuchotement suivant, si une classe est en attente et que le texte correspond à une valeur de `eSpecType` (`bots/specs/BotSpecType.cs`), lancer le spawn avec cette spécialisation. Ajouter un lien « Random » pour garder le comportement actuel.
3. Ajouter un paramètre `eSpecType? spec = null` à `Spawn(...)` et au constructeur `GameBot`, et remplacer `BotSpec.ChooseRandomSpecialization(classe)` par `spec ?? ChooseRandomSpecialization(classe)` aux lignes 2285-2289 (Bonedancer et Sluaghbinder ont leur propre constructeur de spec : même remplacement).
4. Les liens du second écran doivent avoir des noms qui ne rentrent pas en collision avec les noms de classe, car le texte reçu est interprété par `TryResolve`. Les valeurs de `eSpecType` sont techniques (`OneHandAndShield`, `MendHealer`…) : prévoir des libellés lisibles et une table libellé → `eSpecType`.
5. Variante texte : `/spawn <classe> <spec>` en prolongeant le découpage de `args` dans `OnCommand` (ligne 184).
Limites vues : le client n'affiche que du texte et des liens ; le menu est un PNJ de 10 minutes (`MenuLifetimeMilliseconds`). Je n'ai pas vérifié le nombre maximal de liens ou de lignes que la fenêtre supporte. Un nombre de choix par classe de 2 à 4 (`GetSpecializationChoices`) est raisonnable.

**`/bot create` actuel** (`bots/BotCommand.cs:87`) : `/bot create <nom> <classId> <raceId> <genderId>` (ids numériques, classId limité à 1-50 par une validation codée en dur, donc le Sluaghbinder 63 est exclu). Appelle `BotManager.CreateBot` (`BotManager.cs:42`, limite 15 bots par joueur) → même constructeur `GameBot` (donc **même tirage aléatoire**), puis `SaveToDatabase()` (`GameBot.cs:4639` : ignoré pour un helper `/spawn`, sinon `BotDatabase.SaveBot`), puis spawn, groupe et suivi.
- Problème constaté dans le code : `BotDatabase.LoadBotByName/Load` (`bots/database/BotDatabase.cs:79`) recrée `new GameBot(owner, profile.ClassId, profile.Name, profile.RaceId, profile.GenderId, …)` à partir du profil. Aucune mention de spécialisation dans ce fichier (je n'ai pas lu `BotProfile` dans son détail) : la spécialisation semble donc **retirée au hasard à chaque rechargement** d'un bot `/bot create`. À confirmer.
- Pour faire mieux avec `/bot create` : ajouter un champ de spécialisation à `BotProfile` / `bot_profiles` (migration de table), l'accepter en argument (`/bot create <nom> <classe> <race> <genre> [spec]`, avec les noms de classe et de spec au lieu des ids), le passer au constructeur et le relire au chargement. C'est plus lourd que le menu `/spawn`, mais le choix devient permanent.
- Différence de nature : `/spawn` = helper temporaire sans sauvegarde (`IsTemporaryGroupHelper`) ; `/bot create` = compagnon persistant, 15 maximum.

**Persistance d'un bot `/bot create`** (lu dans `bots/database/BotDatabase.cs` et `BotManager.cs`) :
- Oui, le bot est enregistré en base : `BotProfile` (table `bot_profiles` : propriétaire, nom, classe, race, genre, niveau, `IsActive`) et `BotSettings` (distance de suivi, stance dans `CombatMode`, seuil de soin, cible préférée). Écrit par `BotDatabase.SaveBot` lors de `/bot create`.
- `/bot despawn` retire le bot du monde mais le garde en base (`IsActive = false`) ; `/bot delete` le supprime (`BotManager.DeleteBot`).
- Réapparition à la connexion : `BotManager.RespawnBotsOnLogin` (événement `GameEntered`) recharge les profils actifs, les replace près du joueur, les groupe et les fait suivre.
- À la déconnexion du propriétaire, `GameBot.OnOwnerQuit` retire le bot du monde (`BotManager.RemoveBot`) sans le supprimer en base ; un helper `/spawn`, lui, est supprimé (`Delete()`).
- **Ce qui n'est pas sauvegardé** : spécialisation, équipement, inventaire, expérience, position. `LoadBot` recrée un `new GameBot(...)` à partir du profil, donc spécialisation tirée au hasard et équipement régénéré à chaque chargement ; le niveau est relu depuis `Level` (écrit seulement à la création, sauf autre sauvegarde non trouvée dans ces fichiers).
- À ne pas confondre avec les gamebots autonomes, qui ont leur propre persistance complète (`OfflineWorldBotRecord` : `SerializedSpecs`, `SerializedBuildPlan`, inventaire, XP, position) et utilisent `ChoosePersistentSpecialization`.

**Recommandation** : commencer par le menu `/spawn` à deux écrans (peu de code, pas de migration), puis traiter `/bot create` seulement si le besoin de persistance se confirme.

## 10. Pistes pour la suite

- Lire la machine à états (`FSM`, états AGGRO/IDLE) et `AttackMostWanted`.
- Lire `GameBot.cs` en entier (équipement, `BotSpec`, spécialisations).
- Lire `TemporaryGroupClassCatalog` et `TemporaryGroupSpawnMenu` (hors `/spawn` direct).
- Cartographier `bots/autonomous/` (buts, camps, groupes) si l'autre repo s'intéresse aux gamebots.
