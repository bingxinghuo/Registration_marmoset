import numpy as np
import os, math, sys
import SimpleITK as sitk
from itertools import product
import ndreg3D
import os

pixelsize = "40"
mapPath = outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/Hmap_composed.vtk'
inMap = imgRead(mapPath)
field = mapToField(inMap, [0.04, 0.04, 0.04])
sitk.WriteImage(field,outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/field_forward.vtk')
mapPath = outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/Kimap_composed.vtk'
inMap = imgRead(mapPath)
field = mapToField(inMap, [0.04, 0.04, 0.04])
sitk.WriteImage(field,outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/field_reverse.vtk')