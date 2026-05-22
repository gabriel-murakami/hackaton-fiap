.PHONY: stop

stop:
	docker compose down --remove-orphans
spec_report:
	docker compose run --rm -e RAILS_ENV=test -e RAILS_LOG_TO_STDOUT=false report_service bundle exec rspec
	${MAKE} stop
spec_upload:
	docker compose run --rm -e RAILS_ENV=test -e RAILS_LOG_TO_STDOUT=false upload_service bundle exec rspec
	${MAKE} stop
start:
	docker compose up -d
restart:
	make stop && make start
reset_db:
	docker compose run --rm report_service bundle exec rake db:drop db:create db:migrate
	docker compose run --rm upload_service bundle exec rake db:drop db:create db:migrate
