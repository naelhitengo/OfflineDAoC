# Résumé des Ajouts Personnalisés : Sagas et Chants pour le Skald
* **Serveur** : DAoC Offline (Moteur DOL)
* **Package ID** : `Saga_Of_Nael`
* **Ligne de spécialisation** : `Battlesongs`

Ce document récapitule l'ensemble des sorts personnalisés injectés dans la base de données pour enrichir la classe **Skald**, s'appuyant sur une nomenclature nordique immersive et des paramètres techniques adaptés au combat dynamique.

---

## 1. Vue d'ensemble de la Plage d'IDs
Tous les sorts personnalisés ont été intégrés dans une tranche dédiée sécurisée (`401081+`) pour éviter tout conflit avec les identifiants natifs du jeu :
* **Sagas d'Endurance** : `401081` à `401085`
* **Sagas de Mana / Power** : `401121` à `401125`
* **Bulles Bladeturn Pulsées (PBT)** : `402724` à `402726`

---

## 2. Détail des Sagas d'Endurance
*Inspirées des chants de régénération d'endurance, intégrées sur la ligne principale.*

| SpellID | Nom du Sort | Niveau requis | Valeur | Paramètres techniques |
| :--- | :--- | :---: | :---: | :--- |
| **401081** | `Saga of Endurance` | 2 | 1.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401082** | `Saga of Stamina` | 12 | 2.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401083** | `Saga of Persistence` | 22 | 3.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401084** | `Saga of Resilience` | 32 | 4.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401085** | `Saga of Perseverance` | 42 | 5.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |

---

## 3. Détail des Sagas de Mana (Power)
*Inspirées des chants de régénération de power, sans contrainte d'instrument.*

| SpellID | Nom du Sort | Niveau requis | Valeur | Paramètres techniques |
| :--- | :--- | :---: | :---: | :--- |
| **401121** | `Saga of Power` | 10 | 1.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401122** | `Saga of Energy` | 21 | 2.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401123** | `Saga of Clarity` | *[Palier 3]* | 3.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401124** | `Saga of the Mind` | 39 | 4.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |
| **401125** | `Saga of Empowering` | 50 | 5.0 | `Target` = Group, `CastTime` = 0.0, `InstrumentReq` = 0 |

---

## 4. Détail des Bulles Bladeturn Pulsées (PBT)
*Adaptation des sorts de type Runemaster en chants instantanés de groupe.*

| SpellID | Nom du Sort | Niveau requis | Durée / Fréquence | Paramètres techniques |
| :--- | :--- | :---: | :---: | :--- |
| **402724** | `Saga of Guard` | 26 | Durée: 10s / Fréq: 100 | `CastTime` = 0.0, `RecastDelay` = 16, `Radius` = 16 |
| **402725** | `Saga of Barrier` | 34 | Durée: 8s / Fréq: 80 | `CastTime` = 0.0, `RecastDelay` = 16, `Radius` = 16 |
| **402726** | `Saga of Aegis` | 44 | Durée: 6s / Fréq: 60 | `CastTime` = 0.0, `RecastDelay` = 16, `Radius` = 16 |

---

## 5. Paramètres Techniques Communs (Validation DOL)
* **`PackageID`** : `Saga_Of_Nael` (Permet un suivi et un nettoyage propre des ajouts custom).
* **`InstrumentRequirement`** : `0` (Permet l'utilisation des chants en plein combat sans équipement d'instrument spécifique).
* **`CastTime`** : `0.0` (Chants instantanés indispensables pour l'ergonomie du Skald).
* **`LineName`** : `Battlesongs` (Tous les sorts sont directement rattachés à la ligne de spécialisation principale du Skald).