NAME = inception

all: pulizia network mariadb wordpress

mariadb: 
	sudo docker build -f srcs/requirements/mariadb/Dockerfile -t mariadb srcs/requirements/mariadb
	sudo docker run -d --name mariadb --network wordpress_network -v mariadb_data:/var/lib/mysql mariadb

wordpress:
	sudo docker build -f srcs/requirements/wordpress/Dockerfile -t worpress srcs/requirements/wordpress
	sudo docker run -d --name wordpress --network wordpress_network -v --network wordpress_network -v wordpress_data:/var/www/html wordpress

network: 
	sudo docker network create wordpress_network 2>/dev/null || true

pulizia: 
	docker stop mariadb wordpress nginx 2>/dev/null; docker rm mariadb wordpress nginx 2>/dev/null; docker rmi mariadb wordpress nginx 2>/dev/null; docker volume rm mariadb_data wordpress_data srcs_mariadb_data srcs_wordpress_data 2>/dev/null; docker network rm wordpress_network 2>/dev/null; sudo rm -rf ~/data/mariadb ~/data/wordpress
	sudo docker system prune -a --volumes