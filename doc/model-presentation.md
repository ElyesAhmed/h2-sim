# Model presentation reference

Use the anticline page (`hydrogen-anticline.rst`), saline aquifer page
(`store.rst`), biochemistry page (`biochem.rst`), and PHREEQC page (`phreeqc.rst`) when
adding or refreshing a Model page.

- Render scientific data from the initial and accepted simulation states.
  Retain operating-stage endpoints; label actual times and disclose uneven
  sampling. Do not interpolate plume fields for smoother playback.
- Use `h2simStoragePlotStyle` for the dark navy animation background,
  saturation palette, teal injection and orange withdrawal. Static scientific
  figures use white backgrounds, Arial labels and the same saturation palette.
- Keep saturation limits fixed across a case's animation and snapshots.
  State the plotted quantity, units, thresholds and any vertical exaggeration.
  Different physical cases may need different limits; report them explicitly.
- Arrange an animation first, then geology, plume snapshots, operating response,
  and any model-specific diagnostics. Include reproduction commands and input
  provenance. Explain simplifications without claiming benchmark agreement.
- Export a muted, looping MP4 with user controls, an actual-state PNG poster,
  and a GIF download. Use 200-dpi PNG and vector PDF for scientific figures.
- Show signed active-well rates over their actual schedule intervals. Do not
  plot stale inactive-well BHP. For the single-completion aquifer with zero
  connection-pressure correction, obtain shut-in BHP from the saved reservoir
  pressure using the local zero-drawdown balance; record this in provenance.
  Distinguish dissolution from irreversible hydrogen loss.
- Record source hashes, configuration, selected state indices/times and asset
  hashes in a JSON provenance file. Verify the HTML targets, decode the media,
  and visually inspect figures and representative animation frames.

The animation colour/axes helper is shared by the storage and biochemistry
galleries. Python exporters use `tools/storage_gallery_style.py`, whose
palette is checked against the MATLAB helper. Label logarithmic scales and
workflow-specific population normalizations explicitly. Physical models, solvers and tolerances remain independent of the presentation functions.

## Animation attribution

Use the H2sim logo and the existing SINTEF copyright attribution in a footer
band below the original plot area. The GPL notice identifies the software
license. Leave space beneath the signature for the video player's controls.

After exporting the scientific movies, GIFs and posters, apply the shared
branding step before publishing:

```bash
python -m pip install -r tools/requirements-figures.txt
python tools/brand_storage_animations.py
```

The default covers all five website animations. GIF/PNG-only exports are
supported too; a missing MP4 is skipped. To brand one local export:

```bash
python tools/brand_storage_animations.py --directory build/anticline \
    --animations hydrogen_anticline
```

The command records input/output hashes, dimensions, frame counts and timing
in `animation_branding_provenance.json`, and updates available per-case asset
hashes. Repeating it skips unchanged branded files. After changing the footer
or logo, regenerate the original scientific exports before branding again.
Poster plots retain their original pixels; movie and GIF frames retain their
source times and order, with normal video encoding/palette quantization.

## Small figure attribution

Use a small teal H2sim logo and the existing SINTEF copyright line in the
lower-right margin of scientific figures. Keep the mark below the original
artwork, including legends and colour bars. The logo occupies about 6% of the
figure width; the margin is about 2.4% of that width.

After exporting figures, apply:

```bash
python -m pip install -r tools/requirements-figures.txt
python tools/brand_website_figures.py
```

This covers the website's plot PNGs, matching PDFs and two SVG diagrams.
Animation posters use the animation attribution step above. For a local set:

```bash
python tools/brand_website_figures.py --directory build/aquifer-gallery
```

The PNG plot area is preserved pixel-for-pixel. PDFs keep the original artwork
coordinates and vector content. The command records input/output hashes and
margin geometry in `figure_branding_provenance.json`, updates existing figure
asset hashes, and skips unchanged branded files on subsequent runs. Regenerate
original exports before changing the signature itself.
