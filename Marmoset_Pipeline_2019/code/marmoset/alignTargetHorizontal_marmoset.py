from __future__ import print_function 
import SimpleITK as sitk
import numpy as np
import matplotlib.pyplot as plt
import sys

#target = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/stackalign/PMD2562N/PMD2562_40_full.img')
#target = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/registration/PMD2562/PMD2562_STSpipeline_output/PMD2562_orig_target_STS.img')
#atlas = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/atlas_images/ara_nissl_40_withoutOB.img')
#patientnumber = "PMD3072"
patientnumber = sys.argv[1]
targetfilename = sys.argv[2]
outputdirectoryname = sys.argv[3]
outputtargetfilename = sys.argv[4]
transformoutputdirectoryname = sys.argv[5]
if len(sys.argv) > 6:
    if int(sys.argv[6]) == 1:
        print('final transform')
        transformanno = True
    else:
        transformanno = False
else:
    transformanno = False

#target = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_orig_target_STS.img')
target = sitk.ReadImage(targetfilename)
#atlas = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/atlas_images/ara_nissl_40_withoutOB.img')
atlas = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded_refined.img',sitk.sitkFloat32)
#atlas = sitk.ReadImage('/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/PMD2562_deformedtarget.img')
target.SetDirection(atlas.GetDirection())
target.SetOrigin(atlas.GetOrigin())

dimension = 3
affine = sitk.AffineTransform(dimension)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
zeroIndex = [0]*dimension

# downsample to 100 um
target_ds = sitk.Resample(sitk.SmoothingRecursiveGaussian(target,0.025), tuple([int(np.round(x/(0.2/0.08))) for x in target.GetSize()]), affine, sitk.sitkLinear, target.GetOrigin(), (0.2, 0.2, 0.2), identityDirection, 0.0)
atlas_ds = sitk.Resample(sitk.SmoothingRecursiveGaussian(atlas,0.025), tuple([int(np.round(x/(0.2/0.08))) for x in atlas.GetSize()]), affine, sitk.sitkLinear, atlas.GetOrigin(), (0.2, 0.2, 0.2), identityDirection, 0.0)

costmetric = 'MI'

# try histogram matching
numBins = 64
numMatchPoints = 8
target_hist = sitk.HistogramMatchingImageFilter().Execute(target, atlas, numBins, numMatchPoints, False)

# try histogram matching
numBins = 64
numMatchPoints = 8
target_hist_ds = sitk.HistogramMatchingImageFilter().Execute(target_ds, atlas_ds, numBins, numMatchPoints, False)

# low res translation transform
interpolator = sitk.sitkLinear
transtransform = sitk.TranslationTransform(dimension)
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transtransform)
#registration.SetMetricAsMattesMutualInformation(64)
registration.SetMetricAsMeanSquares()
learningRate = 0.04
iterations = 400
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(atlas_ds,0.15),sitk.SmoothingRecursiveGaussian(target_ds,0.15) )
translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
outImg = sitk.Resample(target, atlas.GetSize(), transtransform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_translationtest.img')


# low res rigid 3D transform
transform = sitk.ScaleVersor3DTransform()
#transform.SetTranslation(translation[9:12])
transform.SetCenter(tuple(x/2.0*target_hist_ds.GetSpacing()[0] for x in target_hist_ds.GetSize()))
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)

if costmetric == "MI":
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.1
else:
    registration.SetMetricAsMeanSquares()
    learningRate = 0.1

iterations = 400
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0005)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(atlas_ds,0.15),sitk.SmoothingRecursiveGaussian(target_ds,0.15) )
euler3D_ds = list(transform.GetMatrix()) + list(transform.GetTranslation())
euler3D_ds_param = list(transform.GetParameters())

outImg = sitk.Resample(target, atlas.GetSize(), transform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(target[:,120,:]))
#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(outImg[:,120,:]))
#plt.show()
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_sv3dtest.img')


'''
# low res similarity 3D transform
transform = sitk.Similarity3DTransform()
transform.SetTranslation(euler3D_ds[9:12])
transform.SetMatrix(euler3D_ds[0:9])
transform.SetCenter((x/2.0*target_hist_ds.GetSpacing()[0] for x in target_hist_ds.GetSize()))
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)

if costmetric == "MI":
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.08
else:
    registration.SetMetricAsMeanSquares()
    learningRate = 0.05

iterations = 3000
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0005)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(target_ds,0.06),sitk.SmoothingRecursiveGaussian(atlas_ds,0.06) )
sim3D_ds = list(transform.GetMatrix()) + list(transform.GetTranslation())

outImg = sitk.Resample(target, target.GetSize(), transform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
plt.figure()
plt.imshow(sitk.GetArrayFromImage(target[:,120,:]))
plt.figure()
plt.imshow(sitk.GetArrayFromImage(outImg[:,120,:]))
plt.show()
'''
# low res similarity 3D transform
transform = sitk.ScaleVersor3DTransform()
#transform.SetTranslation(euler3D_ds[9:12])
#transform.SetMatrix(euler3D_ds[0:9])
transform.SetParameters(euler3D_ds_param)
transform.SetCenter(tuple(x/2.0*target_hist_ds.GetSpacing()[0] for x in target_hist_ds.GetSize()))
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)

if costmetric == "MI":
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.02
else:
    registration.SetMetricAsMeanSquares()
    learningRate = 0.1

iterations = 400
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0002)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(atlas_ds,0.15),sitk.SmoothingRecursiveGaussian(target_ds,0.15) )
sim3D_ds = list(transform.GetMatrix()) + list(transform.GetTranslation())
sim3D_ds_param = list(transform.GetParameters())
outImg = sitk.Resample(target, atlas.GetSize(), transform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)

#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(target[:,120,:]))
#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(outImg[:,100,:]))
#plt.show()
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_sv3d2test.img')

# high res similarity 3D transform
transform = sitk.ScaleVersor3DTransform()
#transform.SetTranslation(sim3D_ds[9:12])
#transform.SetMatrix(sim3D_ds[0:9])
transform.SetParameters(sim3D_ds_param)
transform.SetCenter(tuple(x/2.0*target.GetSpacing()[0] for x in target.GetSize()))
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)

if costmetric == "MI":
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.04
else:
    registration.SetMetricAsMeanSquares()
    learningRate = 0.1

iterations = 400
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.0003)
registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
registration.Execute(sitk.SmoothingRecursiveGaussian(atlas,0.06),sitk.SmoothingRecursiveGaussian(target,0.06) )
sim3D = list(transform.GetMatrix()) + list(transform.GetTranslation())

outImg = sitk.Resample(target, atlas.GetSize(), transform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_sv3dhrtest.img')

#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(target[:,120,:]))
#plt.figure()
#plt.imshow(sitk.GetArrayFromImage(outImg[:,100,:]))
#plt.show()

#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_rotatetest.img')

R = [sim3D[0]/transform.GetScale()[0], sim3D[1]/transform.GetScale()[1], sim3D[2]/transform.GetScale()[2], sim3D[3]/transform.GetScale()[0], sim3D[4]/transform.GetScale()[1], sim3D[5]/transform.GetScale()[2], sim3D[6]/transform.GetScale()[0], sim3D[7]/transform.GetScale()[1], sim3D[8]/transform.GetScale()[2]]

theta_y = np.arctan2(-R[6],np.sqrt(R[7]**2 + R[8]**2))


# produce rotation only matrix
Ry = [np.cos(theta_y),0,np.sin(theta_y),0,1,0,-np.sin(theta_y),0,np.cos(theta_y)]

# produce transform
finaltransform = sitk.Euler3DTransform()
finaltransform.SetMatrix(Ry)
#finaltransform.SetTranslation(transform.GetTranslation())
finaltransform.SetCenter(tuple(x/2.0*target.GetSpacing()[0] for x in target.GetSize()))
outImg = sitk.Resample(target, atlas.GetSize(), finaltransform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_finaltest.img')


#translation of (1,0,0) moves brain superior
#translation of (0,1,0) moves brain anterior
#translation of (0,0,1) moves brain left
# to obtain the translation in terms of global coordinates, apply the inverse rotation to the translation. then just apply the x and y (x,0,y) components to the image

Rymat = np.array(Ry)
Rymat = Rymat.reshape((3,3))
Tymat = np.zeros((3,1))
Tymat[0,0] = transform.GetTranslation()[0]
Tymat[1,0] = transform.GetTranslation()[1]
Tymat[2,0] = transform.GetTranslation()[2]
Rymat_inv = np.linalg.inv(Rymat)
Tymat_global = np.dot(Rymat_inv,Tymat)
finaltranslation = sitk.TranslationTransform(3)
finaltranslation.SetOffset((Tymat_global[0,0],0,Tymat_global[2,0]))

compositetransform = sitk.Transform(3,sitk.sitkComposite)
compositetransform.AddTransform(finaltransform)
compositetransform.AddTransform(finaltranslation)

outImg = sitk.Resample(target, atlas.GetSize(), compositetransform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_finalcomposite.img')


# apply a final translation to center it in the target image dimensions rather than the atlas image dimensions, assuming the target is centered in the atlas dimensions
finalcentertrans = [0,0,0]
finalcentertrans[0] = atlas.GetSize()[0]/2.0*atlas.GetSpacing()[0] - target.GetSize()[0]/2.0*target.GetSpacing()[0]
finalcentertrans[2] = atlas.GetSize()[2]/2.0*atlas.GetSpacing()[2] - target.GetSize()[2]/2.0*target.GetSpacing()[2]
finalcentertransform = sitk.TranslationTransform(3)
finalcentertransform.SetOffset(finalcentertrans)
finalcompositetransform = sitk.Transform(3,sitk.sitkComposite)
finalcompositetransform.AddTransform(finaltransform)
finalcompositetransform.AddTransform(finaltranslation)
finalcompositetransform.AddTransform(finalcentertransform)
outImg = sitk.Resample(target, target.GetSize(), finalcompositetransform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/cis/home/leebc/Projects/Mouse_Histology/data/registration/STStest/BNBoutput/' + patientnumber + '_finaltarget.img')

# compose the transform into a single matrix
R3 = np.eye(4)
R3[0,3] = finalcentertrans[0]
R3[2,3] = finalcentertrans[2]

R2 = np.eye(4)
R2[0,0] = finaltransform.GetMatrix()[0]
R2[0,1] = finaltransform.GetMatrix()[1]
R2[0,2] = finaltransform.GetMatrix()[2]
R2[1,0] = finaltransform.GetMatrix()[3]
R2[1,1] = finaltransform.GetMatrix()[4]
R2[1,2] = finaltransform.GetMatrix()[5]
R2[2,0] = finaltransform.GetMatrix()[6]
R2[2,1] = finaltransform.GetMatrix()[7]
R2[2,2] = finaltransform.GetMatrix()[8]

R1 = np.eye(4)
R1[0,3] = finaltranslation.GetOffset()[0]
R1[2,3] = finaltranslation.GetOffset()[2]

Ra = np.dot(R1,R3)
Rb = np.dot(R2,Ra)

singletransform = sitk.Euler3DTransform()
singletransform.SetCenter(tuple(x/2.0*target.GetSpacing()[0] for x in target.GetSize()))
singletransform.SetTranslation((Rb[0,3],0,Rb[2,3]))
singletransform.SetMatrix(tuple(map(tuple,Rb[0:3,0:3].reshape(1,9)))[0])
outImg = sitk.Resample(target, target.GetSize(), singletransform, sitk.sitkLinear, target.GetOrigin(), target.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
#sitk.WriteImage(outImg,'/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_orig_target_STS_rot.img')
sitk.WriteImage(outImg,outputdirectoryname + '/' + outputtargetfilename)

# last transform only, not the composed one
if transformanno:
    # apply to annotation
    anno = sitk.ReadImage(outputdirectoryname + '/' + patientnumber + '_annotation.img')
    anno.SetOrigin((0,0,0))
    anno.SetDirection((1,0,0,0,1,0,0,0,1))
    #anno = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_annotation.img')
    outAnno = sitk.Resample(anno, anno.GetSize(), singletransform, sitk.sitkNearestNeighbor, anno.GetOrigin(), anno.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
    sitk.WriteImage(outAnno, outputdirectoryname + '/' + patientnumber + '_annotation_rot2.img')
    #sitk.WriteImage(outAnno, '/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_annotation_rot.img')
    # apply to atlas
    #defatlas = sitk.ReadImage('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_deformedatlas.img')
    #defatlas = sitk.ReadImage(outputdirectoryname + '/' + patientnumber + '_deformedatlas.img')
    #defatlas.SetOrigin((0,0,0))
    #defatlas.SetDirection((1,0,0,0,1,0,0,0,1))
    #outDefAtlas = sitk.Resample(defatlas, defatlas.GetSize(), singletransform, sitk.sitkLinear, defatlas.GetOrigin(), defatlas.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)
    #sitk.WriteImage(outDefAtlas, '/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/' + patientnumber + '_deformedatlas_rot.img')
    #sitk.WriteImage(outDefAtlas, outputdirectoryname + '/' + patientnumber + '_deformedatlas_rot.img')

# write out transforms
R_2D = np.eye(3)
R_2D[0,0] = Rb[0,0]
R_2D[0,1] = Rb[0,2]
R_2D[1,0] = Rb[2,0]
R_2D[1,1] = Rb[2,2]
R_2D[0,2] = Rb[0,3]
R_2D[1,2] = Rb[2,3]
R_2D_inv = np.linalg.inv(R_2D)
#finaltransform2d = sitk.Euler2DTransform()
#finaltransform2d.SetCenter((target.GetSize()[0]/2.0*target.GetSpacing()[0],target.GetSize()[2]/2.0*target.GetSpacing()[2]))
#finaltransform2d.SetTranslation((R_2D[0,2],R_2D[1,2]))
#finaltransform2d.SetMatrix((R_2D[0,0],R_2D[0,1],R_2D[1,0],R_2D[1,1]))

#testslice = target[:,120,:]
#testout2d = sitk.Resample(testslice, testslice.GetSize(), finaltransform2d, sitk.sitkLinear, testslice.GetOrigin(), testslice.GetSpacing(), (1,0,0,1), 0.0)

#outputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/transforms'
if transformanno:
    myxformfile = open(transformoutputdirectoryname + '/' + patientnumber + '_XForm_finalrotation_matrix.txt','w')
else:
    myxformfile = open(transformoutputdirectoryname + '/' + patientnumber + '_XForm_firstrotation_matrix.txt','w')

myxformfile.write("%f,%f,%f,%f,%f,%f,%f,%f\n" % (R_2D[0,0],R_2D[0,1],R_2D[1,0],R_2D[1,1],R_2D[0,2],R_2D[1,2],target.GetSize()[0]/2.0*target.GetSpacing()[0],target.GetSize()[2]/2.0*target.GetSpacing()[2]))
myxformfile.close()


'''
# affine transform
transform = sitk.AffineTransform(3)
transform.SetMatrix(sim3D[0:9])
transform.SetTranslation(sim3D[9:12])
#transform.SetTranslation(translation[9:12])
registration = sitk.ImageRegistrationMethod()
registration.SetInterpolator(interpolator)
registration.SetInitialTransform(transform)

if costmetric == "MI":
    numHistogramBins = 64
    registration.SetMetricAsMattesMutualInformation(numHistogramBins)
    learningRate=0.001
else:
    registration.SetMetricAsMeanSquares()
    learningRate = 0.05

iterations = 2000
registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.001)
registration.Execute(sitk.SmoothingRecursiveGaussian(target_hist,0.06),sitk.SmoothingRecursiveGaussian(atlas,0.06) )
affine = list(transform.GetMatrix()) + list(transform.GetTranslation())

'''

