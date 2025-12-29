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

[🔐 Auth](#-authentification) • [🏠 Accueil](#-accueil-adaptatif) • [🗺️ Recherche](#️-recherche-géolocalisée) • [📅 Réservation](#-réservation) • [💳 Paiement](#-paiement-stripe) • [💬 Messagerie](#-messagerie) • [👤 Profil](#-profil-client) • [💇‍♀️ Espace Pro](#%EF%B8%8F-espace-coiffeuse) • [🛡️ Admin](#️-administration)

<br/>

> 🎬 **Vidéo démo** : [Regarder sur YouTube](#) | 📱 **Télécharger l'APK** : [Releases](#)

</div>

---

## 📋 À propos

**Hairbnb** est une application mobile et web complète permettant aux clients de découvrir, réserver et payer des prestations chez des coiffeurs à proximité. Les professionnels disposent d'un espace dédié pour gérer leur salon, leurs services, leurs disponibilités et suivre leurs revenus en temps réel.

### 🎯 Problème résolu

Trouver un coiffeur disponible, comparer les prix et réserver un créneau peut être fastidieux. Hairbnb simplifie ce processus en offrant une plateforme centralisée avec géolocalisation, paiement sécurisé et gestion complète pour les professionnels.

### ✨ Points forts

- 🔍 **Recherche géolocalisée** avec carte interactive et itinéraire
- 📅 **Réservation en temps réel** avec créneaux disponibles
- 💳 **Paiement sécurisé** via Stripe
- 🤖 **Assistant IA** pour les professionnels
- 📊 **Dashboard complet** avec suivi des revenus
- 🛡️ **Panel d'administration** pour la modération

---

## 📱 Captures d'écran

### 🔐 Authentification

Système d'authentification complet avec Firebase : connexion email/mot de passe, Google Sign-In et récupération de mot de passe.

| Connexion | Inscription | Google Sign-In | Mot de passe oublié |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/auth/login.jpeg" width="200"/> | <img src="screenshots/auth/signin.jpeg" width="200"/> | <img src="screenshots/auth/google-signin.jpeg" width="200"/> | <img src="screenshots/auth/forgot-password.jpeg" width="200"/> |

---

### 🏠 Accueil adaptatif

Interface d'accueil qui s'adapte automatiquement au rôle de l'utilisateur (Client ou Coiffeuse) avec des règles et fonctionnalités spécifiques.

**Espace Client :**

| Accueil 1 | Accueil 2 | Accueil 3 |
|:---:|:---:|:---:|
| <img src="screenshots/home/home-client-1.jpeg" width="220"/> | <img src="screenshots/home/home-client-2.jpeg" width="220"/> | <img src="screenshots/home/home-client-3.jpeg" width="220"/> |

**Espace Coiffeuse :**

| Dashboard 1 | Dashboard 2 | Dashboard 3 | Dashboard 4 |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/home/home-hairdresser-1.jpeg" width="200"/> | <img src="screenshots/home/home-hairdresser-2.jpeg" width="200"/> | <img src="screenshots/home/home-hairdresser-3.jpeg" width="200"/> | <img src="screenshots/home/home-hairdresser-4.jpeg" width="200"/> |

---

### 🗺️ Recherche géolocalisée

Recherche avancée par position GPS ou par ville avec carte interactive, calcul d'itinéraire multimodal et partage vers Google Maps, Waze ou Apple Maps.

**Recherche par position GPS :**

| Position GPS 1 | Position GPS 2 |
|:---:|:---:|
| <img src="screenshots/search/search-gps-1.jpeg" width="250"/> | <img src="screenshots/search/search-gps-2.jpeg" width="250"/> |

**Recherche par ville :**

| Recherche ville 1 | Recherche ville 2 |
|:---:|:---:|
| <img src="screenshots/search/search-city-1.jpeg" width="250"/> | <img src="screenshots/search/search-city-2.jpeg" width="250"/> |

**Itinéraire et partage :**

| Calcul itinéraire | Partage navigation |
|:---:|:---:|
| <img src="screenshots/search/itinerary.jpeg" width="250"/> | <img src="screenshots/search/share-itinerary.jpeg" width="250"/> |

**Fiche salon complète :**

| Carte salon | Profil 1 | Profil 2 | Profil 3 |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/search/salon-card.jpeg" width="200"/> | <img src="screenshots/search/salon-profile-1.jpeg" width="200"/> | <img src="screenshots/search/salon-profile-2.jpeg" width="200"/> | <img src="screenshots/search/salon-profile-3.jpeg" width="200"/> |

| Profil 4 | Horaires | Services | Contact |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/search/salon-profile-4.jpeg" width="200"/> | <img src="screenshots/search/salon-hours.jpeg" width="200"/> | <img src="screenshots/search/salon-services.jpeg" width="200"/> | <img src="screenshots/search/contact-salon.jpeg" width="200"/> |

| Appeler le salon |
|:---:|
| <img src="screenshots/search/call-salon.jpeg" width="250"/> |

---

### 📅 Réservation

Processus de réservation complet : sélection de services, panier, choix de date/heure parmi les créneaux disponibles, et suivi des réservations avec countdown en temps réel.

**Sélection et panier :**

| Sélection service | Ajout panier | Panier | Récapitulatif |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/booking/select-service.jpeg" width="200"/> | <img src="screenshots/booking/add-to-cart-success.jpeg" width="200"/> | <img src="screenshots/booking/cart.jpeg" width="200"/> | <img src="screenshots/booking/cart-summary.jpeg" width="200"/> |

**Choix date et heure :**

| Confirmation | Sélection date | Sélection heure |
|:---:|:---:|:---:|
| <img src="screenshots/booking/checkout-1.jpeg" width="220"/> | <img src="screenshots/booking/select-date.jpeg" width="220"/> | <img src="screenshots/booking/select-time.jpeg" width="220"/> |

**Suivi des réservations (avec countdown) :**

| Liste RDV 1 | Liste RDV 2 | Liste RDV 3 |
|:---:|:---:|:---:|
| <img src="screenshots/booking/reservations-list-1.jpeg" width="220"/> | <img src="screenshots/booking/reservations-list-2.jpeg" width="220"/> | <img src="screenshots/booking/reservations-list-3.jpeg" width="220"/> |

| Détail commande 1 | Détail commande 2 |
|:---:|:---:|
| <img src="screenshots/booking/reservation-detail-1.jpeg" width="250"/> | <img src="screenshots/booking/reservation-detail-2.jpeg" width="250"/> |

---

### 💳 Paiement Stripe

Intégration complète de Stripe Checkout avec support Stripe Link, cartes bancaires et génération automatique de reçus.

| Page sécurisée | Stripe Checkout | Stripe Link | Reçu Stripe |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/payment/payment-secure.jpeg" width="200"/> | <img src="screenshots/payment/stripe-checkout-1.jpeg" width="200"/> | <img src="screenshots/payment/stripe-checkout-2.jpeg" width="200"/> | <img src="screenshots/payment/stripe-receipt.jpeg" width="200"/> |

---

### 💬 Messagerie

Chat en temps réel entre clients et salons avec historique des conversations.

| Liste conversations | Chat |
|:---:|:---:|
| <img src="screenshots/messaging/conversations-list.jpeg" width="250"/> | <img src="screenshots/messaging/chat.jpeg" width="250"/> |

---

### 👤 Profil Client

Gestion du profil utilisateur avec accès aux favoris, avis donnés et historique des réservations.

| Profil 1 | Profil 2 | Favoris |
|:---:|:---:|:---:|
| <img src="screenshots/profile-client/profile-1.jpeg" width="220"/> | <img src="screenshots/profile-client/profile-2.jpeg" width="220"/> | <img src="screenshots/profile-client/favorites.jpeg" width="220"/> |

| Mes avis | Mes réservations |
|:---:|:---:|
| <img src="screenshots/profile-client/my-reviews.jpeg" width="250"/> | <img src="screenshots/profile-client/my-reservations.jpeg" width="250"/> |

---

### 💇‍♀️ Espace Coiffeuse

Dashboard professionnel complet pour gérer son activité : salon, services, promotions, disponibilités, commandes, avis clients, revenus et assistant IA.

**Dashboard principal :**

| Dashboard 1 | Dashboard 2 |
|:---:|:---:|
| <img src="screenshots/hairdresser/dashboard-1.jpeg" width="250"/> | <img src="screenshots/hairdresser/dashboard-2.jpeg" width="250"/> |

**Profil professionnel :**

| Profil 1 | Profil 2 |
|:---:|:---:|
| <img src="screenshots/hairdresser/profile-1.jpeg" width="250"/> | <img src="screenshots/hairdresser/profile-2.jpeg" width="250"/> |

**Gestion du salon :**

| Mon salon 1 | Mon salon 2 | Mon salon 3 | Mon salon 4 |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/hairdresser/my-salon-1.jpeg" width="200"/> | <img src="screenshots/hairdresser/my-salon-2.jpeg" width="200"/> | <img src="screenshots/hairdresser/my-salon-3.jpeg" width="200"/> | <img src="screenshots/hairdresser/my-salon-4.jpeg" width="200"/> |

**Gestion des services :**

| Liste services | Ajouter service |
|:---:|:---:|
| <img src="screenshots/hairdresser/services-list.jpeg" width="250"/> | <img src="screenshots/hairdresser/add-service.jpeg" width="250"/> |

**Gestion des promotions :**

| Promotions 1 | Promotions 2 | Détail promo | Ajouter promo |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/hairdresser/promotions-1.jpeg" width="200"/> | <img src="screenshots/hairdresser/promotions-2.jpeg" width="200"/> | <img src="screenshots/hairdresser/promotions-3.jpeg" width="200"/> | <img src="screenshots/hairdresser/add-promotion.jpeg" width="200"/> |

**Gestion des disponibilités :**

| Mes disponibilités |
|:---:|
| <img src="screenshots/hairdresser/availabilities.jpeg" width="280"/> |

**Gestion des commandes :**

| Liste commandes | Modifier statut |
|:---:|:---:|
| <img src="screenshots/hairdresser/orders-list.jpeg" width="250"/> | <img src="screenshots/hairdresser/order-status-modal.jpeg" width="250"/> |

**Avis clients :**

| Statistiques avis |
|:---:|
| <img src="screenshots/hairdresser/client-reviews.jpeg" width="280"/> |

**Suivi des revenus :**

| Revenus 1 | Revenus 2 | Revenus 3 |
|:---:|:---:|:---:|
| <img src="screenshots/hairdresser/revenues-1.jpeg" width="220"/> | <img src="screenshots/hairdresser/revenues-2.jpeg" width="220"/> | <img src="screenshots/hairdresser/revenues-3.jpeg" width="220"/> |

**Assistant IA Personnel :**

| Liste conversations | Bienvenue IA | Exemples questions |
|:---:|:---:|:---:|
| <img src="screenshots/hairdresser/ai-assistant-1.jpeg" width="220"/> | <img src="screenshots/hairdresser/ai-assistant-5.jpeg" width="220"/> | <img src="screenshots/hairdresser/ai-assistant-2.jpeg" width="220"/> |

| Questions suggérées | Réponse IA avec données |
|:---:|:---:|
| <img src="screenshots/hairdresser/ai-assistant-4.jpeg" width="250"/> | <img src="screenshots/hairdresser/ai-assistant-3.jpeg" width="250"/> |

---

### 🛡️ Administration

Panel d'administration complet pour la modération des avis, la gestion des utilisateurs et un assistant IA pour l'administration.

**Dashboard Admin :**

| Admin 1 | Admin 2 |
|:---:|:---:|
| <img src="screenshots/admin/dashboard-1.jpeg" width="250"/> | <img src="screenshots/admin/dashboard-2.jpeg" width="250"/> |

**Modération des avis :**

| Modération avis |
|:---:|
| <img src="screenshots/admin/reviews-moderation.jpeg" width="280"/> |

**Gestion des utilisateurs :**

| Utilisateurs 1 | Utilisateurs 2 |
|:---:|:---:|
| <img src="screenshots/admin/users-management-1.jpeg" width="250"/> | <img src="screenshots/admin/users-management-2.jpeg" width="250"/> |

**Assistant IA Admin :**

| IA Admin 1 | IA Admin 2 | IA Admin 3 |
|:---:|:---:|:---:|
| <img src="screenshots/admin/ai-admin-1.jpeg" width="220"/> | <img src="screenshots/admin/ai-admin-2.jpeg" width="220"/> | <img src="screenshots/admin/ai-admin-3.jpeg" width="220"/> |

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

| Ressource | Méthodes | Description |
|-----------|----------|-------------|
| `/api/users/` | GET, PUT, DELETE | Gestion du profil utilisateur |
| `/api/salons/` | GET, POST, PUT | Gestion des salons |
| `/api/salons/nearby/` | GET | Recherche géolocalisée |
| `/api/services/` | GET, POST, PUT, DELETE | Gestion des services |
| `/api/reservations/` | GET, POST, PUT | Gestion des réservations |
| `/api/payments/` | POST | Création session Stripe |
| `/api/conversations/` | GET, POST | Messagerie |
| `/api/reviews/` | GET, POST, PUT, DELETE | Gestion des avis |
| `/api/ai/chat/` | POST | Assistant IA |

---

## 📁 Structure du projet

```
hairbnb/
├── backend/                    # API Django
│   ├── hairbnb/               # Configuration Django
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
│   │   ├── config/            # Configuration
│   │   ├── models/            # Modèles de données
│   │   ├── providers/         # State management
│   │   ├── services/          # Services API
│   │   ├── screens/           # Écrans de l'app
│   │   └── widgets/           # Composants réutilisables
│   ├── assets/
│   └── pubspec.yaml
│
├── screenshots/               # Captures d'écran
├── docs/                      # Documentation
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🧪 Tests

```bash
# Backend
cd backend && python manage.py test

# Frontend
cd frontend && flutter test
```

---

## 🤝 Contribution

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

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/votre-profil/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/faceoff2003)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://votre-portfolio.com)

*Développeur Full Stack - Diplômé en Informatique de Gestion (EAFC Colfontaine, 2025)*

</div>

---

<div align="center">

### ⭐ Si ce projet vous a plu, n'hésitez pas à lui donner une étoile !

<br/>

Made with ❤️ and ☕ in Belgium 🇧🇪

</div>
