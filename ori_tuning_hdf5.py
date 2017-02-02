#!/usr/bin/env python

import h5py
import numpy as np
import sys
import glob
import LFutils as ut
import os
import tkinter as tk
from tkinter import filedialog
import scipy.io as sio

filenames = glob.glob('frames/*.dat')
filenames.sort()

N = len(filenames)
(L1,L2) = (2048,2048)

tgt_fname = input('HDF5 filename: ')
if not tgt_fname.endswith('.hdf5'):
    tgt_fname = tgt_fname+'.hdf5'
tgt_fold = os.path.dirname(tgt_fname)
if tgt_fold:
    tgt_fold = tgt_fold + '/'
    if not os.path.isdir(tgt_fold):
        os.mkdir(tgt_fold)
    os.chdir(tgt_fold)
print(tgt_fname)
assert(not os.path.exists(tgt_fname))

f = h5py.File(tgt_fname,'w')
g = f.create_group('ori_tuning')
g = f['ori_tuning']
g['date'] = input('date: ')
g['frame_rate'] = float(input('frame rate (Hz): '))
g['animalid'] = input('animal ID: ')
g['stim_type'] = input('stim delivery: ')
g['notes'] = input('notes: ')
stim_frames = [int(line.strip()) for line in open('stims.txt')]
glf = g.create_group('LF')
glf['stim_frames'] = np.asarray(stim_frames)

print('select stim file')
root = tk.Tk()
root.withdraw()
filepath = filedialog.askopenfilename()
matfile = sio.loadmat(filepath,squeeze_me=True)
result = matfile['result']
glf['stim_orientations'] = result['stimParams'][()][0]
raw_fname = 'rawLF.hdf5'
with h5py.File(tgt_fold+raw_fname,'w') as fraw:
    for attr in ['date','animalid','notes']:
        fraw[attr] = g[attr]
    frames = fraw.create_dataset('frames',(N,L1,L2),dtype=np.uint16)
    #glf.create_dataset('raw',(N,L1,L2),dtype=np.uint16)
    for j,name in enumerate(filenames):
        with open(name,'rb') as fid:
            frame = np.fromfile(fid,dtype=np.uint16).reshape((2048,2048))
        frames[j] = frame
        print(j)
glf['raw_frames'] = h5py.ExternalLink(raw_fname,tgt_fold)
f.close()
