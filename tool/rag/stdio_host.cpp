// Local stdio host: preserve JSON pipes while owning every descendant process.
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
