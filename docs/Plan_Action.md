# Plan d'Action — Lumora

## Introduction

### Vision
Lumora est un jeu mobile innovant, intuitif et addictif, concu pour un public large (casual et core gamers). Le style visuel est ultra-moderne : 2D avec effets 3D (parallaxe, lumieres dynamiques, particules). L'UI est 100 % organique — pas de boutons carres gris, pas de bords droits ; tout est arrondi, avec degrades, glassmorphism, ombres portees et micro-animations fluides. Le jeu vise a etre accessible a tous, pas seulement aux gamers, grace a une courbe d'apprentissage validee et des indices visuels decroissants intelligents.

### Objectifs
- Livrer un MVP (Minimum Viable Product) complet sur Android et iOS en 16 semaines.
- Atteindre une qualite visuelle et technique premium des le lancement.
- Instaurer une boucle de monetisation saine et non intrusive (gratuit + pubs + IAP abordables).
- Construire une base technique scalable pour les evenements automatiques et les mises a jour saisonnieres.

### KPIs Cibles
| KPI | Cible |
|-----|-------|
| D1 Retention | >= 45 % |
| D7 Retention | >= 20 % |
| D30 Retention | >= 10 % |
| ARPDAU (Revenu moyen par utilisateur actif quotidien) | >= 0.05 $ |
| LTV (Lifetime Value) | >= 2.50 $ |
| Taux de conversion IAP (payant / total) | >= 3 % |
| Temps de session moyen | >= 8 min |
| Niveaux completes par session | >= 3 |

---

## Phase 1 : Conception & Specifications (Semaines 1–4)

### Objectif
Etablir un socle de conception solide : gameplay, economie, progression, monetisation, retention, et charte graphique organique/2D+3D.

### Etapes

| Etape | Description | Livrable | Responsable |
|-------|-------------|----------|-------------|
| 1.1 | Game Design Document (GDD) complet | `docs/GDD.md` | Lead Game Designer |
| 1.2 | Specifications Fonctionnelles Generales | `docs/Specifications_Fonctionnelles_Generales.md` | Lead Product Owner |
| 1.3 | Charte graphique et UI/UX (100 % organique) | `docs/UI_Charte.md` + Figma | Lead UI/UX Designer |
| 1.4 | Architecture technique et choix de stack | `docs/Architecture.md` | Lead Tech |
| 1.5 | Plan de monetisation detaille | `docs/Monetisation.md` | Lead Product Owner |
| 1.6 | Plan de retention et notifications | `docs/Retention.md` | Lead Product Owner |
| 1.7 | Definition des evenements automatiques | `docs/Events.md` | Lead Game Designer |
| 1.8 | Schema Firestore et regles de securite | `docs/Firestore_Schema.md` | Lead Backend |
| 1.9 | Definir les paliers de difficulte et la courbe d'apprentissage | `docs/Difficulty_Curve.md` | Lead Game Designer |
| 1.10 | Definir le systeme d'indices visuels decroissants par palier | `docs/HintSystem.md` | Lead Game Designer |

### Jalons
- **Jalon J1 (Fin S1)** : GDD valide, charte UI/UX approuvee, architecture confirmee.
- **Jalon J2 (Fin S2)** : Specs fonctionnelles finalisees, schema Firestore fige.
- **Jalon J3 (Fin S3)** : Prototype visuel (UI + navigation) jouable en Figma/Flame.
- **Jalon J4 (Fin S4)** : Revue de conception generale, go/no-go pour la phase 2.

### Livrables
- GDD complet
- Specifications Fonctionnelles Generales
- Charte UI/UX (organique, arrondi, glassmorphism, degrades, ombres)
- Architecture technique (Flutter 3.24+, Flame, Riverpod, Firebase)
- Schema Firestore + regles de securite
- Plan de monetisation (pubs + IAP)
- Plan de retention (notifications + daily rewards + streak)
- Calendrier des evenements automatiques
- Courbe de difficulte validee
- Systeme d'indices decroissants parametre

---

## Phase 2 : Developpement (Semaines 5–12)

### 2.1 Frontend (Flutter + Flame)

| Module | Description | Contraintes Transversales Verifiees |
|--------|-------------|--------------------------------------|
| **App Shell** | Router GoRouter, theme Lumora, navigation | UI organique : LumoraButton, LumoraCard uniquement ; jamais de bords droits |
| **Auth** | Google Sign-In, Apple Sign-In, Email/Password, anonyme | Compte utilisateur cross-device obligatoire |
| **Game Core** | Moteur de jeu Flame, boucle de gameplay, niveaux | 2D avec effets 3D (parallaxe, lumieres, particules) |
| **Hint System** | Indices visuels avec opacite, delai, frequence reglables par palier | Indices decroissants integres des la conception |
| **Progression** | Niveaux, etoiles, unlocks, sauvegarde locale + Firestore | Progression cross-device via Firestore |
| **Settings** | Parametres utilisateur, sauvegarde/restauration cross-device | Sauvegarde cross-device obligatoire |
| **Social** | Capture d'ecran de fin de niveau + overlay reseaux sociaux | Partage social obligatoire |
| **Monetisation** | Interstitielles, recompensees, IAP (RevenueCat) | Gratuit + pubs + IAP abordables |
| **Retention** | Notifications locales/push (24h, 72h, 7j, 30j), daily rewards, streak | Notifications de retour obligatoires |
| **Events** | Defis week-end, saisonniers, quotidiens, tournois automatiques | Evenements automatiques obligatoires |
| **Analytics** | Firebase Analytics, Crashlytics, Remote Config pour A/B testing | Analytics et A/B testing integres |

### 2.2 Backend (Firebase)

| Service | Implementation | Details |
|---------|----------------|---------|
| **Firebase Auth** | Google, Apple, Email/Password, anonyme | Liaison compte anonyme -> authentifie preserve la progression |
| **Firestore** | Collections `users`, `levels`, `progress`, `events`, `purchases` | Regles user-scoped ; indexation pour leaderboard |
| **Cloud Functions** | checkQuota, dailyRewardReset, eventScheduler, leaderboardUpdate | Functions securisees, idempotentes |
| **Firebase Storage** | Assets dynamiques, captures de partage social | Regles d'acces publiques pour images de partage |
| **FCM** | Notifications push de retour (24h, 72h, 7j, 30j) | Topics par segment de churn |
| **Remote Config** | Parametres de difficulte, frequence pubs, prix IAP pour A/B testing | Flags par groupe d'utilisateurs |

### 2.3 Integration & Outils

| Outil | Usage |
|-------|-------|
| **Riverpod + build_runner** | State management, providers auto-generes |
| **share_plus** | Partage natif image + texte |
| **firebase_dynamic_links** | Liens profonds pour invites et partage |
| **Google Mobile Ads** | Interstitielles (tous les X niveaux) + recompensees |
| **RevenueCat** | IAP : packs de vies, themes cosmétiques, passe saisonnier |
| **Very Good Analysis** | Linting strict, qualite de code |

### Jalons
- **Jalon J5 (Fin S5)** : Auth complet, navigation UI, theme Lumora integre.
- **Jalon J6 (Fin S6)** : Core gameplay jouable (3 niveaux prototype).
- **Jalon J7 (Fin S7)** : Systeme de progression + sauvegarde Firestore fonctionnel.
- **Jalon J8 (Fin S8)** : Monetisation (pubs + IAP) integree et testable.
- **Jalon J9 (Fin S9)** : Retention (notifications + daily rewards + streak) active.
- **Jalon J10 (Fin S10)** : Evenements automatiques (defis quotidiens + week-end) en place.
- **Jalon J11 (Fin S11)** : Social (partage + leaderboard) operationnel.
- **Jalon J12 (Fin S12)** : Feature freeze, codebase complete, tous les modules integres.

---

## Phase 3 : Test & Validation Visuelle (Semaines 13–14)

### 3.1 QA Interne

| Type de Test | Portee | Critere de Succes |
|--------------|--------|-------------------|
| **Tests Unitaires** | Core, providers, repositories, regles metier | Couverture >= 70 %, `flutter test --tags unit` passe |
| **Tests Widget** | UI organique (LumoraButton, LumoraCard, ecrans) | `flutter test --tags widget` passe, pas de regression visuelle |
| **Tests d'Integration** | Parcours complet : onboarding -> niveau 1 -> pub -> IAP | Passage sans crash sur Android + iOS |
| **Tests de Performance** | Temps de chargement niveau, fluidite 60 FPS | <= 2s chargement niveau, jank < 5 % |
| **Tests d'Accessibilite** | Lecteurs d'ecran, contrastes, tailles de police | Conforme WCAG 2.1 AA |
| **Tests de Compatibilite** | Android 8+ (API 26+), iOS 14+, differents ecrans | Pas de deformation UI, boutons cliquables |
| **Validation Visuelle** | Screenshots par ecran, comparaison charte graphique | 100 % conforme charte organique/2D+3D |

### 3.2 Beta Fermee (TestFlight + Google Play Internal Testing)
- 50–100 testeurs internes et externes.
- Collecte de feedback via Firebase Crashlytics + Google Forms.
- A/B testing preliminaire sur la frequence des pubs (Remote Config).

### 3.3 Validation des Contraintes Transversales
Checklist obligatoire avant passage en Phase 4 :

- [ ] UI organique : aucun bouton carre gris, aucun bord droit detecte dans l'app.
- [ ] Effets 3D presents : parallaxe, lumieres dynamiques ou particules verifies dans au moins 3 niveaux.
- [ ] Indices decroissants : opacite, delai et frequence diminuent bien par palier (teste sur 10 niveaux).
- [ ] Compte utilisateur : Google, Apple, Email et anonyme fonctionnels ; liaison anonyme -> authentifie sans perte.
- [ ] Sauvegarde cross-device : progression restauree sur un second appareil en < 5s.
- [ ] Partage social : capture de fin de niveau generee et partagee avec overlay reseaux sociaux.
- [ ] Monetisation : interstitielles affichees tous les X niveaux, recompensees pour vie/indice, IAP abordables (< 5$).
- [ ] Evenements automatiques : defi quotidien et defi week-end se declenchent sans intervention manuelle.
- [ ] Notifications de retour : notifications 24h, 72h, 7j, 30j recues et cliquables.

### Livrables
- Rapport QA complet avec screenshots de validation visuelle.
- Rapport de couverture de tests (lcov).
- Rapport Crashlytics (zero crash critique).
- Retour beta synthetise et plan de correctifs.

---

## Phase 4 : Deploiement & Suivi (Semaines 15–16 + Post-Launch)

### 4.1 CI/CD & Build

| Pipeline | Description | Outil |
|----------|-------------|-------|
| **CI** | `flutter analyze`, `flutter test --coverage`, build APK/iOS/Web | GitHub Actions |
| **CD** | Build release signe, upload Google Play Console + App Store Connect | GitHub Actions + fastlane |
| **Staging** | Deploy automatique sur Internal Test Track / TestFlight | fastlane |

### 4.2 Soumission Stores

| Etape | Details | Delai |
|-------|---------|-------|
| **Store Assets** | Screenshots, video promo, description localisee (FR, EN, ES, DE) | S15 J1–J3 |
| **Google Play** | APK/AAB release, fiche produit, classification PEGI | S15 J4–J5 |
| **App Store** | Build iOS, fiche App Store, review guidelines | S15 J4–J5 |
| **Attente Review** | Periode de review Apple (~1–2 jours) et Google (~1–3 jours) | S15 J6–S16 J2 |
| **Release** | Production gradualle (10 %, 50 %, 100 %) | S16 J3–J5 |

### 4.3 Monitoring & Iterations Post-Launch

| Outil | Usage | Frequence |
|-------|-------|-----------|
| **Firebase Analytics** | D1/D7/D30 retention, ARPDAU, LTV, funnel conversion | Quotidien |
| **Crashlytics** | Crashs, ANR, exceptions non gerees | Quotidien |
| **Remote Config** | A/B testing : prix IAP, frequence pubs, difficulte niveaux | En continu |
| **RevenueCat Dashboard** | Revenus IAP, churn, renouvellements | Hebdomadaire |
| **Google AdMob** | eCPM, taux de remplissage, revenus pubs | Hebdomadaire |

### Iterations Post-Launch (Mois 2–6)
- **Mois 2** : Ajustement courbe de difficulte selon les drop-offs (Analytics).
- **Mois 3** : Premier evenement saisonnier (ete) + nouveau pack de themes.
- **Mois 4** : Tournoi automatique hebdomadaire + leaderboard mondial.
- **Mois 5** : Nouveaux niveaux (batch de 50) + mecanique gameplay mineure.
- **Mois 6** : Passe saisonnier 2 + optimisation LTV (bundles IAP).

---

## Planning Macro (Timeline Estimee)

| Semaine | Phase | Activites Principales |
|---------|-------|----------------------|
| S1 | Conception | GDD, charte UI/UX, architecture |
| S2 | Conception | Specs fonctionnelles, schema Firestore, monetisation |
| S3 | Conception | Prototype visuel, courbe difficulte, hint system |
| S4 | Conception | Revue generale, go/no-go |
| S5 | Developpement | Auth, UI shell, theme Lumora |
| S6 | Developpement | Core gameplay Flame, 3 niveaux |
| S7 | Developpement | Progression, sauvegarde Firestore |
| S8 | Developpement | Monetisation (Ads + IAP) |
| S9 | Developpement | Retention (notifications + rewards + streak) |
| S10 | Developpement | Evenements automatiques |
| S11 | Developpement | Social, partage, leaderboard |
| S12 | Developpement | Feature freeze, integration finale |
| S13 | Test & QA | Tests unitaires/widget/integration, validation visuelle |
| S14 | Beta | Beta fermee, feedback, correctifs |
| S15 | Deploiement | CI/CD, assets stores, soumission |
| S16 | Release | Review stores, deploiement graduel, monitoring |
| M2–M6 | Post-Launch | Iterations, evenements, A/B testing, nouveaux contenus |

---

## Matrice des Risques et Mitigations

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| **Retards de developpement** | Moyenne | Eleve | Sprints de 1 semaine, revues hebdo, scope freeze a S12 |
| **Rejet store (Apple/Google)** | Faible | Critique | Conformite guidelines des S5, beta interne S13, test pre-submission |
| **Mauvaise retention D1/D7** | Moyenne | Eleve | Courbe difficulte validee, indices decroissants, onboarding tutoriel court et interactif |
| **Revenus IAP insuffisants** | Moyenne | Eleve | Prix abordables (< 5$), A/B testing prix via Remote Config, packs valeur claire |
| **Pubs trop intrusives** | Moyenne | Moyen | Limitation stricte (1 interstitielle tous les 5 niveaux), recompensees optionnelles, respect consentement GDPR/COPPA |
| **Problemes de sauvegarde cross-device** | Faible | Moyen | Firestore user-scoped, tests de restauration systematiques, gestion offline avec sync automatique |
| **Evenements automatiques non fiables** | Faible | Moyen | Cloud Functions idempotentes, monitoring Firebase Scheduler, rollback manuel documente |
| **Couts serveur Firebase imprevus** | Faible | Moyen | Limites Firestore configurees, quotas Cloud Functions, monitoring facturation quotidien |
| **Concurrence jeux casual** | Elevee | Moyen | Differentiation visuelle forte (UI organique, 2D+3D), evenements uniques, communaute Discord/TikTok |
| **Dependance a un package tiers (RevenueCat, Ads)** | Faible | Moyen | Veille version, tests de non-regression a chaque majeure, abstraction des services dans adapters |

---

## Conclusion

Ce plan d'action vise a livrer Lumora en 16 semaines avec une qualite premium, une monetisation saine et une retention optimisee des le premier jour. Chaque phase inclut des jalons clairs, des livrables mesurables et une verification stricte des contraintes transversales (UI organique, 2D+effets 3D, indices decroissants, compte cross-device, partage social, gratuit+pubs+IAP, evenements automatiques, notifications de retour).
