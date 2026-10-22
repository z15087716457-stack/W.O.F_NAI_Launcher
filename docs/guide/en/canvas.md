> [← Back to home](../../../README.md) · [Guide index](README.md)

# Infinite canvas and visual channel

## Infinite canvas

The middle of the generation page is an infinitely pannable canvas, with results laid out in batches.

| Action | Control |
| --- | --- |
| Pan | Wheel for up/down, `Shift+wheel` for left/right; or drag with middle mouse / `Shift+left mouse` |
| Zoom | `Ctrl+wheel` |
| Navigate | `W A S D` |
| Fit all | `Ctrl+0` |
| See original | For results with an original image, such as inpainting, hold the mouse button, Space or Enter to show the original and the current repaint area (marked OLD on the image) |

- Starting generation places a placeholder and moves to the newest batch; progress previews and final results appear in the same spot.
- You can “Pin image” for images you like so they stay on the canvas even if history is cleared.
- Choose a display background for transparent images (checkerboard, solid color and more). It affects only the display, not the image file.
- “Canvas display” lets you toggle filling the view, reduced motion and locking the canvas camera.

## Visual channel

<img src="../../images/readme/en/channel.webp" alt="Visual channel" width="100%">

The visual channel is decoration that scrolls along both sides of the canvas. **It is drawn only outside your images and never covers them.**

To enable it: gear at the bottom left of the canvas → “Canvas display” → “Visual channel.”

- **Themes**: Circuit, Star atlas, Herbarium, Arcade, Abyss, Seigaiha, Caliber, Strata, Metro, Score and Luna—11 in total.
- **Mode**: Off, One theme or Shuffle (keep at least two themes for Shuffle; use “Reshuffle” to change the selection).
- **Strength**: Soft, Normal or Bold.
- **Time marks**: Show batch times, day dividers and the scrubber on the right.
- **Idle motion**: Subtle movement when not generating; pauses automatically during generation.

<img src="../../images/readme/en/channel-themes.webp" alt="Visual channel themes" width="100%">
