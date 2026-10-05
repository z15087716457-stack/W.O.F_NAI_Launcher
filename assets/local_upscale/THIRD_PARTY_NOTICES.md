# Local Upscaling Components

Optional SeedVR2 and RTX components are downloaded only when the user requests
installation. No model weights, Python runtime, NVIDIA VSR DLL or SDK headers
are bundled with Studio. Pinned versions, sizes and SHA-256 identities appear
in advanced_manifest.json.

- SeedVR2 standalone CLI: numz/ComfyUI-SeedVR2_VideoUpscaler, Apache-2.0,
  revision 4490bd1f482e026674543386bb2a4d176da245b9. The original LICENSE is
  retained in the private installation. Model weights come from the pinned
  numz/SeedVR2_comfyUI Hugging Face repository; see its model card and license.
  https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler
- uv: Astral, MIT or Apache-2.0, version 0.12.17. It installs a private
  CPython 3.12.11 environment and hash-pinned packages. Python (PSF License),
  PyTorch, CUDA runtime packages and other dependencies retain their own
  upstream licenses inside the private environment.
  https://github.com/astral-sh/uv
- NVIDIA RTX Video SDK 1.1.0: proprietary NVIDIA SDK license, not Studio's
  license. Only the official release nvngx_vsr.dll and the original license
  PDF are extracted on request. The license PDF remains in that installation.
  The bundled Studio-owned worker links the SDK's object-code API support
  library. NVIDIA SDK headers and developer tools are build dependencies and
  are not redistributed. NVIDIA's original rights and terms remain in effect.
  https://developer.nvidia.com/rtx-video-sdk

Studio's worker source is tool/local_upscale/studio_upscale_worker.cpp. The
adapter script and hashed dependency lock are seedvr2/worker.py and
seedvr2/requirements.lock. The original offline NCNN component notices follow.

Studio launches an unmodified, short-lived Real-ESRGAN NCNN/Vulkan executable.
Engine release: v0.2.0 (2022-04-24), source revision 37026f4.
https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan/releases/tag/v0.2.0

The engine and default Real-ESRGAN x4plus Anime model are MIT licensed by
Xintao Wang. The original engine license, including realsr-ncnn-vulkan's
MIT notice (nihui), is reproduced in windows/LICENSE.
https://github.com/xinntao/Real-ESRGAN

Optional models are taken from the upstream v0.2.5.0 model archive
realesrgan-ncnn-vulkan-20220424-windows.zip. The engine archive, model
archive and each installed engine/model file have pinned SHA-256 hashes
and sizes in manifest.json. Only the chosen model files are extracted.

The engine source pins NCNN 6125c9f47cd14b589de0521350668cf9d3d37e3c
(Tencent, BSD 3-Clause) and libwebp 8ea81561d2fdd382da60f57958741a7c23a18eb6
(WebM Project, BSD). Their full notices are included in NCNN-LICENSE.txt
and LIBWEBP-LICENSE.txt. NCNN pins glslang
4afd69177258d0636f78d2c4efb823ab6382a187; its complete upstream license
notice is reproduced in GLSLANG-LICENSE.txt.

The Windows engine uses Windows Imaging Component for PNG/JPEG decoding.
Vulkan device drivers are provided by the graphics vendor and are not bundled.
The engine's release dependency vcomp140.dll is Microsoft's Visual C++ OpenMP
redistributable runtime. It remains unmodified and retains Microsoft's ownership
and license terms. No debug runtime (vcomp140d.dll) is distributed.
https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files

The exact-size finishing step uses Studio's existing Dart port of Pica's
Lanczos3 pipeline. Its MIT attribution is recorded in the project root
THIRD_PARTY_NOTICES.md.

User-imported NCNN model pairs are separate user files. Their ownership and
license are determined by the model's author; Studio does not convert or
redistribute them as bundled models.
