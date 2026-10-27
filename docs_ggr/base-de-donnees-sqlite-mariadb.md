# Base de données : SQLite (jeu) et MariaDB (héritage OpenDAoC)

Question : le serveur utilise-t-il une base SQLite locale, au lieu de ou en plus de MariaDB/MySQL ? Où est la chaîne de connexion, où est le fichier `.db`, et comment l'inspecter ou le modifier ?
Notes de recherche sur le dépôt Offline DAoC, sans modification du code. Chemins relatifs à la racine du dépôt, sauf mention contraire.

## 1. Réponse courte

- Le jeu Offline DAoC utilise **SQLite** : un seul fichier, `runtime/data/opendaoc.sqlite3.db`, dans le dossier jouable (`AGENTS.md` ; `docs/DEVELOPMENT.md` : « world plus saves »). Il contient à la fois le monde (spawns, sorts, objets) et les sauvegardes (comptes, personnages, bots).
- Le code du serveur **sait encore parler MariaDB/MySQL** (héritage d'OpenDAoC), mais **un seul type de base est actif à la fois** : le choix se fait par `DBType` dans le fichier de configuration. Ce n'est pas un « en complément ».
- Je n'ai trouvé **aucun fichier `serverconfig.xml` réel** ni aucun dossier jouable sur cette machine (recherche dans `C:\ws_perso`) : la chaîne de connexion effectivement utilisée par un jeu installé n'a donc pas été lue. Voir §3.

## 2. Types de base pris en charge par le code

- `source/server/CoreDatabase/Enums/EConnectionType.cs` : `DATABASE_XML`, `DATABASE_MYSQL`, `DATABASE_SQLITE`, `DATABASE_MSSQL`, `DATABASE_ODBC`, `DATABASE_OLEDB`.
- `source/server/CoreDatabase/ObjectDatabase.cs:971`, `GetObjectDatabase(connectionType, connectionString)` : ne construit réellement que MySQL (`MySqlObjectDatabase`) et SQLite (`SqliteObjectDatabase`), les autres types n'ont pas de gestionnaire relevé ici. Gestionnaires : `CoreDatabase/Handlers/MySqlObjectDatabase.cs` et `SqliteObjectDatabase.cs`.
- Le gestionnaire SQLite utilise `System.Data.SQLite` (`SqliteObjectDatabase.cs:5`). Les mêmes classes d'objets (`DbCoreCharacter`, `DbAccount`, `DbServerProperty`…) servent aux deux bases ; seule la connexion change.

## 3. Où est définie la chaîne de connexion

1. **Fichier de configuration** lu au démarrage : `./config/serverconfig.xml` relatif au dossier du serveur (`source/server/CoreServer/GameServerService.cs:30` et `Actions/ConsoleStart.cs:63`, option `--start [-config=./config/serverconfig.xml]`). Dans un jeu installé, c'est `runtime/server/config/serverconfig.xml` (chemin utilisé par les scripts de build : `source/tools/build_release_037.py:298`).
2. Les clés lues : `<DBType>` (valeurs `xml`, `mysql`, `sqlite`, `mssql`, `odbc`, `oledb`, insensible à la casse ; valeur inconnue → XML) et `<DBConnectionString>`, plus `DBAutosave` et `DBAutosaveInterval` (`source/server/GameServer/GameServerConfiguration.cs:189-215`, écriture lignes 318-347).
3. **Le fichier d'exemple du dépôt est resté en MySQL** : `source/server/CoreServer/config/serverconfig.example.xml` contient `<DBType>MYSQL</DBType>` et `Server=localhost;Port=3306;Database=DBNAME;UserId=USERNAME;Password=PASSWORD;…`. C'est un reste d'OpenDAoC. La doc demande de le copier tel quel en `serverconfig.xml` pour que la compilation passe (« the build only needs it to exist », `docs/DEVELOPMENT.md`) ; ce n'est pas la configuration d'un jeu jouable. Même chose pour `source/server/docker-compose.yml` (image `mariadb:10.6`, `DB_TYPE: "MYSQL"`) : environnement hérité d'OpenDAoC.
4. **Valeur par défaut codée en dur** (`GameServerConfiguration.cs`, constructeur, lignes 385-387), utilisée quand la clé est absente du fichier :
   ```
   DBType = SQLITE
   Data Source=<dossier du serveur>\dol.sqlite3.db;Version=3;Pooling=False;Cache Size=1073741824;Journal Mode=Off;Synchronous=Off;Foreign Keys=True;Default Timeout=60
   ```
   (`dol.sqlite3.db` à côté de l'exécutable, nom différent du fichier du jeu).
5. **Dans le jeu jouable**, le fichier est `runtime/data/opendaoc.sqlite3.db`. La chaîne exacte écrite dans le `serverconfig.xml` du jeu est fixée par le paquet de release ; elle **n'est pas** dans le dépôt (`assemble_release_037.py:21` exclut `serverconfig.xml`, et `build_release_037.py:298` le copie depuis un jeu de développement en y forçant seulement `AutoAccountCreation`). À lire dans le fichier de votre dossier jouable : ouvrir `runtime/server/config/serverconfig.xml` et repérer `DBType` et `DBConnectionString`.
6. Détails du gestionnaire (`SqliteObjectDatabase.cs`) : les écritures sont sérialisées par un verrou en processus ; le mode **WAL** est utilisé quand la connexion est « poolée » (`Pooling=True`), ce qui crée les fichiers `opendaoc.sqlite3.db-wal` et `-shm` à côté du `.db`. Les scripts de déploiement du dépôt préservent `data\opendaoc.sqlite3.db` **et** `data\opendaoc.sqlite3.db-wal` (par exemple `source/server/tools/deploy_bot_goals.ps1`). Les paquets publics excluent `.sqlite3.db`, `-wal`, `-shm`, `-journal` (`build_release_037.py:64`) et réinitialisent le monde.

## 4. Inspecter ou modifier la base depuis votre poste

Règles du projet : **jamais** commiter une base jouée, `account.txt`, journaux, sauvegardes (`AGENTS.md`, `docs/DEVELOPMENT.md`). Travailler sur une copie, ou sauvegarder avant (`docs/LLM-QUICKSTART.md`). Les changements de base se font **serveur arrêté**, en **une transaction**, après sauvegarde (`docs/CLIENT-MODDING-GUIDE.txt`, règle 4) ; redémarrer le serveur ensuite. Un serveur actif réécrit les lignes des personnages connectés à chaque sauvegarde.

**A. Sauvegarde cohérente (obligatoire avant toute modification)**
- Le plus sûr : serveur arrêté, copier `opendaoc.sqlite3.db` **avec** `-wal` et `-shm` s'ils existent.
- Ou, avec Python (méthode déjà utilisée par les scripts du dépôt, `build_release_037.py:292-294`) :
  ```python
  import sqlite3
  src = sqlite3.connect("runtime/data/opendaoc.sqlite3.db")
  dst = sqlite3.connect("runtime/data/opendaoc.backup.db")
  src.backup(dst); dst.close(); src.close()
  ```

**B. Outil graphique léger**
- Un explorateur SQLite (par exemple « DB Browser for SQLite » ou une extension SQLite d'éditeur) ouvre le `.db` directement. Ouvrir une **copie**, ou ouvrir en lecture seule, tant que le serveur tourne.

**C. Ligne de commande SQLite**
- Si le client `sqlite3` est installé (non vérifié sur cette machine) : `sqlite3 runtime/data/opendaoc.sqlite3.db`, puis `.tables`, `.schema DOLCharacters`, `PRAGMA table_info(DOLCharacters);`.

**D. Script Python (le plus utilisé dans ce dépôt)**
- De nombreux scripts de `source/server/tools/*.py` et `source/tools/*.py` ouvrent la base avec `sqlite3` (module standard). Lecture seule : `sqlite3.connect(Path(db).as_uri() + "?mode=ro", uri=True)` (déjà utilisé par `build_release_037.py:292`).
- Modification : une transaction explicite, après sauvegarde, serveur arrêté :
  ```python
  con = sqlite3.connect(db)
  with con:  # commit ou rollback automatique
      con.execute("UPDATE DOLCharacters SET SerializedSpecs=? WHERE DOLCharacters_ID=?", (valeur, identifiant))
  con.close()
  ```
- Plusieurs scripts existants refusent de tourner hors d'un chemin attendu (garde dans `migrate_darkness_falls_charm_165.py`) et font leur propre sauvegarde ; à imiter.

**E. Depuis C# (si vous écrivez du code serveur ou un outil)**
- Dans le serveur, on passe par `GameServer.Database` (`SelectObjects<T>`, `SaveObject`, `AddObject`), pas par SQL brut ; la classe SQLite s'occupe du verrou d'écriture et de la connexion. Un outil externe .NET peut utiliser `System.Data.SQLite` comme le serveur.

**F. Tables utiles déjà documentées**
- `DOLCharacters`, `Account`, `ServerProperty` : voir `points-de-competences.md` (sections 3 ter et 3 quater). Les noms de tables et de colonnes viennent des attributs `[DataTable]` et `[DataElement]` du code ; à confirmer avec `PRAGMA table_info(...)` (la base du jeu n'est pas dans le dépôt).

**G. Script d'exemples prêt à copier sur l'autre poste** : `docs_ggr/exemples_sqlite.py` (Python 3 standard, sans dépendance, non exécuté faute de base ici). Commandes de lecture : `tables`, `schema <table>`, `find-char <nom>`, `show-specs <nom>`. Commandes d'écriture (aperçu par défaut, `--apply` pour écrire) : `set-specs`, `set-priv`, `set-prop`. Avec `--apply` : refus si le port 10300 répond, sauvegarde horodatée, transaction unique, annulation si autre chose qu'une ligne est touchée.

## 5. Si vous retrouviez une version MariaDB

- Si vous ouvrez un jeu où `DBType` vaut `MYSQL`, la base est un serveur externe (hôte, port, nom de base, identifiants dans `DBConnectionString`) et non un fichier ; les mêmes tables existent. La doc du projet ne décrit pas d'édition MariaDB du jeu Offline DAoC : tout y pointe vers SQLite.
- Pour passer un jeu de SQLite à MariaDB (ou l'inverse) il faudrait changer `DBType` et `DBConnectionString` **et** migrer les données (aucun outil de migration trouvé dans le dépôt) : non testé.

## 6. Points non vérifiés

- Contenu réel du `serverconfig.xml` d'un jeu installé (aucun présent ici).
- Existence et nom exact des tables (le `.schema` de votre base fait foi).
- Disponibilité du client `sqlite3` en ligne de commande sur votre poste.
