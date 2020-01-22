import SimpleITK as sitk
import numpy as np
import scipy.ndimage
import histFunctions
import ndreg3D
import sys

targetfilename = sys.argv[1]
outputfilename = sys.argv[2]
outputtargetfilename = sys.argv[3]

target = sitk.ReadImage(targetfilename)
refImg = sitk.ReadImage(targetfilename)
origRefImg = sitk.ReadImage(targetfilename)
inflectionpoint = histFunctions.getInflectionPoint(target)
mymask = ndreg3D.imgMakeMask(target,threshold=inflectionpoint)

mymaskarray = sitk.GetArrayFromImage(mymask)



mymaskarrayfilled = scipy.ndimage.morphology.binary_fill_holes(mymaskarray,np.ones((5,5,5)))
mymaskarrayfilledimg = sitk.GetImageFromArray(mymaskarrayfilled.astype('int8'))
mymaskarrayfilledimg.SetSpacing(target.GetSpacing())

sitk.WriteImage(mymaskarrayfilledimg,outputfilename)

targetmasked = ndreg3D.imgMask(target,mymaskarrayfilledimg)
sitk.WriteImage(targetmasked,outputtargetfilename)
