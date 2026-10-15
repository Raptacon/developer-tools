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

student_signup:
	$(RUN) python make_qr.py \
	  --url "https://docs.google.com/forms/d/e/1FAIpQLSfWt5lqr97af-EOEq9cjTrVfWQHFe0CVCMZx-DxC1TgM08EuQ/viewform" \
	  --caption "New/Returning Student Signup" \
	  --logo "$(LOGO)" --output "build/new_returning_student_signup.png"

parent_signup:
	$(RUN) python make_qr.py \
	  --url "https://docs.google.com/forms/d/e/1FAIpQLSdlH22teaJ_KtLI_RqJZGwJbj4pbfXZAI5CEbxjXYV6CDPwKg/viewform" \
	  --caption "New/Returning Parent Signup" \
	  --logo "$(LOGO)" --output "build/new_returning_parent_signup.png"

mentor_volunteer_signup:
	$(RUN) python make_qr.py \
		--url "https://docs.google.com/forms/d/e/1FAIpQLSdyPS4k2cB_XU2jhokFvOwhZi-zGThR1Nhl-Qw0dEeb3wlC8g/viewform" \
	  --caption "New/Returning Mentor Signup" \
	  --logo "$(LOGO)" --output "build/new_returning_mentor_volunteer_signup.png"

attendance_checkin_checkout:
	$(RUN) python make_qr.py \
		--url "https://docs.google.com/forms/d/e/1FAIpQLSdW2tp9eZut-Bmnuwok8-7tUpgPJU0yXWHDZXqZ0Hb2Z-XwUQ/viewform" \
	  --logo "$(LOGO)" --output "build/attendance_checkin_checkout.png"

raptacon_handbook:
	$(RUN) python make_qr.py \
		--url "https://docs.google.com/document/d/19xdyY0cUXU5lqMMsEIhkcs5NqTy1XQ93uskZNUNlgAY/edit?usp=sharing" \
	  --caption "Raptacon Handbook" \
	  --logo "$(LOGO)" --output "build/raptacon_handbook.png"

handbook_ack:
	$(RUN) python make_qr.py \
		--url "https://docs.google.com/forms/d/e/1FAIpQLScWCkReToQ0QJ1SzqZzZwIr7HtPNzqyHdEWpxzEHoWSDCSWuA/viewform" \
	  --caption "Handbook Acknowledgment" \
	  --logo "$(LOGO)" --output "build/handbook_acknowledgment.png"

raptacon_interest_signup:
	$(RUN) python make_qr.py \
		--url "https://docs.google.com/forms/d/e/1FAIpQLSeW0uMsun7YcFj-EK1JcdNO-1nycjypbBniRMwGSOCqltdO1w/viewform" \
	  --caption "Interested in Robots?" \
	  --logo "$(LOGO)" --output "build/interested_in_joining.png"

team_calendar:
	$(RUN) python make_qr.py \
		--url "https://sites.google.com/cherrycreekschools.org/raptacon-3200/calendar" \
	  --caption "Team Calendar" \
	  --logo "$(LOGO)" --output "build/team_calendar.png"

raptacon_discord_signup:
	$(RUN) python make_qr.py \
		--url "https://discord.gg/TdtZqT4fN4" \
	  --caption "Discord Signup" \
	  --logo "$(LOGO)" --output "build/discord_signup.png"
	
raptacon_payments:
	$(RUN) python make_qr.py \
		--url "https://raptacon-boosters.square.site/" \
	  --caption "Raptacon Payments" \
	  --logo "$(LOGO)" --output "build/raptacon_payments.png"

build:
	@mkdir -p build

clean:
	rm -rf build .pytest_cache __pycache__

distclean: clean
	-$(PIPENV) --rm
