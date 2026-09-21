# Pixel Snap offline reference fixtures

`official_cpu.json` contains output from synthetic inputs, computed with the
JavaScript CPU backend of the locally archived NovelAI Pixel Snap worker.
The reference worker is not bundled in the app or needed to run the tests.

Reference SHA-256 (UTF-8 source bytes):
`a69a19c9255de14b09126b583a0a845e37d532b77689b8aaa7f8888cbc570de1`.

The 18 cases combine aligned/offset grids, opaque/partially transparent input,
off/auto/custom palettes and both over-refinement settings. The Dart test
reconstructs each source image from the JSON specification and checks every
output channel and dimension against the reference. Auto tolerance is 6.5;
custom palette size is 16. The input color and alpha formula is in
`pixel_snap_official_parity_test.dart`.

Coverage is intentionally bounded: this checks the CPU algorithm after decode,
not browser-specific canvas premultiplication or GPU backend rounding on every
possible image. The implementation runs in an isolate and retains separate
tests for invalid input, palette limits and nearest-neighbor enlargement.
