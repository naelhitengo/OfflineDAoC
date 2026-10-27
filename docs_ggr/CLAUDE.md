# Contexte de travail (docs_ggr)

## Premier prompt de la session

> bonjour sur ce projet on ne travaille que pour augmenter la documentation incluse dans le dossier docs_ggr.
> l'objectif est d'explorer la codebase et de preparer des utilisations futures.

## Cadre

- **Investigations seulement.** On lit et on documente. On ne modifie pas le code du dépôt, on ne compile pas, on ne déploie pas et on ne lance pas de serveur sans demande explicite.
- **Seul `docs_ggr/` est modifié.** Le reste du dépôt (`docs/`, `source/`, `tools/`…) reste intact.
- **Pas de commit ni de push.** Les identifiants git de cette machine sont ceux de l'activité professionnelle de l'utilisateur : ils ne doivent pas servir pour ce dépôt personnel. Ne pas committer, ne pas pousser, ne pas configurer de remote ni d'identité git. Les règles de commit du `CLAUDE.md` global (`<ticket>: <message>`) ne s'appliquent donc pas ici. `docs_ggr/` reste non suivi par git (`?? docs_ggr/`).
- Les règles du projet (`AGENTS.md`) restent valables pour toute recommandation : protéger les données de joueur, ne jamais démarrer ni déployer sans permission, distinguer joueurs réels, compagnons et gamebots autonomes.

## Conventions des notes

- Rédigées en français ; chemins relatifs à la racine du dépôt.
- Chaque note dit ce qui a été **lu**, ce qui est **non vérifié** et si quelque chose a été **exécuté**.
- Numéros de ligne relevés au commit `abb58da` : à revérifier.
- Un nouveau sujet = un nouveau fichier `sujet-en-minuscules.md`, ajouté au tableau de `README.md`.
- Reprise de session : voir le dernier `handoff_AAAAMMJJ.md`.
