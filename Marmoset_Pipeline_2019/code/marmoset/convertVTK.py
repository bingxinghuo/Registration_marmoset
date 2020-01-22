import numpy as np
import os, math, sys
import SimpleITK as sitk
from itertools import product
#import ndreg3D
import os
import sys
#import histFunctions
#import scipy.ndimage

dimension = 3
vectorComponentType = sitk.sitkFloat32
vectorType = sitk.sitkVectorFloat32
affine = sitk.AffineTransform(dimension)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
zeroIndex = [0]*dimension

def main():
    inputhmapfile = sys.argv[1]
    inputkimapfile = sys.argv[2]
    outputhmapfile = sys.argv[3]
    outputkimapfile = sys.argv[4]
    pixelsize = sys.argv[5]
    
    pixelsize = "40"
    dspixelsize = "100"
    costmetric = "MI"
    
    dimension = 3
    affine = sitk.AffineTransform(dimension)
    identityAffine = list(affine.GetParameters())
    identityDirection = list(affine.GetMatrix())
    zeroOrigin = [0]*dimension
    zeroIndex = [0]*dimension
    
    #mapPath = outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/Hmap_composed.vtk'
    inMap = imgRead(inputhmapfile)
    field = mapToField(inMap, [float(pixelsize), float(pixelsize), float(pixelsize)])
    #sitk.WriteImage(field,outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/field_forward.vtk')
    sitk.WriteImage(field,outputhmapfile)
    #mapPath = outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/Kimap_composed.vtk'
    inMap = imgRead(inputkimapfile)
    field = mapToField(inMap, [float(pixelsize), float(pixelsize), float(pixelsize)])
    sitk.WriteImage(field,outputkimapfile)
    #sitk.WriteImage(field,outputdirectoryname + '/' + patientnumber + '_STSpipeline_output/field_reverse.vtk')
    return

def mapToField(inMap, inSpacing=[]):
    """
    Convert input displacement field into CIS compatible map.
    The spacing metadata of CIS maps is often incorrect.
    Thus the user can set it using the inSpacing parameter.
    """
    inSize = inMap.GetSize()
    if inSpacing == []:
        inSpacing = inMap.GetSpacing()
    else:
        if (not isIterable(inSpacing)) or (len(inSpacing) != dimension): raise Exception("inSspacing must be a list of length "+str(dimension) + ".")
        inMap.SetSpacing(inSpacing)

    idMap = mapCreateIdentity(inSize)
    idMap.CopyInformation(inMap)

    outFieldComponentList = []
    for i in range(dimension):
        idMapComponent = sitk.VectorIndexSelectionCastImageFilter().Execute(idMap, i, vectorComponentType)
        inMapComponent = sitk.VectorIndexSelectionCastImageFilter().Execute(inMap, i, vectorComponentType)
        outFieldComponent = (inMapComponent - idMapComponent) * inSpacing[i]
        outFieldComponentList += [outFieldComponent]
    
    outField = sitk.ComposeImageFilter().Execute(outFieldComponentList)

    # Write output field
    
    return outField

def mapCreateIdentity(size):
    """
    Generates an identity map of given size
    """
    spacing = [1,1,1]
    return sitk.PhysicalPointImageSource().Execute(vectorType, size, zeroOrigin, spacing, identityDirection)

def imgApplyField(img, field, useNearest=False, size=[], spacing=[],defaultValue=0):
    """
    img \circ field
    """
    field = sitk.Cast(field, sitk.sitkVectorFloat64)

    # Set interpolator
    interpolator = [sitk.sitkLinear, sitk.sitkNearestNeighbor][useNearest]

    # Set transform field
    transform = sitk.DisplacementFieldTransform(img.GetDimension())
    transform.SetInterpolator(sitk.sitkLinear)
    transform.SetDisplacementField(field)

    # Set size
    if size == []:
        size = img.GetSize()
    else:
        if len(size) != img.GetDimension(): raise Exception("size must have length {0}.".format(img.GetDimension()))

    # Set Spacing
    if spacing == []:
        spacing = img.GetSpacing()
    else:
        if len(spacing) != img.GetDimension(): raise Exception("spacing must have length {0}.".format(img.GetDimension()))
    
    # Apply displacement transform
    return  sitk.Resample(img, size, transform, interpolator, [0]*img.GetDimension(), spacing, img.GetDirection() ,defaultValue)


def imgResample(img, spacing, size=[], useNearest=False):
    """
    Resamples image to given spacing and size.
    """
    if len(spacing) != img.GetDimension(): raise Exception("len(spacing) != " + str(img.GetDimension()))

    # Set Size
    if size == []:
        inSpacing = img.GetSpacing()
        inSize = img.GetSize()
        size = [int(math.ceil(inSize[i]*(inSpacing[i]/spacing[i]))) for i in range(img.GetDimension())]
    else:
        if len(size) != img.GetDimension(): raise Exception("len(size) != " + str(img.GetDimension()))
    
    # Resample input image
    interpolator = [sitk.sitkLinear, sitk.sitkNearestNeighbor][useNearest]
    identityTransform = sitk.Transform()
    
    return sitk.Resample(img, size, identityTransform, interpolator, zeroOrigin, spacing)


def imgRead(path):
    """
    Alias for sitk.ReadImage
    """
    
    inImg = sitk.ReadImage(path)
    inImg = imgCollapseDimension(inImg) ###
    #if(inImg.GetDimension() == 2): inImg = sitk.JoinSeriesImageFilter().Execute(inImg)
        
    inDimension = inImg.GetDimension()
    inImg.SetDirection(sitk.AffineTransform(inDimension).GetMatrix())
    inImg.SetOrigin([0]*inDimension)
    
    return inImg

def imgCollapseDimension(inImg):
    inSize = inImg.GetSize()
    
    if inImg.GetDimension() == dimension and inSize[dimension-1] == 1:
        outSize = list(inSize)
        outSize[dimension-1] = 0
        outIndex = [0]*dimension
        inImg = sitk.Extract(inImg, outSize, outIndex, 1)
        
    return inImg

def isIterable(obj):
    """
    Returns True if obj is a list, tuple or any other iterable object
    """
    return hasattr([],'__iter__')

if __name__ == "__main__":
    main()
