#!/usr/bin/env python3
"""Validate default host port inventory for Toolkit v2."""

import re
import unittest
from pathlib import Path

SOURCE = (
    Path(__file__).resolve().parents[1]
    / "scripts/preflight.sh"
).read_text()


class PreflightPortTests(unittest.TestCase):

    def test_expected_ports(self):
        matches = re.findall(
            r'^check_port\s+(\d+)\s+(tcp|udp)\s+"[^"]+"',
            SOURCE,
            re.MULTILINE,
        )

        actual = {(int(port), proto) for port, proto in matches}

        expected = {
            (9443, "tcp"),
            (5353, "tcp"),
            (5353, "udp"),
            (8088, "tcp"),
            (51821, "udp"),
        }

        self.assertEqual(actual, expected)
        self.assertEqual(len(matches), len(expected))

    def test_no_legacy_wg_easy_labels(self):
        self.assertNotIn("wg-easy", SOURCE.lower())

    def test_assessment_remains_read_only(self):
        self.assertIn("No changes were made to this host.", SOURCE)


if __name__ == "__main__":
    unittest.main(verbosity=2)
