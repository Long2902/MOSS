##############################################################
#                                                            #
# AutoMOSS Makefile                                          #
#                                                            #
# Authors: Joshua Lochner, Daniel Lochner and Carl Combrinck #
# Date: 06/10/2021                                           #
#                                                            #
##############################################################
# service mysql start && python3 manage.py runserver 0.0.0.0:80
# service mysql start && until mysqladmin ping -h "localhost" --silent; do echo "Waiting for database connection..."; sleep 2; done && mysql -u root -e "CREATE DATABASE IF NOT EXISTS automoss;" && mysql -u root -e "CREATE USER IF NOT EXISTS 'automoss'@'localhost' IDENTIFIED BY 'password';" && mysql -u root -e "GRANT ALL PRIVILEGES ON automoss.* TO 'automoss'@'localhost';" && mysql -u root -e "FLUSH PRIVILEGES;" && source venv/bin/activate && python manage.py makemigrations && python manage.py migrate && python manage.py runserver 0.0.0.0:8000
# Define variables
MAKE          := make
PYTHON        := python

# Define directories
MEDIA_DIR     := media
COVERAGE_DIR  := htmlcov

# Define files
MAIN          := manage.py

install:
	sudo apt-get -y update
	sudo apt-get -y install redis mysql-server libmysqlclient-dev python3-pip
	python3 -m venv venv
	source venv/bin/activate && pip install --upgrade pip && pip install -r requirements_dev.txt --upgrade
	# pip install -r requirements_dev.txt --upgrade 
	#--break-system-packages
	$(MAKE) db

start-mysql:
	@[ "$(shell ps aux | grep mysqld | grep -v grep)" ] && echo "MySQL already running" || (sudo service mysql start)

run: start-mysql
	$(PYTHON) $(MAIN) runserver

migrations:
	$(PYTHON) $(MAIN) makemigrations && $(PYTHON) $(MAIN) migrate --run-syncdb

create-db:
	@echo "Starting MySQL database server"
	service mysql start
	find . -type d -name __pycache__ -exec rm -r {} \+
	rm -rf htmlcov/*
	rm -rf .coverage
	. venv/bin/activate && $(PYTHON) automoss/db.py

# https://simpleisbetterthancomplex.com/tutorial/2016/07/26/how-to-reset-migrations.html
db: start-mysql clean create-db migrations

docker-rebuild:
	docker-compose build
	$(MAKE) docker-start

docker-start:
	docker-compose up -d

docker-stop:
	docker-compose down

admin:
	$(PYTHON) $(MAIN) createsuperuser

clean-media:
	rm -rf $(MEDIA_DIR)/*

clean-redis:
	rm -f dump.rdb

clean-migrations:
	find . -path '*/migrations/*.py' -delete

clean:
	find . -type d -name __pycache__ -exec rm -r {} \+
	rm -rf $(COVERAGE_DIR)/*
	rm -rf .coverage

clean-all: clean-media clean-redis clean-migrations clean

test:
	export IS_TESTING=1 && $(PYTHON) $(MAIN) test -v 2

coverage:
	export IS_TESTING=1 && coverage run --source='.' $(MAIN) test -v 2
	coverage report
	coverage html
	$(PYTHON) -m webbrowser $(COVERAGE_DIR)/index.html

lint:
	flake8 . --statistics --ignore=E501,W503,F811
