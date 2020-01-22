#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 30 18:05:00 2019

@author: bingxinghuo
"""

import SimpleITK as sitk
import numpy as np
import sys

resultfile = sys.argv[1]
atlasfile = sys.argv[2]
flipfile=sys.argv[3]

reader = sitk.ImageFileReader()
reader.SetFileName(resultfile)
img = reader.Execute()
arr = sitk.GetArrayFromImage(img)
arr2 = np.swapaxes(arr,1,2)
arr2=np.float32(arr2)
img1 = sitk.GetImageFromArray(arr2)

atlasimg=sitk.ReadImage(atlasfile)

img1.SetSpacing(atlasimg.GetSpacing())
img1.SetOrigin(atlasimg.GetOrigin())
img1.SetDirection(atlasimg.GetDirection())

sitk.WriteImage(img1,flipfile)
