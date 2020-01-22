from __future__ import print_function
import sys
#from ndreg import *
import os
import SimpleITK as sitk
import numpy as np
import histFunctions
import ndreg3D

identityAffine = sitk.AffineTransform(3)

targetnumber=sys.argv[1]

outputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/target_images/' + targetnumber + '/'

croptransformfile = outputdirectoryname + targetnumber + '_invivo_croptransform.txt'

refImg = ndreg3D.imgRead('/sonas-hs/mitra/hpc/home/blee/data/target_images/' + targetnumber + '/' + targetnumber + '_invivo_mri_full.img')

# upsample to 80
outputpixelsize = 0.08
refImg_us = sitk.Resample(refImg,[int(np.round(refImg.GetSize()[0] * refImg.GetSpacing()[0] / outputpixelsize )),int(np.round(refImg.GetSize()[1] * refImg.GetSpacing()[1] / outputpixelsize )),int(np.round(refImg.GetSize()[2] * refImg.GetSpacing()[2] / outputpixelsize ))] ,identityAffine,sitk.sitkLinear,(0,0,0),(outputpixelsize, outputpixelsize, outputpixelsize),(1,0,0,0,1,0,0,0,1),0.0)

# crop
inflectionpoint = histFunctions.getInflectionPoint(refImg_us)
mymask = ndreg3D.imgMakeMask(refImg_us,threshold=inflectionpoint)

xmax = np.min((np.where(sitk.GetArrayFromImage(mymask)==1)[0].max()+15,refImg_us.GetSize()[2]))
xmin = np.max((np.where(sitk.GetArrayFromImage(mymask)==1)[0].min()-15,0))

ymax = np.min((np.where(sitk.GetArrayFromImage(mymask)==1)[2].max()+15,refImg_us.GetSize()[0]))
ymin = np.max((np.where(sitk.GetArrayFromImage(mymask)==1)[2].min()-15,0))

zmax = np.min((np.where(sitk.GetArrayFromImage(mymask)==1)[1].max()+15,refImg_us.GetSize()[1]))
zmin = np.max((np.where(sitk.GetArrayFromImage(mymask)==1)[1].min()-15,0))

croptransform = sitk.TranslationTransform(3)
croptransform.SetOffset((float(ymin) * refImg_us.GetSpacing()[0],float(zmin) * refImg_us.GetSpacing()[1], float(xmin) * refImg_us.GetSpacing()[2]))

refImg_us = sitk.Resample(refImg_us, (ymax-ymin+1,zmax-zmin+1,xmax-xmin+1), croptransform, sitk.sitkLinear, refImg_us.GetOrigin(), refImg_us.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)

myxformfile = open(croptransformfile,'w')

myxformfile.write("%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n" % (1,0,0,0,1,0,0,0,1,croptransform.GetOffset()[0],croptransform.GetOffset()[1],croptransform.GetOffset()[2],0,0,0))
myxformfile.close()

sitk.WriteImage(refImg_us,outputdirectoryname + targetnumber + '_invivo_mri_80.img')
