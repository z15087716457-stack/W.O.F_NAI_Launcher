# Local Upscaling Components

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
