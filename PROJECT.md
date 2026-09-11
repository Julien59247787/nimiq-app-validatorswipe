# Validator Swipe — Nimiq Mini Apps Competition (Cycle II)

## Concept
Découverte et délégation de validateurs façon "swipe" : score de confiance, taux de récompense et
disponibilité présentés carte par carte, délégation en un tap (`sendNewStakerTransaction`). Lien
direct avec le dashboard des validateurs de Julien — rend le dashboard actionnable, pas seulement
informatif.

## Statut
Extra pour le dashboard, pas candidate à la soumission officielle du Cycle II (NIM Drop a été
choisie). Dépôt GitHub privé par défaut. Les données de validateurs affichées sont des **exemples
clairement identifiés comme tels** dans l'UI — en production, elles doivent venir du dashboard réel
des validateurs, jamais inventées.

## Ce qui est déjà construit
- `index.html` — démo interactive complète, même famille visuelle (Fraunces + Sora), palette
  graphite/vert-signal/violet différenciée du reste de la famille.
- Pile de cartes swipeable (passer / déléguer), 5 validateurs d'exemple.
- FAQ "Qui paie quoi ?" expliquant la différence entre déléguer et transférer (point souvent mal
  compris sur le staking : le validateur ne détient jamais les fonds délégués).
- Détection progressive de `window.nimiqPay`, appel réel `sendNewStakerTransaction()`.

## Ce qui manque pour une intégration dashboard réelle
1. **Remplacer les données d'exemple par les vraies données des deux validateurs** (score de
   confiance, taux de récompense, disponibilité) — nécessite une API/export depuis le dashboard
   existant, à caler avec NIMIQ-BACKEND/NIMIQ-FRONTEND.
2. Gestion du montant à déléguer (actuellement pas de champ de saisie, la démo se concentre sur la
   comparaison/sélection).
3. Hébergement sur l'infra des validateurs, comme les autres apps de la famille.
