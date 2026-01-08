NAME = inception
COMPOSE = sudo docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/ldei-sva/data

all: compose

compose:
	sudo mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) stop

up:
	$(COMPOSE) start

clean:
	$(COMPOSE) down -v --rmi all 2>/dev/null || true
	sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	sudo docker system prune -af --volumes

re: clean all

.PHONY: all compose down up clean re