.PHONY: build install uninstall test

build:
	./scripts/build-saver.sh

install:
	./scripts/install-saver.sh

uninstall:
	./scripts/uninstall-saver.sh

test:
	swift test
