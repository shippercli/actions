"""Exercise HTTP authentication failure through the actual health script."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class HealthAuthenticationTest(unittest.TestCase):
    def test_invalid_token_fails_once_with_actionable_diagnostic(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'matrix.json').write_text(json.dumps([
                {'repository': 'fixture/one', 'workflow': 'ci.yml'},
                {'repository': 'fixture/two', 'workflow': 'ci.yml'},
            ]))
            curl = root / 'curl'
            curl.write_text('#!/bin/sh\necho call >> "$CALLS"\nprintf \'{"message":"Bad credentials"}\\n401\'\nexit 22\n')
            curl.chmod(0o755)
            result = subprocess.run(['bash', 'scripts/check-org-ci-health.sh', str(root / 'matrix.json')],
                env=dict(os.environ, PATH=str(root)+':'+os.environ['PATH'],
                         CALLS=str(root / 'calls'), GITHUB_TOKEN='synthetic-secret'),
                text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('ORG_CI_HEALTH_TOKEN', result.stdout + result.stderr)
            self.assertIn('401', result.stdout + result.stderr)
            self.assertNotIn('synthetic-secret', result.stdout + result.stderr)
            self.assertEqual((root / 'calls').read_text().splitlines(), ['call'])


if __name__ == '__main__':
    unittest.main()
