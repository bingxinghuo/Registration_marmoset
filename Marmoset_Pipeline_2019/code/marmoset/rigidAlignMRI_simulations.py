from __future__ import print_function
import SimpleITK as sitk
import numpy as np
import ndreg3D
import sys

mrifilename = sys.argv[1]
targetfilename = sys.argv[2]
outputimagefilename = sys.argv[3]
transformfilename = sys.argv[4]

#mri = sitk.ReadImage('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/m920/mri_200.img')
#target = sitk.ReadImage('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img')
mri = sitk.ReadImage(mrifilename)
target = sitk.ReadImage(targetfilename)

# find the center of the MRI (temp)
#mri_NP = sitk.GetArrayFromImage(mri)
#mricenter = np.array((np.mean(np.where(mri_NP>20)[2])*mri.GetSpacing()[0],np.mean(np.where(mri_NP>20)[1])*mri.GetSpacing()[1],np.mean(np.where(mri_NP>20)[0])*mri.GetSpacing()[2]))

# find the center of the nissl (last)
#target_NP = sitk.GetArrayFromImage(target)
#targetcenter = np.array((np.mean(np.where(target_NP>28)[2])*target.GetSpacing()[0],np.mean(np.where(target_NP>28)[1])*target.GetSpacing()[1],np.mean(np.where(target_NP>28)[0])*target.GetSpacing()[2]))

# shift centers
#myoffset = -1*(targetcenter-mricenter)

# downsample the target to 200 um
#identityAffine = sitk.AffineTransform(3)
#target_ds = sitk.Resample(target,tuple(int(np.round(x/2.5)) for x in target.GetSize()),identityAffine,sitk.sitkLinear,(0,0,0),mri.GetSpacing(),(1,0,0,0,1,0,0,0,1),0.0)

# euler3d transform
interpolator = sitk.sitkLinear
transform = sitk.Euler3DTransform()
#transform.SetMatrix(euler3d[0:9])
#transform.SetTranslation(euler3d[9:12])
transform.SetCenter([x/2.0*mri.GetSpacing()[0] for x in mri.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.02
iterations=2000
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0001)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(target,mri)
euler3d = list(transform.GetMatrix()) + list(transform.GetTranslation())

interpolator = sitk.sitkLinear
transform = sitk.Euler3DTransform()
transform.SetMatrix(euler3d[0:9])
transform.SetTranslation(euler3d[9:12])
transform.SetCenter([x/2.0*mri.GetSpacing()[0] for x in mri.GetSize()])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)
numHistogramBins = 64
registration.SetMetricAsMattesMutualInformation(numHistogramBins)
learningRate=0.01
iterations=2000
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0001)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(target,mri)
euler3d = list(transform.GetMatrix()) + list(transform.GetTranslation())

# resample image
#mriOut = ndreg3D.imgApplyAffine(mri, euler3d, useNearest=False, size=target.GetSize())
mriOut = sitk.Resample(mri,target.GetSize(),transform,sitk.sitkLinear,(0,0,0),target.GetSpacing(),(1,0,0,0,1,0,0,0,1),0.0)

sitk.WriteImage(mriOut,outputimagefilename)

# save the transform
mytransformfile = open(transformfilename, "w")
for item in euler3d:
    mytransformfile.write("%s\n" % item)

mytransformfile.write("%s\n" % str(mri.GetSize()[0]/2.0*mri.GetSpacing()[0]))
mytransformfile.write("%s\n" % str(mri.GetSize()[1]/2.0*mri.GetSpacing()[0]))
mytransformfile.write("%s\n" % str(mri.GetSize()[2]/2.0*mri.GetSpacing()[0]))
mytransformfile.close()


