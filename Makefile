all:
	./pinata-ssh-pull.sh || ./pinata-ssh-build.sh
	@echo Please run "make install"

build: ## Builds docker image latest
	./pinata-ssh-build.sh

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

install:
	@if [ ! -d "$(PREFIX)" ]; then echo Error: need a $(PREFIX) directory; exit 1; fi
	@mkdir -p $(BINDIR)
	cp pinata-ssh-forward.sh $(BINDIR)/pinata-ssh-forward
	cp pinata-ssh-mount.sh $(BINDIR)/pinata-ssh-mount
	cp pinata-ssh-pull.sh $(BINDIR)/pinata-ssh-pull

NAME := ssh-agent-forward
TAG := latest
IMAGE_NAME := uber/$(NAME)

clean: ## Remove built images
	docker rmi $(IMAGE_NAME):latest || true
	docker rmi $(IMAGE_NAME):$(TAG) || true
