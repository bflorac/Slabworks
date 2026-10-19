# SlabWorks

A [Vectric](https://www.vectric.com/) gadget for VCarve Pro and Aspire that creates surfacing toolpaths to flatten slabs of wood with a large surfacing bit.

SlabWorks builds the toolpaths directly from the job size, so you don't need to draw any vectors. Pick a bit, a pattern and a depth, then click **Apply**. Each pass becomes its own toolpath, and SlabWorks remembers how deep you've gone, so you can keep surfacing in steps until the slab is flat.

## Contents

- [Toolpath types](#toolpath-types)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Dialog settings](#dialog-settings)
- [How depth and passes work](#how-depth-and-passes-work)
- [The toolpaths SlabWorks creates](#the-toolpaths-slabworks-creates)
- [Tips](#tips)
- [Limitations](#limitations)
- [Building a release](#building-a-release)
- [Version history](#version-history)
- [License](#license)

## Toolpath types

| | Type | Path |
|:---:|---|---|
| <img src="icons/path-vertical-serpentine.svg" width="48" alt=""> | **Linear Y** | Back-and-forth passes along Y (front to back), stepping left to right, with a half-circle U-turn at each end. |
| <img src="icons/path-horizontal-serpentine.svg" width="48" alt=""> | **Linear X** | Back-and-forth passes along X (left to right), stepping front to back, with half-circle U-turns. |
| <img src="icons/path-climb-only.svg" width="48" alt=""> | **Climb only** | Every cut runs front to back as a climb cut. Between cuts, the bit returns around the left side of the slab, outside the material, then steps right. Slower, but gives the cleanest finish. |
| <img src="icons/path-spiral.svg" width="48" alt=""> | **Spiral** | Follows the slab's edges clockwise and works inward, starting at the lower left. Corners are rounded where the stepover allows. |
| <img src="icons/path-circular-spiral.svg" width="48" alt=""> | **True Spiral** | A continuous Archimedean spiral from the top center, clockwise, working inward. It's fitted inside the slab (dotted box), so the **corners are not cut**. Best for round slabs. |

The green dot marks where each path starts. Every path starts and ends outside the material, so the bit plunges in clear air.

## Requirements

- Vectric **VCarve Pro** or **Aspire** with gadget support (developed on VCarve Pro Makerspace Edition V12.5)
- The job's **Z zero** set to the **material surface**. SlabWorks checks this and won't run otherwise.
- The job's **XY origin** at the **lower left** of the material. SlabWorks doesn't check this, so set it before you start.
- Inch units. Bit size, depths and feeds are in inches and inches per minute.

## Installation

**From a release (recommended):**

1. Download the latest `Slabworks_<version>.vgadget` from the [`releases`](releases) folder.
2. In VCarve, choose **Gadgets > Install Gadget...** and select the file.

**Manually:**

1. Download this repository (**Code > Download ZIP**).
2. Copy the `SlabWorks` folder into the gadgets folder for your Vectric product:
   `C:\Users\Public\Documents\Vectric Files\Gadgets\<your product and version>\`
3. Restart VCarve. **SlabWorks** will appear in the **Gadgets** menu.

Only the `SlabWorks` folder is needed to run the gadget.

## Quick start

1. Create a job the size of your slab: width (X), height (Y) and thickness. Set Z zero to the material surface and the XY origin to the lower left.
2. Run **Gadgets > SlabWorks**.
3. Click a bit preset (**6210**, **6220** or **RC2255**), or enter your own bit diameter, RPM and feed rate.
4. Choose a toolpath type.
5. Set **Cut Depth**, and either **Repeat** or **Depth**.
6. Click **Apply**. One toolpath is created for each pass.
7. Preview the toolpaths, then save them with your post processor.

To take more off later, run SlabWorks again: **Depth Offset** will already be set to where the last run finished.

## Dialog settings

### Slab

| Setting | Description |
|---|---|
| Slab Width / Height / Thickness | Read from the job and material setup. To change them, change the job. |

### Bit

| Setting | Range | Default | Description |
|---|---|---|---|
| Bit Dia. | 0.25 – 2.0" | 2.0" | Diameter of the surfacing bit. |
| Spindle RPM | 6,000 – 24,000 | 14,000 | Saved with the toolpath's tool. |
| Stepover | up to 70% of the bit | 40% (0.8") | Distance between passes. **Actual Value** shows it in inches; **Percent of Dia(%)** shows it as a percentage of the bit diameter. Switching between the two converts the number. |
| Feedrate | 50 – 400 in/min | 250 | Cutting feed. Plunge rate is set to half of this. |

**Presets** fill in the bit settings for common surfacing bits:

| Button | Bit | Diameter | Feedrate | RPM | Stepover |
|---|---|---|---|---|---|
| **6210** | Whiteside 6210, ¼" shank, 3 flutes | 1" | 91 | 14,000 | 40% |
| **6220** | Whiteside 6220, ½" shank, 4 flutes | 2" | 185 | 14,000 | 40% |
| **RC2255** | Amana RC-2255, ½" shank, 3 flutes | 2" | 250 | 14,400 | 40% |

The 6210 and 6220 feed rates come from Whiteside's chip loads, scaled to 14,000 RPM. The RC2255 settings use 250 in/min at 14,400 RPM.

### Toolpath

| Setting | Default | Description |
|---|---|---|
| Toolpath Type | Linear Y | See [Toolpath types](#toolpath-types). The image next to the options previews the selected path. |
| Perimeter cut first | off | Linear X and Y only. Before the main passes, cuts three clockwise laps around the slab: the bit's edge 1/8" outside the slab, on the edge, and 1/8" inside. This climb-cuts the edges first to reduce chip-out. The main passes then stop 1/8" inside the edge instead of running 1/4" past it. |
| Alternate tool number | off | Gives the passes tool numbers T1, T2, T1, T2… When the toolpaths are saved together, your post processor inserts a tool change between passes. The machine then pauses, so you can check the surface or clear chips. |

### Depth

| Setting | Range | Default | Description |
|---|---|---|---|
| Repeat | 1 – 20 | 1 | Number of passes. Changing it updates **Depth**. |
| Depth | up to 6.0" | 0.05" | Total depth to remove in this run (Repeat × Cut Depth). Changing it updates **Repeat**. |
| Depth Offset | ≥ 0 | depth of last SlabWorks toolpath | Depth already removed by earlier runs. The first pass starts at Depth Offset + Cut Depth. |
| Cut Depth | ≥ 0.01" | 0.05" | Depth of each pass. You'll get a warning above 1". |
| Home Height | 0.5 – 4.0" | 1.0" | Z height at the start and end of each toolpath, above the lower-left corner of the material. |

### Buttons

| Button | Action |
|---|---|
| **Help...** | Opens the help page in your web browser. |
| **Clear Toolpaths** | Deletes every toolpath whose name starts with `Slab` and resets Depth Offset to 0. |
| **Reset All** | Returns every setting to its default. Depth Offset is set to the depth of the last SlabWorks toolpath. |
| **Apply** | Creates the toolpaths. The dialog stays open, so you can run more. |
| **Close** | Closes the dialog. |

When you close the dialog, the settings from your last **Apply** (or **Reset All**) are saved in the Windows registry. They're restored the next time you open SlabWorks. Changes you make without clicking Apply aren't saved. Depth Offset isn't stored; it's worked out from the toolpaths in the job.

## How depth and passes work

Each **Apply** creates **Repeat** toolpaths. Each one cuts the whole slab once, one **Cut Depth** deeper than the last:

| | Depth Offset | Cut Depth | Repeat | Toolpaths created | Depth Offset afterward |
|---|---|---|---|---|---|
| First run | 0 | 0.05 | 3 | 0.05, 0.10, 0.15 | 0.15 |
| Second run | 0.15 | 0.05 | 2 | 0.20, 0.25 | 0.25 |

That makes it easy to surface in steps: cut, check the slab, and click **Apply** again for more.

SlabWorks will never cut all the way through: it stops adding passes once the depth would reach the slab thickness.

## The toolpaths SlabWorks creates

- **Names** look like `Slab  3 T1 (0.15)`: a running count, the tool number, and the depth of that pass.
- **Tool:** an end mill with the bit diameter, feed rate and spindle speed from the dialog. The plunge rate is half the feed rate.
- **Heights:** the bit moves at 0.5" above the material between cuts. It starts its plunge, at the plunge rate, 0.25" above the surface.
- **Lead-in:** every toolpath starts outside the material, so the bit plunges in air and then moves into the cut.
- **Overrun:** Linear X and Y passes run 1/4" past each edge, so the whole surface is cut.
- **Editing:** SlabWorks creates raw toolpaths without vectors, so VCarve can't edit them afterward. To change one, delete it (or use **Clear Toolpaths**) and run SlabWorks again.

## Tips

- **Find the high spot first.** Set Depth Offset to 0 and make one light pass, e.g. 0.02–0.05". Then repeat until the whole surface has been touched.
- **Save the passes together** in one file. With **Alternate tool number** on, the machine stops between passes so you can vacuum and check progress.
- **Use Perimeter cut first** with Linear X or Y on figured or brittle wood. It reduces chip-out along the edges.
- **Use Climb only** for the final finishing pass when a clean surface matters more than speed.
- **Choose a stepover of 30–50%** for a surfacing bit. SlabWorks won't accept more than 70%.
- **Always preview** the toolpaths in VCarve before cutting.

## Limitations

- Inch units only.
- The XY origin must be at the lower left of the material. This isn't checked; with any other origin, the toolpaths will be offset from the slab.
- **True Spiral** leaves the corners of a rectangular slab uncut.
- **Perimeter cut first** applies only to Linear X and Y.
- **Clear Toolpaths** deletes *every* toolpath whose name starts with `Slab`, including any you created yourself with that name.

## Repository layout

```
SlabWorks/            the gadget: copy this folder into the Vectric gadgets folder
  SlabWorks.lua       gadget script
  SlabWorks.htm       dialog
  SlabWorks_Help.htm  help page
  LICENSE.txt
icons/                SVG sources for the toolpath preview images
releases/             packaged .vgadget installers, one per version
```

The dialog runs in Vectric's built-in Internet Explorer engine (IE7 mode), which can't display SVG. So the toolpath preview images are embedded in `SlabWorks.htm` as PNGs rendered from the SVGs in `icons/`. If you change an icon, regenerate its PNG and replace it in the HTML.

## Building a release

A `.vgadget` file is a zip containing the `SlabWorks` folder (`SlabWorks/SlabWorks.lua`, and so on).

1. Update `g_version` and the version notes at the top of `SlabWorks.lua`.
2. From the repository root, using the `tar` built into Windows 10 and 11 (Command Prompt or PowerShell):

   ```bat
   tar --format=zip -cf releases\Slabworks_1.0.6.vgadget SlabWorks
   ```

   Avoid `Compress-Archive` in Windows PowerShell 5.1: it writes `\` into zip paths, which other tools may not read correctly.

3. Test-install it in VCarve, then commit.

## Version history

| Version | Changes |
|---|---|
| 1.0.6 | Toolpath preview images in the dialog; copyright and licence notices |
| 1.0.5 | Preset buttons for standard bits |
| 1.0.4 | True Spiral; Clear Toolpaths button |
| 1.0.0 | Depth field, which calculates the repeat count |

## License

Copyright (c) 2025-2026 Bill Florac. Released under the [MIT License](LICENSE.txt).

The dialog's header and footer, including the gear graphic, come from Vectric's standard gadget template. Vectric's template notice at the top of `SlabWorks.htm` is kept unchanged, as Vectric's gadget licence requires.

SlabWorks is provided as-is, without warranty. Always check toolpaths in preview before cutting.
