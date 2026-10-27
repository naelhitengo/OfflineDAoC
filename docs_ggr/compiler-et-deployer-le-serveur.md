# Recompiler le serveur et le redéployer (première base)

Synthèse tirée de la documentation du dépôt : `docs/DEVELOPMENT.md` (sections « Build and test » et « Deploy a build into a playable folder »), `docs/CLIENT-MODDING-GUIDE.txt` (règles 4 et 5), `docs/HELMET-FACE-FIX.md` (étape 5), `AGENTS.md` (« Build and test separately »), `source/server/AGENTS.md` (commandes de test ciblé).
Aucune commande n'a été exécutée pour écrire ce fichier. Chemins relatifs à la racine du dépôt.

## 0. Ce qu'il faut savoir avant

- Le dépôt contient le **code source** (`source/server`). Le jeu jouable est un **autre dossier** (« playable folder ») qui contient `runtime/server`, `runtime/data/opendaoc.sqlite3.db`, `runtime/client-opendaoc/app`, etc. On compile dans le dépôt, puis on **copie** le résultat dans le dossier jouable. Le dossier jouable n'est pas dans le dépôt : repérez le vôtre.
- Un seul serveur peut utiliser le port **10300** à la fois (`AGENTS.md`).
- Ne jamais copier une build sur un serveur **en cours d'exécution** ; sauvegarder ce qu'on remplace (`AGENTS.md`).
- Ne jamais commiter une base jouée, `account.txt`, journaux ou sauvegardes (`docs/DEVELOPMENT.md`, « Sharing safely »).

## 1. Prérequis

- **Kit .NET 10 (SDK)** sur Windows (`docs/DEVELOPMENT.md`). Vérification faite sur cette machine : `dotnet --list-sdks` affiche `9.0.312` et `10.0.401`. Le projet `GameServer` cible `net10.0` (`source/server/GameServer/GameServer.csproj`).
- Un fichier de configuration local, ignoré par git, qui doit exister pour que la compilation passe :
  ```powershell
  Copy-Item source/server/CoreServer/config/serverconfig.example.xml source/server/CoreServer/config/serverconfig.xml
  ```
  (la doc dit : « The build only needs it to exist »).

## 2. Compiler

Depuis la racine du dépôt (PowerShell) :
```powershell
dotnet build "source/server/Dawn of Light.sln" -c Release
```
- La solution est `source/server/Dawn of Light.sln`. Dans `source/server`, la commande équivalente est `dotnet build "Dawn of Light.sln" -c Release`.
- Résultat du projet `GameServer` : `OutputPath = ..\$(Configuration)\lib\`, soit `source/server/Release/lib/GameServer.dll` (et `.pdb`). Fichiers intermédiaires : `source/server/build/GameServer/Release/` (`GameServer.csproj`, lignes 3, 11, 12).
- Si vous avez aussi modifié du code de `CoreDatabase/` (par exemple `DbCoreCharacter`), il faut déployer aussi `CoreDatabase.dll` (règle 5 de `CLIENT-MODDING-GUIDE.txt`). L'emplacement exact de sa sortie n'a pas été vérifié : regardez `source/server/CoreDatabase/CoreDatabase.csproj`.

## 3. Tester (séparément du déploiement)

```powershell
dotnet test source/server/Tests/Tests.csproj -c Release
```
- À 0.37 : 2 790 tests serveur et 107 tests du lanceur passent (`docs/DEVELOPMENT.md`). Un test lié à votre sujet précis :
  ```powershell
  dotnet test source/server/Tests/Tests.csproj -c Release --filter "FullyQualifiedName~UT_OutOfPowerCasterMelee"
  ```
- La règle du projet (`AGENTS.md`, `docs/DEVELOPMENT.md`) : les tests automatiques ne remplacent pas un essai en jeu, et on rapporte les deux séparément.

## 4. Déployer dans le dossier jouable

1. **Tout arrêter** : lanceur, jeu (client) et serveur.
2. **Sauvegarder** ce que vous allez remplacer (copies datées de `GameServer.dll` et `GameServer.pdb`) dans les trois dossiers cibles. Les guides du projet notent aussi les empreintes avant/après (SHA-256) pour pouvoir revenir en arrière.
3. **Copier** `source/server/Release/lib/GameServer.dll` (et `GameServer.pdb`) vers :
   - `runtime/server`
   - `runtime/server/lib`
   - `runtime/server/win-x64`
   (dans le dossier jouable ; trois destinations, c'est la règle d'`AGENTS.md`, ligne 75).
4. Si le lanceur a changé : copier les fichiers `OfflineDAoC.*` de `source/tools/OfflineDaoc.Launcher/bin/Release/net10.0-windows` vers `runtime/` (hors sujet pour un changement de serveur seul).
5. **Relancer** via le lanceur, puis **tester en jeu**.
6. Retour arrière : recopier les sauvegardes de l'étape 2 au même endroit, serveur arrêté.

Exemple de sauvegarde et copie (adapter `$jeu`, serveur arrêté) :
```powershell
$jeu = "D:\OfflineDAoC"      # dossier jouable : à adapter
$src = "source/server/Release/lib"
$stamp = Get-Date -Format yyyyMMdd-HHmmss
foreach ($d in "runtime/server", "runtime/server/lib", "runtime/server/win-x64") {
    $cible = Join-Path $jeu $d
    New-Item -ItemType Directory -Force "$cible/_backup_$stamp" | Out-Null
    Copy-Item "$cible/GameServer.dll", "$cible/GameServer.pdb" "$cible/_backup_$stamp" -ErrorAction SilentlyContinue
    Copy-Item "$src/GameServer.dll", "$src/GameServer.pdb" $cible -Force
}
```
Ce script est un exemple pour votre autre repo : il n'est pas dans la documentation du projet et n'a pas été exécuté.

## 5. Changements de base de données (rappel)

- Toute modification SQL se fait **serveur arrêté**, sur une copie sauvegardée, dans **une seule transaction** (`CLIENT-MODDING-GUIDE.txt`, règle 4) ; redémarrer ensuite le serveur (règle 6).
- Pour les points de compétences, voir `points-de-competences.md` (garde-fou `VerifySpecPoints`).

## 6. Pour modifier le garde-fou des points (exemple de cycle complet)

1. Modifier `GamePlayer.VerifySpecPoints()` (`source/server/GameServer/gameobjects/GamePlayer.cs`, ≈ ligne 10075), par exemple pour ne pas appeler `RespecAllLines()`.
2. Écrire ou adapter un test dans `source/server/Tests/UnitTests/`.
3. `dotnet build` puis `dotnet test` (sections 2 et 3).
4. Arrêter le serveur, sauvegarder, déployer (section 4), relancer, vérifier en jeu avec un personnage de test.
Attention aux règles du projet (`AGENTS.md`) : ne pas perturber les gamebots ni les règles de jeu du propriétaire ; distinguer joueurs, compagnons et gamebots autonomes.

## 7. Pièges à connaître

- Un serveur encore actif verrouille les DLL et garde le port 10300 : fermer le lanceur ET le serveur avant de copier.
- Si un seul des trois dossiers (`runtime/server`, `lib`, `win-x64`) garde l'ancienne DLL, le comportement peut rester ancien : copier les trois.
- La compilation échoue si `serverconfig.xml` manque (section 1).
- Le serveur réécrit les colonnes d'un personnage connecté à chaque sauvegarde : ne modifiez la base qu'avec le serveur arrêté.
