# Raptacon 3200 — Branded QR Code Generator

Generates a QR code with the Raptacon logo in the center, black modules on
white, and high (Level-H) error correction so the embedded logo doesn't
break scannability. An optional caption can be printed below the code for
printed materials.

## Why

We hand out a lot of links — check-in / check-out, event sign-ups, parent
and mentor interest forms, safety quizzes. A plain `forms.gle` QR works but
looks anonymous on a flyer or a table tent. A branded code is instantly
recognizable as ours and still scans from a phone camera at arm's length.

## Ready-made codes

Print-ready codes live in [`codes/`](codes/), one per named Makefile target.
Download a PNG straight from GitHub; no setup needed.

| Code | Target | Links to |
|------|--------|----------|
| [Student sign-up](codes/new_returning_student_signup.png) | `student_signup` | Student sign-up form |
| [Parent sign-up](codes/new_returning_parent_signup.png) | `parent_signup` | Parent sign-up form |
| [Mentor/Volunteer sign-up](codes/new_returning_mentor_volunteer_signup.png) | `mentor_volunteer_signup` | Mentor/Volunteer sign-up form |
| [Check in / out](codes/attendance_checkin_checkout.png) | `attendance_checkin_checkout` | Attendance check-in form |
| [GitHub & Discord usernames](codes/team_accounts.png) | `team_accounts` | Team accounts form (add GitHub/Discord usernames) |
| [Roster viewer (mentors)](codes/roster_viewer.png) | `roster_viewer` | Read-only roster viewer; opens only for people with Master Roster access |
| [Interest form](codes/interested_in_joining.png) | `raptacon_interest_signup` | Interest form |
| [Handbook](codes/raptacon_handbook.png) | `raptacon_handbook` | Raptacon Handbook (Google Doc) |
| [Handbook acknowledgment](codes/handbook_acknowledgment.png) | `handbook_ack` | Handbook acknowledgment form |
| [Team calendar](codes/team_calendar.png) | `team_calendar` | Team calendar page |
| [Discord](codes/discord_signup.png) | `raptacon_discord_signup` | Discord invite |
| [Remind](codes/remind_signup.png) | `remind_signup` | Texts @3200rapta to 81010 (Remind sign-up) |
| [Payments](codes/raptacon_payments.png) | `raptacon_payments` | Boosters payment store (pay.raptacon.org) |

To change a link: edit its target's `--url` in the Makefile, run
`make codes`, and commit the regenerated PNG. `make test` fails if a
committed code doesn't match its Makefile URL, or if `codes/` has a PNG no
target produces.

## Setup

This is a [pipenv](https://pipenv.pypa.io/) project.

```bash
cd qr-generator
make install        # or: pipenv install --dev
```

`make install` creates the virtualenv and installs both the runtime
dependencies (`qrcode[pil]`, `pillow`) and the dev dependencies used by the
tests (`pytest`, `pyzbar`).

`pyzbar` needs the native **zbar** library to be present for the tests to
run:

```bash
brew install zbar          # macOS
sudo apt-get install libzbar0   # Debian/Ubuntu
```

zbar is only needed for `make test` (it decodes generated codes to verify
they still scan). Generating QR codes does not require it.

## Usage

### With make (recommended)

```bash
make qr                                   # prompts for URL + caption
make qr URL="https://forms.gle/abc123" CAPTION="Check In / Out" OUTPUT=build/checkin.png
make example                               # writes a sample to build/
```

### Directly

Interactive — prompts for the URL and an optional caption:

```bash
pipenv run python make_qr.py
```

Non-interactive — pass any of the flags (handy for generating a batch):

```bash
pipenv run python make_qr.py \
  --url "https://forms.gle/abc123" \
  --caption "Check In / Out" \
  --logo Raptacon_Logo.png \
  --output checkin_qr.png
```

| Flag        | Default             | Notes                                             |
|-------------|---------------------|---------------------------------------------------|
| `--url`     | *(prompted)*        | The link the QR encodes. Required.                |
| `--caption` | *(prompted)*        | Text printed below the code. Empty = no caption.  |
| `--logo`    | `Raptacon_Logo.png` | Path to the center logo. Missing file = plain QR. |
| `--output`  | `raptacon_qr.png`   | Output PNG path.                                  |

The PNG is saved as RGB and is ready to drop into a doc or send to print.

## Brand color

**Raptacon green is `#84EC5C`.** This README is the canonical reference for
that value; it is also recorded as a comment in `make_qr.py`.

The QR modules themselves stay **black**, not green — black-on-white gives
the best contrast and the most reliable scans. The green is the logo's own
background color.

## About the logo

`Raptacon_Logo.png` currently has a **solid green background** and includes
the "RAPTACON 3200" wordmark. That works fine as-is: the logo is sized to
~28% of the code's width, well under the ~30% that Level-H error correction
tolerates, and the generated codes decode cleanly (see the tests).

A **transparent, icon-only** version — just the bird, dropping the wordmark
(which is unreadable at QR-embed size anyway) — would look cleaner centered
in a code. It's a nice-to-have, not a blocker. If someone makes one, just
drop it in as `Raptacon_Logo.png` (or point `--logo` at it); no code
changes needed.

## Tests

`test_make_qr.py` is a round-trip check: it builds codes with the real
logo composited in, then decodes them back with zbar and asserts the
payload survived. It also covers the caption path, the missing-logo
fallback, and the end-to-end CLI.

```bash
make test           # or: pipenv run pytest
```
