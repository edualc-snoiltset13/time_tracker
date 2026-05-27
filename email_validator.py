"""
Email address validator (standard-library only).

Validation rules enforced
--------------------------
This implementation targets a practical subset of RFC 5321 / RFC 5322.
Rules are documented explicitly here so behaviour is unambiguous.

Structure
~~~~~~~~~
A valid address has the form:  local@domain

Local part
~~~~~~~~~~
- 1–64 characters (RFC 5321 §4.5.3.1.1)
- Allowed characters: a-z, A-Z, 0-9, and: ! # $ % & ' * + - / = ? ^ _ ` { | } ~
- Dots (.) are allowed between other characters but NOT as the first or last
  character, and NOT consecutively.
- Quoted local parts ("quoted string"@example.com) are NOT accepted.  Keeping
  the implementation simple and rejecting the rarely-used quoting syntax avoids
  a large surface area of edge cases.

Domain part
~~~~~~~~~~~
- 1 or more dot-separated labels.
- Each label: 1–63 characters, a-z / A-Z / 0-9 / hyphen, must not start or end
  with a hyphen (RFC 5321 §4.1.2 / RFC 1123).
- The rightmost label (TLD) must be at least 2 characters and consist only of
  letters (a-z / A-Z).
- IP-literal domains (e.g. [192.168.1.1]) are NOT accepted.
- Total address length must not exceed 254 characters (RFC 5321 §4.5.3.1.3).
- Trailing dots in the domain are not accepted.

Whitespace / control characters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Any whitespace or ASCII control character anywhere in the address is rejected.
"""

import re

# Local part: printable non-special chars + dot rules
_LOCAL_CHARS = r"[a-zA-Z0-9!#$%&'*+\-/=?^_`{|}~]"
_LOCAL_RE = re.compile(
    r"^"
    + _LOCAL_CHARS
    + r"+"  # one or more valid chars at start
    + r"(?:\." + _LOCAL_CHARS + r"+)*"  # optional dot-separated segments
    + r"$"
)

# Domain label: starts and ends with alnum, may contain hyphens in the middle
_LABEL_RE = re.compile(r"^[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$")
_TLD_RE = re.compile(r"^[a-zA-Z]{2,}$")


def is_valid_email(email: str) -> bool:
    """Return True if *email* is a valid address under the rules in this module."""
    if not isinstance(email, str):
        return False

    # Reject anything containing whitespace or ASCII control characters
    if any(c <= " " or c == "\x7f" for c in email):
        return False

    # Total length check (RFC 5321 §4.5.3.1.3)
    if len(email) > 254:
        return False

    # Must contain exactly one '@'
    at_count = email.count("@")
    if at_count != 1:
        return False

    local, domain = email.split("@", 1)

    # --- Local part ---
    if not local or len(local) > 64:
        return False
    if not _LOCAL_RE.match(local):
        return False

    # --- Domain part ---
    if not domain:
        return False

    # Reject trailing dot
    if domain.endswith("."):
        return False

    labels = domain.split(".")
    if len(labels) < 2:
        # No dot in domain → no TLD
        return False

    for i, label in enumerate(labels):
        if not label:
            # Consecutive dots or leading dot
            return False
        is_tld = i == len(labels) - 1
        if is_tld:
            if not _TLD_RE.match(label):
                return False
        else:
            if not _LABEL_RE.match(label):
                return False
            if len(label) > 63:
                return False

    return True
