#!/usr/bin/env python

import h5py
import numpy as np
import sys
import glob
import LFutils as ut
import os

filenames = glob.glob('*.dat')
filenames.sort()

N = len(filenames)
(L1,L2) = (2048,2048)

tgt_fname = input('HDF5 filename: ')
if not tgt_fname.endswith('.hdf5'):
    tgt_fname = tgt_fname+'.hdf5'
assert(not os.path.exists(tgt_fname))

f = h5py.File(tgt_fname,'w')
g = f.create_group('ori_tuning')
g = f['ori_tuning']
g['date'] = input('date: ')
g['frame_rate'] = float(input('frame rate (Hz): '))
g['animalid'] = input('animal ID: ')
g['stim_type'] = input('stim delivery: ')
g['notes'] = input('notes: ')
g.create_dataset('raw',(N,L1,L2),dtype=np.uint16)
for j,name in enumerate(filenames):
    with open(name,'rb') as fid:
        frame = np.fromfile(fid,dtype=np.uint16).reshape((2048,2048))
    g['raw'][j] = frame
    print(j)
stim_frames = [int(line.strip()) for line in open('stims.txt')]
g['stim_frames'] = np.asarray(stim_frames)
f.close()
