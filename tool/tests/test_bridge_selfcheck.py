"""The manual selfcheck must never change a user's valid parameter values."""
import contextlib
import io
import json
from pathlib import Path
import runpy
import sys
import types
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / 'tool/bridge_selfcheck.py'


class BridgeSelfcheckTests(unittest.TestCase):
    def run_check(self, *, fail_read=None, edit_on_read=None, connect_fails=False):
        state = {'steps': 28, 'reads': 0, 'payloads': [], 'valid_writes': [], 'bridges': []}

        class Bridge:
            def __init__(self):
                self.closed = False
                self.ws = self
                state['bridges'].append(self)

            async def connect(self):
                if connect_fails:
                    raise OSError('fixture handshake failure')

            async def rpc(self, kind, payload=None):
                if kind == 'get_params':
                    state['reads'] += 1
                    if state['reads'] == edit_on_read:
                        state['steps'] = 47
                    if state['reads'] == fail_read:
                        raise OSError('fixture read failure')
                    return {'type': 'params', 'prompt': '', 'negative_prompt': '',
                            'model': 'fake', 'sampler': 'fake', 'steps': state['steps'],
                            'cfg_scale': 5, 'seed': 1, 'width': 64, 'height': 64}
                if kind == 'set_params':
                    state['payloads'].append(payload)
                    applied = []
                    if isinstance(payload.get('steps'), int):
                        state['steps'] = payload['steps']
                        state['valid_writes'].append(payload['steps'])
                        applied = ['steps']
                    return {'type': 'params_set', 'applied': applied}
                raise AssertionError(kind)

            async def send(self, text):
                self.sent = json.loads(text)

            async def recv(self):
                return json.dumps({'type': 'error', 'code': 'invalid_request'})

            async def close(self):
                self.closed = True

        module = types.ModuleType('nai_bridge_client')
        module.Bridge = Bridge
        module.DISCOVERY = types.SimpleNamespace(
            read_text=lambda **_: json.dumps({'port': 0, 'pid': 0}))
        before_path = list(sys.path)
        error = None
        code = None
        try:
            with patch.dict(sys.modules, {'nai_bridge_client': module}), \
                    patch('subprocess.run', return_value=types.SimpleNamespace(stdout='nai_launcher.exe')), \
                    contextlib.redirect_stdout(io.StringIO()):
                try:
                    runpy.run_path(str(SCRIPT), run_name='__main__')
                except SystemExit as result:
                    code = result.code
                except Exception as result:
                    error = result
        finally:
            sys.path[:] = before_path
        return state, code, error

    def test_success_checks_protocol_without_temporary_parameter_changes(self):
        state, code, error = self.run_check()
        self.assertIsNone(error)
        self.assertEqual(code, 0)
        self.assertEqual(state['steps'], 28)
        self.assertEqual(state['valid_writes'], [])
        self.assertTrue(all(bridge.closed for bridge in state['bridges']))

    def test_read_failures_leave_values_unchanged_and_close_every_started_bridge(self):
        for fail_read in (1, 2, 3):
            with self.subTest(fail_read=fail_read):
                state, _, error = self.run_check(fail_read=fail_read)
                self.assertIsInstance(error, OSError)
                self.assertEqual(state['steps'], 28)
                self.assertEqual(state['valid_writes'], [])
                self.assertTrue(all(bridge.closed for bridge in state['bridges']))

    def test_user_edit_during_check_is_preserved(self):
        state, code, error = self.run_check(edit_on_read=2)
        self.assertIsNone(error)
        self.assertEqual(code, 0)
        self.assertEqual(state['steps'], 47)
        self.assertEqual(state['valid_writes'], [])

    def test_failed_handshake_still_closes_the_bridge(self):
        state, code, error = self.run_check(connect_fails=True)
        self.assertIsNone(error)
        self.assertEqual(code, 1)
        self.assertEqual(state['valid_writes'], [])
        self.assertTrue(all(bridge.closed for bridge in state['bridges']))


if __name__ == '__main__':
    unittest.main()
