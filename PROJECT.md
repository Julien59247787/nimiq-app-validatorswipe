# Validator Swipe — Nimiq Mini Apps Competition (Cycle II)

Notes internes de développement — le pitch destiné au jury est dans `README.md`.

## Statut

**Soumission officielle du Cycle II** (décidé par Julien le 13/09, vote d'équipe 3 voix sur 4,
contre NIM Drop). Déployée et vérifiée en prod sur les deux validateurs
(`dashboard-nodenimiq{1,2}.nimiq-ju.fr/miniapps/validator-swipe/`).

## Ce qui est fait

- Les ~40 validateurs actifs du réseau, données réelles via `/api/v2/validators-list`
  (address, stake, disponibilité, fiabilité, taux de récompense, frais — `—` explicite si absent,
  jamais deviné). Les deux validateurs de Julien gardent leur nom/description.
- Flux en deux phases (ajouté le 13/09, demande de Julien) : **Parcourir** (passer / mettre de côté
  — gratuit, aucune transaction) puis **Mes favoris** (retirer / déléguer — seul endroit où
  `sendNewStakerTransaction()` part réellement). Navigation arrière dans les deux écrans.
- i18n fr/en (pattern `T`/`t()`/`data-i18n`, cohérent avec le dashboard).
- FAQ "Qui paie quoi ?" expliquant déléguer vs transférer.
- Repli gracieux en mode démo hors de Nimiq Pay.

## Ce qui reste à faire avant la deadline (18/09 23:59 UTC)

1. **Test réel de bout en bout dans Nimiq Pay** (délégation réelle confirmée) — jamais fait pour
   aucune des 4 mini apps, priorité absolue maintenant que le choix est tranché. Seul Julien peut
   le faire (accès à l'app + un appareil).
2. **Dépôt public** : `nimiq-app-validatorswipe` doit passer en public sous licence MIT (exigence du
   règlement — pas d'alternative privé+accès juges). `LICENSE` (MIT) et `README.md` (pitch jury)
   déjà ajoutés au dépôt en préparation. Seul Julien bascule un dépôt en public (règle d'équipe) —
   à faire par lui avant soumission.
3. Renseigner le formulaire de soumission (portail Nimiq) : nom/pseudo, profil GitHub, adresse
   Nimiq de paiement du lead d'équipe — infos à fournir par Julien, pas par moi.
4. Vidéo de démo (optionnelle mais encouragée, contribue au score storytelling) — à évaluer si le
   temps le permet d'ici la deadline.
