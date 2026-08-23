/// 模型标识 → 友好名映射（UI 层纯函数，可单测）
///
/// 未知模型原样返回。
String galleryModelFriendlyName(String model) {
  return switch (model) {
    'nai-diffusion-3' => 'NAI 3',
    'nai-diffusion-furry-3' => 'Furry 3',
    'nai-diffusion-4-curated-preview' => 'NAI 4 Curated',
    'nai-diffusion-4-full' => 'NAI 4 Full',
    'nai-diffusion-4-5-curated' => 'NAI 4.5 Curated',
    'nai-diffusion-4-5-full' => 'NAI 4.5 Full',
    'nai-diffusion-5-curated' => 'NAI 5 Curated',
    'nai-diffusion-5-full' => 'NAI 5 Full',
    _ => model,
  };
}
