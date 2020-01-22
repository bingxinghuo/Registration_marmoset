#import sys
#sys.path.remove('/cis/home/leebc/.local/lib/python2.7/site-packages')
#sys.path.append('/cis/home/leebc/.local.old/lib/python2.7/site-packages')
from __future__ import print_function
import SimpleITK as sitk
import numpy as np
import math

dimension = 2
zeroOrigin = [0]*dimension
zeroIndex = [0]*dimension
affine = sitk.AffineTransform(dimension)
identityDirection = list(affine.GetMatrix())
identityAffine = list(affine.GetParameters())
costmetric = 'MI'

def identifyMe():
    print(538)
    return

def imgApplyAffine2D(inImg, affine, useNearest=False, size=[], spacing=[]):
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
    outImg = sitk.Resample(inImg, size, affineTransform, interpolator, inImg.GetOrigin(), spacing, identityDirection, inImg.GetPixel(0,0))

    return outImg

def targetToAtlasRigid2D(targetImg, atlasImg, initialtransform=[1,0,0,1,0,0]):
    
    # translation
    numBins = 64
    numMatchPoints = 8
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset((initialtransform[4], initialtransform[5]))
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    registration.SetMetricAsMattesMutualInformation(numBins)
    learningRate=1
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(atlasImg,5),sitk.SmoothingRecursiveGaussian(targetImg,5) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    # translation
    numBins = 64
    numMatchPoints = 8
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    registration.SetMetricAsMattesMutualInformation(numBins)
    learningRate=0.02
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(atlasImg,5),sitk.SmoothingRecursiveGaussian(targetImg,5) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    # big learning rate
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(translation[4:6])
    transform.SetMatrix(initialtransform[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    if costmetric == "MI":
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.01
    else:
        registration.SetMetricAsMeanSquares()
        learningRate = 0.05
    
    iterations = 12000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00001)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(atlasImg,5),sitk.SmoothingRecursiveGaussian(targetImg,5) )
    euler2D = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # small learning rate
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2D[4:6])
    transform.SetMatrix(euler2D[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    if costmetric == "MI":
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.0001
    else:
        registration.SetMetricAsMeanSquares()
        learningRate = 0.05

    iterations = 12000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00001)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(atlasImg,2),sitk.SmoothingRecursiveGaussian(targetImg,2) )
    euler2D = list(transform.GetMatrix()) + list(transform.GetTranslation())
    outImg = imgApplyAffine2D(targetImg, euler2D, size=tuple(np.divide(targetImg.GetSize(),1)), spacing=targetImg.GetSpacing())
    
    registration = sitk.ImageRegistrationMethod()
    if costmetric == "MI":
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    else:
        registration.SetMetricAsMeanSquares()
    
    #metricval = registration.MetricEvaluate(outImg,atlasImg)
    
    return outImg, euler2D

def sectionToSectionRigid2D(tempimg, lastimg):
    #TODO: either find the correct parameters or just use the parameters we already have for 0.01 mm pixel size and scale back up afterwards
    
    #perform translation registration
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=1
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,10),sitk.SmoothingRecursiveGaussian(tempimg,10) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    #perform translation registration
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.02
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,8),sitk.SmoothingRecursiveGaussian(tempimg,8) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    #perform translation registration
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.005
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,8),sitk.SmoothingRecursiveGaussian(tempimg,8) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.5
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,5),sitk.SmoothingRecursiveGaussian(tempimg,5) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.02
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,1.5),sitk.SmoothingRecursiveGaussian(tempimg,1.5) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.005
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,1.5),sitk.SmoothingRecursiveGaussian(tempimg,1.5) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.001
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,1),sitk.SmoothingRecursiveGaussian(tempimg,1) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.0002
    iterations = 1000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000005)
    registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(lastimg,tempimg )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    outImg = imgApplyAffine2D(tempimg, euler2d, size=lastimg.GetSize(), spacing = lastimg.GetSpacing())
    
    #registration = sitk.ImageRegistrationMethod()
    #if costmetric == "MI":
    #    numHistogramBins = 64
    #    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    #else:
    #    registration.SetMetricAsMeanSquares()
    
    #metricval = registration.MetricEvaluate(outImg,lastimg)
    
    return outImg, euler2d


def sectionToSectionRigid2D10(tempimg, lastimg):
    #perform translation registration
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.1
    iterations = 1000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.4),sitk.SmoothingRecursiveGaussian(tempimg,0.4) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.02
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.35),sitk.SmoothingRecursiveGaussian(tempimg,0.35) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    
    #perform translation registration
    interpolator = sitk.sitkLinear
    transtransform = sitk.TranslationTransform(dimension)
    transtransform.SetOffset(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transtransform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.005
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.35),sitk.SmoothingRecursiveGaussian(tempimg,0.35) )
    translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(translation[4:6])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.1
    iterations = 1000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.2),sitk.SmoothingRecursiveGaussian(tempimg,0.2) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.02
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.005
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    # perform euler2d registration
    transform = sitk.Euler2DTransform()
    transform.SetTranslation(euler2d[4:6])
    transform.SetMatrix(euler2d[0:4])
    registration = sitk.ImageRegistrationMethod()
    registration.SetInterpolator(interpolator)
    registration.SetInitialTransform(transform)
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.002
    iterations = 10000
    registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
    #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
    registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.04),sitk.SmoothingRecursiveGaussian(tempimg,0.04) )
    euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    outImg = imgApplyAffine2D(tempimg, euler2d, size=lastimg.GetSize(), spacing = lastimg.GetSpacing())
    
    return outImg, euler2d

def targetToAtlasRigid2D10(tempimg,lastimg,initialtransform=[1,0,0,1,0,0]):
    # produce a downsampled version of the inputs
    tempimg_ds = imgResample(tempimg,[0.04,0.04])
    lastimg_ds = imgResample(lastimg,[0.04,0.04])
    
    try:
        #perform translation registration
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 1000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.4),sitk.SmoothingRecursiveGaussian(tempimg,0.4) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    try:
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.02
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.35),sitk.SmoothingRecursiveGaussian(tempimg,0.2) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    try:
        #perform translation registration
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.005
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.35),sitk.SmoothingRecursiveGaussian(tempimg,0.05) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 1000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.2),sitk.SmoothingRecursiveGaussian(tempimg,0.2) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.02
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.005
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.002
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.04),sitk.SmoothingRecursiveGaussian(tempimg,0.04) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    outImg = imgApplyAffine2D(tempimg, euler2d, size=tempimg.GetSize(), spacing = tempimg.GetSpacing())
    
    return outImg, euler2d

def sectionToSectionRigid2D10wds(tempimg,lastimg,initialtransform=[1,0,0,1,0,0]):
    # produce a downsampled version of the inputs
    tempimg_ds = imgResample(tempimg,[0.04,0.04])
    lastimg_ds = imgResample(lastimg,[0.04,0.04])
    
    # try to center the two images on themselves first, otherwise if there is no overlap the alignment will go out of bounds
    # either do this naively by centering tempimg on lastimg and assume that the technician centered the camera over the sample
    # or try masking which is riskier. masking may also not work for AAV images.
    
    # place the center of tempimg on the center of lastimg
    tempcenter = np.divide(tempimg_ds.GetSize(),2)
    lastcenter = np.divide(lastimg_ds.GetSize(),2)
    myoffset = -1*(lastcenter - tempcenter) * 0.04
    
    #perform translation registration
    try:
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(list(myoffset))
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.08
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,1),sitk.SmoothingRecursiveGaussian(tempimg_ds,1) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = [1,0,0,1,0,0]
    
    try:
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.7),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.7) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = [1,0,0,1,0,0]
    
    try:
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.4),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.4) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    try:
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.02
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.35),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.35) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    
    try:
        #perform translation registration
        interpolator = sitk.sitkLinear
        transtransform = sitk.TranslationTransform(dimension)
        transtransform.SetOffset(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transtransform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.005
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.2),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.2) )
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    except:
        translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(translation[4:6])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.2),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.2) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.02
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.06),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.005
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.06),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.002
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg_ds,0.04),sitk.SmoothingRecursiveGaussian(tempimg_ds,0.04) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    
    # switch back to high res===========================================================
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(translation[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.1
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.02
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.06),sitk.SmoothingRecursiveGaussian(tempimg,0.06) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.005
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.04),sitk.SmoothingRecursiveGaussian(tempimg,0.04) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    try:
        # perform euler2d registration
        transform = sitk.Euler2DTransform()
        transform.SetTranslation(euler2d[4:6])
        transform.SetMatrix(euler2d[0:4])
        registration = sitk.ImageRegistrationMethod()
        registration.SetInterpolator(interpolator)
        registration.SetInitialTransform(transform)
        numHistogramBins = 64
        registration.SetMetricAsMattesMutualInformation(numHistogramBins)
        learningRate=0.002
        iterations = 10000
        registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
        registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
        registration.Execute(sitk.SmoothingRecursiveGaussian(lastimg,0.02),sitk.SmoothingRecursiveGaussian(tempimg,0.02) )
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    except:
        euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
    
    
    outImg = imgApplyAffine2D(tempimg, euler2d, size=lastimg.GetSize(), spacing = lastimg.GetSpacing())
    
    return outImg, euler2d

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
