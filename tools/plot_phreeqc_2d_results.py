"""Export completed packed 2D comparisons for the website; never runs MATLAB.

Usage: python tools/plot_phreeqc_2d_results.py --manifest path/to/manifest.json
The manifest lists three result MAT files per workflow (mobile, phreeqc).
"""
from pathlib import Path
import argparse, base64, gzip, hashlib, json
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.colors import ListedColormap, BoundaryNorm
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/_static/field2d'
FIG=ROOT/'doc/_static/examples'
COLORS={'mobile':'#586575','phreeqc':'#087f82'}
LABELS={'mobile':'Mobile flow–biochemistry','phreeqc':'Compositional PHREEQC'}
def read(p): return loadmat(p,simplify_cells=True)
def polygons(g):
 cp=np.asarray(g['cells']['facePos'],int)-1; cf=np.asarray(g['cells']['faces'],int);fi=(cf[:,0] if cf.ndim==2 else cf)-1
 fp=np.asarray(g['faces']['nodePos'],int)-1; fn=np.asarray(g['faces']['nodes'],int)-1;xy=np.asarray(g['nodes']['coords'])[:,:2];result=[]
 for i in range(int(g['cells']['num'])):
  ids=np.unique(np.concatenate([fn[fp[f]:fp[f+1]] for f in fi[cp[i]:cp[i+1]]]))
  v=xy[ids];d=v-v.mean(0);result.append(v[np.argsort(np.arctan2(d[:,1],d[:,0]))])
 return result
def packed(r):
 p=str(r['packedOutputDirectory']).replace('\\','/')
 for prefix in ['//wsl.localhost/Ubuntu','//wsl.localhost/ubuntu']:p=p.removeprefix(prefix)
 return Path(p)
def save(fig,name):
 fig.savefig(FIG/(name+'.png'),dpi=190,bbox_inches='tight',facecolor='white');plt.close(fig)
def mapplot(ax,poly,values,cmap,lo,hi):
 im=PolyCollection(poly,array=values,cmap=cmap,edgecolors='none',linewidths=0,antialiased=False,rasterized=True);im.set_clim(lo,hi);ax.add_collection(im)
 ax.set(xlim=(0,50),ylim=(0,50),xlabel='Distance, x (m)',ylabel='Height, y (m)');ax.set_aspect('equal');return im
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--manifest',required=True,type=Path);args=ap.parse_args();manifest=json.loads(args.manifest.read_text())
 OUT.mkdir(parents=True,exist_ok=True);FIG.mkdir(parents=True,exist_ok=True)
 plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.titlesize':11,'axes.spines.top':False,'axes.spines.right':False,'figure.constrained_layout.use':True})
 runs={};sources=[]
 for key in LABELS:
  runs[key]=[]
  for path in manifest[key]:
   p=Path(path);r=read(p)['result'];runs[key].append(r)
   assert r['savedFullStates'] and r.get('completed',True)
   sources.append({'workflow':key,'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 base=runs['phreeqc'][0];poly=polygons(base['grid']);xy=np.asarray(base['coordinates']);wc=np.atleast_1d(base['wellCells']).astype(int)-1
 times=np.concatenate([r['timeDays'] for r in runs['phreeqc']]);n=len(times)
 for key in LABELS:np.testing.assert_allclose(times,np.concatenate([r['timeDays'] for r in runs[key]]))
 phases=[];rates=[]
 for r in runs['phreeqc']:
  controls=np.atleast_1d(r['schedule']['control']);ids=np.asarray(r['schedule']['step']['control'],int)-1
  for t,idx in zip(r['timeDays'],ids):
   w=controls[idx]['W'];active=bool(w['status']) and float(w['val'])!=0;rate=float(w['val'])*86400 if active else 0
   rates.append(rate);phases.append('Build-up' if t<=147 else ('Injection' if active and w['sign']>0 else 'Withdrawal' if active and w['sign']<0 else 'Idle'))
 selected=np.unique(np.r_[np.linspace(0,n-1,60).astype(int),np.flatnonzero(np.r_[True,np.asarray(phases[1:])!=np.asarray(phases[:-1])]),[np.argmin(abs(times-t)) for t in [147,174,240.801367,307.602734,times[-1]]]])
 selected=selected.astype(int)
 data={'times':times[selected].round(4).tolist(),'phases':[phases[i] for i in selected], 'polygons':[v.round(5).tolist() for v in poly], 'well':xy[wc,:2].tolist(),'runs':{},'variables':[]}
 fields={}
 for key in LABELS:
  rr=runs[key];h=np.concatenate([r['h2'] for r in rr],axis=1);b=np.concatenate([r['biomass'] for r in rr],axis=1)
  assert np.isfinite(h).all() and h.min()>=-1e-12 and np.isfinite(b).all() and b.min()>=0
  # Both collector representations start at population scale 15. Ratios
  # show evolution within a workflow, not equivalent physical biomass.
  fields[key]=[np.log10(np.maximum(h[:,selected].T,1e-12))]+[np.log10(np.maximum(b[:,selected,j].T/15,1e-6)) for j in range(3)]
 for j,(name,cmap) in enumerate([('Dissolved H₂ mole fraction','viridis'),('MET population / initial','magma'),('ACE population / initial','magma'),('SRB population / initial','magma')]):
  vals=np.concatenate([fields[k][j].ravel() for k in LABELS]);lo=float(np.floor(vals.min()));hi=float(np.ceil(vals.max()));hi=max(hi,lo+1)
  palette=(matplotlib.colormaps[cmap](np.linspace(0,1,256))[:,:3]*255).round().astype(int).tolist()
  data['variables'].append({'name':name,'lo':lo,'hi':hi,'palette':palette})
 for key in LABELS:
  data['runs'][key]=[base64.b64encode(np.clip(np.round((a-data['variables'][j]['lo'])/(data['variables'][j]['hi']-data['variables'][j]['lo'])*255),0,255).astype('uint8').tobytes()).decode() for j,a in enumerate(fields[key])]
 (OUT/'frames.json.gz').write_bytes(gzip.compress(json.dumps(data,separators=(',',':')).encode(),mtime=0))
 # Geometry and operating schedule.
 fig,ax=plt.subplots(1,2,figsize=(11,4.2),gridspec_kw={'width_ratios':[1,1.5]})
 regions=np.asarray(base['rock']['regions']['saturation']);im=mapplot(ax[0],poly,regions,ListedColormap(['#e8d8b8','#9db6c6','#657e90']),1,3)
 ax[0].plot(xy[wc,0],xy[wc,1],color='#172a3a',lw=2)
 for name,pos in [('Caprock',(25,43)),('Storage aquifer',(25,18)),('Bedrock',(25,3))]:ax[0].text(*pos,name,ha='center',fontsize=10)
 ax[0].set_title('Layered storage model');ax[1].step(np.r_[0,times],np.r_[rates[0],rates],where='pre',color='#087f82',lw=1.5)
 for t in [147,213.801367,280.602734]:ax[1].axvline(t,color='#a8b4bd',ls=':',lw=.8)
 ax[1].axhline(0,color='#607080',lw=.7);ax[1].set(xlabel='Time (days)',ylabel='Prescribed surface gas rate (m³/day)',title='Build-up and three storage cycles',xlim=(0,times[-1]));ax[1].grid(axis='y',alpha=.2);save(fig,'phreeqc_2d_setup')
 # Paired loss histories and metabolic decomposition.
 fig,axes=plt.subplots(1,2,figsize=(11,3.7));history=[]
 for key in LABELS:
  rr=runs[key];loss=np.concatenate([r['lossPercent'] for r in rr]);cons=np.concatenate([r['consumedMoles'] for r in rr]);injected=np.concatenate([r['injectionHistoryMoles'] for r in rr]);reaction=np.concatenate([r['consumption'].sum(0) for r in rr],axis=0)
  np.testing.assert_allclose(reaction.sum(1),cons,atol=1e-6);assert np.diff(cons).min()>=-1e-7
  axes[0].plot(times,loss,label=LABELS[key],color=COLORS[key],lw=2)
  for i,t in enumerate(times):history.append([key,t,cons[i],injected[i],loss[i],*reaction[i]])
 for j,(name,color) in enumerate(zip(['Methanogenesis','Acetogenesis','Sulfate reduction'],['#087f82','#b86299','#d78a25'])):
  for key,ls in [('phreeqc','-'),('mobile','--')]:
   v=np.concatenate([r['consumption'][:,:,j].sum(0) for r in runs[key]])/1000
   axes[1].plot(times,v,color=color,ls=ls,lw=1.8,label=name if key=='phreeqc' else None)
 for a in axes:
  a.set(xlabel='Time (days)',xlim=(0,times[-1]));a.grid(axis='y',alpha=.2)
  for t in [147,213.801367,280.602734]:a.axvline(t,color='#b8c4ca',ls=':',lw=.8)
 axes[0].set(ylabel='Consumed / cumulative injected H₂ (%)',title='Hydrogen consumption');axes[0].legend(frameon=False,fontsize=9)
 axes[1].set(ylabel='Cumulative H₂ consumed (kmol)',title='Reaction pathways · solid PHREEQC, dashed mobile');axes[1].legend(frameon=False,fontsize=9);save(fig,'phreeqc_2d_loss')
 # Snapshot at the last injection endpoint, explicitly excluding absent gas.
 r=runs['phreeqc'][-1];localph=phases[-len(r['timeDays']):];idx=np.flatnonzero(np.array(localph)=='Injection')[-1];s=read(packed(r)/f'state{idx+1}.mat')['data']
 fig,axes=plt.subplots(1,4,figsize=(12,3.8));snap=[]
 for j,(name,values,cmap,lo,hi) in enumerate([('Gas H₂',s['y'][:,1],'viridis',0,1),('Gas CO₂',s['y'][:,2],'magma',0,float(s['y'][:,2].max())),('Gas CH₄',s['y'][:,3],'viridis',0,1),('Aqueous pH',s['phreeqcPH'],'cividis',float(s['phreeqcPH'].min()),float(s['phreeqcPH'].max()))]):
  values=np.array(values,float);values[np.asarray(s['s'])[:,1]<1e-6]=np.nan if j<3 else values[np.asarray(s['s'])[:,1]<1e-6]
  im=mapplot(axes[j],poly,values,cmap,lo,hi);axes[j].plot(xy[wc,0],xy[wc,1],color='#172a3a',lw=1.4);axes[j].set_title(name);fig.colorbar(im,ax=axes[j],orientation='horizontal',fraction=.06,pad=.16,label='Mole fraction (–)' if j<3 else 'pH (–)')
  snap.append(values)
 save(fig,'phreeqc_2d_chemistry')
 import csv
 with (OUT/'histories.csv').open('w',newline='') as f:
  w=csv.writer(f);w.writerow(['workflow','time_days','consumed_h2_mol','cumulative_injected_h2_mol','loss_percent','met_h2_mol','ace_h2_mol','srb_h2_mol']);w.writerows(history)
 metrics={'end_days':float(times[-1]),'frames':len(selected),'cells':len(poly),'snapshot_days':float(r['timeDays'][idx]),'sources':sources,'loss_normalization':'Cumulative consumed H2 divided by cumulative prescribed H2 injection at each time.','population_normalization':'Collector population scale divided by initial value 15; workflow-specific representations are not equivalent physical biomass units.','animation_sampling':'Selected accepted states; no interpolation of fields. Color quantization: 256 levels in log10 space.','results':{k:{'loss_percent':float(runs[k][-1]['finalLossPercent']),'consumed_kmol':float(runs[k][-1]['consumedMoles'][-1]/1000),'element_audit_available':bool(runs[k][-1]['elementAuditAvailable']),'element_audit_failures':sum(int(r['elementAuditFailures']) for r in runs[k]),'element_audit_max_mol':max(float(r['elementAuditMaxAbsoluteResidual']) for r in runs[k])} for k in LABELS}}
 (OUT/'provenance.json').write_text(json.dumps(metrics,indent=2));print(json.dumps(metrics,indent=2))
if __name__=='__main__':main()
