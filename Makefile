# --- Developer notebook tools ---

YELLOW := \033[33m
RESET  := \033[0m
CI_IMAGE := fusillator/ci-tools:2026.10.06

.PHONY: unit-tests linter precommit-check generate-hash pull

pull:
	@printf "$(YELLOW)Pulling the ci tools image...$(RESET)\n"
	docker pull $(CI_IMAGE)

generate-hash: pull 
	@printf "$(YELLOW)Generating hash for dependencies tree...$(RESET)\n"
	mkdir -p $(CURDIR)/locks
	touch $(CURDIR)/locks/requirements-lock-dev.txt 
	touch $(CURDIR)/locks/requirements-lock.txt
	CUTOFF=$$(date -u -d '7 days ago' +"%Y-%m-%dT00:00:00Z"); \
	docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m \
	--tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m \
	-v $(CURDIR)/pyproject.toml:/home/ci/pyproject.toml:ro \
	-v $(CURDIR)/locks:/home/ci/locks \
	-w /home/ci -e HOME=/home/ci \
	$(CI_IMAGE) \
	sh -c "pip-compile --generate-hashes --pip-args='--only-binary=:all:' --uploaded-prior-to=$$CUTOFF -o locks/requirements-lock.txt pyproject.toml \
	&& pip-compile --generate-hashes --pip-args='--only-binary=:all:' --uploaded-prior-to=$$CUTOFF --extra dev --constraint locks/requirements-lock.txt -o locks/requirements-lock-dev.txt pyproject.toml"
	mv $(CURDIR)/locks/* $(CURDIR) && rmdir $(CURDIR)/locks

unit-tests:
	@printf "$(YELLOW)Running unit tests...$(RESET)\n"
	docker build --target local -t flask-demo:latest .
	docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
	--network=none \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
	--tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
	-v "$(CURDIR)/src/testina:/app/src/testina:ro" \
	-v "$(CURDIR)/tests:/app/tests:ro" \
	-w /app -e HOME=/home/ci \
	flask-demo:latest \
	pytest -m "not integration" -o cache_dir=/home/ci/.cache/pytest_cache

linter: pull
	@printf "$(YELLOW)Running ruff...$(RESET)\n"
	mkdir -p $(CURDIR)/.cache/ruff
	docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
	--network=none \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
	--tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
	-v $(CURDIR):/home/ci:ro \
	-w /home/ci -e HOME=/home/ci -e RUFF_CACHE_DIR=/home/ci/.cache/ruff \
	$(CI_IMAGE) \
	ruff check src tests

sca: pull
	@printf "$(YELLOW)Launching pi-audit...$(RESET)\n"
	docker run --rm --user 1000:1000 --cap-drop=ALL --security-opt=no-new-privileges:true --read-only \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
	--tmpfs /home/ci/.cache:rw,noexec,nosuid,size=128m,uid=1000,gid=1000,mode=0700 \
	-v $(CURDIR)/requirements-lock.txt:/home/ci/requirements-lock.txt:ro \
	-v $(CURDIR)/requirements-lock-dev.txt:/home/ci/requirements-lock-dev.txt:ro \
	-w /home/ci -e HOME=/home/ci \
	$(CI_IMAGE) \
	pip-audit --disable-pip --strict --require-hashes -r requirements-lock.txt -r requirements-lock-dev.txt 

precommit-check: sca linter unit-tests 
