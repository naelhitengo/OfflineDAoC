donc pour choisir comment baisser les monstres d'une zone, il faut definir une zone cible pour le test. 
on peut baisser, mais on pourrait aussi dans le serveur ideal commencer au niveau 40, et touts les monstres sont niveua 35 minimum, et on peut se balader partout. (faudrait reduire l'agro quand même)

premiere recherche montre qu'il y a des zones et des regions, pour l'instant c'est un peu flou pourquoi cette differentiation geographique.

SELECT  * FROM Zones WHERE ZoneID = 216;
ZoneID	RegionID	Name	IsLava	DivingFlag	WaterLevel	OffsetY	OffsetX	Width	Height	Experience	Realmpoints	Bountypoints	Coin	Realm	LastTimeRowUpdated	Zones_ID
216	200	Sheeroe Hills	0	0	0	79	43	8	8	0	0	0	0	0	2026-10-27 15:37:50.0051605Z	216

select * from Regions where RegionId= 200
RegionID	Name	Description	IP	Port	Expansion	HousingEnabled	DivingEnabled	WaterLevel	ClassType	IsFrontier	LastTimeRowUpdated	Regions_ID
200	Region200	Hibernia	127.0.0.1	10400	0	0	0	0		1	2017-01-08 18:50:32	40b8a17b-f7f2-4e0a-9c3d-093cd9809170



Avant de modifier le niveau des monstres, il faut penser a fair un backup du niveau des mobs 
De ce que je vois le max est 255 (des pnjs de royaume très importants)

les monstres sont de niveau max 81 / les dragons, boss de si et DF

 select   distinct  ClassType, name, Level,Region 
 from mob 
 where level > 55 and level <95
 order by level desc

donc plein de beaux noms :)

DOL.GS.Olcasgean	Olcasgean	87	191
DOL.GS.GlacierGiant	Glacier Giant	86	100
DOL.GS.CryptLord	Crypt Lord	86	60
DOL.GS.KingTuscar	King Tuscar	85	160
DOL.GS.QueenKula	Queen Kula	85	160

DOL.GS.Scripts.Legion	Legion	83	249

DOL.GS.Scripts.LichLordIlron	Lich Lord Ilron	82	60

DOL.GS.Xaga	Xaga	81	191
DOL.GS.Hurionthex	Hurionthex	81	191

DOL.GS.Balor	Balor	81	190

DOL.GS.LordSanguis	Lord Sanguis	81	60

DOL.GS.MidGjalpinulva	Gjalpinulva	80	100

DOL.GS.HibCuuldurach	Cuuldurach the Glimmer King	80	200

DOL.GS.Xanxicar	Xanxicar	80	62

DOL.GS.AlbGolestandt	Golestandt	80	1

DOL.GS.Nosdoden	Nosdoden	80	150


Ton idée de diviser par 5 ce qui dépasse le niveau 50 pour lisser la progression est maligne. En SQLite, tu peux faire ça proprement en une seule requête UPDATE en combinant une condition CASE WHEN :

UPDATE Mob 
SET Level = 50 + CAST((Level - 50) / 5 AS INTEGER)
WHERE Region = <ID_DE_REGION> AND Level > 50;

Exemple avec cette formule :

Un mob niveau 55 donne 50 + (5 / 5) = 51.
Un mob niveau 60 donne 50 + (10 / 5) = 52.
Un mob niveau 75 donne 50 + (25 / 5) = 55.
Ça compresse joliment l'écart de puissance tout en gardant une hiérarchie !



sinon pour le backup 

ALTER TABLE Mob ADD COLUMN defaultLevel INTEGER DEFAULT 0;
UPDATE Mob SET defaultLevel = Level;


voir de revenir en arriere sur une seule region : 
UPDATE Mob 
SET Level = defaultLevel 
WHERE Region = 200;

c'est possible de faire les deux en une requete ? ou risqué ? 
ALTER TABLE Mob ADD COLUMN defaultLevel INTEGER DEFAULT 0;
UPDATE Mob SET defaultLevel = Level;

c'est pour ma culture perso

Techniquement, tu ne peux pas combiner la création d'une colonne et sa mise à jour dans une seule et unique requête SQL (comme un seul ordre exécuté d'un coup).

En SQL standard, l'instruction ALTER TABLE sert à modifier la structure de la table, tandis que UPDATE sert à modifier les données. SQLite (comme la plupart des bases de données) exige que ce soit deux requêtes distinctes :

SQL
-- Requête 1 : Ajout de la structure
ALTER TABLE Mob ADD COLUMN defaultLevel INTEGER DEFAULT 0;

-- Requête 2 : Remplissage des données
UPDATE Mob SET defaultLevel = Level;
Est-ce risqué de les enchaîner ?
Non, ce n'est pas risqué du tout, à condition de les exécuter l'une après l'autre dans le même script ou la même session.

Pourquoi ? Dès que la première instruction (ALTER TABLE) est validée, la colonne defaultLevel existe physiquement dans la table, mais elle est initialisée par défaut à 0 (comme tu l'as précisé dans le DEFAULT 0).

La seconde instruction (UPDATE) vient immédiatement écraser ce 0 pour y copier la valeur exacte du Level de chaque monstre.

C'est une excellente habitude pour garder un historique propre avant de lancer tes modifications de niveaux par strates !


20261030

ok c'est fait pour tur suil


ok c'est fait . 

--select * from mob where Region =190
-- Étape 1 : Ajout de la colonne de secours
-- ALTER TABLE Mob ADD COLUMN defaultLevel INTEGER DEFAULT 0;
-- Étape 2 : Sauvegarde de tous les niveaux d'origine
-- UPDATE Mob SET defaultLevel = Level;

-- Étape 3 : Application du lissage par strates uniquement sur la région 190
-- UPDATE Mob 
-- SET Level = 50 + CAST((Level - 50) / 5 AS INTEGER)
-- WHERE Region = 190 AND Level > 50;

UPDATE Mob 
 SET Level = 50 + CAST((defaultLevel - 50) / 5 AS INTEGER)
 WHERE Region = 190 AND defaultLevel > 50;

select Name,Region,Level,defaultLevel,ClassType, Brain	
 from mob where Region =190
 order by level desc;

Name	Region	Level	defaultLevel	ClassType	Brain
Balor	190	56	81	DOL.GS.Balor	DOL.AI.Brain.BalorBrain
Sargan the Conqueror	190	54	71	DOL.GS.SarganConqueror	DOL.AI.Brain.SarganConquerorBrain
Norsob the Annihilator	190	54	72	DOL.GS.NorsobAnnihilator	DOL.AI.Brain.NorsobAnnihilatorBrain
Queen Qunilaria	190	54	72	DOL.GS.QueenQunilaria	DOL.AI.Brain.QueenQunilariaBrain
Abomos the Soultrapper	190	53	68	DOL.GS.AbomosSoultrapper	DOL.AI.Brain.AbomosSoultrapperBrain
Kierac the Destroyer	190	53	69	DOL.GS.KieracDestroyer	DOL.AI.Brain.KieracDestroyerBrain
burrowing monstrosity	190	52	60	DOL.GS.GameNPC	
balorian huon	190	51	56	DOL.GS.GameNPC	
balorian huon	190	51	56	DOL.GS.GameNPC	
balorian maccus	190	51	57	DOL.GS.GameNPC	
balorian huon	190	51	56	DOL.GS.GameNPC	
burrowing monstrosity	190	51	57	DOL.GS.GameNPC	
balorian huon	190	51	56	DOL.GS.GameNPC	
balorian huon	190	51	56	DOL.GS.GameNPC	


bonnus : 

UPDATE Mob 
 SET Level = 50 + CAST((defaultLevel - 50) / 5 AS INTEGER)
 WHERE Region in(50,150,62) AND defaultLevel > 50;

select Name,Region,Level,defaultLevel,ClassType, Brain	
 from mob where Region in(50,150,62)
 order by level desc;

 
 select * from regions where regionId in(50,150,62) ;
RegionID	Name	Description	IP	Port
50	Region050	Avalon City	127.0.0.1	10400
62	Region062	Crystal Cave	127.0.0.1	10400
150	Region150	Trollheim	127.0.0.1	10400


Name	Region	Level	defaultLevel	ClassType	Brain
Xanxicar	62	56	80	DOL.GS.Xanxicar	DOL.AI.Brain.XanxicarBrain
Nosdoden	150	56	80	DOL.GS.Nosdoden	DOL.AI.Brain.NosdodenBrain
Uppat gungledar	150	55	77	DOL.GS.GameNPC	
Dura'ek the Empowered	50	54	71	DOL.GS.DuraekEmpowered	DOL.AI.Brain.DuraekEmpoweredBrain
Rotodjur	150	54	71	DOL.GS.Rotoddjur	DOL.AI.Brain.RotoddjurBrain

Name	Region	Level	defaultLevel	ClassType
xanxicarian elite	62	55	75	DOL.GS.GameEpicNPC
xanxicarian sentry	50	54	70	DOL.GS.GameNPC


ca sera fun :)

20261108
ok j'ai beau editer le sql, le "level" revient a la meme valeur docn il faut que ej trouve ou om est ecrasé ...

select Name,Region,Level,defaultLevel,ClassType, Brain	
 from mob where Region in(50,150,62)
 order by level desc;
