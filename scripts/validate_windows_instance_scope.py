"""Compile the runner's routing code and test it with hidden Win32 fixtures."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output-dir', type=Path,
                    default=ROOT / '.dart_tool/windows-instance-tests' / uuid.uuid4().hex)
args = parser.parse_args()
output = args.output_dir.resolve()
output.mkdir(parents=True, exist_ok=True)
native = (ROOT / 'windows/runner/main.cpp').read_text('utf-8')
receiver = (ROOT / 'windows/runner/flutter_window.cpp').read_text('utf-8')
sources = ['windows/runner/main.cpp', 'windows/runner/studio_sandbox.h',
           'windows/runner/flutter_window.cpp']
before = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}
prefix = native[native.index('// 单实例互斥体名称'):native.index('int APIENTRY wWinMain')]
receiver = receiver[receiver.index('constexpr const wchar_t kWakeUpMessageName[]'):
                    receiver.index('FlutterWindow::FlutterWindow')]
registration = native.split('::CoUninitialize();\n    return EXIT_FAILURE;\n  }\n', 1)[1]
registration = registration.split('  window.SetQuitOnClose', 1)[0]
registration = registration.replace('window.GetHandle()', 'window')
# Only OS object names are changed. A legacy global lock must not affect Studio.
test_id = 'WOF_Instance_Test_' + uuid.uuid4().hex
prefix = prefix.replace('NAI_Launcher_SingleInstance_Mutex', test_id + '_Mutex')
prefix = prefix.replace('NAI_Launcher_WakeUp_Message', test_id + '_Wake')
receiver = receiver.replace('NAI_Launcher_WakeUp_Message', test_id + '_Wake')
(output / 'receiver.cpp').write_text(
    '#include <windows.h>\n#include "studio_sandbox.h"\n' + receiver +
    '\nUINT FixtureReceiverMessage() { return GetWakeUpMessage(); }\n', encoding='utf-8')
fixture = r'''
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <string>
#include "studio_sandbox.h"
BOOL FixtureShow(HWND, int) { return TRUE; }
BOOL FixtureForeground(HWND) { return TRUE; }
#define ShowWindow FixtureShow
#define SetForegroundWindow FixtureForeground
''' + prefix + r'''
#undef ShowWindow
#undef SetForegroundWindow
UINT FixtureReceiverMessage();
std::wstring events;
LRESULT CALLBACK FixtureProc(HWND window, UINT message, WPARAM w, LPARAM l) {
  if (message == FixtureReceiverMessage()) {
    std::ofstream out(std::filesystem::path(events), std::ios::app);
    out << "wake\n";
    return 0;
  }
  return DefWindowProcW(window, message, w, l);
}
int wmain(int argc, wchar_t** argv) {
  if (argc != 3 || !studio_sandbox::Valid()) return 90;
  const std::wstring mode = argv[1];
  const auto identity = mode == L"legacy" ? std::wstring(kSingleInstanceMutexName)
      : studio_sandbox::Identity(kSingleInstanceMutexName);
  HANDLE mutex = CreateMutexW(nullptr, TRUE, identity.c_str());
  const bool exists = GetLastError() == ERROR_ALREADY_EXISTS;
  if (mode == L"probe") {
    const bool found = exists && FindExistingFlutterWindow() != nullptr;
    const bool woke = exists && WakeUpExistingWindow(100);
    std::ofstream out{std::filesystem::path(argv[2])};
    out << "{\"mutexExists\":" << (exists ? "true" : "false")
        << ",\"matchingWindow\":" << (found ? "true" : "false")
        << ",\"woke\":" << (woke ? "true" : "false") << "}";
    CloseHandle(mutex);
    return 0;
  }
  if (exists) return 91;
  events = argv[2];
  WNDCLASSW cls = {}; cls.hInstance = GetModuleHandleW(nullptr);
  cls.lpfnWndProc = FixtureProc; cls.lpszClassName = kFlutterRunnerWindowClassName;
  if (!RegisterClassW(&cls)) return 92;
  HWND window = CreateWindowW(cls.lpszClassName, studio_sandbox::Title(kLauncherWindowTitle).c_str(),
      WS_OVERLAPPEDWINDOW, 0, 0, 100, 100, nullptr, nullptr, cls.hInstance, nullptr);
  if (!window) return 93;
  if (mode == L"serve") {
''' + registration + r'''
  }
  { std::ofstream out{std::filesystem::path(events)}; out << "ready\n"; }
  MSG message;
  while (GetMessageW(&message, nullptr, 0, 0) > 0) DispatchMessageW(&message);
  CloseHandle(mutex);
}
'''
(output / 'fixture.cpp').write_text(fixture, encoding='utf-8')
vswhere = Path(os.environ['ProgramFiles(x86)']) / 'Microsoft Visual Studio/Installer/vswhere.exe'
vs = subprocess.check_output([str(vswhere), '-latest', '-products', '*',
                              '-property', 'installationPath'], text=True).strip()
batch = [
    '@echo off',
    f'call "{Path(vs) / "Common7/Tools/VsDevCmd.bat"}" -arch=x64 -host_arch=x64 >nul',
    'if errorlevel 1 exit /b 1',
    f'cl /nologo /std:c++17 /utf-8 /EHsc /DUNICODE /D_UNICODE /I"{ROOT / "windows/runner"}" fixture.cpp receiver.cpp /Fenai_instance_fixture.exe user32.lib',
    'exit /b %errorlevel%',
]
(output / 'build.cmd').write_bytes(('\r\n'.join(batch) + '\r\n').encode('ascii'))
with (output / 'build.log').open('w', encoding='utf-8') as log:
    subprocess.run([os.environ['COMSPEC'], '/d', '/c', str(output / 'build.cmd')],
                   cwd=output, stdout=log, stderr=subprocess.STDOUT, timeout=60, check=True)

programs = []
for name in ['install A 中文', 'install B']:
    folder = output / name
    folder.mkdir(exist_ok=True)
    exe = folder / 'nai_instance_fixture.exe'
    shutil.copy2(output / 'nai_instance_fixture.exe', exe)
    programs.append(exe)
first, second = programs
renamed = first.with_name('renamed_fixture.exe')
shutil.copy2(first, renamed)
processes = []
cases = []
flags = subprocess.CREATE_NO_WINDOW

def environment(root):
    env = dict(os.environ)
    env.pop('NAI_STUDIO_SANDBOX', None)
    if root is not None:
        env['NAI_STUDIO_SANDBOX'] = str(root)
    return env

def start(exe, root=None, mode='serve'):
    ready = output / (uuid.uuid4().hex + '.ready')
    process = subprocess.Popen([str(exe), mode, str(ready)], env=environment(root),
                               creationflags=flags)
    processes.append(process)
    for _ in range(100):
        if ready.exists():
            return process, ready
        assert process.poll() is None, process.returncode
        time.sleep(.02)
    raise AssertionError('Fixture window did not become ready')

def stop(process):
    if process.poll() is None:
        process.terminate()
        process.wait(timeout=5)

def probe(exe, root=None, cwd=None):
    result = output / (uuid.uuid4().hex + '.json')
    subprocess.run([str(exe), 'probe', str(result)], env=environment(root), cwd=cwd,
                   creationflags=flags, timeout=5, check=True)
    return json.loads(result.read_text('utf-8'))

def expect(name, actual, exists, matching, woke):
    assert actual == {'mutexExists': exists, 'matchingWindow': matching, 'woke': woke}, (name, actual)
    cases.append({'case': name, **actual})
    print(json.dumps(cases[-1], ensure_ascii=False), flush=True)

passed = False
try:
    a, a_log = start(first)
    expect('same directory wakes its existing window', probe(first), True, True, True)
    assert a_log.read_text().count('wake') == 1
    expect('different directory can start independently', probe(second), False, False, False)
    b, b_log = start(second)
    count_a = a_log.read_text().count('wake')
    expect('second directory wakes only its own window', probe(second), True, True, True)
    assert b_log.read_text().count('wake') == 1
    assert a_log.read_text().count('wake') == count_a
    count_b = b_log.read_text().count('wake')
    expect('first directory remains independently reachable', probe(first), True, True, True)
    assert a_log.read_text().count('wake') == count_a + 1
    assert b_log.read_text().count('wake') == count_b
    expect('same directory with another executable name shares storage identity', probe(renamed), True, True, True)
    expect('working directory does not change instance identity', probe(first, cwd=second.parent), True, True, True)
    stop(a); stop(b)

    legacy, _ = start(first, mode='legacy')
    expect('legacy global lock does not block a new scoped instance', probe(second), False, False, False)
    assert legacy.poll() is None
    stop(legacy)

    shared = output / 'shared sandbox'
    sandbox, sandbox_log = start(first, shared)
    expect('same sandbox from another install wakes the shared instance', probe(second, shared), True, True, True)
    assert sandbox_log.read_text().count('wake') == 1
    equivalent = str(shared).upper().replace('\\', '/') + '/'
    expect('sandbox path case separators and trailing slash normalize', probe(second, equivalent), True, True, True)
    assert sandbox_log.read_text().count('wake') == 2
    expect('different sandbox roots remain independent', probe(first, output / 'other sandbox'), False, False, False)
    stop(sandbox)

    unmarked, _ = start(first, mode='unmarked')
    expect('unmarked window is not mistaken for this instance', probe(first), True, False, False)
    stop(unmarked)

    for invalid in ['', 'relative/path', 'E:relative']:
        result = subprocess.run([str(first), 'probe', str(output / 'invalid.json')],
                                env=environment(invalid), creationflags=flags, timeout=5)
        assert result.returncode == 90, invalid
    cases.append({'case': 'invalid sandbox roots remain rejected', 'variants': 3})
    passed = True
finally:
    for process in processes:
        stop(process)
    assert all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h for p, h in before.items())
    (output / 'verification.json').write_text(json.dumps({
        'passed': passed, 'cases': cases, 'sourceSha256': before,
        'fixtureProcessesStopped': True, 'realStudioStarted': False,
        'productSourceUnchangedByHarness': True,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Passed {len(cases)} native instance scenarios. Evidence: {output}')
