// Studio-owned process host and RTX Video SDK integration.
// SDK headers/libraries are build dependencies, not redistributed source.
#define NOMINMAX
#include <windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <wincodec.h>
#include <wrl/client.h>
#include <nvsdk_ngx.h>
#include <nvsdk_ngx_helpers_vsr.h>
#include <atomic>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

using Microsoft::WRL::ComPtr;
namespace fs = std::filesystem;

static void Check(HRESULT value) {
  if (FAILED(value)) throw std::runtime_error("windows_api");
}
static void CheckNgx(NVSDK_NGX_Result value) {
  if (NVSDK_NGX_FAILED(value)) {
    std::cerr << "NGX failure " << std::hex << value << std::endl;
    throw std::runtime_error("rtx_unavailable");
  }
}
static void Progress(const char* phase, int current, int total) {
  std::cout << "{\"phase\":\"" << phase << "\",\"current\":" << current
            << ",\"total\":" << total << "}" << std::endl;
}
static std::wstring Quote(const std::wstring& value) {
  std::wstring result = L"\"";
  size_t slashes = 0;
  for (auto c : value) {
    if (c == L'\\') { ++slashes; continue; }
    if (c == L'\"') result.append(slashes * 2 + 1, L'\\');
    else result.append(slashes, L'\\');
    slashes = 0;
    result += c;
  }
  result.append(slashes * 2, L'\\');
  return result + L"\"";
}

// Each launch owns a Windows job. Only this launch and its descendants are
// terminated; normal exit and cancellation wait for every descendant to end.
static int Run(int argc, wchar_t** argv) {
  if (argc < 3 || !fs::path(argv[2]).is_absolute()) return 2;
  HANDLE job = CreateJobObjectW(nullptr, nullptr);
  if (!job) return 3;
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit{};
  limit.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, &limit, sizeof(limit))) {
    CloseHandle(job); return 3;
  }
  std::wstring command;
  for (int i = 2; i < argc; ++i) {
    if (i != 2) command += L" ";
    command += Quote(argv[i]);
  }
  HANDLE childOut{}, childErr{};
  DuplicateHandle(GetCurrentProcess(), GetStdHandle(STD_OUTPUT_HANDLE), GetCurrentProcess(),
                  &childOut, 0, TRUE, DUPLICATE_SAME_ACCESS);
  DuplicateHandle(GetCurrentProcess(), GetStdHandle(STD_ERROR_HANDLE), GetCurrentProcess(),
                  &childErr, 0, TRUE, DUPLICATE_SAME_ACCESS);
  SECURITY_ATTRIBUTES attributes{sizeof(attributes), nullptr, TRUE};
  HANDLE childIn = CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                              &attributes, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  STARTUPINFOW start{};
  start.cb = sizeof(start);
  start.dwFlags = STARTF_USESTDHANDLES;
  start.hStdInput = childIn; start.hStdOutput = childOut; start.hStdError = childErr;
  PROCESS_INFORMATION process{};
  BOOL created = CreateProcessW(argv[2], command.data(), nullptr, nullptr, TRUE,
                               CREATE_NO_WINDOW | CREATE_SUSPENDED, nullptr, nullptr, &start, &process);
  CloseHandle(childIn); CloseHandle(childOut); CloseHandle(childErr);
  if (!created) { CloseHandle(job); return 3; }
  if (!AssignProcessToJobObject(job, process.hProcess)) {
    TerminateProcess(process.hProcess, 3);
    WaitForSingleObject(process.hProcess, INFINITE);
    CloseHandle(process.hThread); CloseHandle(process.hProcess); CloseHandle(job);
    return 3;
  }
  std::thread([job] {
    std::string line;
    while (std::getline(std::cin, line)) {
      if (line == "cancel") { TerminateJobObject(job, 130); return; }
    }
    // Parent disappearance also cancels the entire task.
    TerminateJobObject(job, 130);
  }).detach();
  ResumeThread(process.hThread);
  CloseHandle(process.hThread);
  WaitForSingleObject(process.hProcess, INFINITE);
  DWORD code = 3;
  GetExitCodeProcess(process.hProcess, &code);
  TerminateJobObject(job, code);
  JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting{};
  do {
    if (!QueryInformationJobObject(job, JobObjectBasicAccountingInformation,
                                  &accounting, sizeof(accounting), nullptr)) break;
    if (accounting.ActiveProcesses) Sleep(10);
  } while (accounting.ActiveProcesses);
  CloseHandle(process.hProcess);
  // Process exit closes the job handle after the detached reader is stopped.
  return static_cast<int>(code);
}

struct Ngx {
  ComPtr<ID3D11Device> device;
  ComPtr<ID3D11DeviceContext> context;
  NVSDK_NGX_Parameter* parameters = nullptr;
  NVSDK_NGX_Handle* feature = nullptr;
  bool initialized = false;
  ~Ngx() {
    if (feature) NVSDK_NGX_D3D11_ReleaseFeature(feature);
    if (parameters) NVSDK_NGX_D3D11_DestroyParameters(parameters);
    if (initialized) NVSDK_NGX_D3D11_Shutdown1(device.Get());
  }
  void Initialize(const fs::path& folder) {
    if (!folder.is_absolute() || !fs::is_regular_file(folder / L"nvngx_vsr.dll"))
      throw std::runtime_error("component_missing");
    SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
    AddDllDirectory(folder.c_str());
    ComPtr<IDXGIFactory1> factory;
    Check(CreateDXGIFactory1(IID_PPV_ARGS(&factory)));
    ComPtr<IDXGIAdapter1> adapter;
    for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; ++i) {
      DXGI_ADAPTER_DESC1 description{};
      Check(adapter->GetDesc1(&description));
      if (description.VendorId == 0x10de && !(description.Flags & DXGI_ADAPTER_FLAG_SOFTWARE)) break;
      adapter.Reset();
    }
    if (!adapter) throw std::runtime_error("no_nvidia_gpu");
    D3D_FEATURE_LEVEL level;
    Check(D3D11CreateDevice(adapter.Get(), D3D_DRIVER_TYPE_UNKNOWN, nullptr,
                           D3D11_CREATE_DEVICE_BGRA_SUPPORT, nullptr, 0, D3D11_SDK_VERSION,
                           &device, &level, &context));
    fs::create_directories(folder / L"cache");
    const wchar_t* paths[]{folder.c_str()};
    NVSDK_NGX_FeatureCommonInfo info{};
    info.PathListInfo = {paths, 1};
    CheckNgx(NVSDK_NGX_D3D11_Init(0, (folder / L"cache").c_str(), device.Get(), &info));
    initialized = true;
    CheckNgx(NVSDK_NGX_D3D11_GetCapabilityParameters(&parameters));
    int available = 0;
    CheckNgx(parameters->Get(NVSDK_NGX_Parameter_VSR_Available, &available));
    if (!available) throw std::runtime_error("rtx_unavailable");
    CheckNgx(NVSDK_NGX_D3D11_CreateFeature(context.Get(), NVSDK_NGX_Feature_VSR, parameters, &feature));
  }
};

static int Rtx(int argc, wchar_t** argv) {
  const bool probe = std::wstring(argv[1]) == L"--rtx-probe";
  if ((probe && argc != 3) || (!probe && argc != 7)) return 2;
  Check(CoInitializeEx(nullptr, COINIT_MULTITHREADED));
  Ngx ngx;
  ngx.Initialize(fs::path(argv[2]));
  if (probe) {
    std::cout << "{\"available\":true,\"engine\":\"RTX Video SDK 1.1.0\"}" << std::endl;
    return 0;
  }
  const unsigned long w = std::stoul(argv[5]), h = std::stoul(argv[6]);
  if (!w || !h || w > 16384 || h > 16384 || uint64_t(w) * h > 64000000)
    throw std::runtime_error("size_limit");
  ComPtr<IWICImagingFactory> wic;
  Check(CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&wic)));
  ComPtr<IWICBitmapDecoder> decoder;
  Check(wic->CreateDecoderFromFilename(argv[3], nullptr, GENERIC_READ,
                                      WICDecodeMetadataCacheOnLoad, &decoder));
  ComPtr<IWICBitmapFrameDecode> frame;
  Check(decoder->GetFrame(0, &frame));
  UINT inWidth{}, inHeight{};
  Check(frame->GetSize(&inWidth, &inHeight));
  if (!inWidth || !inHeight || uint64_t(inWidth) * inHeight > 64000000)
    throw std::runtime_error("size_limit");
  ComPtr<IWICFormatConverter> converter;
  Check(wic->CreateFormatConverter(&converter));
  Check(converter->Initialize(frame.Get(), GUID_WICPixelFormat32bppRGBA,
                             WICBitmapDitherTypeNone, nullptr, 0, WICBitmapPaletteTypeCustom));
  std::vector<unsigned char> pixels(size_t(inWidth) * inHeight * 4);
  Check(converter->CopyPixels(nullptr, inWidth * 4, static_cast<UINT>(pixels.size()), pixels.data()));
  for (size_t i = 3; i < pixels.size(); i += 4) pixels[i] = 255;
  D3D11_TEXTURE2D_DESC desc{};
  desc.Width = inWidth; desc.Height = inHeight;
  desc.MipLevels = 1; desc.ArraySize = 1; desc.SampleDesc.Count = 1;
  desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  desc.Usage = D3D11_USAGE_DEFAULT;
  desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_UNORDERED_ACCESS;
  D3D11_SUBRESOURCE_DATA data{pixels.data(), inWidth * 4, 0};
  ComPtr<ID3D11Texture2D> input, output, staging;
  Check(ngx.device->CreateTexture2D(&desc, &data, &input));
  desc.Width = w; desc.Height = h;
  Check(ngx.device->CreateTexture2D(&desc, nullptr, &output));
  NVSDK_NGX_D3D11_VSR_Eval_Params evaluation{};
  evaluation.pInput = input.Get(); evaluation.pOutput = output.Get();
  evaluation.InputSubrectSize = {inWidth, inHeight};
  evaluation.OutputSubrectSize = {static_cast<UINT>(w), static_cast<UINT>(h)};
  evaluation.QualityLevel = NVSDK_NGX_VSR_Quality_Ultra;
  Progress("inference", 0, 1);
  CheckNgx(NGX_D3D11_EVALUATE_VSR_EXT(ngx.context.Get(), ngx.feature, ngx.parameters, &evaluation));
  desc.BindFlags = 0; desc.Usage = D3D11_USAGE_STAGING; desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  Check(ngx.device->CreateTexture2D(&desc, nullptr, &staging));
  ngx.context->CopyResource(staging.Get(), output.Get());
  D3D11_MAPPED_SUBRESOURCE mapped{};
  Check(ngx.context->Map(staging.Get(), 0, D3D11_MAP_READ, 0, &mapped));
  std::vector<unsigned char> result(size_t(w) * h * 4);
  for (size_t row = 0; row < h; ++row)
    memcpy(result.data() + row * w * 4, static_cast<unsigned char*>(mapped.pData) + row * mapped.RowPitch, w * 4);
  ngx.context->Unmap(staging.Get(), 0);
  Progress("inference", 1, 1);
  ComPtr<IWICStream> stream;
  Check(wic->CreateStream(&stream));
  Check(stream->InitializeFromFilename(argv[4], GENERIC_WRITE));
  ComPtr<IWICBitmapEncoder> encoder;
  Check(wic->CreateEncoder(GUID_ContainerFormatPng, nullptr, &encoder));
  Check(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache));
  ComPtr<IWICBitmapFrameEncode> encoded;
  Check(encoder->CreateNewFrame(&encoded, nullptr));
  Check(encoded->Initialize(nullptr));
  Check(encoded->SetSize(w, h));
  auto format = GUID_WICPixelFormat32bppBGRA;
  Check(encoded->SetPixelFormat(&format));
  if (format != GUID_WICPixelFormat32bppBGRA) throw std::runtime_error("output_format");
  for (size_t i = 0; i < result.size(); i += 4) std::swap(result[i], result[i + 2]);
  Check(encoded->WritePixels(h, w * 4, static_cast<UINT>(result.size()), result.data()));
  Check(encoded->Commit()); Check(encoder->Commit());
  return 0;
}

int wmain(int argc, wchar_t** argv) {
  try {
    if (argc >= 2 && std::wstring(argv[1]) == L"--run") return Run(argc, argv);
    if (argc >= 2 && (std::wstring(argv[1]) == L"--rtx" || std::wstring(argv[1]) == L"--rtx-probe"))
      return Rtx(argc, argv);
    return 2;
  } catch (const std::exception& error) {
    std::cerr << "{\"error\":\"" << error.what() << "\"}" << std::endl;
    return 11;
  }
}
