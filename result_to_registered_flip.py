#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 30 18:05:00 2019
Modified on Tue Apr 28 2020

@author: bingxinghuo
"""

import SimpleITK as sitk
import numpy as np
import sys
import os

resultfile = sys.argv[1]
atlasfile = sys.argv[2]
flipfile=sys.argv[3]

if resultfile.endswith('.tif'):
    reader = sitk.ImageFileReader()
    reader.SetFileName(resultfile)
    img = reader.Execute()
    arr0 = sitk.GetArrayFromImage(img)
    arr = np.swapaxes(arr0,1,2)
    arr=np.float32(arr)
elif resultfile.endswith('.mat'):
    import h5py
    f=h5py.File(resultfile,'r') # read file -v7.3 mat
    a=f['neurondensityproof'] 
    C=a.len() # number of cells
    a1=a[0][0] # access individual cell
    a1=f.get(a1).value # get numpy array
    matsize=a1.shape
    matsizel=list(matsize)
    matsizel.append(3)
    matsize=tuple(matsizel)
    arr=np.empty(matsize)
    arr[:,:,:,0]=a1
    for c in range(1,C):
        a1=a[c][0] # access individual cell
        a1=f.get(a1).value # get numpy array
        arr[:,:,:,c]=a1
            

atlasimg=sitk.ReadImage(atlasfile)
filename, file_extension = os.path.splitext(flipfile)
C=arr.shape[3]        
for c in range(C):
    img1 = sitk.GetImageFromArray(arr[:,:,:,c],False)
    img1.SetSpacing(atlasimg.GetSpacing())
    img1.SetOrigin(atlasimg.GetOrigin())
    img1.SetDirection(atlasimg.GetDirection())       
    sitk.WriteImage(img1,filename+'_'+str(c+1)+file_extension)
