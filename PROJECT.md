# Validator Swipe — Nimiq Mini Apps Competition (Cycle II)

Notes internes de développement — le pitch destiné au jury est dans `README.md`.

## Statut

**Soumission officielle du Cycle II** (décidé par Julien le 13/09, vote d'équipe 3 voix sur 4,
contre NIM Drop). Déployée et vérifiée en prod sur les deux validateurs
(`dashboard-nodenimiq{1,2}.nimiq-ju.fr/miniapps/validator-swipe/`).

## Infos de soumission (confirmées par Julien, 17/09)

- Nom d'équipe : **@Ju'Team**
- Membres : Ju & Claude
- Compte X : julien59247787
- Email de contact : ju@nimiq-ju.fr
- Login GitHub : julien59247787
- Adresse Nimiq de paiement : `NQ17 498K 2LSH A4XN 9CTG Q018 8UJE X5BF T5UK`

## Ce qui est fait

- Les ~40 validateurs actifs du réseau, données réelles via `/api/v2/validators-list`
  (address, stake, disponibilité, fiabilité, taux de récompense, frais — `—` explicite si absent,
  jamais deviné ; nom publié NimiqHub affiché quand disponible). Les deux validateurs de Julien
  traités comme tous les autres (plus de tag/couleur spéciale, demande de Julien le 17/09).
- Flux en deux phases : **Parcourir** (passer / mettre de côté — gratuit, aucune transaction) puis
  **Mes favoris** (seul endroit où une vraie transaction part). Cartes redimensionnées à leur
  contenu réel (plus de zone morte), navigation ◀▶ dans les deux vues.
- **Cycle de staking complet et réel**, testé en conditions réelles par Julien :
  créer un staker / ajouter à un stake existant / changer de validateur
  (`sendNewStakerTransaction` / `sendStakeTransaction` / `sendUpdateStakerTransaction`, choix
  automatique selon l'état réel via `/api/v2/staker-status`) ; retirer (`sendRetireStakeTransaction`)
  puis récupérer les fonds après le délai réseau (`sendRemoveStakeTransaction`). Bloc "Mon stake"
  et bandeau de délégation active pilotés par les vraies données on-chain, visibles dès la connexion.
- **Connexion hors Nimiq Pay via Nimiq Hub** (bouton "Se connecter", popup Keyguard) pour tester/
  utiliser l'app en navigateur classique — délégation réelle possible par ce chemin aussi (transaction
  construite localement via `@nimiq/core`, signée et diffusée via `hubApi.checkout()`). Seule
  exception : "Récupérer mes fonds" reste Nimiq-Pay-only (mapping des champs non vérifié à temps
  pour ce cas particulier côté Hub).
- i18n complet dans les 11 langues du dashboard (fr, en, es, zh, ja, ko, de, pt, ru, tr, ar) via DeepL,
  traductions machine non relues par des locuteurs natifs (signalé honnêtement, repli fr si clé
  manquante).
- Charte graphique alignée sur le logo officiel du projet (bleu + or, échantillonnés directement sur
  les pixels du fichier logo, pas devinés) ; mascotte et footer credit cohérents avec le dashboard.
- Messages d'erreur humains (pas le jargon brut du SDK) avec détail technique disponible en second
  plan pour le débogage ; modales de succès/erreur cohérentes dans toute l'app.
- Repli gracieux en mode démo hors de Nimiq Pay et hors connexion Hub.

## Ce qui reste à faire avant la deadline (18/09 23:59 UTC)

- ~~Dépôt public~~ **Fait** — `nimiq-app-validatorswipe` est déjà public sous licence MIT (scan de
  sécurité fait avant bascule, rien de confidentiel trouvé). Plus bloquant.
1. **Formulaire de soumission** (portail Nimiq) : infos ci-dessus confirmées, restent à saisir dans
   le formulaire lui-même par Julien.
2. **Décision en attente** : NIM Drop — bouton "Se connecter"/délégation réelle hors Nimiq Pay
   possible aussi (via Hub) mais son flux d'envoi tourne en arrière-plan (incompatible avec le
   popup Hub tel quel) ; changement de flux nécessaire si Julien veut ça pour NIM Drop aussi. Sans
   incidence sur Validator Swipe (soumission officielle), à traiter seulement si le temps le permet.
3. Vidéo de démo (optionnelle mais encouragée, contribue au score storytelling) — gérée par Julien.
4. Repasse qualité 11 langues sur le dashboard principal — explicitement en dernier dans l'ordre de
   priorité de Julien, après les 4 mini apps ; pas encore commencée.
