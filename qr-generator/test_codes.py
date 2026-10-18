"""
Checks the committed QR codes in codes/ against the Makefile: every named
target's PNG exists and decodes to that target's URL, and codes/ holds no
PNG that no target produces. Fails when a URL changes without `make codes`.

Run:  pipenv run pytest
"""

import re
from pathlib import Path

import pytest
from PIL import Image
from pyzbar.pyzbar import decode

HERE = Path(__file__).parent
CODES = HERE / "codes"

TARGET = re.compile(
    # One target's recipe: no blank line between its --url and --output.
    r'--url "(?P<url>(?:https?://|sms:)[^"]+)"(?:(?!\n\n).)*?--output "\$\(CODES\)/(?P<png>[^"]+)"',
    re.S,
)


def named_codes():
    makefile = (HERE / "Makefile").read_text()
    return {m["png"]: m["url"] for m in TARGET.finditer(makefile)}


def test_makefile_has_named_codes():
    assert len(named_codes()) >= 11


@pytest.mark.parametrize("png,url", sorted(named_codes().items()))
def test_committed_code_matches_makefile_url(png, url):
    path = CODES / png
    assert path.exists(), f"{png} missing: run `make codes`"
    assert [r.data.decode() for r in decode(Image.open(path))] == [url]


def test_no_orphan_codes():
    orphans = {p.name for p in CODES.glob("*.png")} - set(named_codes())
    assert not orphans, f"PNGs with no Makefile target: {sorted(orphans)}"
