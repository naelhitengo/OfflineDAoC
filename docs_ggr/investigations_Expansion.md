# ebauche de l'activation d'une extension

## deux pistes pour l'instant 
chercher les occurences de 
C:\ws_opendaoc\OfflineDAoC\source\server\GameServer\Enums\eClientExpansion.cs

namespace DOL.GS
{
    public enum eClientExpansion : int
	{
		None = 1,
		ShroudedIsles = 2,
		TrialsOfAtlantis = 3,
		Catacombs = 4,
		DarknessRising = 5,
		Labyrinth = 6
	}
}

et en base sql
select * from ServerProperty where key ='disabled_expansions'
Category	Key	Description	DefaultValue	Value	LastTimeRowUpdated	ServerProperty_ID
system	disabled_expansions	Disable Trials of Atlantis and every later expansion.	3;4;5;6	3;4;5;6	2000-01-01 00:00:00	


## apprehension
Activer les zones n'est pas suffisant, dans el sql c'est juste pour le client pas le cote serveur
il faudra vérifier les scripts;
les pnjs; les quetes et les mobs... 

si j'en crois la table Mob, il ya 68000 monstres (enfin de loc ou un monstre peut apparaitre avec telle loc etc...

## les pnjs

en plus du teleporter allrealm (voir le md en lien a ajouter )
je vois celui ci : source\server\GameServer\gameobjects\Atlantis\Teleporter\AncientBoundDjinn.cs

## sources
https://github.com/Eve-of-Darkness/db-public/tree/master
https://camelot.allakhazam.com/db/mobsbyzone.html

