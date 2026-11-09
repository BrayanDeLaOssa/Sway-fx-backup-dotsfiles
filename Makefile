# Atajos de desarrollo
.PHONY: install uninstall doctor test lint check

install:
	./install.sh

uninstall:
	./uninstall.sh

doctor:
	./install.sh doctor

test:
	./tests/test-installer.sh

check: lint test

lint:
	@for f in install.sh uninstall.sh scripts/doctor.sh scripts/lib/*.sh \
		dotfiles/sway/scripts/*.sh tests/*.sh; do \
		bash -n "$$f" || exit 1; \
	done
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning install.sh uninstall.sh scripts/doctor.sh \
			scripts/lib/*.sh dotfiles/sway/scripts/*.sh tests/*.sh; \
	else \
		echo "shellcheck no instalado; se omite."; \
	fi
	@echo "Lint OK."
