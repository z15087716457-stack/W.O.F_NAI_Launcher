# V5 / N5

For the `nai-diffusion-5` family, use natural-language descriptions with tags as optional anchors.

## Capabilities & limitations on V5

- No Vibe Transfer (`reference_manage` / `reference_library` vibe actions return `reference_unsupported`).
- Precise Reference IS supported on V5 Curated and V5 Full (5 Anlas per reference per image; max 16): supports `character`, `style`, `characterAndStyle`, and V5-only `outfit` (`costume` in API), plus optional `prefer_same_outfit` on `character` / `characterAndStyle`. Strength slider ranges up to `5.0` (higher strength often helps Style References and aesthetic mixing); Fidelity is removed on V5.
- Precise Reference is NOT supported during V5 inpainting (references are skipped with a warning and not billed) and requires High effort (Full, not Turbo / Medium effort).
- No noise schedule, Variety+ or SMEA options; leave `noise_schedule`, `variety_plus` and `smea*` out of V5 cards and settings.
- Up to 32 characters with free coordinates.

## V5 Full Turbo

- Turbo (official Medium Effort) uses `nai-diffusion-5-full-medium`; inpainting uses `nai-diffusion-5-full-medium-inpainting`. Current `model_constraints`: 14 steps, Euler Ancestral, Heavy negative preset; custom main/character negatives and CFG Rescale are unsupported, guidance stays adjustable. The UI shows Full with a lightning toggle.
- Fixed values apply to quotes and requests; raw draft values remain available for switching back to Full. Read actual settings from `model_constraints` / `generation_prepare`; identify Turbo from explicit metadata, not step count alone.
