import numpy as np
import os, math, sys
import SimpleITK as sitk
import ndreg3D
import os
import histFunctions
import scipy.ndimage

targetimagefile = sys.argv[1]
outputmaskfile = sys.argv[2]
outputimagefile = sys.argv[3]

refImg = sitk.ReadImage(targetimagefile)
refImg.SetOrigin((0,0,0))
refImg.SetDirection((1,0,0,0,1,0,0,0,1))
origRefImg = sitk.ReadImage(targetimagefile)
origRefImg.SetOrigin((0,0,0))
origRefImg.SetDirection((1,0,0,0,1,0,0,0,1))

dimension = 3
affine = sitk.AffineTransform(dimension)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
zeroIndex = [0]*dimension

# determine cutoff for masking by histogram
#inflectionpoint = histFunctions.getInflectionPoint(refImg)
refImgNP = sitk.GetArrayFromImage(refImg)


for i in range(refImg.GetSize()[1]):
    
