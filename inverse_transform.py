#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 30 15:24:48 2019

@author: bingxinghuo
"""

import SimpleITK as sitk
import numpy as np
import sys

old_image_file=sys.argv[1]
atlas_image_file=sys.argv[2]
transformfile = sys.argv[3]
outputimagefile=sys.argv[4]

old_image=sitk.ReadImage(old_image_file)
atlas_image=sitk.ReadImage(atlas_image_file)
atlas_image_size=atlas_image.GetSize()
atlas_image_spacing=atlas_image.GetSpacing()

params = np.loadtxt(transformfile)
# inverse transform
transform = sitk.AffineTransform(3)
transform.SetMatrix(params[0:9])
transform.SetTranslation(params[9:12])
transform.SetCenter(params[12:15])
inverse_transform=transform.GetInverse()

new_image = sitk.Resample(old_image,atlas_image_size,inverse_transform,sitk.sitkLinear,(0,0,0),atlas_image_spacing,(1,0,0,0,1,0,0,0,1),0.0)
sitk.WriteImage(new_image,outputimagefile)