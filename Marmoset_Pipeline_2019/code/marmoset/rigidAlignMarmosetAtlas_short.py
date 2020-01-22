from __future__ import print_function
import SimpleITK as sitk
import numpy as np
import sys

atlasfilename = sys.argv[1]
targetfilename = sys.argv[2]
annofilename = sys.argv[3]
atlasmaskfilename = sys.argv[4]
outputatlasfilename = sys.argv[5]
outputannofilename = sys.argv[6]
outputatlasmaskfilename = sys.argv[7]
transformfilename = sys.argv[8]

atlas = sitk.ReadImage(atlasfilename)
target = sitk.ReadImage(targetfilename)
anno = sitk.ReadImage(annofilename)
atlasmask = sitk.ReadImage(atlasmaskfilename)
#mri = sitk.ReadImage('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/m920/mri_200.img')
#target = sitk.ReadImage('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img')

# find the center of the MRI (temp)
#mri_NP = sitk.GetArrayFromImage(mri)
#mricenter = np.array((np.mean(np.where(mri_NP>20)[2])*mri.GetSpacing()[0],np.mean(np.where(mri_NP>20)[1])*mri.GetSpacing()[1],np.mean(np.where(mri_NP>20)[0])*mri.GetSpacing()[2]))

# find the center of the nissl (last)
#target_NP = sitk.GetArrayFromImage(target)
#targetcenter = np.array((np.mean(np.where(target_NP>28)[2])*target.GetSpacing()[0],np.mean(np.where(target_NP>28)[1])*target.GetSpacing()[1],np.mean(np.where(target_NP>28)[0])*target.GetSpacing()[2]))

# shift centers
#myoffset = -1*(targetcenter-mricenter)

# downsample the target to 200 um
identityAffine = sitk.AffineTransform(3)
target_ds = sitk.Resample(target,tuple(int(np.round(x/2.5)) for x in target.GetSize()),identityAffine,sitk.sitkLinear,(0,0,0),(0.2,0.2,0.2),(1,0,0,0,1,0,0,0,1),0.0)

# downsample the atlas to 200 um
atlas_ds = sitk.Resample(atlas,tuple(int(np.round(x/2.5)) for x in atlas.GetSize()),identityAffine,sitk.sitkLinear,(0,0,0),(0.2,0.2,0.2),(1,0,0,0,1,0,0,0,1),0.0)

# translation transform
interpolator = sitk.sitkLinear
transtransform = sitk.TranslationTransform(3)
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transtransform)
registration.SetMetricAsMeanSquares()
learningRate = 0.1
iterations = 200
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.15),sitk.SmoothingRecursiveGaussian(atlas_ds,0.015) )

# euler3d transform
interpolator = sitk.sitkLinear
transform = sitk.Euler3DTransform()
transform.SetTranslation(transtransform.GetOffset())
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.06
iterations=500
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0005)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.15),sitk.SmoothingRecursiveGaussian(atlas_ds,0.15))
euler3d = list(transform.GetMatrix()) + list(transform.GetTranslation())

interpolator = sitk.sitkLinear
transform = sitk.Euler3DTransform()
transform.SetMatrix(euler3d[0:9])
transform.SetTranslation(euler3d[9:12])
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.02
iterations=500
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0002)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.15),sitk.SmoothingRecursiveGaussian(atlas_ds,0.15))
euler3d = list(transform.GetMatrix()) + list(transform.GetTranslation())

interpolator = sitk.sitkLinear
transform = sitk.Similarity3DTransform()
transform.SetMatrix(euler3d[0:9])
transform.SetTranslation(euler3d[9:12])
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.02
iterations=500
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0002)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.06),sitk.SmoothingRecursiveGaussian(atlas_ds,0.06))
sim3d = list(transform.GetMatrix()) + list(transform.GetTranslation())
sim3d_params = list(transform.GetParameters())
sim3d_params.append(sim3d_params[6])
sim3d_params.append(sim3d_params[6])

interpolator = sitk.sitkLinear
transform = sitk.ScaleVersor3DTransform()
transform.SetParameters(sim3d_params)
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.02
iterations=500
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0002)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.06),sitk.SmoothingRecursiveGaussian(atlas_ds,0.06))
sim3d = list(transform.GetMatrix()) + list(transform.GetTranslation())


interpolator = sitk.sitkLinear
transform = sitk.AffineTransform(3)
transform.SetMatrix(sim3d[0:9])
transform.SetTranslation(sim3d[9:12])
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.02
iterations=500
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0002)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.06),sitk.SmoothingRecursiveGaussian(atlas_ds,0.06))
sim3d = list(transform.GetMatrix()) + list(transform.GetTranslation())


interpolator = sitk.sitkLinear
transform = sitk.AffineTransform(3)
transform.SetMatrix(sim3d[0:9])
transform.SetTranslation(sim3d[9:12])
transform.SetCenter([x/2.0*atlas.GetSpacing()[0] for x in atlas.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.01
iterations=400
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0001)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target,0.06),sitk.SmoothingRecursiveGaussian(atlas,0.06))
hraffine = list(transform.GetMatrix()) + list(transform.GetTranslation())

# resample image
#mriOut = ndreg3D.imgApplyAffine(mri, euler3d, useNearest=False, size=target.GetSize())
atlasOut = sitk.Resample(atlas,target.GetSize(),transform,sitk.sitkLinear,(0,0,0),target.GetSpacing(),(1,0,0,0,1,0,0,0,1),0.0)
annoOut = sitk.Resample(anno,target.GetSize(),transform,sitk.sitkNearestNeighbor,(0,0,0),target.GetSpacing(),(1,0,0,0,1,0,0,0,1),0.0)
atlasmaskOut = sitk.Resample(atlasmask,target.GetSize(),transform,sitk.sitkNearestNeighbor,(0,0,0),target.GetSpacing(),(1,0,0,0,1,0,0,0,1),0.0)

sitk.WriteImage(atlasOut,outputatlasfilename)
sitk.WriteImage(annoOut,outputannofilename)
sitk.WriteImage(atlasmaskOut,outputatlasmaskfilename)

# save the transform
mytransformfile = open(transformfilename,"w")
for item in hraffine:
    mytransformfile.write("%s\n" % item)

mytransformfile.write("%s\n" % str(atlas.GetSize()[0]/2.0*atlas.GetSpacing()[0]))
mytransformfile.write("%s\n" % str(atlas.GetSize()[1]/2.0*atlas.GetSpacing()[0]))
mytransformfile.write("%s\n" % str(atlas.GetSize()[2]/2.0*atlas.GetSpacing()[0]))
mytransformfile.close()


