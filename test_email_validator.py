"""Tests for email_validator.is_valid_email."""

import pytest
from email_validator import is_valid_email


# ---------------------------------------------------------------------------
# Valid addresses
# ---------------------------------------------------------------------------
VALID = [
    # typical cases
    "user@example.com",
    "User.Name@example.com",
    "user+tag@example.co.uk",
    "user-name@sub.domain.org",
    "u@x.io",
    "a@b.cc",
    # all allowed special characters in local part
    "user!#$%&'*+/=?^_`{|}~-@example.com",
    # dots inside local part
    "first.last@example.com",
    "a.b.c@example.com",
    # numeric TLD (two-char letter TLD like .io, .ai)
    "test@example.ai",
    # subdomain
    "user@mail.example.com",
    # hyphen inside domain label
    "user@my-host.example.com",
    # mixed case
    "USER@EXAMPLE.COM",
    # local part exactly 64 chars
    ("a" * 64) + "@example.com",
    # total length exactly 254: local(64) + @(1) + b*63 + .(1) + c*63 + .(1) + e*61 = 254
    ("a" * 64) + "@" + ("b" * 63) + "." + ("c" * 63) + "." + ("e" * 61),
]


# ---------------------------------------------------------------------------
# Invalid addresses
# ---------------------------------------------------------------------------
INVALID = [
    # empty string
    ("", "empty string"),
    # missing @
    ("userexample.com", "missing @"),
    # multiple @
    ("user@@example.com", "multiple @"),
    ("user@host@example.com", "multiple @"),
    # missing local part
    ("@example.com", "missing local part"),
    # missing domain
    ("user@", "missing domain"),
    # missing TLD (no dot in domain)
    ("user@localhost", "missing TLD"),
    # single-char TLD
    ("user@example.c", "TLD too short"),
    # numeric-only TLD
    ("user@example.123", "numeric TLD"),
    # leading dot in local
    (".user@example.com", "leading dot in local"),
    # trailing dot in local
    ("user.@example.com", "trailing dot in local"),
    # consecutive dots in local
    ("user..name@example.com", "consecutive dots in local"),
    # leading dot in domain
    ("user@.example.com", "leading dot in domain"),
    # trailing dot in domain
    ("user@example.com.", "trailing dot in domain"),
    # consecutive dots in domain
    ("user@example..com", "consecutive dots in domain"),
    # spaces
    ("user @example.com", "space before @"),
    ("user@ example.com", "space after @"),
    ("us er@example.com", "space in local"),
    # tab
    ("user\t@example.com", "tab character"),
    # newline
    ("user\n@example.com", "newline character"),
    # invalid character in local (comma)
    ("user,name@example.com", "comma in local"),
    # invalid character in local (brackets)
    ("user(name@example.com", "parenthesis in local"),
    ("user[name@example.com", "bracket in local"),
    # quoted local part is NOT accepted by this implementation
    ('"user name"@example.com', "quoted local part"),
    # IP literal domain not accepted
    ("user@[192.168.1.1]", "IP literal domain"),
    # hyphen at start of domain label
    ("user@-example.com", "leading hyphen in domain label"),
    # hyphen at end of domain label
    ("user@example-.com", "trailing hyphen in domain label"),
    # local part too long (65 chars)
    (("a" * 65) + "@example.com", "local part > 64 chars"),
    # total length too long (255 chars): local(64)+@(1)+b*63+.(1)+c*63+.(1)+e*62=255
    (("a" * 64) + "@" + ("b" * 63) + "." + ("c" * 63) + "." + ("e" * 62), "total length > 254 chars"),
    # non-string input
    (None, "non-string None"),
    (123, "non-string int"),
    # only whitespace
    ("   ", "whitespace only"),
    # missing both parts
    ("@", "only @"),
]


@pytest.mark.parametrize("email", VALID)
def test_valid(email):
    assert is_valid_email(email), f"Expected valid: {email!r}"


@pytest.mark.parametrize("email,reason", INVALID)
def test_invalid(email, reason):
    assert not is_valid_email(email), f"Expected invalid ({reason}): {email!r}"


# ---------------------------------------------------------------------------
# Length-boundary tests (explicit)
# ---------------------------------------------------------------------------
def test_local_part_exactly_64_chars():
    assert is_valid_email(("a" * 64) + "@example.com")


def test_local_part_65_chars_rejected():
    assert not is_valid_email(("a" * 65) + "@example.com")


def test_total_length_exactly_254():
    # local(64) + @(1) + b*63 + .(1) + c*63 + .(1) + e*61 = 254
    assert is_valid_email(("a" * 64) + "@" + ("b" * 63) + "." + ("c" * 63) + "." + ("e" * 61))


def test_total_length_255_rejected():
    # local(64) + @(1) + b*63 + .(1) + c*63 + .(1) + e*62 = 255
    assert not is_valid_email(("a" * 64) + "@" + ("b" * 63) + "." + ("c" * 63) + "." + ("e" * 62))
