bash:
	@docker compose run app bash

dump:
	@docker compose run app bash -c "bin/dump.bash $(s)"

run:
	@docker compose run app bash -c "bin/run.bash $(s)"

gdb:
	@docker compose run app bash -c "bin/gdb.bash $(s)"
