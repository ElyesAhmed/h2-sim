"""Shared storage-gallery colours, accepted-state sampling and video export.

Scientific plotting dependencies are optional; sampling and constants use only
Python's standard library. Colours match MATLAB's h2simStoragePlotStyle.
"""
from pathlib import Path
import math

BACKGROUND = (0.025, 0.055, 0.1)
INJECTION = (0.4, 0.9, 0.9)
WITHDRAWAL = (1.0, 0.65, 0.25)
TEAL = (0.02, 0.48, 0.49)
ORANGE = (0.85, 0.36, 0.12)
SATURATION_ANCHORS = (
    (0.12, 0.22, 0.35), (0.08, 0.48, 0.65), (0.15, 0.75, 0.62),
    (0.85, 0.88, 0.3), (1.0, 0.65, 0.18),
)


def select_state_indices(times, phases, maximum=100):
    """Select existing states by physical time, retaining each stage endpoint.

    Returns zero-based indices. No field or state interpolation is performed.
    Input times must be finite and strictly increasing; the first accepted
    state is retained, without inventing a time-zero state.
    """
    if not times or len(times) != len(phases):
        raise ValueError('Times and operating phases must be nonempty and aligned.')
    if any(not math.isfinite(t) for t in times) or any(
            right <= left for left, right in zip(times, times[1:])):
        raise ValueError('Accepted-state times must be finite and increasing.')
    if not isinstance(maximum, int) or maximum < 2:
        raise ValueError('maximum must be an integer of at least two.')
    mandatory = {0, len(times) - 1}
    mandatory.update(i for i in range(len(times) - 1) if phases[i] != phases[i + 1])
    if len(mandatory) > maximum:
        raise ValueError('maximum must accommodate all operating-stage endpoints.')
    if len(times) <= maximum:
        return list(range(len(times)))
    slots = maximum - len(mandatory)
    for k in range(slots):
        target = times[0] + (times[-1] - times[0]) * k / max(1, slots - 1)
        mandatory.add(min(range(len(times)), key=lambda i: abs(times[i] - target)))
    return sorted(mandatory)


def storage_operation(name, active, sign):
    """Label the actual scheduled operation, including pre-cycle shut-in."""
    if not active or sign == 0:
        return 'Shut-in'
    if sign < 0:
        return 'Withdrawal'
    if str(name).lower() == 'cushion':
        return 'Cushion injection'
    return 'Injection'


def storage_colormap():
    from matplotlib.colors import LinearSegmentedColormap
    return LinearSegmentedColormap.from_list('h2sim_storage', SATURATION_ANCHORS, N=256)


def dark_axes(ax):
    ax.set_facecolor(BACKGROUND)
    ax.tick_params(colors='white', labelsize=8)
    for spine in ax.spines.values():
        spine.set_color('white')
    for item in (ax.xaxis.label, ax.yaxis.label, ax.title):
        item.set_color('white')


def render_phreeqc_storage(data, fields, history_times, loss, rates, folder):
    """Export the selected PHREEQC states, not decoded/quantized explorer data.

    Fields contain log10 aqueous H2 mole fraction and log10 population/initial.
    Movie frames have equal duration, despite uneven labelled simulation times.
    GIF/MP4 use the same frames. Source values and diagnostics are unchanged.
    """
    import numpy as np
    import matplotlib.pyplot as plt
    from matplotlib.collections import PolyCollection
    from PIL import Image
    import imageio_ffmpeg

    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    fig = plt.figure(figsize=(12.8, 7.4), dpi=100, facecolor=BACKGROUND,
                     constrained_layout=False)
    positions = [(0.055, .56, .23, .25), (.34, .56, .23, .25),
                 (.055, .20, .23, .25), (.34, .20, .23, .25)]
    titles = ['Dissolved hydrogen', 'Methanogenesis (MET)',
              'Acetogenesis (ACE)', 'Sulfate reduction (SRB)']
    patches = []
    well = np.asarray(data['well'])
    for j, position in enumerate(positions):
        ax = fig.add_axes(position)
        collection = PolyCollection(data['polygons'], array=fields[j][0],
                                    cmap=storage_colormap(), edgecolors='none',
                                    linewidths=0, antialiased=False)
        variable = data['variables'][j]
        collection.set_clim(variable['lo'], variable['hi'])
        ax.add_collection(collection)
        ax.plot(well[:, 0], well[:, 1], 'wo', markersize=2.5, markerfacecolor=INJECTION)
        ax.set(xlim=(0, 50), ylim=(0, 50), aspect='equal',
               xlabel='Horizontal distance (m)', ylabel='Elevation (m)')
        ax.set_title(titles[j], fontsize=10)
        dark_axes(ax)
        ax.xaxis.label.set_fontsize(8)
        ax.yaxis.label.set_fontsize(8)
        colorbar = fig.colorbar(collection, ax=ax, fraction=.045, pad=.035)
        colorbar.set_label('log₁₀(H₂ mole fraction)' if j == 0 else 'log₁₀(population / initial)', fontsize=8, color='white')
        colorbar.ax.tick_params(colors='white', labelsize=8)
        patches.append(collection)
    ax_loss = fig.add_axes((.65, .52, .3, .25))
    curve, = ax_loss.plot([], [], color=INJECTION, lw=2)
    ax_loss.set(xlim=(0, history_times[-1]), ylim=(0, max(1, max(loss) * 1.1)),
                xlabel='Simulated time (days)', ylabel='Consumed / injected H₂ (%)',
                title='Cumulative microbial consumption')
    dark_axes(ax_loss)
    ax_rate = fig.add_axes((.65, .22, .3, .17))
    # End-of-step rates apply to the interval preceding each accepted state.
    ax_rate.stairs(rates, np.r_[0, history_times], color=INJECTION, lw=1.3)
    cursor = ax_rate.axvline(0, color=WITHDRAWAL, lw=1.5)
    ax_rate.set(xlim=(0, history_times[-1]), xlabel='Simulated time (days)',
                ylabel='Prescribed gas rate (surface m³/day)')
    dark_axes(ax_rate)
    fig.text(.04, .93, 'H2sim | Reactive hydrogen storage with PHREEQC',
             color='white', fontsize=21, fontweight='bold')
    label = fig.text(.04, .86, '', color=(.7, .85, .95), fontsize=11)
    fig.text(.04, .05,
             '50 m structural trap | Three cycles | Cell-local PHREEQC kinetics\n'
             'Accepted simulation states | Uneven simulated time intervals | Logarithmic map scales\n'
             'Population changes represent growth and decay | No vertical exaggeration',
             color=(.7, .77, .84), fontsize=9, linespacing=1.4)
    writer = imageio_ffmpeg.write_frames(str(folder/'phreeqc_storage.mp4'),
        (1280, 740), fps=6, quality=8, codec='libx264', pix_fmt_in='rgb24',
        pix_fmt_out='yuv420p', macro_block_size=2, ffmpeg_log_level='error')
    writer.send(None)
    gif_frames = []
    poster = min(range(len(data['times'])), key=lambda i: abs(data['times'][i] - 147))
    try:
        for i, time in enumerate(data['times']):
            for j, collection in enumerate(patches):
                collection.set_array(fields[j][i])
            stop = int(np.argmin(abs(history_times - time))) + 1
            curve.set_data(history_times[:stop], loss[:stop])
            cursor.set_xdata([time, time])
            label.set_text(f"Day {time:6.2f} | {data['phases'][i]} | {len(data['polygons']):,} cells | {loss[stop-1]:.1f}% consumed")
            fig.canvas.draw()
            rgb = np.asarray(fig.canvas.buffer_rgba())[:, :, :3].copy()
            writer.send(rgb)
            image = Image.fromarray(rgb)
            if i == poster:
                image.save(folder/'phreeqc_storage.png')
            preview = image.resize((800, 462), Image.Resampling.LANCZOS)
            if i == 0:
                palette = preview.quantize(colors=128)
            gif_frames.append(preview.quantize(palette=palette, dither=Image.Dither.NONE))
    finally:
        writer.close()
        plt.close(fig)
    gif_frames[0].save(folder/'phreeqc_storage.gif', save_all=True,
        append_images=gif_frames[1:], duration=170, loop=0, optimize=False)
