# Carte du dépôt Offline DAoC (vue d'ensemble pour recherches futures)

Synthèse tirée de `AGENTS.md`, `docs/DEVELOPMENT.md`, `docs/LLM-QUICKSTART.md`, `source/server/AGENTS.md` et d'un survol des dossiers (listes de fichiers, comptages). Aucun code n'a été modifié ni exécuté.
Chemins relatifs à la racine du dépôt. Comptages relevés au commit `abb58da` : à revérifier.

Non lu en détail : le contenu de la plupart des fichiers cités ici. Cette carte dit **où chercher**, pas **comment ça marche**. Pour le comportement, voir les autres notes (`README.md` de ce dossier).

## 1. Les grands blocs

| Bloc | Chemin | Contenu |
|---|---|---|
| Serveur de jeu | `source/server` | Solution `Dawn of Light.sln`, .NET 10, fork d'OpenDAoC-Core |
| Outils et lanceur | `source/tools` | Lanceur WinForms, patcher, import de progression, scripts Python de release |
| Nouveau client | `source/new-client` | Godot 4 (GDScript + client réseau C#), pipeline de contenu |
| Outils d'art client | `tools/` | `pet-art`, `asset-tool`, `claude-version` (aides base et client) |
| Référence | `source/reference` | `client-launcher`, `daocportal` (non explorés) |
| Mesh de navigation | `source/development-tools` | `OpenDAoC-BuildNav`, `OpenDAoC-Core` |
| Docs du projet | `docs/` | Guides joueur et développeur ; `docs/history/` pour les anciennes versions |
| Docs perso | `docs_ggr/` | Ces notes |
| Anciennes versions | `older-versions/`, `package-files*/` | Non explorés |

## 2. Le serveur (`source/server`)

Projets de la solution :

| Dossier | Rôle |
|---|---|
| `CoreBase/` | Utilitaires : journalisation (log4net), réseau, threads, minuteries, fichiers MPK |
| `CoreDatabase/` | ORM maison : `DataObject`, `ObjectDatabase`, `SqlObjectDatabase`, 102 fichiers dans `Tables/` (une classe par table) |
| `CoreServer/` | Point d'entrée (`MainClass.cs`), `config/serverconfig.example.xml` |
| `GameServer/` | Toute la logique de jeu (≈ 2 580 fichiers `.cs`). C'est là que se fait presque tout le développement |
| `Pathing/` | Bibliothèque de navigation (Detour) |
| `Tests/` | NUnit : `UnitTests/` (≈ 270 fichiers `UT_*.cs`) ; les listes `UnitTest.playlist`, `Integration.playlist` |
| `docs/reports/` | Rapports d'audit datés (par ex. `2026-09-11-audit-fixes.md`) |

### Dans `GameServer/` (premier niveau)

| Dossier | À chercher ici |
|---|---|
| `bots/` | Compagnons (`GameBot`, `BotBrain`, `BotCommand`, `BotManager`), politiques par sujet, `specs/` (spécialisations par royaume), `database/` (`BotProfile`, `BotSettings`, `BotDatabase`), `Sluaghbinder/` |
| `bots/autonomous/` | 158 fichiers : gamebots autonomes (buts, camps, groupes, trajets, RvR, sièges, Darkness Falls, raids de royaume, événements, chat, économie, watchdog). Données JSON/TXT dans `data/` |
| `commands/` | Commandes : `playercommands/` (133 fichiers), `gmcommands/` (56), `admincommands/` (13). Attribut `CmdAttribute`, interface `ICommandHandler` |
| `gameobjects/` | PNJ, joueurs, objets du monde (`GameLiving`, `GameMerchant`, `GameDoor`, `GameGuard`, `GameEpicBoss`…), classes spéciales (`Animist/`, `Bonedancer/`, `Atlantis/`) |
| `playerclasses/` | Une classe de personnage par fichier, par royaume (`albion/`, `hibernia/`, `midgard/`, `base/`) |
| `ECS-Components/`, `ECS-Services/`, `ECS-Effects/`, `ECS-Debug/` | Architecture entité-composant. Services : `GameLoopService`, `AttackService`, `CastingService`, `MovementService`, `NpcService`, `EffectService`, `ZoneService`, `TimerService`, `ReaperService`, quêtes périodiques… |
| `spells/`, `styles/`, `effects/`, `realmabilities/` | Sorts, styles, effets, capacités de royaume |
| `propertycalc/` | Calcul des propriétés (stats, résistances, régénération…) |
| `packets/` | Protocole client (paquets par version) |
| `keeps/`, `relics/`, `minotaurrelics/`, `housing/` | RvR : forts, reliques, maisons |
| `quests/`, `craft/`, `trainer/`, `playertitles/` | Quêtes, artisanat, entraîneurs, titres |
| `serverproperty/` | `ServerProperties.cs` : réglages serveur déclarés par attribut `[ServerProperty]` (par ex. `ENABLE_SLUAGHBINDER`) |
| `database/` | `DOLDB.cs` et `updaters/` (mises à jour de schéma/données) |
| `Managers/` | Gestionnaires : `worldmanager/`, `npcmanager/`, `playermanager/`, `GameLoop/`, `Discord/`… |
| `world/`, `ai/`, `behaviour/`, `events/`, `scripts/` | Monde, cerveaux de PNJ classiques, comportements, événements, scripts |
| `webui/`, `API/`, `Metrics/`, `PerformanceStatistics/` | Interface web, API, métriques |

### Les trois populations de bots (rappel)

| Population | Création | Cerveau / contrôleur | Persistance |
|---|---|---|---|
| Helper temporaire `/spawn` | `TemporaryGroupCommands.cs` | `BotBrain` | Aucune (supprimé à la déconnexion) |
| Compagnon persistant `/bot create` | `BotCommand.cs`, `BotManager.cs` | `BotBrain` | Profil seulement (`bot_profiles`) |
| Gamebot autonome | `AutonomousPopulationController`, `AutonomousBotIdentityGenerator` | `BotBrain` + `AutonomousWorldBotController*` | Complète (`OfflineWorldBotRecord`) |

Détails dans `bots-spawn-ia.md`.

### Familles de fichiers dans `bots/autonomous/` (par préfixe)

| Préfixe | Sujet |
|---|---|
| `AutonomousBotDecisionEngine`, `AutonomousBotGoalPolicy`, `BotGoalSettings`, `*GoalCatalog` | Choix des buts |
| `AutonomousCamp*`, `AutonomousPveTargetPolicy`, `AutonomousSoloCampFloor` | Camps et cibles de chasse |
| `AutonomousBotGroupCoordinator*`, `AutonomousGroup*` | Groupes |
| `AutonomousRvr*`, `AutonomousSiege*`, `AutonomousFrontier*`, `RvrKeepRoute` | RvR, sièges, frontières |
| `AutonomousDarknessFalls*`, `DarknessFallsCharmPolicy` | Darkness Falls |
| `RealmRaid*`, `RealmEvent*`, `AutonomousRealmRaid` | Raids et événements de royaume |
| `AutonomousZone*`, `AutonomousCorridor*`, `AutonomousRoute*`, `AutonomousNavigationSurface` | Déplacement et navigation |
| `AutonomousStable*`, `AutonomousCapitalTransit`, `AutonomousTownTeleporters`, `GameBotTaxi` | Voyages (stablemasters, téléporteurs) |
| `AutonomousBotChat*`, `AutonomousChat*`, `RealmEventBanter` | Chat des bots |
| `AutonomousBotEconomy`, `AutonomousAuctionValuation`, `AutonomousSupplyMerchantSpace` | Économie, ventes |
| `AutonomousPopulation*`, `AutonomousAiBudget`, `AutonomousFidelityPolicy` | Population et budget de réflexion |
| `AutonomousStuckWatchdog`, `AutonomousGoalDiagnostics`, `AutonomousBotDashboard` | Blocages, diagnostic, tableaux de bord |

## 3. Les outils (`source/tools`)

| Élément | Rôle |
|---|---|
| `OfflineDaoc.Launcher` (+ `.Tests`) | Lanceur Windows ; affiche la version (`MainForm.DisplayVersion`) ; mode « nouveau client » si `..\godot\project.godot` existe |
| `OfflineDaoc.Patcher` | Patcher livré dans chaque mise à jour (contrôle, sauvegarde, application, retour arrière) |
| `OfflineDaoc.ProgressImport` | Transfert de progression entre versions (`progress-policy.json`) |
| `OfflineDaoc.Setup`, `OfflineDaoc.Mpk`, `LauncherLayoutCheck` | Installation, archives MPK, contrôle de mise en page (non lus) |
| `build_release_037.py`, `assemble_release_037.py`, `build_newclient_037.py` | Paquets de référence 0.37 |
| `make_patch.py`, `make_downloaders_037.py`, `find_changes_since_release.py` | Patches, téléchargeurs, différences depuis la base 0.36 |
| `smoke_release_037.py`, `test_release_import_037.py` | Tests de bout en bout d'un paquet |
| `release-baselines/`, `release-world-defaults.json` | Empreintes de la base 0.36 ; état par défaut des forts et portes |
| `*_035.py`, `*_036.py`, `*_02.py` | Pipelines des versions précédentes (référence) |

## 4. Le nouveau client (`source/new-client`)

- `godot/` : projet Godot 4 (`project.godot`, `MMOEngine.csproj`). Le code de jeu est dans `godot/game/` (GDScript : `login_screen`, `character_factory`, `combat/`, `companions/`, `classes/`…). Le contenu converti n'est pas dans Git.
- `pipeline/` : conversion du contenu du jeu d'origine. `tools/` : outils associés. `README.md` : guide.
- Il parle au même serveur que le client d'origine (même compte, même base).

## 5. Le dossier jouable (hors dépôt)

`runtime/server` (binaires, `navmesh/`), `runtime/data/opendaoc.sqlite3.db` (monde + sauvegardes), `runtime/client-opendaoc/app` (client d'origine), `runtime/OfflineDAoC.exe` (lanceur), `runtime/account.txt`, et en 0.37c `new-client/`. Ce dossier n'est pas dans le dépôt (voir `compiler-et-deployer-le-serveur.md`).

## 6. Fichiers racine à connaître

`AGENTS.md` / `CLAUDE.md` (règles), `DEVELOPMENT - START HERE.md`, `CHANGELOG.md`, `ALL SERVER COMMANDS.txt`, `QUICK COMMANDS.txt` (commandes de jeu), `RELEASE VERIFICATION.txt`, `THIRD_PARTY.md`.

## 7. Où commencer selon l'objectif

| Objectif | Départ |
|---|---|
| Changer le comportement d'un bot de groupe | `bots/BotBrain.cs` (5 300 lignes), politiques `Bot*Policy` ; notes : `bots-spawn-ia.md` |
| Changer ce que font les gamebots autonomes | `bots/autonomous/AutonomousBotDecisionEngine.cs`, `bot-goals.json` du dossier jouable |
| Ajouter ou modifier une commande | copier le modèle d'un fichier de `commands/playercommands/` (attribut `CmdAttribute`) |
| Ajouter un réglage serveur | `serverproperty/ServerProperties.cs` (lire d'abord un exemple existant) |
| Modifier les données du monde (sorts, objets, PNJ) | base SQLite du dossier jouable ; notes : `base-de-donnees-sqlite-mariadb.md`, `exemples_sqlite.py` |
| Points de spécialisation | `points-de-competences.md` |
| Compiler et déployer | `compiler-et-deployer-le-serveur.md` |
| Art, modèles, effets du client | `docs/CLIENT-MODDING-GUIDE.txt`, `tools/pet-art` |
| Tests | `source/server/Tests/UnitTests/UT_*.cs` ; filtre `--filter "FullyQualifiedName~UT_Nom"` |

## 8. À explorer ensuite

- `ServerProperties.cs` et le mécanisme `[ServerProperty]` (lecture depuis la base).
- Cycle de vie d'une commande (`CmdAttribute`, chargement par réflexion) et d'un tick (`GameLoopService`).
- `AutonomousBotDecisionEngine` et le format de `bot-goals.json`.
- `OfflineWorldBotRecord` et la persistance des gamebots.
- Le schéma SQLite complet (via `exemples_sqlite.py ... tables`, quand une base jouée est disponible).
- Les rapports `source/server/docs/reports/` (historique des audits et des correctifs).
