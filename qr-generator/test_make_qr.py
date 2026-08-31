"""
Round-trip tests for make_qr.py.

The important property is that a generated QR still *scans* after the logo
is composited into the middle of it. These tests build a code, decode it
back with zbar (via pyzbar), and assert the payload survived.

Run:  pipenv run pytest
"""

from pathlib import Path

import pytest
from PIL import Image
from pyzbar.pyzbar import decode

import make_qr

TEST_URL = "https://forms.gle/raptacon-checkin-test"
LOGO = Path(__file__).parent / "Raptacon_Logo.png"


def decoded_payloads(img: Image.Image):
    return [r.data.decode() for r in decode(img)]


def test_logo_present_for_tests():
    assert LOGO.exists(), "Raptacon_Logo.png should sit next to the script"


def test_qr_with_logo_still_scans():
    img = make_qr.build_qr_with_logo(TEST_URL, LOGO)
    assert decoded_payloads(img) == [TEST_URL]


def test_logo_stays_under_error_correction_budget():
    # Level-H tolerates ~30% obscured; we should be comfortably below that.
    assert make_qr.LOGO_SIZE_RATIO ** 2 < 0.15


def test_missing_logo_still_produces_a_scannable_qr(tmp_path, capsys):
    img = make_qr.build_qr_with_logo(TEST_URL, tmp_path / "nope.png")
    assert "logo not found" in capsys.readouterr().out
    assert decoded_payloads(img) == [TEST_URL]


def test_caption_expands_canvas_without_breaking_scan():
    base = make_qr.build_qr_with_logo(TEST_URL, LOGO)
    captioned = make_qr.add_caption(base, "Check In / Out")
    assert captioned.height > base.height
    assert captioned.width == base.width
    assert decoded_payloads(captioned) == [TEST_URL]


def test_end_to_end_file_output(tmp_path, monkeypatch):
    out = tmp_path / "qr.png"
    monkeypatch.setattr(
        "sys.argv",
        ["make_qr.py", "--url", TEST_URL, "--caption", "Sign Up", "--output", str(out)],
    )
    make_qr.main()
    assert out.exists()
    assert decoded_payloads(Image.open(out)) == [TEST_URL]


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))
