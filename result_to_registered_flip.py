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
    [C1,C2]=a.shape # number of cells
    n=0
    a1=a[0][n] # access individual cell
    a1=f.get(a1)[()] # get numpy array
    while (a1.sum()==0):
        n=n+1
        a1=a[0][n]
        a1=f.get(a1)[()] # get numpy array
        
    matsize=a1.shape
    matsizel=list(matsize)
    matsizel.append(3)
    matsize=tuple(matsizel)
    arr=np.empty(matsize)
#    arr[:,:,:,0]=a1
    if C2>C1:
        for c in range(1,C2):
            a1=a[C1-1][c] # access individual cell
            a1=f.get(a1)[()] # get numpy array
            if a1.sum()>0:
                arr[:,:,:,c]=a1
            
#    elif C1>C2:
#        for c in range(1,C1):
#            a1=a[c][C2-1] # access individual cell
#            a1=f.get(a1)[()] # get numpy array
#            arr[:,:,:,c]=a1
            

atlasimg=sitk.ReadImage(atlasfile)
filename, file_extension = os.path.splitext(flipfile)
C=arr.shape[3]        
for c in range(C):
    img1 = sitk.GetImageFromArray(arr[:,:,:,c],False)
    img1.SetSpacing(atlasimg.GetSpacing())
    img1.SetOrigin(atlasimg.GetOrigin())
    img1.SetDirection(atlasimg.GetDirection())       
    sitk.WriteImage(img1,filename+'_'+str(c+1)+file_extension)
