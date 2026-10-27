# Configuration du serveur : `GameServerConfiguration`, `serverconfig.xml` et le type de serveur (PvE, PvP…)

Lu : `source/server/GameServer/GameServerConfiguration.cs`, `source/server/CoreBase/Configs/BaseServerConfig.cs`, `source/server/CoreBase/Enums/EGameServerType.cs`, `source/server/CoreServer/Actions/ConsoleStart.cs`, `source/server/CoreServer/GameServerService.cs`, `source/server/CoreServer/config/serverconfig.example.xml`, extraits de `GameServer/gameutils/ScriptMgr.cs`, `serverrules/PvEServerRules.cs`, `serverrules/DFEnterJumpPoint.cs`.
Rien n'a été exécuté ni modifié. Chemins relatifs à la racine du dépôt ; numéros de ligne au commit `abb58da`.
Lu aussi : `source/server/CoreServer/MainClass.cs` (lecture de `-config`, section 2bis).
Non vérifié : le contenu du `serverconfig.xml` d'un dossier jouable (aucun dans le dépôt).

## 1. Ce que fait `GameServerConfiguration`

Classe de `GameServer/GameServerConfiguration.cs`, qui hérite de `BaseServerConfig` (`CoreBase/Configs/`). Elle est un **objet de réglages** : valeurs par défaut dans le constructeur, lecture et écriture d'un fichier XML, propriétés publiques lues ensuite par le reste du serveur via `GameServer.Instance.Configuration` (`GameServer.cs:131`).

Deux niveaux :

| Classe | Réglages |
|---|---|
| `BaseServerConfig` | Réseau : `Port` (10300), `IP`, `RegionIP`, `RegionPort` (10400), `UdpIP`, `UdpPort` (10400), `EnableUPnP`, `DetectRegionIP`. Valeurs `"any"` = `IPAddress.Any` |
| `GameServerConfiguration` | Nom du serveur, type de jeu, base de données, compilation de scripts, journaux, métriques (voir tableau ci-dessous) |

Réglages de `GameServerConfiguration` (balises sous `<root><Server>`) :

| Balise XML | Propriété | Défaut (constructeur) | Remarque |
|---|---|---|---|
| `ServerName` / `ServerNameShort` | `ServerName` / `ServerNameShort` | `Offline DAoC` / `DOLSERVER` | Le nom court apparaît dans `/loc` |
| `GameType` | `ServerType` | `Normal` | Voir section 3 |
| `DBType` | `DBType` | `SQLITE` dans le constructeur, **mais `XML` si la balise est absente** à la lecture | Valeurs : `xml`, `mysql`, `sqlite`, `mssql`, `odbc`, `oledb`. Valeur inconnue = `XML` |
| `DBConnectionString` | `DBConnectionString` | `Data Source=<racine>\dol.sqlite3.db;Version=3;…` | Le fichier d'exemple fournit une chaîne MySQL |
| `DBAutosave` / `DBAutosaveInterval` | `AutoSave` / `SaveInterval` | `True` / `10` (minutes) | |
| `AutoAccountCreation` | `AutoAccountCreation` | `True` | La propriété `account / allow_auto_account_creation` doit aussi être vraie (`ServerProperties.cs:2415`) |
| `EnableCompilation`, `ScriptCompilationTarget`, `ScriptAssemblies` | idem | `True`, `./lib/GameServerScripts.dll`, vide | Compilation de scripts au démarrage |
| `LogConfigFile` | `LogConfigFile` | `./config/logconfig.xml` | Chemin relatif résolu par rapport à `RootDirectory` |
| `InvalidNamesFile` | `InvalidNamesFile` | `./config/invalidnames.txt` | idem |
| `CheatLoggerName`, `DualIPLoggerName`, `GMActionLoggerName` | idem | `cheats`, `dualip`, `gmactions` | Noms de loggers |
| `UDPOutIP` + `UDPOutPort` | (champ `m_udpOutEndpoint`) | non défini | Ignorés si l'un des deux est invalide |
| `MetricsEnabled`, `OtlpEndpoint`, `MetricsExportInterval` | idem | `false`, `http://localhost:4317/`, `60s` | Durée au format `10s`, `2m`, `4h` (`ParseDurationToMilliseconds`) ; autre format = `FormatException` |

Pièges de lecture dans le code :
- `RootDirectory` est calculé depuis l'assembly d'entrée (dossier de `CoreServer.dll`/de l'exécutable). La lecture de `RootDirectory` depuis le XML est commentée (« Removed to not confuse users »).
- `LoadFromConfig` utilise le défaut **de la balise** (`GetString("Normal")`, `GetString("XML")`) et non la valeur du constructeur pour `GameType` et `DBType` : si la balise manque, le type reste `Normal` et la base devient `XML`, pas `SQLITE`.
- Dans le fichier d'exemple, `MetricsInterval` ne correspond pas à la balise lue par le code (`MetricsExportInterval`) : cette valeur est donc ignorée (défaut 60 s).
- `SaveToConfig` ne réécrit pas les réglages de métriques.

## 2. D'où vient le fichier et quand est-il lu

1. Au démarrage (`CoreServer/Actions/ConsoleStart.cs`, `OnAction`) :
   - si le paramètre `-config <fichier>` est donné, c'est ce fichier ;
   - sinon : `<dossier de l'exécutable>/config/serverconfig.xml`.
2. `new GameServerConfiguration()` (valeurs par défaut), puis :
   - fichier présent → `LoadFromXMLFile` (`LoadFromConfig`, base d'abord puis `GameServer`) ;
   - fichier absent → le dossier `config` est créé et le fichier est **écrit avec les valeurs par défaut** (`SaveToXMLFile`), donc type `Normal` et SQLite `dol.sqlite3.db` à côté du serveur.
3. `GameServer.CreateInstance(config)` puis `GameServer.Instance.Start()`.
4. Si le serveur tourne comme service Windows (`GameServerService.cs`), le fichier est toujours `./config/serverconfig.xml` (le `TODO` du code dit que `-config` n'y est pas géré).

Dans le dépôt, `serverconfig.xml` est ignoré par git ; seul `source/server/CoreServer/config/serverconfig.example.xml` existe. Les scripts de release (`build_release_037.py`) modifient `runtime/server/config/serverconfig.xml` (fonction `set_auto_account_creation`) et `assemble_release_037.py` l'exclut des paquets (`SKIP_NAMES`).

### 2bis. Comment `-config` est lu (confirmé dans `CoreServer/MainClass.cs`)

- Sans argument, `Main` utilise `--start` (action `ConsoleStart`, syntaxe affichée : `--start [-config=./config/serverconfig.xml]`). C'est le cas du lanceur.
- `ParseParameters` : le **premier argument doit être l'action** et commencer par `--`, sinon le message « First argument must be the action » s'affiche et le programme **s'arrête sans rien démarrer**.
- Les paramètres suivants commencent par un seul `-` et la valeur se donne avec **`=`** : `-config=C:\chemin\serverconfig.xml`. Avec un espace (`-config chemin`), `-config` reçoit une valeur vide et le chemin est ignoré.
- Exemple valide : `CoreServer.exe --start -config=D:\test\serverconfig.xml`. Deux actions `--…` donnent une erreur.
- `ConsoleStart` : si `-config` est présent, il fait `new FileInfo(valeur)`. Si le fichier n'existe pas, il est **créé avec les valeurs par défaut** à cet endroit (`SaveToXMLFile`), donc en `Normal`. `-config=` avec une valeur vide fait probablement planter `FileInfo("")` (déduit du code, non testé).
- Le **lanceur n'utilise pas** `-config` : il démarre sans argument (voir 4.1). Pour un essai avec un autre fichier, il faut lancer `CoreServer.exe` à la main, lanceur et serveur arrêtés (un seul serveur sur le port 10300).
- L'action service Windows n'est compilée que sous `NETFRAMEWORK` (`#if NETFRAMEWORK`) : ici, seule `--start` existe.

## 3. Lancer le serveur en mode `pve` (ligne 168)

La ligne 168 est un `case "pve":` du `switch` qui lit la balise **`<GameType>`**. Il n'y a rien à coder : il suffit de mettre cette valeur dans `serverconfig.xml`.

1. **Arrêter** le lanceur, le client et le serveur (un seul serveur sur le port 10300).
2. Trouver le fichier du dossier jouable : `runtime/server/config/serverconfig.xml` (chemin d'après `build_release_037.py` ; à confirmer sur votre installation). Pour un test depuis le dépôt : copier `serverconfig.example.xml` en `serverconfig.xml`.
3. **Sauvegarder** le fichier, puis changer :
   ```xml
   <GameType>PvE</GameType>
   ```
   La comparaison ignore la casse (`ToLower()`). Valeurs acceptées : `Normal`, `Casual`, `Roleplay`, `PvE`, `PvP`, `Test`. Toute autre valeur donne `Normal` **sans message d'erreur**.
4. Redémarrer le serveur. Pour pointer vers un autre fichier : `CoreServer.exe --start -config=<chemin>` (voir section 2bis).
5. Vérifier : après un `SaveToConfig` le fichier réécrit contient `PvE` ; en jeu, `/loc`/web UI ; côté code, `GameServer.Instance.Configuration.ServerType == EGameServerType.GST_PvE`. Aucune commande de jeu lue ne l'affiche : à chercher.

Attention : si le lanceur de l'utilisateur régénère `serverconfig.xml` ou si le fichier n'existe pas, la valeur repasse à `Normal`.

### Ce que change le type `PvE` (relevé par recherche de `GST_PvE` ; liste non exhaustive)

- **Règles du serveur** : `ScriptMgr.CreateServerRules(ServerType)` (`GameServer.cs:167`, `:740`) cherche la classe dotée de `[ServerRules(EGameServerType.GST_PvE)]` → `PvEServerRules` (`serverrules/PvEServerRules.cs`). Elle modifie qui peut attaquer qui (les familiers comptent comme leur propriétaire).
- **Mort** (`GamePlayer.cs:5987`) : le `switch` sur le type de serveur change le message et la perte d'expérience.
- **Invulnérabilité de réapparition** : `StartInvulnerabilityTimer` (`GamePlayer.cs:12242`) retourne `false` en PvE.
- **Forts** : `AbstractGameKeep`, `Lord`, `MissionMaster`, `GameKeepGuard`, `GameKeepComponent` ont des cas particuliers (forts sans royaume, gardes, seigneurs).
- **Darkness Falls** : `DFEnterJumpPoint.CanRealmEnter` retourne `true` pour tout type différent de `Normal` : l'entrée n'est plus liée au royaume qui possède la forteresse.
- **Divers** : `/assist`, `/who`, maisons (`HouseTemplateMgr`), points de passage de portes (`DoorRequestHandler`), `GatewayPersonalBind`.
- Autres types : `GST_Normal` est celui des règles RvR « classiques » (messages de royaume dans les connexions, volley d'Atlas…) ; `GST_PvP` active des règles de groupe et de guilde propres.

### Risque pour ce projet

`AGENTS.md` demande de préserver les règles du propriétaire (par ex. **Darkness Falls ouvert aux bots solo**, forts et reliques à l'état par défaut, tous réglés pour le type `Normal`). Le serveur du jeu a été construit et testé avec `Normal` (valeur par défaut), et je n'ai pas lu les tests qui couvrent d'autres types. Passer en `PvE` est donc à essayer **sur une copie du dossier jouable**, avec une sauvegarde de la base, et à vérifier en jeu : forts, mort, bots autonomes en RvR (`AutonomousRvr*`).

## 4. Découvertes : pourquoi `PvE` peut sembler ne pas marcher après un passage en `Normal`

Contexte rapporté : `Normal` fonctionne (autre machine) ; `PvE` « semble ne pas fonctionner » si le serveur a déjà tourné en `Normal`. Aucun test n'a été fait de mon côté : ce qui suit vient de la lecture du code. Les symptômes exacts n'étant pas connus, ce sont des **hypothèses classées par vraisemblance**.

### 4.1 Le fichier est bien relu à chaque démarrage (hypothèse écartée)

- Le lanceur démarre `CoreServer.exe` **sans argument**, avec le dossier du serveur comme dossier de travail (`OfflineDaoc.Launcher/MainForm.cs` ≈ 2669). Le fichier lu est donc `<dossier du serveur>/config/serverconfig.xml` (`ConsoleStart.cs`).
- Rien dans le lanceur ni les outils ne réécrit `GameType` (aucune occurrence dans `source/tools`). Seul `build_release_037.py` touche ce fichier, et uniquement pour `AutoAccountCreation`.
- Donc la base n'« enregistre » pas le type de serveur : changer la balise suffit côté configuration. Vérifier plutôt que le fichier modifié est bien celui du dossier qui sert (`runtime/server/config/`), et qu'aucun autre `CoreServer.exe` ne tourne encore (le lanceur arrête les `CoreServer` existants, ≈ `MainForm.cs:2990`).

### 4.2 Hypothèse principale : les forts gardent le propriétaire reçu en `Normal`

- Le propriétaire d'un fort est **stocké en base** : `AbstractGameKeep.Realm` lit et écrit `DBKeep.Realm` (`keeps/AbstractGameKeep.cs:390`). Le serveur ne le remet pas à `OriginalRealm` au démarrage, quel que soit le type de serveur (recherche de `OriginalRealm` dans `keeps/` : seuls `RelicGateMgr` et `RelicMgr` l'utilisent, pas le chargement).
- Les comportements « PvE » des forts ne s'appliquent qu'aux forts **sans royaume** (`Realm == None`) :
  - respawn du seigneur « mob à farmer pour des sceaux » (`AbstractGameKeep.cs:237`, `Lord.cs:390`) ;
  - le seigneur ne donne ni points de royaume ni de renommée en PvE (`Lord.cs:51`, `:77`) ;
  - appel à l'aide du seigneur (`ai/brain/Guards/Lord.cs:42`).
- Dans `PvEServerRules.IsAllowedToAttack` (`serverrules/PvEServerRules.cs:17`), deux entités ayant chacune un royaume (≠ `None`) ne peuvent **pas** s'attaquer (« You can not attack other players on this server! »), sauf duel. Un fort encore possédé par un royaume (gardes et seigneur avec ce royaume) devient donc **inattaquable par les joueurs et les bots** : il faut des forts à `Realm = 0`.
- Une base jouée en `Normal` contient vraisemblablement des forts possédés (`Keep.Realm` ≠ 0) ; je n'ai pas vu de base réelle, donc la valeur de départ des forts n'est pas vérifiée. Pour un monde PvE (forts sans royaume), il faudrait que `Realm` vaille 0. **Cette conversion n'a pas été testée et je n'ai pas trouvé de documentation du projet qui la décrive.**
- Les reliques et leurs portes (`RelicGateMgr`) comparent `Realm` et `OriginalRealm` du fort : états de reliques et de portes déjà posés en `Normal` restent en base aussi.

Pistes pour tester (sur une **copie** du dossier jouable, serveur arrêté, base sauvegardée) :
1. Lire l'état : `SELECT KeepID, Name, Realm, OriginalRealm FROM [Keep];` (table `[Keep]`, colonnes vues dans `KeepRelicReset.cs`). Avec `exemples_sqlite.py DB schema Keep` pour confirmer les noms.
2. Comparer avec `Realm = 0` pour tous les forts concernés et relancer en `PvE`.
3. Le lanceur propose un « reset keeps and relics » (`KeepRelicReset.cs`) : il remet les forts à leur état d'origine (`OriginalRealm`), **pas** à 0. À ne pas confondre avec une conversion PvE.

### 4.3 Autres éléments à impacter (relevés dans le code)

| Sujet | Constat | Fichier |
|---|---|---|
| Combat entre joueurs de royaumes différents | Interdit en PvE (sauf duel) : normal, pas un bug | `PvEServerRules.cs:50` |
| Couleurs des noms côté client | `GetColorHandling` = 3 (tous les joueurs amis, PNJ de royaume 0 ennemis) | `PvEServerRules.cs:171` |
| Création de personnages | PvE autorise des personnages dans tous les royaumes d'un même compte (`IsAllowedCharsInAllRealms` = vrai) ; en `Normal` le compte est lié à un royaume (`CharacterOverviewRequestHandler.cs:32`, `:54`) | |
| Groupes, guildes, échanges | Toujours permis entre royaumes | `PvEServerRules.cs:139-152` |
| Mort | Branche dédiée au type de serveur dans `GamePlayer.Die` (≈ 5987) | `GamePlayer.cs` |
| Darkness Falls | Entrée libre pour tous (`CanRealmEnter` vrai si le type n'est pas `Normal`) | `serverrules/DFEnterJumpPoint.cs:22` |
| Boutique d'intérieur de maison | Catalogue « tous royaumes » en PvE/PvP | `housing/HouseTemplateMgr.cs:95` |
| **Bots** | Aucune référence à `ServerType` dans `GameServer/bots/` (recherche textuelle). Les gamebots autonomes ont été conçus pour le RvR `Normal` (`AutonomousRvr*`, sièges, raids de royaume) ; en PvE leurs attaques de forts/joueurs ennemis sont refusées par les règles (`IsAllowedToAttack`) : **comportement à observer, non vérifié** | |
| Règles d'Offline DAoC | Voir `AGENTS.md` : forts et reliques par défaut, Darkness Falls ouvert aux bots solo | |

### 4.4 Ce qu'il manque pour conclure

- Le **symptôme précis** observé en PvE (le serveur ne démarre pas ? démarre mais pas de PvE ? forts inattaquables ? message d'erreur ?) et le journal de la console du serveur au démarrage (le lanceur l'écrit dans `logs/server-console.log` d'après `MainForm.cs`, à vérifier). La ligne `Server rules:` du démarrage (`GameServer.cs:745`) indique les règles chargées ; le nom exact des règles affiché pour PvE est « standard PvE server rules » (`RulesDescription`).
- La valeur réelle de `GameType` dans le `serverconfig.xml` du dossier jouable concerné.
- Le contenu de la table `Keep` (propriétaires) de cette base.

## 5. Pour aller plus loin

- Savoir comment `-config` est lu : `CoreServer/MainClass.cs`.
- Réglages **dans la base** (distincts du XML) : `ServerProperties` (`serverproperty/ServerProperties.cs`), par ex. `classes / enable_sluaghbinder`, `account / allow_auto_account_creation` ; les réglages propres à Offline DAoC sont dans les tables `offline_population_settings` et `offline_local_options` (cf. `AGENTS.md`).
- Voir `base-de-donnees-sqlite-mariadb.md` pour `DBType` / `DBConnectionString`.
