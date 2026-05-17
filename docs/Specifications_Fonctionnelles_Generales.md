# Specifications Fonctionnelles Generales — Lumora

## 1. Vision Produit et Public Cible

### 1.1 Vision
Lumora est un jeu mobile innovant, intuitif et addictif, concu pour un public large (casual et core gamers). Le style visuel est ultra-moderne : 2D avec effets 3D (parallaxe, lumieres dynamiques, particules). L'UI est 100 % organique — pas de boutons carres gris, pas de bords droits ; tout est arrondi, avec degrades, glassmorphism, ombres portees et micro-animations fluides.

Le jeu vise a offrir une experience accessible a tous, pas seulement aux gamers, grace a une courbe d'apprentissage validee, des indices visuels intelligents et une monetisation respectueuse.

### 1.2 Public Cible
- **Primaire** : Joueurs casual, 18–45 ans, hommes et femmes, jouant sur mobile en sessions courtes (5–15 min).
- **Secondaire** : Core gamers cherchant un defi progressif et des evenements competitifs.
- **Tertiaire** : Public large, y compris seniors et debutants, grace a l'accessibilite renforcee (indices, tutoriel interactif, UI intuitive).

### 1.3 Positionnement
- **Genre** : Puzzle/Reflexion avec mecaniques de progression et collection.
- **Differentiation** : UI 100 % organique et effets 3D dans un moteur 2D ; monetisation non intrusive ; evenements automatiques saisonniers ; partage social natif.
- **Monetisation** : Gratuit avec publicites (interstitielles + recompensees) et IAP abordables (packs de vies, themes cosmétiques, passe saisonnier).

---

## 2. Contraintes d'Accessibilite

### 2.1 Joueur Debutant
- **Tutoriel interactif** : Premier lancement = tutoriel court (max 60 secondes) integre au niveau 1, sans ecran texte statique. Les instructions sont donnees par des bulles organiques arrondies avec des fleches animees.
- **Indicateurs visuels** : Tout element interactif doit avoir un halo pulsant ou une ombre portee animée pour attirer l'attention du joueur.
- **Feedback immediat** : Chaque action (touch, swipe, tap) declenche une animation visuelle (particules, ripple) et un feedback haptique leger (sur mobile).
- **Pas de blocage brutal** : Si le joueur echoue 3 fois sur un niveau, une proposition de passer le niveau (via video recompensee ou consommation de vies) est affichee dans une carte organique arrondie.

### 2.2 Contraintes Visuelles d'Accessibilite
- **Contrastes** : Tout texte doit avoir un ratio de contraste >= 4.5:1 (WCAG 2.1 AA).
- **Tailles de police** : Minimum 14sp pour le texte courant, 16sp pour les boutons, 24sp pour les titres. Support du texte dynamique (accessibilite systeme).
- **Couleurs** : Pas de codes couleur comme seule indication d'etat. Les etats (actif/inactif) doivent etre differencies par forme, ombre, animation ou icone.
- **Duree des animations** : Les animations de gameplay doivent etre >= 200ms et <= 500ms pour ne pas provoquer de malaise. Les micro-animations UI (hover, press) peuvent etre plus courtes (100–150ms).

### 2.3 Contraintes UI Transversales (Organique)
- **Jamais de boutons carres gris** : Tout widget interactif utilise `LumoraButton` ou `LumoraCard` depuis `shared/`. Jamais de `ElevatedButton`, `TextButton` ou `OutlinedButton` bruts de Flutter.
- **Jamais de bords droits** : Tous les conteneurs, cartes, modales et panneaux doivent avoir des coins arrondis (minimum 16dp pour les cartes, 24dp pour les modales, 32dp pour les ecrans complets).
- **Glassmorphism** : Les panneaux de superposition (pause, victoire, defaite) utilisent un effet glassmorphism (blur + opacite partielle + bordure blanche legere).
- **Degrades** : Les fonds d'ecran et les boutons principaux utilisent des degrades lineaires ou radiaux (jamais de couleur unie grise ou beige).
- **Ombres portees** : Tout element suréleve (bouton, carte, avatar) possede une ombre douce (elevation 4–8dp, ombre coloree assortie au theme).
- **Micro-animations** : Toute transition d'ecran utilise un hero animation ou un fade + slide organique (courbes d'animation : ease-in-out-cubic).

---

## 3. Systeme de Compte Utilisateur

### 3.1 Modes d'Authentification
L'application propose 4 modes d'authentification, dans l'ordre de priorite d'affichage :

1. **Google Sign-In** (Android/iOS)
2. **Apple Sign-In** (iOS obligatoire, Android recommandé)
3. **Email / Password** (avec verification d'email)
4. **Anonyme** (jouer sans compte, avec possibilite de liaison ulterieure)

### 3.2 Flux Anonyme -> Authentifie
- Un utilisateur anonyme peut jouer, progresser et effectuer des achats.
- Lors de la liaison avec Google/Apple/Email, la progression, les achats et les ressources (vies, etoiles, themes) sont fusionnes dans le nouveau compte.
- Si un conflit existe (deux comptes avec des progressions differentes), l'utilisateur choisit laquelle conserver via une modale organique.

### 3.3 Regles Metier
- **RB-AC-01** : L'authentification anonyme est proposee par defaut uniquement si l'utilisateur appuie sur "Jouer plus tard" sur l'ecran de bienvenue.
- **RB-AC-02** : La liaison anonyme -> authentifie doit etre possible a tout moment depuis les parametres.
- **RB-AC-03** : Les achats IAP sont rattaches au compte Firebase Auth UID. Un compte anonyme perdant son ID (reinstallation) ne peut pas recuperer ses achats sans liaison prealable.
- **RB-AC-04** : L'ecran d'authentification utilise des boutons organiques arrondis avec les logos Google/Apple/Email, sur un fond degrade avec effet glassmorphism.

---

## 4. Sauvegarde et Restauration Cross-Appareil

### 4.1 Architecture de Sauvegarde
- **Source de verite** : Firestore (cloud).
- **Cache local** : SecureStorage + SharedPreferences pour le offline-first.
- **Synchronisation** : Automatique a chaque fin de niveau, achat, ou changement de parametre. Sync differée si offline.

### 4.2 Donnees Sauvegardees
| Collection Firestore | Champs Principaux |
|----------------------|-------------------|
| `users/{uid}` | profile (nom, avatar, dateCreation), parametres (son, musique, notifications, langue) |
| `progress/{uid}` | niveauCourant, etoilesParNiveau (Map<int,int>), niveauxDebloques (List<int>), timestampDerniereSync |
| `inventory/{uid}` | vies, themesDebloques (List<String>), passeSaisonnierActif (bool, dateExpiration), consommables |
| `events/{uid}` | participations, scores, recompensesRecuperees |
| `purchases/{uid}` | historique des transactions (RevenueCat transactionId, produit, date, montant) |

### 4.3 Regles Metier
- **RB-SA-01** : La restauration sur un nouvel appareil se fait automatiquement apres authentification, en moins de 5 secondes.
- **RB-SA-02** : En cas de conflit de donnees (progression locale plus recente que le cloud), une resolution automatique privilegie la progression la plus avancee (max niveau, max etoiles).
- **RB-SA-03** : L'application fonctionne offline. Les donnees sont stockees localement et syncronisees des que la connexion revient.
- **RB-SA-04** : Un indicateur visuel organique (petit nuage avec fleche en haut a droite) montre l'etat de sync : vert (sync), orange (en attente), rouge (erreur — tap pour retry).

---

## 5. Systeme de Progression

### 5.1 Niveaux
- Le jeu est decoupe en **mondes** (thematiques visuelles) contenant chacun **20 niveaux**.
- Chaque monde est debloque apres avoir obtenu un certain nombre d'etoiles cumulees dans le monde precedent.
- Total au lancement : 5 mondes = 100 niveaux.

### 5.2 Systeme d'Etoiles
- Chaque niveau peut rapporter 1 a 3 etoiles selon la performance :
  - 1 etoile : Niveau termine.
  - 2 etoiles : Termine dans le temps alloue (par niveau).
  - 3 etoiles : Termine sans utiliser d'indice.

### 5.3 Unlocks
| Unlock | Condition |
|--------|-----------|
| Nouveau monde | Etoiles cumulees >= seuil du monde |
| Themes cosmétiques | Achete via IAP ou recompense evenement |
| Passe saisonnier | IAP "Passe Saisonnier" |
| Avatars | Recompenses de streak, evenements, ou IAP |
| Titre de profil | Tous les 10 niveaux completes |

### 5.4 Regles Metier
- **RB-PR-01** : Le joueur ne peut pas sauter un niveau non debloque, sauf via video recompensee (1 saut par tranche de 24h).
- **RB-PR-02** : Les etoiles sont cumulables et retroactives : rejouer un niveau pour ameliorer son score met a jour le max.
- **RB-PR-03** : L'ecran de selection de niveau utilise des bulles organiques flottantes avec parallaxe 3D. Les niveaux verrouilles sont des bulles grises translucides avec un cadenas anime.

---

## 6. Systeme de Difficulte Graduelle

### 6.1 Courbe d'Apprentissage
La difficulte suit une courbe sigmoide moderee :
- **Niveaux 1–10** : Tutoriel implicite, mecaniques introduites une par une, indices frequents.
- **Niveaux 11–30** : Combinaison de 2 mecaniques, temps alloue legerement reduit.
- **Niveaux 31–60** : Combinaison de 3 mecaniques, introduction d'obstacles dynamiques.
- **Niveaux 61–90** : Mecaniques avancees, temps serre, indices rares.
- **Niveaux 91+** : Maitrise complete, defis de precision, recompenses exclusives.

### 6.2 Parametres de Difficulte par Niveau
| Parametre | Plage | Evolution |
|-----------|-------|-----------|
| Temps alloue | 120s – 30s | Decroit lineairement par paliers de 10 niveaux |
| Nombre d'obstacles | 0 – 5 | Augmente tous les 15 niveaux |
| Vitesse des elements | 1.0x – 1.8x | Augmente tous les 20 niveaux |
| Complexite du puzzle | 2 – 8 etapes | Augmente tous les 10 niveaux |

### 6.3 Validation de la Courbe
- La courbe est validee par des tests de playthrough internes (minimum 5 testeurs par tranche de 20 niveaux).
- Un taux de reussite cible est defini par tranche :
  - Niveaux 1–10 : >= 95 % de reussite.
  - Niveaux 11–30 : >= 80 %.
  - Niveaux 31–60 : >= 65 %.
  - Niveaux 61+ : >= 50 %.
- Si le taux reel est inferieur de > 10 points, le niveau est ajuste (temps +10s, obstacle retire, ou indice plus precoce).

### 6.4 Regles Metier
- **RB-DI-01** : Jamais de blocage brutal. Si un joueur echoue 3 fois de suite sur un niveau, le systeme propose automatiquement un indice gratuit (sans penalite d'etoile) ou une video recompensee pour passer le niveau.
- **RB-DI-02** : La difficulte est ajustable dynamiquement via Firebase Remote Config pour les cohortes A/B testing.

---

## 7. Systeme d'Indices Visuels Decroissants

### 7.1 Concept
Pour garantir l'accessibilite des debutants sans frustrer les joueurs avances, le systeme d'indices (`HintSystem`) adapte automatiquement son comportement selon la progression du joueur.

### 7.2 Parametres par Palier

| Palier (Niveaux) | Delai avant indice (s) | Opacite de l'indice | Frequence d'apparition | Type d'indice |
|------------------|------------------------|---------------------|------------------------|---------------|
| 1 – 10 | 15 | 90 % | A chaque hesitation > 5s | Fleche animee + halo brillant |
| 11 – 25 | 25 | 75 % | Toutes les 2 hesitations | Halo pulsant seul |
| 26 – 45 | 40 | 60 % | Toutes les 3 hesitations | Contour subtil + son subtil |
| 46 – 70 | 60 | 45 % | Toutes les 5 hesitations | Eclaircissement passif de la zone cible |
| 71 – 100 | Aucun (desactive par defaut) | 30 % | Sur demande manuelle (bouton indice) | Ombre legere |
| 101+ | Aucun | 20 % | Sur demande manuelle | Micro-ripple |

### 7.3 Comportement Dynamique
- **Hesitation** : Le joueur ne touche aucun element interactif pendant X secondes (X = 5s par defaut, configurable).
- **Indice automatique** : Declenche apres le delai du palier, si le joueur est en hesitation.
- **Indice manuel** : Bouton indice accessible depuis la barre de pause (icone ampoule organique). Consomme 1 indice gratuit (regenere toutes les 24h) ou propose une video recompensee.

### 7.4 Regles Metier
- **RB-IN-01** : Les indices automatiques ne retirent pas d'etoile. Seuls les indices manuels actives avant la victoire retirent la 3e etoile.
- **RB-IN-02** : L'opacite de l'indice est proportionnelle au palier : moins le joueur est debutant, plus l'indice est subtil.
- **RB-IN-03** : Le delai avant indice augmente lineairement par palier pour forcer l'autonomie.
- **RB-IN-04** : La frequence d'apparition decroit pour eviter le spoil des solutions.
- **RB-IN-05** : Le joueur peut desactiver les indices automatiques dans les parametres (toggle organique arrondi).

---

## 8. Partage Social

### 8.1 Capture d'Ecran de Fin de Niveau
- A la fin de chaque niveau (victoire ou defaite), une capture d'ecran du jeu est generee automatiquement.
- Un overlay organique est ajoute :
  - Avatar du joueur (rond, avec bordure degradee).
  - Score / etoiles obtenues (bulles flottantes).
  - Texte personnalise : "J'ai complete le niveau 42 de Lumora avec 3 etoiles ! Peux-tu faire mieux ?"
  - Background glassmorphism avec le logo Lumora.

### 8.2 Partage Reseaux Sociaux
- Le joueur peut partager via : Instagram, Facebook, Twitter/X, WhatsApp, Snapchat, ou generique (share_sheet).
- Le partage inclut : image + texte + lien dynamique (Firebase Dynamic Links) redirigeant vers la fiche store.
- Si le destinataire installe le jeu via le lien, le joueur original recoit une recompense (vie + indice) — systeme de parrainage.

### 8.3 Regles Metier
- **RB-SO-01** : Le bouton de partage est present sur l'ecran de victoire sous forme de bulle organique flottante avec une icone de partie.
- **RB-SO-02** : L'overlay de partage respecte la charte organique : jamais de rectangles, jamais de bords droits, degrades et ombres portees.
- **RB-SO-03** : Les liens dynamiques expirent apres 30 jours. Le parrainage est credite une seule fois par nouvel install.
- **RB-SO-04** : Le joueur peut desactiver le partage automatique a la victoire dans les parametres.

---

## 9. Monetisation

### 9.1 Modele Economique
Lumora est **gratuit** avec :
- **Publicites interstitielles** : Affichees tous les X niveaux.
- **Publicites recompensees** : Visionnement volontaire pour obtenir une recompense.
- **IAP abordables** : Achats integres a prix bas pour maximiser la conversion.

### 9.2 Publicites Interstitielles
- **Frequence** : 1 interstitielle tous les **5 niveaux completes** (par defaut, parametrable via Remote Config).
- **Placement** : Apres l'ecran de victoire, avant la carte de selection de niveau.
- **Regles** :
  - Jamais pendant un niveau.
  - Jamais apres une defaite (pour eviter la frustration).
  - Cooldown minimum 60s entre deux interstitielles.
  - Reseau : Google Mobile Ads (AdMob).

### 9.3 Publicites Recompensees
- **Declenchement** : Volontaire, via bouton organique "Bonus" en forme de bulle.
- **Recompenses possibles** :
  - 1 vie supplementaire (quand le joueur est a 0 vie).
  - 1 indice supplementaire (quand le stock est a 0).
  - Doubler les recompenses du daily reward.
  - Debloquer un theme cosmétique pendant 24h (essai).

### 9.4 Achats Integres (IAP) — Abordables
Tous les prix sont TTC et indexes en USD ; ajustes localement par RevenueCat.

| Produit | Prix (USD) | Description |
|---------|------------|-------------|
| **Pack de 5 Vies** | 0.99 $ | Recharge immediate, utilisable a tout moment |
| **Pack de 20 Vies** | 2.99 $ | Meilleur rapport qualite/prix |
| **Pack de 50 Vies** | 4.99 $ | Max 5$ — respect contrainte "abordable" |
| **Theme Premium "Nebula"** | 1.99 $ | Theme visuel cosmétique avec effets 3D exclusifs |
| **Pack de 3 Themes** | 3.99 $ | Bundle de themes saisonniers |
| **Passe Saisonnier** | 4.99 $ | Deblocage de niveaux evenementiels, recompenses x2, pub interstitielle desactivee |

### 9.5 Regles Metier
- **RB-MO-01** : Aucune publicite n'est affichee aux joueurs ayant achete le Passe Saisonnier.
- **RB-MO-02** : Les prix IAP ne depassent jamais 5 $ (strategie "abordable").
- **RB-MO-03** : La premiere video recompensee du jour offre un bonus de 2x (2 vies au lieu de 1).
- **RB-MO-04** : Les interstitielles sont desactivables temporairement via video recompensee (2h sans pub).
- **RB-MO-05** : L'ecran de boutique utilise des cartes organiques arrondies avec apercu 3D du produit, jamais de liste verticale grise.

---

## 10. Systeme de Retention

### 10.1 Notifications de Retour (Push & Locales)
Declenchees par Firebase Cloud Messaging + notifications locales (fallback si FCM non autorise).

| Delai apres derniere session | Contenu de la notification | Son / Style |
|------------------------------|----------------------------|-------------|
| **24h** | "Tu nous manques ! Reviens recuperer ta recompense quotidienne." | Son doux, icone cadeau |
| **72h** | "Un nouveau defi week-end t'attend ! Reviens jouer et gagne 3 vies." | Son entrain, icone trophee |
| **7j** | "Ta streak va disparaitre ! Reviens maintenant pour la preserver." | Son urgent mais pas agressif, icone feu |
| **30j** | "Lumora a change ! De nouveaux niveaux et evenements t'attendent." | Son magique, icone etoile |

### 10.2 Daily Rewards
- Calendrier mensuel affiche sous forme de bulles organiques en grille circulaire.
- Recompense croissante : J1=1 vie, J2=2 vies, J3=1 indice, J4=2 indices, J5=theme essai 24h, J6=3 vies, J7=5 vies + 1 theme.
- **Streak** : Si le joueur revient 7 jours consecutifs, un bonus de streak (trophee + avatar exclusif) est accorde.
- **Rupture** : Si le joueur manque un jour, le streak est remis a zero (sauf si rachete via video recompensee ou IAP "Protection Streak" 0.99$).

### 10.3 Regles Metier
- **RB-RE-01** : Les notifications sont personnalisables (son, heure, desactivation) dans les parametres.
- **RB-RE-02** : La notification 24h n'est pas envoyee si le joueur a deja ouvert l'app ce jour-la.
- **RB-RE-03** : L'ecran de daily reward s'affiche automatiquement au premier lancement de la journee, avec une animation d'ouverture de bulle cadeau (3D, particules).
- **RB-RE-04** : Le systeme de streak est visible en permanence sur l'ecran d'accueil (flamme organique avec compteur arrondi).

---

## 11. Evenements Automatiques

### 11.1 Types d'Evenements

| Evenement | Frequence | Declenchement | Recompenses |
|-----------|-----------|---------------|-------------|
| **Defi Quotidien** | Tous les jours | 00:00 UTC via Cloud Function | 1 vie + 1 etoile bonus |
| **Defi Week-End** | Samedi–Dimanche | Vendredi 20:00 UTC | 3 vies + avatar week-end |
| **Evenement Saisonnier** | Par saison (Halloween, Noel, Paques, Ete, etc.) | Date fixe du calendrier, declenche par Cloud Function `eventScheduler` | Theme saisonnier exclusif + passe reduit |
| **Tournoi Automatique** | Toutes les 2 semaines | Lundi 00:00 UTC | Leaderboard mondial, top 100 = themes exclusifs, top 10 = passe saisonnier gratuit |
| **Happy Hour** | Aleatoire, 2x par semaine | Cloud Function aleatoire entre 18h–22h UTC | Pubs recompensees x2, IAP a -50 % |

### 11.2 Mecanique de Programmation
- Tous les evenements sont planifies via **Google Cloud Scheduler** + **Firebase Cloud Functions**.
- Aucune intervention manuelle n'est requise pour le lancement ou la cloture.
- Les joueurs sont notifies automatiquement par FCM 1h avant le debut d'un evenement (sauf defi quotidien).

### 11.3 Regles Metier
- **RB-EV-01** : Les evenements saisonniers sont prepares 2 semaines a l'avance (assets, parametres, traductions).
- **RB-EV-02** : Le joueur ne peut participer qu'a un evenement a la fois s'ils se chevauchent (priorite : Saisonnier > Tournoi > Week-end > Quotidien).
- **RB-EV-03** : Les recompenses d'evenement sont stockees dans l'inventaire et syncronisees cross-device immediatement.
- **RB-EV-04** : L'ecran d'evenement utilise une mise en scene organique : bulles flottantes, compte a rebours circulaire, fond parallaxe 3D saisonnier.

---

## 12. Analytics et A/B Testing

### 12.1 Evenements Tracks (Firebase Analytics)

| Evenement | Parametres |
|-----------|------------|
| `level_start` | level_id, world_id, difficulty_tier |
| `level_complete` | level_id, stars, time_spent, hints_used, retry_count |
| `level_fail` | level_id, time_spent, fail_reason |
| `hint_auto_shown` | level_id, delay_s, opacity, tier |
| `hint_manual_used` | level_id, source (free/ad/rewarded) |
| `ad_interstitial_show` | level_id_after, frequency_config |
| `ad_rewarded_show` | reward_type, placement |
| `iap_purchase` | product_id, price_usd, revenuecat_transaction_id |
| `share_screenshot` | network, level_id, stars |
| `daily_reward_claim` | day_number, streak_count, reward_type |
| `notification_open` | notification_id, delay_since_last_open |
| `event_participate` | event_type, event_id |
| `auth_link` | source (anonymous_to_google/apple/email) |
| `cross_device_restore` | device_type_new, sync_duration_ms |

### 12.2 A/B Testing (Firebase Remote Config)

| Test | Variantes | Objectif |
|------|-----------|----------|
| **Frequence interstitielles** | A: 5 niveaux, B: 3 niveaux, C: 7 niveaux | Maximiser ARPDAU sans baisser D1 retention |
| **Prix IAP vies** | A: 0.99/2.99/4.99, B: 0.79/1.99/3.99 | Maximiser conversion IAP |
| **Courbe difficulte** | A: Courbe actuelle, B: +10s par niveau, C: -1 obstacle | Maximiser D7 retention |
| **Indices automatiques** | A: Actuel, B: Toujours actifs, C: Toujours desactives | Mesurer impact sur progression et frustration |
| **Daily reward streak** | A: Reset a zero, B: -1 jour, C: Freeze gratuit 1x | Maximiser D30 retention |

### 12.3 Regles Metier
- **RB-AN-01** : Aucune donnee personnelle (PII) n'est envoyee a Analytics sans consentement explicite (GDPR/COPPA).
- **RB-AN-02** : Les tests A/B sont actifs minimum 7 jours et necessitent 1000 joueurs par variante pour significance statistique.
- **RB-AN-03** : Remote Config est mis a jour en temps reel (15 min max) sans necessiter de mise a jour de l'app.
- **RB-AN-04** : Crashlytics est configure pour rapporter les crashs non-geres avec le contexte du niveau en cours.

---

## 13. Regles Metier Detaillee par Fonctionnalite

### 13.1 Ecran d'Accueil (Home)
- **RB-HO-01** : L'ecran d'accueil affiche le logo Lumora avec un effet de particules 3D (Flame).
- **RB-HO-02** : Les boutons principaux ("Jouer", "Evenements", "Boutique", "Parametres") sont des bulles organiques flottantes avec parallaxe au mouvement du telephone (gyroscope).
- **RB-HO-03** : Le streak actuel est affiche en haut a droite sous forme de flamme organique avec compteur circulaire.
- **RB-HO-04** : Si un evenement est actif, une bulle saisonniere flottante attire l'attention avec une micro-animation de pulsation.

### 13.2 Ecran de Selection de Niveau (World Map)
- **RB-WM-01** : La carte est un fond parallaxe 2D+3D avec des couches de profondeur.
- **RB-WM-02** : Les niveaux sont representes par des bulles flottantes reliees par des fils organiques (courbes de Bezier).
- **RB-WM-03** : Les bulles de niveaux completes brillent avec le nombre d'etoiles obtenues (1–3 petites etoiles flottantes).
- **RB-WM-04** : Les bulles verrouillees sont grises translucides avec un cadenas anime. Tap = vibration legere + message "Complete les niveaux precedents !".
- **RB-WM-05** : Aucune liste verticale ou grille carree. Tout est organique et flottant.

### 13.3 Gameplay (Niveau)
- **RB-GP-01** : Le niveau est rendu en 2D avec des effets 3D : parallaxe de fond, lumieres dynamiques (ombres portees animees), particules lors des interactions.
- **RB-GP-02** : La barre superieure affiche : niveau actuel (bulle), vies restantes (coeurs flottants), timer (cercle organique qui se remplit), bouton pause (bulle), bouton indice (ampoule organique).
- **RB-GP-03** : Le bouton pause ouvre une modale glassmorphism avec des options circulaires : Reprendre, Recommencer, Parametres, Quitter.
- **RB-GP-04** : Tout element interactif a un rayon de tap minimum 48dp (accessibilite) et un feedback haptique + visuel (ripple + particules).

### 13.4 Ecran de Victoire
- **RB-VI-01** : Transition en slow-motion avec explosion de particules 3D (confettis, etoiles).
- **RB-VI-02** : Les etoiles gagnees apparaissent une par une avec un son progressif.
- **RB-VI-03** : Boutons organiques : "Niveau Suivant" (bulle verte degradee), "Partager" (bulle bleue avec icone), "Menu" (bulle grise translucide).
- **RB-VI-04** : Si le joueur a obtenu 3 etoiles pour la premiere fois, un texte "Parfait !" apparait avec un effet de zoom elastique.

### 13.5 Ecran de Defaite
- **RB-DF-01** : Fond qui s'assombrit progressivement avec des particules tombantes (pluie douce).
- **RB-DF-02** : Message d'encouragement aleatoire : "Presque !", "Tu y es presque !", "Reessaye avec un indice !" dans une bulle organique.
- **RB-DF-03** : Boutons : "Reessayer" (bulle orange), "Utiliser une Vie" (bulle rouge si vies > 0, sinon grise), "Quitter" (bulle grise translucide).
- **RB-DF-04** : Si vies = 0, proposition de video recompensee pour 1 vie ou redirection boutique organique.

### 13.6 Boutique (IAP)
- **RB-BO-01** : Fond degrade avec elements 3D flottants (modeles du jeu en rotation lente).
- **RB-BO-02** : Les produits sont presentes dans des cartes organiques arrondies avec apercu du contenu (animation 3D du theme ou des vies qui flottent).
- **RB-BO-03** : Le Passe Saisonnier est mis en avant dans une carte plus grande avec compte a rebours de l'evenement actuel.
- **RB-BO-04** : Prix affiches en gros avec badge "Populaire" sur le pack de 20 vies.
- **RB-BO-05** : Aucune grille carree. Les cartes sont disposées en scroll horizontal organique avec snap elastic.

### 13.7 Parametres
- **RB-PA-01** : Liste d'options dans des cartes organiques empilees avec espacement doux.
- **RB-PA-02** : Toggles arrondis (switch iOS-style) pour : Musique, Son, Vibrations, Notifications, Indices Auto.
- **RB-PA-03** : Bouton "Restaurer les Achats" obligatoire (guideline Apple/Google) dans une bulle secondaire.
- **RB-PA-04** : Section "Compte" avec possibilite de lier anonyme -> Google/Apple/Email, ou de deconnexion.

---

## 14. Contraintes Transversales — Verification Finale

Checklist obligatoire a valider dans chaque livrable et a chaque revue :

- [ ] **UI organique** : Aucun bouton carre gris, aucun bord droit dans l'application. Tous les widgets interactifs utilisent `LumoraButton` / `LumoraCard`.
- [ ] **2D avec effets 3D** : Parallaxe, lumieres dynamiques, particules, ombres portees presentes dans les ecrans principaux (accueil, gameplay, victoire).
- [ ] **Indices decroissants** : Le `HintSystem` parametre opacite, delai et frequence par palier de progression. Teste sur 100+ niveaux.
- [ ] **Compte utilisateur** : Google Sign-In, Apple Sign-In, Email/Password, Anonyme disponibles. Liaison anonyme -> authentifie preserve la progression.
- [ ] **Sauvegarde cross-device** : Firestore user-scoped, restauration automatique < 5s, fonctionnement offline avec sync differée.
- [ ] **Partage social** : Capture d'ecran + overlay organique + lien dynamique + parrainage fonctionnels.
- [ ] **Gratuit + pubs + IAP abordables** : Interstitielles (1/5 niveaux), recompensees (vie/indice), IAP <= 5$.
- [ ] **Evenements automatiques** : Defis quotidiens, week-end, saisonniers, tournois automatiques programmes via Cloud Scheduler sans intervention manuelle.
- [ ] **Notifications de retour** : Notifications push/locales a 24h, 72h, 7j, 30j avec contenu personnalise.

---

## 15. Glossaire

| Terme | Definition |
|-------|------------|
| **UI organique** | Design sans bords droits, avec formes arrondies, degrades, glassmorphism et ombres portees |
| **2D+3D** | Rendu 2D avec effets de profondeur (parallaxe, lumieres, particules, shaders) |
| **Indices decroissants** | Systeme d'aide visuelle dont l'intensite (opacite, delai, frequence) diminue avec la progression |
| **IAP abordables** | Achats integres a moins de 5 $ pour maximiser la conversion |
| **Evenements automatiques** | Evenements programmes declenches par Cloud Functions sans action manuelle |
| **Remote Config** | Service Firebase permettant de modifier les parametres de l'app a la volee |
| **ARPDAU** | Average Revenue Per Daily Active User |
| **LTV** | Lifetime Value — valeur totale generee par un utilisateur |

---

*Document genere le 2026-05-07. Sous-agent Planificateur — Projet Lumora.*
