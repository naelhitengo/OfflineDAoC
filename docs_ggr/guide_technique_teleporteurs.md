# Architecture des Téléporteurs dans OfflineDAoC

Ce document résume le fonctionnement de la téléportation, le rôle des classes C# identifiées (`LiveTeleporter.cs` et `AllRealmsTeleporter.cs`) ainsi que leur articulation avec la base de données SQLite.

---

## 1. Composants Clés

### A. Classes C# (Logique Applicative)

1. **`LiveTeleporter.cs`** (`source/server/GameServer/scripts/teleporters/LiveTeleporter.cs`)
   * **Rôle :** Téléporteur standard basé sur la logique officielle de DAoC.
   * **Fonctionnement :**
     * Envoie du texte formaté au joueur avec des hyperliens entre crochets (ex: `[Svasud Faste]`, `[Jordheim]`).
     * Intercepte les clics du joueur via la méthode `WhisperReceive(GameLiving source, string str)`.
     * Utilise un `switch(str)` pour matcher le mot-clé cliqué et déclencher la téléportation via `t.MoveTo(RegionID, X, Y, Z, Heading)` ou en appelant la base de données.

2. **`AllRealmsTeleporter.cs`** (`source/server/GameServer/gameobjects/CustomNPC/Teleporters/AllRealmsTeleporter.cs`)
   * **Rôle :** PNJ téléporteur personnalisé (*Custom NPC*) permettant de s'affranchir des restrictions de royaume (Albion, Midgard, Hibernia).
   * **Fonctionnement :**
     * Permet le voyage trans-royaumes (idéal pour le mode PvE et les tests avec bots).
     * Peut être assigné directement à un PNJ dans la base de données.

---

## 2. Intégration avec la Base de Données SQLite (`opendaoc.sqlite3.db`)

Le lien entre les objets C# du monde et la base de données repose principalement sur trois tables :

### A. Table `Mob` / `NpcTemplate` (Association PNJ <-> Code C#)
Pour qu'un PNJ (comme *Stor Gothi Annark*) utilise un script de téléportation spécifique :
* **Champ clé :** `ClassType`
* **Valeur :** Le nom complet de la classe C# (ex: `DOL.GS.Scripts.LiveTeleporter` ou `DOL.GS.AllRealmsTeleporter`).

### B. Table `Teleport` (Données des Destinations)
Stocke la liste des points de téléportation connus par le serveur.

| Colonne | Description | Exemple |
| :--- | :--- | :--- |
| **`Type`** | Nom du rôle ou du téléporteur associé | `Castle Sauvage Emissary` |
| **`TeleportID`** | Identifiant de la destination / Nom affiché | `Castle Sauvage`, `Jordheim` |
| **`Realm`** | Royaume associé (1 = Alb, 2 = Mid, 3 = Hib) | `2` |
| **`RegionID`** | Identifiant de la carte/zone | `1` |
| **`X`, `Y`, `Z`** | Coordonnées spatiales de destination | `584151, 477177, 2600` |
| **`Heading`** | Orientation du personnage à l'arrivée | `3058` |

---

## 3. Flux d'Interaction (Joueur <-> PNJ <-> Code <-> DB)

```
[ Joueur Clic sur PNJ ]
         │
         ▼
[ Dialogue affiché avec liens [Destination] ]
         │
         ▼ (Joueur clique sur le lien texte)
         │
[ WhisperReceive(source, "Destination") ]  <--- Intercepté par C#
         │
         ├──► Option A : Coordonnées en dur -> t.MoveTo(...)
         └──► Option B : Recherche SQL dans la table `Teleport`
```

---

## 4. Recommandations pour la création d'un Téléporteur Inter-Royaumes

1. **Créer / Modifier un PNJ dans la table `Mob` :**
   * Choisir ou créer une entrée PNJ dans Midgard, Albion ou Hibernia.
   * Définir son `ClassType` sur `DOL.GS.AllRealmsTeleporter` (ou une variante personnalisée dérivée).
2. **Déclarer les destinations dans `Teleport` ou dans le script :**
   * S'assurer que les zones neutres, donjons épiques ou capitales des 3 royaumes ont leurs coordonnées $X, Y, Z$ bien renseignées.
3. **Compiler et Tester :**
   * Exécuter `dotnet build` pour inclure les éventuelles modifications de scripts.
   * Vérifier en jeu le comportement du PNJ avec le groupe de bots.