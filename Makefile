# Variables
COMPOSE_FILE := docker-compose.yml
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE)
DOCKER_BUILDKIT := DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD := COMPOSE_DOCKER_CLI_BUILD=1

SERVICES_NO_CLI := nginx server matchmaking ai_client frontend_client auth postgres

# Couleurs pour les messages
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Cibles par défaut
.DEFAULT_GOAL := help

setup-ssl:
	@echo "$(YELLOW)Starting SSL setup...$(NC)"
	@if [ ! -d "ssl" ]; then \
		echo "$(GREEN)Creating ssl directory...$(NC)"; \
		mkdir -p ssl; \
	fi
	@if [ ! -f ssl/nginx.crt ] || [ ! -f ssl/nginx.key ]; then \
		echo "$(GREEN)Generating SSL certificates...$(NC)"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout ssl/nginx.key \
			-out ssl/nginx.crt \
			-subj "/C=FR/ST=AURA/L=Lyon/O=42/OU=Student/CN=localhost"; \
	fi
	@echo "$(GREEN)Setting correct permissions for SSL files...$(NC)"
	@chmod 644 ssl/nginx.crt
	@chmod 600 ssl/nginx.key
	@if [ -f ssl/nginx.crt ] && [ -f ssl/nginx.key ]; then \
		echo "$(GREEN)SSL certificates are ready$(NC)"; \
	else \
		echo "$(RED)Warning: SSL certificates were not created properly$(NC)"; \
		exit 1; \
	fi

# Aide
help:
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build [SERVICE]       - Construit tous les conteneurs ou un service spécifique"
	@echo "  build-fast [SERVICE]  - Construit rapidement tous les conteneurs ou un service spécifique"
	@echo "  up [SERVICE]          - Démarre tous les conteneurs ou un service spécifique en arrière-plan"
	@echo "  up-fg [SERVICE]       - Démarre tous les conteneurs ou un service spécifique en avant-plan (avec logs)"
	@echo "  down                  - Arrête et supprime tous les conteneurs"
	@echo "  stop                  - Arrête tous les conteneurs sans les supprimer"
	@echo "  restart [SERVICE]     - Redémarre tous les conteneurs ou un service spécifique"
	@echo "  logs [SERVICE]        - Affiche les logs de tous les conteneurs ou d'un service spécifique"
	@echo "  ps                    - Liste tous les conteneurs"
	@echo "  clean                 - Nettoie tous les conteneurs, images et volumes non utilisés"
	@echo "  nginx-reload          - Recharge la configuration de Nginx"
	@echo "  rebuild [SERVICE]     - Reconstruit et redémarre tous les conteneurs ou un service spécifique"
	@echo "  rebuild-fast [SERVICE]- Reconstruit rapidement et redémarre tous les conteneurs ou un service spécifique"
	@echo "  rebuild-fg [SERVICE]  - Reconstruit et redémarre tous les conteneurs ou un service spécifique en avant-plan"
	@echo "  up-fg-safe            - Démarre tous les services en avant-plan avec gestion sécurisée de l'interruption"
	@echo "  rebuild-fg-safe       - Reconstruit et démarre tous les services en avant-plan avec gestion sécurisée de l'interruption"

# Fonction pour exécuter xhost
define run_xhost
	@echo "$(YELLOW)Configuration de l'accès à l'affichage X11...$(NC)"
	@if command -v xhost > /dev/null; then \
		xhost +local:docker; \
	else \
		echo "$(RED)Commande xhost non trouvée. L'accès à l'affichage X11 pourrait ne pas fonctionner.$(NC)"; \
	fi
endef

# Construire les conteneurs
build: setup-ssl
ifdef SERVICE
	@echo "$(GREEN)Construction du service $(SERVICE)...$(NC)"
	$(DOCKER_COMPOSE) build $(SERVICE)
else
	@echo "$(GREEN)Construction de tous les services...$(NC)"
	$(DOCKER_COMPOSE) build
endif

# Construire rapidement les conteneurs
build-fast: setup-ssl
ifdef SERVICE
	@echo "$(GREEN)Construction rapide du service $(SERVICE)...$(NC)"
	$(DOCKER_BUILDKIT) $(COMPOSE_DOCKER_CLI_BUILD) $(DOCKER_COMPOSE) build $(SERVICE)
else
	@echo "$(GREEN)Construction rapide de tous les services...$(NC)"
	$(DOCKER_BUILDKIT) $(COMPOSE_DOCKER_CLI_BUILD) $(DOCKER_COMPOSE) build
endif

# Démarrer les conteneurs en arrière-plan
up:
	$(call run_xhost)
ifdef SERVICE
	@echo "$(GREEN)Démarrage du service $(SERVICE) en arrière-plan...$(NC)"
	$(DOCKER_COMPOSE) up -d $(SERVICE)
else
	@echo "$(GREEN)Démarrage des services (sans CLI client) en arrière-plan...$(NC)"
	$(DOCKER_COMPOSE) up -d $(SERVICES_NO_CLI)
endif

# Démarrer les conteneurs en avant-plan (avec logs)
up-fg:
	$(call run_xhost)
ifdef SERVICE
	@echo "$(GREEN)Démarrage du service $(SERVICE) en avant-plan...$(NC)"
	$(DOCKER_COMPOSE) up $(SERVICE)
else
	@echo "$(GREEN)Démarrage des services (sans CLI client) en avant-plan...$(NC)"
	$(DOCKER_COMPOSE) up $(SERVICES_NO_CLI)
endif

cli:
	$(call run_xhost)
	@echo "$(GREEN)Démarrage du client CLI...$(NC)"
	@if [ -z "$$(docker compose ps -q cli_client 2>/dev/null)" ]; then \
		echo "$(YELLOW)Démarrage du conteneur CLI client...$(NC)"; \
		$(DOCKER_COMPOSE) up -d cli_client; \
		echo "$(YELLOW)Attente du démarrage complet...$(NC)"; \
		sleep 2; \
	fi
	@echo "$(GREEN)Exécution du programme Python...$(NC)"
	$(DOCKER_COMPOSE) run --rm cli_client python3 main.py

# Arrêter et supprimer tous les conteneurs
down:
	@echo "$(RED)Arrêt et suppression des conteneurs...$(NC)"
	$(DOCKER_COMPOSE) down

# Arrêter tous les conteneurs sans les supprimer
stop:
	@echo "$(YELLOW)Arrêt de tous les conteneurs...$(NC)"
	$(DOCKER_COMPOSE) stop

# Redémarrer les conteneurs
restart:
	$(call run_xhost)
ifdef SERVICE
	@echo "$(GREEN)Redémarrage du service $(SERVICE)...$(NC)"
	$(DOCKER_COMPOSE) restart $(SERVICE)
else
	@echo "$(GREEN)Redémarrage de tous les services...$(NC)"
	$(DOCKER_COMPOSE) restart
endif

# Afficher les logs
logs:
ifdef SERVICE
	@echo "$(GREEN)Affichage des logs du service $(SERVICE)...$(NC)"
	$(DOCKER_COMPOSE) logs -f $(SERVICE)
else
	@echo "$(GREEN)Affichage des logs de tous les services...$(NC)"
	$(DOCKER_COMPOSE) logs -f
endif

# Lister les conteneurs
ps:
	@echo "$(GREEN)Liste des conteneurs:$(NC)"
	$(DOCKER_COMPOSE) ps

# Nettoyer les ressources Docker non utilisées
clean:
	@echo "$(RED)Nettoyage des ressources Docker non utilisées...$(NC)"
	docker system prune -af --volumes

# Recharger la configuration de Nginx
nginx-reload:
	@echo "$(GREEN)Rechargement de la configuration Nginx...$(NC)"
	$(DOCKER_COMPOSE) exec nginx nginx -s reload

# Reconstruire et redémarrer les conteneurs en arrière-plan
rebuild: setup-ssl
	$(call run_xhost)
ifdef SERVICE
	@echo "$(YELLOW)Reconstruction et redémarrage du service $(SERVICE) en arrière-plan...$(NC)"
	$(DOCKER_COMPOSE) up -d --build $(SERVICE)
else
	@echo "$(YELLOW)Reconstruction et redémarrage de tous les services en arrière-plan...$(NC)"
	$(DOCKER_COMPOSE) up -d --build
endif

# Reconstruire rapidement et redémarrer les conteneurs en arrière-plan
rebuild-fast: setup-ssl
	$(call run_xhost)
ifdef SERVICE
	@echo "$(YELLOW)Reconstruction rapide et redémarrage du service $(SERVICE) en arrière-plan...$(NC)"
	$(DOCKER_BUILDKIT) $(COMPOSE_DOCKER_CLI_BUILD) $(DOCKER_COMPOSE) up -d --build $(SERVICE)
else
	@echo "$(YELLOW)Reconstruction rapide et redémarrage de tous les services en arrière-plan...$(NC)"
	$(DOCKER_BUILDKIT) $(COMPOSE_DOCKER_CLI_BUILD) $(DOCKER_COMPOSE) up -d --build
endif

# Reconstruire et redémarrer les conteneurs en avant-plan
rebuild-fg: setup-ssl
	$(call run_xhost)
ifdef SERVICE
	@echo "$(YELLOW)Reconstruction et redémarrage du service $(SERVICE) en avant-plan...$(NC)"
	$(DOCKER_COMPOSE) up --build $(SERVICE)
else
	@echo "$(YELLOW)Reconstruction et redémarrage de tous les services en avant-plan...$(NC)"
	$(DOCKER_COMPOSE) up --build
endif

# Trap pour gérer l'interruption (Ctrl+C)
.PHONY: trap
trap:
	@echo "$(YELLOW)Interruption détectée. Arrêt gracieux des conteneurs...$(NC)"
	$(DOCKER_COMPOSE) stop

# Règle pour exécuter avec trap
up-fg-safe: trap
	$(call run_xhost)
	@echo "$(GREEN)Démarrage des services en avant-plan avec gestion sécurisée de l'interruption...$(NC)"
	$(DOCKER_COMPOSE) up || $(MAKE) stop

rebuild-fg-safe: trap
	$(call run_xhost)
	@echo "$(YELLOW)Reconstruction et démarrage des services en avant-plan avec gestion sécurisée de l'interruption...$(NC)"
	$(DOCKER_COMPOSE) up --build || $(MAKE) stop

.PHONY: help build build-fast up up-fg down stop restart logs ps clean nginx-reload rebuild rebuild-fast rebuild-fg up-fg-safe rebuild-fg-safe
