# Model presentation reference

Use the anticline page (`hydrogen-anticline.rst`) and saline aquifer page
(`store.rst`) when adding or refreshing a Model page.

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
- Show signed active-well rates over their actual schedule intervals. Omit
  inactive-well BHP. Distinguish dissolution from irreversible hydrogen loss.
- Record source hashes, configuration, selected state indices/times and asset
  hashes in a JSON provenance file. Verify the HTML targets, decode the media,
  and visually inspect figures and representative animation frames.

The animation colour/axes helper is shared by both cases. Physical models,
solvers and tolerances remain independent of the presentation functions.
