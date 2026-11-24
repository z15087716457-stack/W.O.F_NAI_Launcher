# V5 / N5

For the `nai-diffusion-5` family, use natural-language descriptions with tags as optional anchors.

## Not available on V5

- No Vibe Transfer and no precise (character) references; `reference_manage` / `reference_library` return `reference_unsupported`.
- No noise schedule, Variety+ or SMEA options; leave `noise_schedule`, `variety_plus` and `smea*` out of V5 cards and settings.
- Up to 32 characters with free coordinates.

## V5 Full Turbo

- Turbo (official Medium Effort) uses `nai-diffusion-5-full-medium`; inpainting uses `nai-diffusion-5-full-medium-inpainting`. Current `model_constraints`: 14 steps, Euler Ancestral, Heavy negative preset; custom main/character negatives and CFG Rescale are unsupported, guidance stays adjustable. The UI shows Full with a lightning toggle.
- Fixed values apply to quotes and requests; raw draft values remain available for switching back to Full. Read actual settings from `model_constraints` / `generation_prepare`; identify Turbo from explicit metadata, not step count alone.
