from __future__ import print_function
import numpy as np
import SimpleITK as sitk
import os, math, sys, subprocess, tempfile, shutil, requests
from itertools import product

dimension = 3
vectorComponentType = sitk.sitkFloat32
vectorType = sitk.sitkVectorFloat32
affine = sitk.AffineTransform(dimension)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
zeroIndex = [0]*dimension

ndregDirPath = "/cis/home/leebc/Projects/Mouse_Histology/code/ndreg_bin/ndreg/"

def dirMake(dirPath):
    if dirPath != "":
        if not os.path.exists(dirPath): os.makedirs(dirPath)
        return os.path.normpath(dirPath) + "/"
    else:
        return dirPath

def imgRead(path):
    """
    Alias for sitk.ReadImage
    """
    
    inImg = sitk.ReadImage(path)
    inImg = imgCollaspeDimension(inImg) ###
    #if(inImg.GetDimension() == 2): inImg = sitk.JoinSeriesImageFilter().Execute(inImg)
    
    inDimension = inImg.GetDimension()
    inImg.SetDirection(sitk.AffineTransform(inDimension).GetMatrix())
    inImg.SetOrigin([0]*inDimension)
    
    return inImg

def imgWrite(img, path):
    """
    Write sitk image to path.
    """
    dirMake(os.path.dirname(path))
    sitk.WriteImage(img, path)

    # Reformat files to be compatible with CIS Software
    ext = os.path.splitext(path)[1].lower()
    if ext == ".vtk": vtkReformat(path, path)

def txtWrite(text, path, mode="w"):
    """
    Conveinence function to write text to a file at specified path
    """
    dirMake(os.path.dirname(path))
    textFile = open(path, mode)
    print(text, file=textFile)
    textFile.close()


def imgApplyAffine(inImg, affine, useNearest=False, size=[], spacing=[]):
    # Set interpolator
    interpolator = [sitk.sitkLinear, sitk.sitkNearestNeighbor][useNearest]

    # Set affine parameters
    affineTransform = sitk.AffineTransform(dimension)
    numParameters = len(affineTransform.GetParameters())
    if (len(affine) != numParameters): raise Exception("affine must have length {0}.".format(numParameters))
    affineTransform = sitk.AffineTransform(dimension)
    affineTransform.SetParameters(affine)

    # Set Spacing
    if spacing == []:
        spacing = inImg.GetSpacing()
    else:
        if len(spacing) != dimension: raise Exception("spacing must have length {0}.".format(dimension))

    # Set size
    if size == []:
        # Compute size to contain entire output image
        size = sizeOut(inImg, affineTransform, spacing)
    else:
       if len(size) != dimension: raise Exception("size must have length {0}.".format(dimension))
    
    # Apply affine transform
    outImg = sitk.Resample(inImg, size, affineTransform, interpolator, zeroOrigin, spacing)
    
    return outImg

def sizeOut(inImg, transform, outSpacing):
    """
    Calculates size of bounding box which encloses transformed image
    """
    outCornerPointList = []
    inSize = inImg.GetSize()
    for corner in product((0,1), repeat=dimension):
        inCornerIndex = np.array(corner)*np.array(inSize)
        inCornerPoint = inImg.TransformIndexToPhysicalPoint(inCornerIndex)
        outCornerPoint = transform.GetInverse().TransformPoint(inCornerPoint)
        outCornerPointList += [list(outCornerPoint)]

    size = np.ceil(np.array(outCornerPointList).max(0) / outSpacing).astype(int)
    return size

def imgThreshold(inImg, threshold=0, forgroundValue=1):
    tmpMask = sitk.BinaryThreshold(inImg, 0, threshold, 0, forgroundValue)
    spacing = min(list(inImg.GetSpacing()))
    openingRadiusMM = 0.5  # In mm
    openingRadius = max(1, int(round(openingRadiusMM / spacing))) # In voxels
    
    # Morphological open mask remove small background objects
    opener = sitk.GrayscaleMorphologicalOpeningImageFilter()
    opener.SetKernelType(sitk.sitkBall)
    opener.SetKernelRadius(openingRadius)
    tmpMask = opener.Execute(tmpMask)
    
    # Morphologically close mask to fill in any holes
    closingRadiusMM = 0.2   # In mm
    closingRadius = max(1, int(round(closingRadiusMM / spacing))) # In voxels
    closer = sitk.GrayscaleMorphologicalClosingImageFilter()
    closer.SetKernelType(sitk.sitkBall)
    closer.SetKernelRadius(closingRadius)
    tmpMask = closer.Execute(tmpMask)
    
    return imgLargestMaskObject(tmpMask)

def imgMakeMask(inImg, threshold=None, forgroundValue=1, openingRadiusMM=0.05, closingRadiusMM=0.45):
    """
    Generates morphologically smooth mask with given forground value from input image.
    If a threshold is given, the binary mask is initialzed using the given threshold...
    ...Otherwise it is initialized using Otsu's Method.
    """
    
    if threshold is None:
        # Initialize binary mask using otsu threshold
        inMask = sitk.BinaryThreshold(inImg, 0, 0, 0, forgroundValue) # Mask of non-zero voxels
        otsuThresholder = sitk.OtsuThresholdImageFilter()
        otsuThresholder.SetInsideValue(0)
        otsuThresholder.SetOutsideValue(forgroundValue)
        otsuThresholder.SetMaskValue(forgroundValue)
        tmpMask = otsuThresholder.Execute(inImg, inMask)
    else:
        # initialzie binary mask using given threshold
        tmpMask = sitk.BinaryThreshold(inImg, 0, threshold, 0, forgroundValue)
    
    # Assuming input image is has isotropic resolution...
    # ... compute size of morphological kernels in voxels.
    spacing = min(list(inImg.GetSpacing()))
    #openingRadiusMM = 0.05  # In mm
    #closingRadiusMM = 0.45   # In mm
    openingRadius = max(1, int(round(openingRadiusMM / spacing))) # In voxels
    closingRadius = max(1, int(round(closingRadiusMM / spacing))) # In voxels
    
    # Morphological open mask remove small background objects
    opener = sitk.GrayscaleMorphologicalOpeningImageFilter()
    opener.SetKernelType(sitk.sitkBall)
    opener.SetKernelRadius(openingRadius)
    tmpMask = opener.Execute(tmpMask)
    
    # Morphologically close mask to fill in any holes
    closer = sitk.GrayscaleMorphologicalClosingImageFilter()
    closer.SetKernelType(sitk.sitkBall)
    closer.SetKernelRadius(closingRadius)
    outMask = closer.Execute(tmpMask)
    
    return imgLargestMaskObject(outMask)

def imgMakeSliceMask(inImg, threshold=None, forgroundValue=1, openingRadiusMM=0.05, closingRadiusMM=0.45):
    """
    Generates morphologically smooth mask with given forground value from input image.
    If a threshold is given, the binary mask is initialzed using the given threshold...
    ...Otherwise it is initialized using Otsu's Method.
    """
    
    if threshold is None:
        # Initialize binary mask using otsu threshold
        inMask = sitk.BinaryThreshold(inImg, 0, 0, 0, forgroundValue) # Mask of non-zero voxels
        otsuThresholder = sitk.OtsuThresholdImageFilter()
        otsuThresholder.SetInsideValue(0)
        otsuThresholder.SetOutsideValue(forgroundValue)
        otsuThresholder.SetMaskValue(forgroundValue)
        tmpMask = otsuThresholder.Execute(inImg, inMask)
    else:
        # initialzie binary mask using given threshold
        tmpMask = sitk.BinaryThreshold(inImg, 0, threshold, 0, forgroundValue)
    
    # Assuming input image is has isotropic resolution...
    # ... compute size of morphological kernels in voxels.
    spacing = min(list(inImg.GetSpacing()))
    #openingRadiusMM = 0.05  # In mm
    #closingRadiusMM = 0.45   # In mm
    openingRadius = max(1, int(round(openingRadiusMM / spacing))) # In voxels
    closingRadius = max(1, int(round(closingRadiusMM / spacing))) # In voxels
    
    # Morphological open mask remove small background objects
    opener = sitk.GrayscaleMorphologicalOpeningImageFilter()
    opener.SetKernelType(sitk.sitkBall)
    opener.SetKernelRadius(openingRadius)
    outMask = opener.Execute(tmpMask)
    
    # Morphologically close mask to fill in any holes
    #closer = sitk.GrayscaleMorphologicalClosingImageFilter()
    #closer.SetKernelType(sitk.sitkBall)
    #closer.SetKernelRadius(closingRadius)
    #outMask = closer.Execute(tmpMask)
    #outMask = sitk.VotingBinaryHoleFilling(outMask, radius=(1,1), majorityThreshold=1, foregroundValue = 1., backgroundValue = 0.)
    
    return imgLargestMaskObject(outMask)
    #return outMask

def imgMask(img, mask):
    """
    Convenience function to apply mask to image
    """
    return  sitk.MaskImageFilter().Execute(img, mask)

def imgLargestMaskObject(maskImg):
    ccFilter = sitk.ConnectedComponentImageFilter()
    labelImg = ccFilter.Execute(maskImg)
    numberOfLabels = ccFilter.GetObjectCount()
    labelArray = sitk.GetArrayFromImage(labelImg)
    labelSizes = np.bincount(labelArray.flatten())
    largestLabel = np.argmax(labelSizes[1:])+1
    keepind = np.where(labelSizes[1:] > 200)[0]+1
    outImg = sitk.GetImageFromArray((labelArray==largestLabel).astype(np.int16))
    outImgArray = sitk.GetArrayFromImage(outImg)
    for i in range(keepind.shape[0]):
        outImgArray[np.where(labelArray==keepind[i])] = 1
    
    outImg = sitk.GetImageFromArray(outImgArray)
    outImg.CopyInformation(maskImg) # output image should have same metadata as input mask image
    return outImg

def imgMetamorphosis(inImg, refImg, alpha=0.02, beta=0.05, scale=1.0, iterations=1000, useNearest=False, useBias=False, useMI=False, verbose=False, debug=False, inMask=None, refMask=None, outDirPath=""):
    """
    Performs Metamorphic LDDMM between input and reference images
    """
    useTempDir = False
    if outDirPath == "":
        useTempDir = True
        outDirPath = tempfile.mkdtemp() + "/"
    else:
        outDirPath = dirMake(outDirPath)

    inPath = outDirPath + "in.img"
    imgWrite(inImg, inPath)
    refPath = outDirPath + "ref.img"
    imgWrite(refImg, refPath)
    outPath = outDirPath + "out.img"

    fieldPath = outDirPath + "field.vtk"
    invFieldPath = outDirPath + "invField.vtk"

    binPath = ndregDirPath + "metamorphosis "
    steps = 5 ###
    command = binPath + " --in {0} --ref {1} --out {2} --alpha {3} --beta {4} --field {5} --invfield {6} --iterations {7} --scale {8} --steps {9} --verbose ".format(inPath, refPath, outPath, alpha, beta, fieldPath, invFieldPath, iterations, scale, steps)
    if(not useBias): command += " --mu 0"
    if(useMI):
        #command += " --cost 1 --sigma 1e-5 --epsilon 1e-3" 
        command += " --cost 1 --sigma 1e-4 --epsilon 1e-3" 
        
    if(inMask):
        inMaskPath = outDirPath + "inMask.img"
        imgWrite(inMask, inMaskPath)
        command += " --inmask " + inMaskPath

    if(refMask):
        refMaskPath = outDirPath + "refMask.img"
        imgWrite(refMask, refMaskPath)
        command += " --refmask " + refMaskPath
    
    if debug: print(command)
    #os.system(command)
    (returnValue, logText) = run(command, verbose=verbose)
    
    logPath = outDirPath+"log.txt"
    txtWrite(logText, logPath)

    field = imgRead(fieldPath)
    invField = imgRead(invFieldPath)
    
    #if useTempDir: shutil.rmtree(outDirPath)
    return (field, invField)


def imgMetamorphosisComposite(inImg, refImg, alphaList=0.02, betaList=0.05, scaleList=1.0, iterations=1000, useNearest=False, useBias=False, useMI=False, inMask=None, refMask=None, verbose=True, debug=False, outDirPath=""):
    """
    Performs Metamorphic LDDMM between input and reference images
    """
    useTempDir = False
    if outDirPath == "":
        useTempDir = True
        outDirPath = tempfile.mkdtemp() + "/"
    else:
        outDirPath = dirMake(outDirPath)

    if isNumber(alphaList): alphaList = [float(alphaList)]
    if isNumber(betaList): betaList = [float(betaList)]
    if isNumber(scaleList): scaleList = [float(scaleList)]
    
    numSteps = max(len(alphaList), len(betaList), len(scaleList))

    if len(alphaList) != numSteps:
        if len(alphaList) != 1:
            raise Exception("Legth of alphaList must be 1 or same length as betaList or scaleList")
        else:
            alphaList *= numSteps

    if len(betaList) != numSteps:
        if len(betaList) != 1:
            raise Exception("Legth of betaList must be 1 or same length as alphaList or scaleList")
        else:
            betaList *= numSteps
        
    if len(scaleList) != numSteps:
        if len(scaleList) != 1:
            raise Exception("Legth of scaleList must be 1 or same length as alphaList or betaList")
        else:
            scaleList *= numSteps

    origInImg = inImg
    origInMask = inMask
    for step in range(numSteps):
        alpha = alphaList[step]
        beta = betaList[step]
        scale = scaleList[step]
        stepDirPath = outDirPath + "step" + str(step) + "/"
        if(verbose): print("\nStep {0}: alpha={1}, beta={2}, scale={3}".format(step,alpha, beta, scale))

        (field, invField) = imgMetamorphosis(inImg, refImg, 
                                             alpha, 
                                             beta, 
                                             scale, 
                                             iterations, 
                                             useNearest, 
                                             useBias, 
                                             useMI, 
                                             verbose,
                                             debug,
                                             inMask=inMask,
                                             refMask=refMask,
                                             outDirPath=stepDirPath)

        if step == 0:
            compositeField = field
            compositeInvField = invField
        else:
            compositeField = fieldApplyField(field, compositeField)
            compositeInvField = fieldApplyField(compositeInvField, invField)

            if outDirPath != "":
                fieldPath = stepDirPath+"field.vtk"
                invFieldPath = stepDirPath+"invField.vtk"
                imgWrite(compositeInvField, invFieldPath)
                imgWrite(compositeField, fieldPath)

        inImg = imgApplyField(origInImg, compositeField, size=refImg.GetSize())
        if(inMask): inMask=imgApplyField(origInMask, compositeField, size=refImg.GetSize(), useNearest=True)

    # Write final results
    if outDirPath != "":
        imgWrite(compositeField, outDirPath+"field.vtk")
        imgWrite(compositeInvField, outDirPath+"invField.vtk")
        imgWrite(inImg, outDirPath+"out.img")
        imgWrite(imgChecker(inImg,refImg), outDirPath+"checker.img")
    
    if useTempDir: shutil.rmtree(outDirPath)
    return (compositeField, compositeInvField)

def run(command, checkReturnValue=True, verbose=False):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, bufsize=1)
    outText = ""

    for line in iter(process.stdout.readline, ''):
        if verbose:  sys.stdout.write(line)
        outText += line
    #process.wait()
    process.communicate()[0]
    returnValue = process.returncode
    if checkReturnValue and (returnValue != 0): raise Exception(outText)

    return (returnValue, outText)

def fieldApplyField(inField, field):
    """ outField = inField \circ field """
    inField = sitk.Cast(inField, sitk.sitkVectorFloat64)
    field = sitk.Cast(field, sitk.sitkVectorFloat64)
    
    size = list(inField.GetSize())
    spacing = list(inField.GetSpacing())

    # Create transform for input field
    inTransform = sitk.DisplacementFieldTransform(dimension)
    inTransform.SetDisplacementField(inField)
    inTransform.SetInterpolator(sitk.sitkLinear)

    # Create transform for field
    transform = sitk.DisplacementFieldTransform(dimension)
    transform.SetDisplacementField(field)
    transform.SetInterpolator(sitk.sitkLinear)
    
    # Combine thransforms
    outTransform = sitk.Transform()
    outTransform.AddTransform(transform)
    outTransform.AddTransform(inTransform)

    # Get output displacement field
    return sitk.TransformToDisplacementFieldFilter().Execute(outTransform, vectorType, size, zeroOrigin, spacing, identityDirection)

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

def isNumber(variable):
    try:
        float(variable)
    except TypeError:
        return False
    return True

def imgCollaspeDimension(inImg):
    inSize = inImg.GetSize()

    if inImg.GetDimension() == dimension and inSize[dimension-1] == 1:
        outSize = list(inSize)
        outSize[dimension-1] = 0
        outIndex = [0]*dimension
        inImg = sitk.Extract(inImg, outSize, outIndex, 1)
        
    return inImg

def vtkReformat(inPath, outPath):
    """
    Reformats vtk file so that it can be read by CIS software.
    """
    # Get size of map
    inFile = open(inPath,"rb")
    lineList = inFile.readlines()
    for line in lineList:
        if line.lower().strip().startswith("dimensions"):
            size = map(int,line.split(" ")[1:dimension+1])
            break
    inFile.close()

    if dimension == 2: size += [0]

    outFile = open(outPath,"wb")
    for (i,line) in enumerate(lineList):
        if i == 1:
            newline = line.lstrip(line.rstrip("\n"))
            line = "lddmm 8 0 0 {0} {0} 0 0 {1} {1} 0 0 {2} {2}".format(size[2]-1, size[1]-1, size[0]-1) + newline
        outFile.write(line)
