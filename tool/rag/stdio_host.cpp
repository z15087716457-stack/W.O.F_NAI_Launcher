// Local stdio host: preserve JSON pipes while owning every descendant process.
// Usage: stdio_host <app pid> <absolute executable> <arguments...>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <filesystem>
#include <string>

static std::wstring Quote(const std::wstring& value) {
  std::wstring result = L"\"";
  size_t slashes = 0;
  for (wchar_t c : value) {
    if (c == L'\\') { ++slashes; continue; }
    result.append(c == L'"' ? slashes * 2 + 1 : slashes, L'\\');
    slashes = 0; result += c;
  }
  result.append(slashes * 2, L'\\');
  return result + L"\"";
}

int wmain(int argc, wchar_t** argv) {
  if (argc < 4 || !std::filesystem::path(argv[2]).is_absolute()) return 2;
  HANDLE parent = OpenProcess(SYNCHRONIZE, FALSE, wcstoul(argv[1], nullptr, 10));
  HANDLE job = CreateJobObjectW(nullptr, nullptr);
  if (!parent || !job) return 3;
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit{};
  limit.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, &limit, sizeof(limit))) return 3;
  HANDLE streams[3]{};
  const DWORD ids[] = {STD_INPUT_HANDLE, STD_OUTPUT_HANDLE, STD_ERROR_HANDLE};
  for (int i = 0; i < 3; ++i) {
    if (!DuplicateHandle(GetCurrentProcess(), GetStdHandle(ids[i]), GetCurrentProcess(),
                         &streams[i], 0, TRUE, DUPLICATE_SAME_ACCESS)) return 3;
  }
  std::wstring command;
  for (int i = 2; i < argc; ++i) {
    if (i != 2) command += L" ";
    command += Quote(argv[i]);
  }
  STARTUPINFOW startup{};
  startup.cb = sizeof(startup); startup.dwFlags = STARTF_USESTDHANDLES;
  startup.hStdInput = streams[0]; startup.hStdOutput = streams[1]; startup.hStdError = streams[2];
  PROCESS_INFORMATION process{};
  BOOL created = CreateProcessW(argv[2], command.data(), nullptr, nullptr, TRUE,
      CREATE_NO_WINDOW | CREATE_SUSPENDED, nullptr, nullptr, &startup, &process);
  for (HANDLE stream : streams) CloseHandle(stream);
  if (!created) return 3;
  if (!AssignProcessToJobObject(job, process.hProcess)) {
    TerminateProcess(process.hProcess, 3); WaitForSingleObject(process.hProcess, INFINITE);
    return 3;
  }
  ResumeThread(process.hThread); CloseHandle(process.hThread);
  HANDLE wait[] = {process.hProcess, parent};
  DWORD result = WaitForMultipleObjects(2, wait, FALSE, INFINITE);
  DWORD code = 130;
  if (result == WAIT_OBJECT_0) GetExitCodeProcess(process.hProcess, &code);
  TerminateJobObject(job, code);
  JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting{};
  do {
    if (!QueryInformationJobObject(job, JobObjectBasicAccountingInformation,
        &accounting, sizeof(accounting), nullptr)) break;
    if (accounting.ActiveProcesses) Sleep(10);
  } while (accounting.ActiveProcesses);
  CloseHandle(process.hProcess); CloseHandle(parent); CloseHandle(job);
  return static_cast<int>(code);
}

#elif defined(__APPLE__)
// macOS: the same contract with a process group in place of the Job. The child
// starts in a new group (before it runs any code, as CREATE_SUSPENDED does) and
// inherits the stdio pipes. When the child exits, the app (argv[1]) exits, or
// the host receives SIGTERM / SIGINT / SIGHUP, the whole group is killed.
// A descendant that leaves the group with setsid() is not reclaimed.
#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <ctime>
#include <fcntl.h>
#include <spawn.h>
#include <sys/event.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

int main(int argc, char** argv) {
  if (argc < 4 || argv[2][0] != '/') return 2;
  char* end = nullptr;
  errno = 0;
  const long parent = std::strtol(argv[1], &end, 10);
  if (errno != 0 || end == argv[1] || *end != '\0' || parent <= 1) return 3;
  const int queue = kqueue();
  if (queue < 0 || fcntl(queue, F_SETFD, FD_CLOEXEC) != 0) return 3;
  const int stops[] = {SIGHUP, SIGINT, SIGTERM};
  struct kevent watch[4];
  EV_SET(&watch[0], parent, EVFILT_PROC, EV_ADD, NOTE_EXIT, 0, nullptr);
  for (int i = 0; i < 3; ++i) {
    EV_SET(&watch[i + 1], stops[i], EVFILT_SIGNAL, EV_ADD, 0, 0, nullptr);
  }
  // Fails with ESRCH when the app is already gone.
  if (kevent(queue, watch, 4, nullptr, 0, nullptr) != 0) return 3;
  // kqueue still reports ignored signals; the child gets them back by default.
  for (int stop : stops) signal(stop, SIG_IGN);

  posix_spawnattr_t attributes;
  if (posix_spawnattr_init(&attributes) != 0) return 3;
  sigset_t defaults;
  sigemptyset(&defaults);
  for (int stop : stops) sigaddset(&defaults, stop);
  posix_spawnattr_setsigdefault(&attributes, &defaults);
  posix_spawnattr_setpgroup(&attributes, 0);
  posix_spawnattr_setflags(&attributes, POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGDEF);
  pid_t child = 0;
  const int spawned = posix_spawn(&child, argv[2], nullptr, &attributes, argv + 2, environ);
  posix_spawnattr_destroy(&attributes);
  if (spawned != 0) return 3;

  struct kevent exit_watch;
  EV_SET(&exit_watch, child, EVFILT_PROC, EV_ADD, NOTE_EXIT, 0, nullptr);
  // A child that already exited cannot be watched; it is a zombie by now.
  bool exited = kevent(queue, &exit_watch, 1, nullptr, 0, nullptr) != 0;
  int stop = 0;
  if (!exited) {
    struct kevent event;
    int ready;
    do ready = kevent(queue, nullptr, 0, &event, 1, nullptr);
    while (ready < 0 && errno == EINTR);
    if (ready > 0 && event.filter == EVFILT_SIGNAL) stop = static_cast<int>(event.ident);
    exited = ready > 0 && event.filter == EVFILT_PROC &&
             static_cast<pid_t>(event.ident) == child;
  }
  // An exited child stays a zombie until it is reaped below, so its pid (the
  // group id) cannot be reused while the group is killed.
  kill(-child, SIGKILL);
  int status = 0;
  while (waitpid(child, &status, 0) < 0 && errno == EINTR) {}
  // Killed descendants are reparented to launchd, which reaps them.
  const timespec pause{0, 10 * 1000 * 1000};
  for (int i = 0; i < 500 && kill(-child, 0) == 0; ++i) nanosleep(&pause, nullptr);
  close(queue);
  if (stop != 0) {
    // End the way an unhosted process would on the same signal.
    signal(stop, SIG_DFL);
    sigset_t pending;
    sigemptyset(&pending);
    sigaddset(&pending, stop);
    sigprocmask(SIG_UNBLOCK, &pending, nullptr);
    raise(stop);
    return 128 + stop;
  }
  if (!exited) return 130;
  return WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
}

#else
#error "stdio_host supports Windows and macOS"
#endif
