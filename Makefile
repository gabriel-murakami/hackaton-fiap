.PHONY: stop

stop:
	docker compose down --remove-orphans
spec_report:
	docker compose run --rm -e RAILS_ENV=test -e RAILS_LOG_TO_STDOUT=false report_service bundle exec rspec
spec_upload:
	docker compose run --rm -e RAILS_ENV=test -e RAILS_LOG_TO_STDOUT=false upload_service bundle exec rspec
