<div align="center">

# ✂️ Hairbnb

### La plateforme qui connecte les coiffeurs et leurs clients

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-5.x-092E20?logo=django&logoColor=white)](https://www.djangoproject.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-008CDD?logo=stripe&logoColor=white)](https://stripe.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<br/>

[📱 Démo](#-démo) • [✨ Fonctionnalités](#-fonctionnalités) • [🛠 Stack Technique](#-stack-technique) • [🚀 Installation](#-installation) • [📖 Documentation API](#-documentation-api)

<br/>

<img src="screenshots/hero-banner.png" alt="Hairbnb Banner" width="100%"/>

</div>

---

## 📋 À propos

**Hairbnb** est une application mobile et web complète permettant aux clients de découvrir, réserver et payer des prestations chez des coiffeurs à proximité. Les professionnels disposent d'un espace dédié pour gérer leur salon, leurs services, leurs disponibilités et suivre leurs revenus en temps réel.

### 🎯 Problème résolu

Trouver un coiffeur disponible, comparer les prix et réserver un créneau peut être fastidieux. Hairbnb simplifie ce processus en offrant une plateforme centralisée avec géolocalisation, paiement sécurisé et gestion complète pour les professionnels.

---

## 📱 Démo

<div align="center">

| Recherche géolocalisée | Réservation | Paiement Stripe |
|:---:|:---:|:---:|
| <img src="screenshots/search-map.png" width="250"/> | <img src="screenshots/booking.png" width="250"/> | <img src="screenshots/payment.png" width="250"/> |

| Espace Coiffeuse | Assistant IA | Administration |
|:---:|:---:|:---:|
| <img src="screenshots/hairdresser-space.png" width="250"/> | <img src="screenshots/ai-assistant.png" width="250"/> | <img src="screenshots/admin-panel.png" width="250"/> |

</div>

> 🎬 **Vidéo démo complète** : [Regarder sur YouTube](#)

---

## ✨ Fonctionnalités

### 👤 Espace Client

<details>
<summary><b>🔐 Authentification sécurisée</b></summary>

- Connexion Email/Mot de passe via Firebase Auth
- Authentification Google Sign-In
- Réinitialisation de mot de passe par email
- Persistance de session

</details>

<details>
<summary><b>🗺️ Recherche géolocalisée</b></summary>

- Recherche par position GPS avec rayon ajustable (10-50km)
- Recherche par ville avec autocomplétion
- Carte interactive avec marqueurs des salons
- Calcul d'itinéraire multimodal (voiture, marche, vélo, transports)
- Partage vers Google Maps, Waze, Apple Maps
- Informations en temps réel : distance, temps estimé, parking

</details>

<details>
<summary><b>📅 Système de réservation complet</b></summary>

- Parcours de services par catégorie (Brushing, Coloration, Chignons...)
- Panier multi-services avec récapitulatif TVA
- Sélection de date via calendrier interactif
- Choix des créneaux horaires disponibles en temps réel
- Countdown jusqu'au rendez-vous
- Historique des réservations avec statuts (En attente, Confirmé, Terminé)

</details>

<details>
<summary><b>💳 Paiement sécurisé Stripe</b></summary>

- Intégration Stripe Checkout
- Support Stripe Link pour paiement rapide
- Cartes bancaires (Visa, Mastercard, etc.)
- Reçus automatiques par email
- Environnement de test/production configurable

</details>

<details>
<summary><b>💬 Messagerie instantanée</b></summary>

- Chat en temps réel avec les salons
- Historique des conversations
- Notifications push

</details>

<details>
<summary><b>⭐ Avis et favoris</b></summary>

- Système de notation 1-5 étoiles
- Commentaires détaillés
- Gestion des salons favoris
- Historique des avis donnés

</details>

---

### 💇‍♀️ Espace Coiffeuse

<details>
<summary><b>📊 Dashboard professionnel</b></summary>

- Vue d'ensemble de l'activité
- Accès rapide à toutes les fonctionnalités
- Interface adaptée au rôle (Coiffeuse / Propriétaire)

</details>

<details>
<summary><b>🏠 Gestion du salon</b></summary>

- Informations générales (nom, adresse, slogan)
- Galerie photos avec upload
- Équipements (WiFi, Parking, TV, Musique...)
- Horaires d'ouverture 7j/7
- Équipe et spécialistes

</details>

<details>
<summary><b>✂️ Gestion des services</b></summary>

- Création/modification/suppression de services
- Organisation par catégories
- Prix et durée personnalisables
- Ajout de services existants ou création de nouveaux

</details>

<details>
<summary><b>🏷️ Gestion des promotions</b></summary>

- Création de promotions avec pourcentage de réduction
- Dates de début et fin configurables
- Statuts : Active, À venir, Expirée
- Application automatique sur les services

</details>

<details>
<summary><b>📅 Gestion des disponibilités</b></summary>

- Configuration des horaires hebdomadaires
- Gestion des indisponibilités ponctuelles
- Créneaux automatiquement calculés

</details>

<details>
<summary><b>📦 Gestion des commandes</b></summary>

- Liste des réservations reçues
- Filtres par statut (En attente, Confirmés, Annulés)
- Actions : Confirmer, Annuler (avec/sans remboursement), Terminer
- Modification de date/heure
- Informations client et paiement

</details>

<details>
<summary><b>💰 Suivi des revenus</b></summary>

- Filtres temporels : Aujourd'hui, Semaine, Mois, Année, Personnalisé
- Métriques clés : Total TTC/HT, TVA, RDV payés, Clients uniques
- Statistiques : Service le plus vendu, Jour le plus rentable
- Détail des rendez-vous payés avec expansion
- Revenus par jour

</details>

<details>
<summary><b>⭐ Avis clients</b></summary>

- Statistiques : Nombre d'avis, Note moyenne, Distribution par étoiles
- Filtres par note
- Consultation des commentaires détaillés

</details>

<details>
<summary><b>🤖 Assistant IA Personnel</b></summary>

- Chat intelligent basé sur les données du salon
- Questions suggérées :
  - "Combien de rendez-vous ce mois-ci ?"
  - "Quels sont mes services les plus populaires ?"
  - "Quel est mon chiffre d'affaires cette semaine ?"
  - "Combien de créneaux libres demain ?"
  - "Comment améliorer ma visibilité ?"
- Historique des conversations avec compteur de tokens
- Réponses personnalisées basées sur les données réelles

</details>

---

### 🛡️ Espace Administration

<details>
<summary><b>📋 Modération des avis</b></summary>

- Recherche par commentaire, client, salon
- Filtres par statut (Visible/Masqué) et note
- Actions : Masquer / Supprimer
- Métadonnées : ID, Client ID, RDV ID

</details>

<details>
<summary><b>👥 Gestion des utilisateurs</b></summary>

- Statistiques : Total, Actifs, Admins
- Recherche par nom/email
- Filtres : Tous, Actifs, Inactifs, Admins
- Actions : Désactiver / Promouvoir admin
- Protection du compte connecté

</details>

<details>
<summary><b>🤖 Assistant IA Admin</b></summary>

- Gestion complète de l'application via chat IA
- Analyses avancées
- Support technique
- Optimisation business
- Requêtes SQL intelligentes sur la base de données

</details>

<details>
<summary><b>📊 Statistiques générales</b></summary>

- Vue d'ensemble de la plateforme
- *(Bientôt disponible)*

</details>

---

## 🛠 Stack Technique

### Frontend

| Technologie | Utilisation |
|-------------|-------------|
| **Flutter 3.x** | Framework UI cross-platform (Android, iOS, Web) |
| **Dart** | Langage de programmation |
| **Provider / Riverpod** | State management |
| **Google Maps Flutter** | Cartes et géolocalisation |
| **Firebase Auth** | Authentification |
| **Stripe Flutter** | Intégration paiements |

### Backend

| Technologie | Utilisation |
|-------------|-------------|
| **Django 5.x** | Framework web Python |
| **Django REST Framework** | API RESTful |
| **PostgreSQL 15** | Base de données relationnelle |
| **Firebase Admin SDK** | Validation des tokens |
| **Stripe API** | Gestion des paiements |
| **OpenAI API** | Assistant IA (GPT) |

### Infrastructure

| Technologie | Utilisation |
|-------------|-------------|
| **Nginx** | Reverse proxy & serveur statique |
| **Gunicorn** | Serveur WSGI Python |
| **Tailscale** | VPN mesh sécurisé |
| **Docker** | Conteneurisation *(optionnel)* |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Android  │  │   iOS    │  │   Web    │                       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │
│       └─────────────┼─────────────┘                             │
│                     │ Flutter                                    │
└─────────────────────┼───────────────────────────────────────────┘
                      │ HTTPS
┌─────────────────────┼───────────────────────────────────────────┐
│                     ▼                                            │
│  ┌─────────────────────────────────────┐                        │
│  │              NGINX                   │                        │
│  │    (Reverse Proxy + Static Files)   │                        │
│  └─────────────────┬───────────────────┘                        │
│                    │                                             │
│  ┌─────────────────▼───────────────────┐                        │
│  │         DJANGO REST API             │                        │
│  │  ┌─────────────────────────────┐    │                        │
│  │  │  • Authentication (Firebase) │    │                        │
│  │  │  • Salons & Services        │    │                        │
│  │  │  • Reservations             │    │                        │
│  │  │  • Payments (Stripe)        │    │                        │
│  │  │  • Messaging                │    │                        │
│  │  │  • AI Assistant (OpenAI)    │    │                        │
│  │  └─────────────────────────────┘    │                        │
│  └─────────────────┬───────────────────┘                        │
│                    │                                             │
│  ┌─────────────────▼───────────────────┐                        │
│  │           PostgreSQL                 │                        │
│  │    (Users, Salons, Bookings...)     │                        │
│  └─────────────────────────────────────┘                        │
│                                                                  │
│                    BACKEND SERVER                                │
└──────────────────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐
│   Firebase   │ │  Stripe  │ │  OpenAI  │
│  (Auth)      │ │(Payments)│ │  (AI)    │
└──────────────┘ └──────────┘ └──────────┘
```

---

## 🚀 Installation

### Prérequis

- **Flutter** 3.x ([Installation](https://docs.flutter.dev/get-started/install))
- **Python** 3.11+ ([Installation](https://www.python.org/downloads/))
- **PostgreSQL** 15+ ([Installation](https://www.postgresql.org/download/))
- **Node.js** 18+ (pour Firebase CLI)

### 1️⃣ Clone du repository

```bash
git clone https://github.com/votre-username/hairbnb.git
cd hairbnb
```

### 2️⃣ Configuration Backend (Django)

```bash
# Accéder au dossier backend
cd backend

# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
.\venv\Scripts\activate   # Windows

# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos configurations

# Appliquer les migrations
python manage.py migrate

# Créer un superutilisateur
python manage.py createsuperuser

# Lancer le serveur de développement
python manage.py runserver
```

### 3️⃣ Configuration Frontend (Flutter)

```bash
# Accéder au dossier frontend
cd ../frontend

# Installer les dépendances
flutter pub get

# Configurer Firebase
# 1. Créer un projet sur Firebase Console
# 2. Ajouter les fichiers de configuration :
#    - android/app/google-services.json
#    - ios/Runner/GoogleService-Info.plist
#    - lib/firebase_options.dart

# Lancer l'application
flutter run
```

### 4️⃣ Variables d'environnement

Créer un fichier `.env` dans le dossier backend :

```env
# Django
DEBUG=True
SECRET_KEY=votre-secret-key-tres-securisee
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgres://user:password@localhost:5432/hairbnb

# Firebase
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json

# Stripe
STRIPE_SECRET_KEY=sk_test_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx

# OpenAI (pour l'assistant IA)
OPENAI_API_KEY=sk-xxxxx
```

---

## 📖 Documentation API

### Authentification

Toutes les requêtes API nécessitent un token Firebase dans le header :

```
Authorization: Bearer <firebase_id_token>
```

### Endpoints principaux

<details>
<summary><b>👤 Utilisateurs</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/users/me/` | Profil utilisateur connecté |
| `PUT` | `/api/users/me/` | Modifier le profil |
| `DELETE` | `/api/users/me/` | Supprimer le compte |

</details>

<details>
<summary><b>💇 Salons</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/salons/` | Liste des salons |
| `GET` | `/api/salons/{id}/` | Détail d'un salon |
| `GET` | `/api/salons/nearby/` | Salons à proximité |
| `POST` | `/api/salons/` | Créer un salon |
| `PUT` | `/api/salons/{id}/` | Modifier un salon |

</details>

<details>
<summary><b>✂️ Services</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/services/` | Liste des services |
| `GET` | `/api/salons/{id}/services/` | Services d'un salon |
| `POST` | `/api/services/` | Créer un service |
| `PUT` | `/api/services/{id}/` | Modifier un service |
| `DELETE` | `/api/services/{id}/` | Supprimer un service |

</details>

<details>
<summary><b>📅 Réservations</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/reservations/` | Mes réservations |
| `POST` | `/api/reservations/` | Créer une réservation |
| `PUT` | `/api/reservations/{id}/status/` | Modifier le statut |
| `GET` | `/api/salons/{id}/availabilities/` | Créneaux disponibles |

</details>

<details>
<summary><b>💳 Paiements</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/payments/create-checkout/` | Créer session Stripe |
| `POST` | `/api/payments/webhook/` | Webhook Stripe |
| `GET` | `/api/payments/{id}/receipt/` | Récupérer le reçu |

</details>

<details>
<summary><b>💬 Messages</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/conversations/` | Mes conversations |
| `GET` | `/api/conversations/{id}/messages/` | Messages d'une conversation |
| `POST` | `/api/messages/` | Envoyer un message |

</details>

<details>
<summary><b>⭐ Avis</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/reviews/` | Mes avis |
| `GET` | `/api/salons/{id}/reviews/` | Avis d'un salon |
| `POST` | `/api/reviews/` | Créer un avis |
| `PUT` | `/api/reviews/{id}/` | Modifier un avis |
| `DELETE` | `/api/reviews/{id}/` | Supprimer un avis |

</details>

<details>
<summary><b>🤖 Assistant IA</b></summary>

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/ai/conversations/` | Mes conversations IA |
| `POST` | `/api/ai/chat/` | Envoyer un message à l'IA |
| `DELETE` | `/api/ai/conversations/{id}/` | Supprimer une conversation |

</details>

---

## 📁 Structure du projet

```
hairbnb/
├── backend/                    # API Django
│   ├── hairbnb/               # Configuration Django
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── users/                 # App utilisateurs
│   ├── salons/                # App salons & services
│   ├── reservations/          # App réservations
│   ├── payments/              # App paiements Stripe
│   ├── messaging/             # App messagerie
│   ├── reviews/               # App avis
│   ├── ai_assistant/          # App assistant IA
│   ├── requirements.txt
│   └── manage.py
│
├── frontend/                   # App Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/            # Configuration (API, Firebase, etc.)
│   │   ├── models/            # Modèles de données
│   │   ├── providers/         # State management
│   │   ├── services/          # Services API
│   │   ├── screens/           # Écrans de l'app
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── search/
│   │   │   ├── booking/
│   │   │   ├── profile/
│   │   │   ├── hairdresser/
│   │   │   └── admin/
│   │   ├── widgets/           # Composants réutilisables
│   │   └── utils/             # Utilitaires
│   ├── assets/                # Images, fonts, etc.
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── screenshots/               # Captures d'écran pour le README
├── docs/                      # Documentation supplémentaire
├── docker-compose.yml         # Configuration Docker (optionnel)
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🧪 Tests

### Backend

```bash
cd backend
python manage.py test
```

### Frontend

```bash
cd frontend
flutter test
```

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment participer :

1. **Fork** le projet
2. Créer une **branche** (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'Add AmazingFeature'`)
4. **Push** sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une **Pull Request**

---

## 📄 Licence

Distribué sous la licence MIT. Voir `LICENSE` pour plus d'informations.

---

## 👨‍💻 Auteur

<div align="center">

**William Soulaymane**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/faceoff2003)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://www.soulayman.be/)

*Développeur Full Stack - Diplômé en Informatique de Gestion (EAFC Colfontaine, 2025)*

</div>

---

<div align="center">

### ⭐ Si ce projet vous a plu, n'hésitez pas à lui donner une étoile !

<br/>

Made with ❤️ and ☕ in Belgium 🇧🇪

</div>
