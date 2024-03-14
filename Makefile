bash:
	@docker compose run $(a) bash # make bash a=x86_64 (or x86_32)

run:
	@docker compose run $(a) bash -c "bin/run.bash $(s) $(a)" # make run a=x86_64 s=hello

hello.world:
	@docker compose run x86_32 bash -c "bin/run.bash hello x86_32" 
	@docker compose run x86_64 bash -c "bin/run.bash hello x86_64" 

run_x86:
	@docker compose run x86_64 bash -c "bin/run_x86.bash $(s)" # make run a=x86_64 s=hello
