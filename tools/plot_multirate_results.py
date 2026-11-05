"""Redraw website figures from stored full-cycle diagnostics.

Requires numpy and matplotlib. Run from any directory:
    python tools/plot_multirate_results.py
No MATLAB execution or simulation is performed.
"""
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'doc/data/multirate'
OUT = ROOT / 'doc/_static/examples'
NAMES = ['compositional', 'multirate']
LABELS = ['Compositional PHREEQC', 'Multirate PHREEQC']
from storage_gallery_style import TEAL, ORANGE, storage_colormap
COLORS = [TEAL, ORANGE]
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10,
                     'axes.spines.top': False, 'axes.spines.right': False,
                     'pdf.fonttype': 42, 'savefig.dpi': 180})


def read(name, suffix):
    return np.genfromtxt(DATA / f'{name}_{suffix}.csv', delimiter=',', names=True)


def time_axis(ax):
    ax.set(xlim=(0, 250), xlabel='Time (days)')
    for day in [50, 200]:
        ax.axvline(day, color='#74818a', lw=.9, ls=':')
    ax.grid(axis='y', alpha=.18)


def save(fig, name):
    OUT.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT / f'{name}.png', bbox_inches='tight', facecolor='white')
    pdf = OUT
    pdf.mkdir(parents=True, exist_ok=True)
    fig.savefig(pdf / f'{name}.pdf', bbox_inches='tight')
    plt.close(fig)


def main():
    histories = [read(n, 'history') for n in NAMES]
    for h in histories:
        assert h['time_days'][-1] == 250 and len(h) == 125
        assert np.allclose(h['loss_percent'], sum(h[f'{r}_percent'] for r in ['met', 'ace', 'srb']))
    fig, axes = plt.subplots(1, 2, figsize=(11.5, 4.1), layout='constrained')
    for h, label, color in zip(histories, LABELS, COLORS):
        axes[0].plot(np.r_[0, h['time_days']], np.r_[0, h['loss_percent']], label=label, color=color, lw=2.2)
        axes[0].annotate(f"{h['loss_percent'][-1]:.2f}%", (250, h['loss_percent'][-1]), xytext=(-8, 5), textcoords='offset points', ha='right', color=color, fontsize=10, weight='bold')
        for reaction, style in zip(['met', 'ace', 'srb'], ['-', '--', ':']):
            axes[1].plot(np.r_[0, h['time_days']], np.r_[0, h[f'{reaction}_percent']], color=color, ls=style, lw=1.8, label=f'{label.split()[0]} · {reaction.upper()}')
    for ax in axes:
        time_axis(ax)
        ax.set_ylabel('Consumed / total prescribed H₂ injection (%)')
    axes[0].set_title('(a) Total microbial hydrogen consumption', loc='left', pad=14)
    axes[1].set_title('(b) Contributions from the three reactions', loc='left', pad=14)
    axes[0].legend(frameon=False, loc='upper left', fontsize=9)
    axes[1].legend(frameon=False, loc='upper left', fontsize=8, ncol=2)
    axes[0].set_ylim(0, 56)
    axes[1].set_ylim(0, 50)
    save(fig, 'multirate_full_cycle_loss')

    fig, axes = plt.subplots(1, 2, figsize=(11.5, 3.8), layout='constrained')
    for h, label, color in zip(histories, LABELS, COLORS):
        for ax, field in zip(axes, ['ph', 'dic']):
            suffix = '' if field == 'ph' else '_mmol_kgw'
            ax.fill_between(h['time_days'], h[f'{field}_min{suffix}'], h[f'{field}_max{suffix}'], color=color, alpha=.10, linewidth=0)
            ax.plot(h['time_days'], h[f'{field}_median{suffix}'], color=color, lw=2, label=label)
    for ax in axes:
        time_axis(ax)
        ax.legend(frameon=False, fontsize=9)
    axes[0].set(ylabel='pH', title='(a) Aqueous acidity: spatial median and range')
    axes[1].set(ylabel='DIC (mmol kg⁻¹ water)', title='(b) Dissolved inorganic carbon: median and range')
    save(fig, 'multirate_full_cycle_chemistry_history')

    chemistry = [read(n, 'chemistry') for n in NAMES]
    fig, axes = plt.subplots(2, 2, figsize=(11.5, 5.5), layout='constrained', sharex=True, sharey=True)
    for col, (field, title, cmap) in enumerate([('ph', 'pH', storage_colormap()), ('dic_mmol_kgw', 'DIC (mmol kg⁻¹ water)', storage_colormap())]):
        lo = min(c[field].min() for c in chemistry)
        hi = max(c[field].max() for c in chemistry)
        for row, (c, label) in enumerate(zip(chemistry, LABELS)):
            times = np.unique(c['time_days'])
            x = np.unique(c['distance_m'])
            values = c[field].reshape(len(times), len(x)).T
            edges = np.r_[0, (times[:-1] + times[1:]) / 2, 250]
            xe = np.r_[0, (x[:-1] + x[1:]) / 2, 50]
            im = axes[row, col].pcolormesh(edges, xe, values, vmin=lo, vmax=hi, cmap=cmap, shading='flat', rasterized=True)
            for day in [50, 200]:
                axes[row, col].axvline(day, color='white', ls=':', lw=1)
            axes[row, col].set_title(f'{label} · {title}', loc='left', fontsize=10)
            axes[row, col].set(xlim=(0, 250), ylim=(0, 50))
            if col == 0:
                axes[row, col].set_ylabel('Distance from inlet (m)')
            if row == 1:
                axes[row, col].set_xlabel('Time (days)')
        fig.colorbar(im, ax=axes[:, col], shrink=.88, label=title)
    save(fig, 'multirate_full_cycle_chemistry_maps')
    print('Redrew three full-cycle comparison figures from saved diagnostics.')


if __name__ == '__main__':
    main()
