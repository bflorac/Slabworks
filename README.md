# SlabWorks

A [Vectric](https://www.vectric.com/) gadget for VCarve / Aspire that creates surfacing toolpaths to flatten slabs of wood with a large surfacing bit.

SlabWorks builds the toolpaths directly from the job size. No vectors need to be drawn. Pick a bit, a pattern and a depth, then click **Apply**.

## Toolpath types

| | Type | Path |
|:---:|---|---|
| <img src="icons/path-vertical-serpentine.svg" width="48" alt=""> | **Linear Y** | Up/down passes, stepping left to right |
| <img src="icons/path-horizontal-serpentine.svg" width="48" alt=""> | **Linear X** | Left/right passes, stepping front to back |
| <img src="icons/path-climb-only.svg" width="48" alt=""> | **Climb only** | Like Linear Y, but every pass is a climb cut; returns travel outside the part |
| <img src="icons/path-spiral.svg" width="48" alt=""> | **Spiral** | Follows the edges of the slab, working inward, clockwise |
| <img src="icons/path-circular-spiral.svg" width="48" alt=""> | **True Spiral** | Continuous spiral from the top center, clockwise, working inward. It is fitted inside the slab, so the corners are not cut. |

The green dot marks where each path starts.

## Features

- Presets for common surfacing bits: Whiteside 6210 and 6220, and Amana RC2255
- Stepover as an actual distance or as a percentage of bit diameter
- Multiple passes: set **Repeat** or total **Depth**, and the other is calculated from **Cut Depth**
- **Depth Offset** carries on from a previous run, so the next run doesn't cut air
- Optional perimeter climb cut first (Linear X and Y), to reduce chip-out at the edges
- Optional alternating tool numbers, to force a tool-change pause between passes
- **Clear Toolpaths** removes all SlabWorks toolpaths from the job
- Settings are remembered between sessions

## Requirements

- Vectric VCarve Pro or Aspire with gadget support (developed on VCarve Pro Makerspace Edition V12.5)
- Job **Z zero** set to the **material surface**
- Job **XY origin** at the **lower left** of the material
- Dimensions in inches

## Installation

1. Download this repository (**Code > Download ZIP**) or a release zip.
2. Copy the `SlabWorks` folder into the gadgets folder for your Vectric product:
   `C:\Users\Public\Documents\Vectric Files\Gadgets\<your product and version>\`
3. Restart VCarve. **SlabWorks** will appear in the **Gadgets** menu.

Only the `SlabWorks` folder is needed to run the gadget. The `icons` folder holds the SVG sources for the toolpath preview images, which are embedded in `SlabWorks.htm` as PNGs.

## Usage

1. Set up the job with the slab's size and thickness.
2. Run **Gadgets > SlabWorks**.
3. Choose a bit (or a preset), stepover, toolpath type and depth.
4. Click **Apply**, then save the toolpath with your post processor.

Click **Help...** in the dialog for a description of every setting.

SlabWorks creates raw toolpaths, which can't be edited afterward. To change one, delete it (or use **Clear Toolpaths**) and run the gadget again.

## Repository layout

```
SlabWorks/            the gadget: copy this folder into the Vectric gadgets folder
  SlabWorks.lua       gadget script
  SlabWorks.htm       dialog
  SlabWorks_Help.htm  help page
  LICENSE.txt
icons/                SVG sources for the toolpath preview images
```

## License

Copyright (c) 2025-2026 Bill Florac. Released under the [MIT License](LICENSE.txt).

The dialog header and footer come from Vectric's standard gadget template, including the gear graphic. Vectric's template notice at the top of `SlabWorks.htm` is kept unchanged, as Vectric's gadget licence requires.

SlabWorks is provided as-is. Always check toolpaths in preview before cutting.
