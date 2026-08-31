# Raptacon 3200 — branded QR code generator
#
# Common tasks. Everything runs inside the pipenv-managed virtualenv.
#
#   make install     one-time setup (creates the venv, installs deps + dev deps)
#   make qr           interactive run (prompts for URL + caption)
#   make qr URL="https://forms.gle/abc" CAPTION="Sign Up" OUTPUT=build/signup.png
#   make test         round-trip scan tests (pytest + zbar)
#   make example      generate a sample check-in QR into build/
#   make clean        remove generated output
#   make distclean    also remove the virtualenv

PIPENV ?= pipenv
RUN     = $(PIPENV) run

LOGO   ?= Raptacon_Logo.png
OUTPUT ?= build/raptacon_qr.png

.PHONY: help install qr test example clean distclean

help:
	@grep -E '^#( |$$)' $(MAKEFILE_LIST) | sed -E 's/^#( |$$)//'

install:
	$(PIPENV) install --dev

## With no URL/CAPTION set, the script prompts for them interactively.
qr: | build
	$(RUN) python make_qr.py \
	  $(if $(strip $(URL)),--url "$(URL)") \
	  $(if $(strip $(CAPTION)),--caption "$(CAPTION)") \
	  --logo "$(LOGO)" --output "$(OUTPUT)"

test:
	$(RUN) pytest -q

example: | build
	$(RUN) python make_qr.py \
	  --url "https://forms.gle/raptacon-checkin-test" \
	  --caption "Check In / Out" \
	  --logo "$(LOGO)" --output "build/example_checkin.png"
	@echo "Wrote build/example_checkin.png"

build:
	@mkdir -p build

clean:
	rm -rf build .pytest_cache __pycache__

distclean: clean
	-$(PIPENV) --rm
