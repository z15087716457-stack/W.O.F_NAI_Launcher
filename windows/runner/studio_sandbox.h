#ifndef RUNNER_STUDIO_SANDBOX_H_
#define RUNNER_STUDIO_SANDBOX_H_

#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <cwctype>
#include <string>

namespace studio_sandbox {
inline std::wstring Root() {
  const DWORD size = GetEnvironmentVariableW(L"NAI_STUDIO_SANDBOX", nullptr, 0);
  if (size == 0) return L"";
  std::wstring root(size, L'\0');
  root.resize(GetEnvironmentVariableW(L"NAI_STUDIO_SANDBOX", root.data(), size));
  return root;
}
inline bool Enabled() { return !Root().empty(); }
inline bool Valid() {
  const auto root = Root();
  // Match Dart's Windows absolute-directory requirement, reject drive-relative.
  if (root.empty()) {
    SetLastError(ERROR_SUCCESS);
    return GetEnvironmentVariableW(L"NAI_STUDIO_SANDBOX", nullptr, 0) == 0 &&
           GetLastError() == ERROR_ENVVAR_NOT_FOUND;
  }
  return (root.size() >= 3 && root[1] == L':' &&
       (root[2] == L'\\' || root[2] == L'/')) ||
      (root.size() >= 2 && root[0] == L'\\' && root[1] == L'\\');
}
inline std::wstring Suffix() {
  auto root = Root();
  if (root.empty()) return L"";
  DWORD size = GetFullPathNameW(root.c_str(), 0, nullptr, nullptr);
  std::wstring normalized(size, L'\0');
  normalized.resize(GetFullPathNameW(root.c_str(), size, normalized.data(), nullptr));
  std::transform(normalized.begin(), normalized.end(), normalized.begin(),
                 [](wchar_t c) { return c == L'/' ? L'\\' : static_cast<wchar_t>(std::towlower(c)); });
  while (normalized.size() > 3 && normalized.back() == L'\\') normalized.pop_back();
  uint64_t hash = 14695981039346656037ULL;
  for (const auto c : normalized) { hash ^= static_cast<uint64_t>(c); hash *= 1099511628211ULL; }
  return L"_sandbox_" + std::to_wstring(hash);
}
inline std::wstring Title(const std::wstring& title) {
  return Enabled() ? title + L" [sandbox]" : title;
}
inline std::wstring Identity(const wchar_t* base) { return std::wstring(base) + Suffix(); }
}  // namespace studio_sandbox
#endif
