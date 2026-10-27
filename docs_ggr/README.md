# Documentation perso (`docs_ggr`) : index

Notes de recherche sur le dépôt Offline DAoC. Elles s'ajoutent à `docs/` sans le modifier. Rédigées en français ; les chemins sont relatifs à la racine du dépôt.

Convention : chaque note dit ce qui a été **lu**, ce qui est **non vérifié**, et si quelque chose a été **exécuté**. Les numéros de ligne datent du commit `abb58da` : à revérifier avant de s'y fier.

| Fichier | Sujet |
|---|---|
| [carte-du-depot.md](carte-du-depot.md) | Vue d'ensemble : blocs, dossiers du serveur, outils, nouveau client, où commencer |
| [bots-spawn-ia.md](bots-spawn-ia.md) | `/spawn`, IA des bots (`BotBrain`), mages sans mana, soigneurs, spécialisations, `/bot create` |
| [points-de-competences.md](points-de-competences.md) | Points de spécialisation : multiplicateur, calcul, persistance, SQL |
| [base-de-donnees-sqlite-mariadb.md](base-de-donnees-sqlite-mariadb.md) | Base SQLite du jeu, héritage MariaDB, inspection depuis le poste |
| [exemples_sqlite.py](exemples_sqlite.py) | Script d'exemple pour lire et modifier la base (aperçu par défaut, `--apply` pour écrire) |
| [configuration-serveur.md](configuration-serveur.md) | `GameServerConfiguration`, `serverconfig.xml`, et comment lancer le serveur en mode `PvE` (`GameType`) |
| [lignes-de-competence-classes.md](lignes-de-competence-classes.md) | Donner une ligne de compétence à une classe (exemple : bouclier pour le Warden) : tables `ClassXSpecialization` / `SpecXAbility` |
| [carrieres-specialisations.md](carrieres-specialisations.md) | « Career » : table `ClassXSpecialization` vs type `CareerSpecialization`, chargement joueur/bot, `Trainable` / `AllowSave` |
| [handoff_20261026.md](handoff_20261026.md) | Reprise de session : acquis sur la config serveur, essai PvE prévu, points à vérifier |
| [handoff_20261027.md](handoff_20261027.md) | Reprise de session : acquis sur les « careers », `LiveWideCareerSpecialization`, requêtes à lancer sur une base |
| [compiler-et-deployer-le-serveur.md](compiler-et-deployer-le-serveur.md) | Compiler, tester, sauvegarder et déployer `GameServer.dll` |
| [revenir_a_la_session.md](revenir_a_la_session.md) | Commande pour reprendre une session Claude Code (`claude --resume …`) |

## Règles de ce dossier

- On n'ajoute ici que de la documentation. Le code du dépôt n'est pas modifié.
- Un nouveau sujet = un nouveau fichier `sujet-en-minuscules.md`, ajouté à ce tableau.
- Ne jamais y mettre de base jouée, de `account.txt`, de journaux ni d'identifiants (règle d'`AGENTS.md`).
