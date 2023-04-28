all:
	./ssh-pull.sh || ./ssh-build.sh
	@echo Please run "make install"

build: ## Builds docker image latest
	./pinata-ssh-build.sh

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

install:
	@if [ ! -d "$(PREFIX)" ]; then echo Error: need a $(PREFIX) directory; exit 1; fi
	@mkdir -p $(BINDIR)
	cp ssh-forward.sh $(BINDIR)/ssh-forward
	cp ssh-mount.sh $(BINDIR)/ssh-mount
	cp ssh-pull.sh $(BINDIR)/ssh-pull

NAME := ssh-agent-forward
TAG := latest
IMAGE_NAME := uber/$(NAME)

clean: ## Remove built images
	docker rmi $(IMAGE_NAME):latest || true
	docker rmi $(IMAGE_NAME):$(TAG) || true
