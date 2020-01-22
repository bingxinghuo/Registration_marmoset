import numpy as np
import SimpleITK as sitk
import os, math, sys
import ndreg2D
import parseSlideNumbers

def main():
    registration(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
    return

def registration( patientnumber, singlestartind, singleendind, listdirectoryname ):
    pixelsize = "80"
    dspixelsize = "100"
    costmetric = "MI"
    atlasdirectoryname = "/sonas-hs/mitra/hpc/home/blee/data/atlas_images/"
    targetdirectoryname = "/sonas-hs/mitra/hpc/home/blee/data/stackalign/" + patientnumber
    outputdirectoryname = "/sonas-hs/mitra/hpc/home/blee/data/registration/" + patientnumber + '/fluoro_old4/'
    matlabdirectoryname = "/opt/hpc/pkg/MATLAB/R2015b/bin/matlab"
    candirectoryname = "/sonas-hs/mitra/hpc/home/blee/code/can/"
    altslicedirectoryname = "/sonas-hs/mitra/hpc/home/blee/data/stackalign/"
    registrationoutputdirectoryname = "/sonas-hs/mitra/hpc/home/blee/data/registration/" + patientnumber + "/"
    
    dimension = 2
    affine = sitk.AffineTransform(dimension)
    identityAffine = list(affine.GetParameters())
    identityDirection = list(affine.GetMatrix())
    zeroOrigin = [0]*dimension
    zeroIndex = [0]*dimension
    
    # prepare output
    if not os.path.isdir(outputdirectoryname):
        os.mkdir(outputdirectoryname)
    
    if not os.path.isdir(outputdirectoryname + patientnumber + '_AAV_registered'):
        os.mkdir(outputdirectoryname + patientnumber + '_AAV_registered')
    
    if not os.path.isdir(outputdirectoryname + patientnumber + '_AAV_registered_rigidtrans'):
        os.mkdir(outputdirectoryname + patientnumber + '_AAV_registered_rigidtrans')
    
    # load the two images
    aavImg = sitk.ReadImage(targetdirectoryname + 'F_maskimg/' + patientnumber + '_' + pixelsize + '_AAV_full_cropped.img',sitk.sitkFloat32)
    #aavImg = sitk.ReadImage(registrationoutputdirectoryname + patientnumber + "_40_AAV_full_firstalign.img")
    aavImg.SetDirection((1,0,0,0,1,0,0,0,1))
    aavImg.SetOrigin((0,0,0))
    #nisslImg = sitk.ReadImage(targetdirectoryname + '/' + patientnumber + '_' + pixelsize + '_full.img',sitk.sitkFloat32)
    nisslImg = sitk.ReadImage(registrationoutputdirectoryname + patientnumber + "_orig_target_STS_sectionsmissing.img")
    #nisslImg = sitk.ReadImage(registrationoutputdirectoryname + patientnumber + "_orig_target_STS.img")
    nisslImg.SetDirection((1,0,0,0,1,0,0,0,1))
    nisslImg.SetOrigin((0,0,0))
    
    # for each target, extract the Nissl slice index values and the Fluoro slice index values
    ''' 
    #nissllist = [None]*1000
    #aavlist = [None]*1000
    #aavnamelist = [None]*1000
    #ka = 0
    #kn = 0
    
    #if patientnumber == "PMD2044" or patientnumber == "PMD2048" or patientnumber == "PMD2050" or patientnumber == "PMD2084":
    #    aavslicedirectoryname = "/cis/home/jpatel/Histology Registration (Partha)/Data/Original/" + patientnumber + "/REgisteredAAVs"
    #    nisslslicedirectoryname = "/cis/home/jpatel/Histology Registration (Partha)/Data/Original/" + patientnumber + "/REgisteredNissls"
    #    aavslicedirectory = os.listdir(aavslicedirectoryname)
    #    nisslslicedirectory = os.listdir(nisslslicedirectoryname)
    #    for f in aavslicedirectory:
    #        if f.find('.tif') != -1:
    #            uind = f.find('.tif')
                aavlist[ka] = int(f[uind-4:uind])
                aavnamelist[ka] = f[0:uind]
                ka += 1
        for f in nisslslicedirectory:
            if f.find('.tif') != -1:
                uind = f.find('.tif')
                nissllist[kn] = int(f[uind-4:uind])
                kn += 1
    else:
        slicedirectoryname = targetdirectoryname + '/10um_downsampled/' 
        if os.path.isdir(slicedirectoryname) and os.listdir(slicedirectoryname) != []:
            slicedirectory = os.listdir(slicedirectoryname)
            for f in slicedirectory:
                if f.find('F') != -1:
                    uind = f.find('.jp2')
                    aavlist[ka] = int(f[uind-4:uind])
                    aavnamelist[ka] = f[0:uind]
                    ka += 1
                elif f.find('N') != -1:
                    uind = f.find('.jp2')
                    nissllist[kn] = int(f[uind-4:uind])
                    kn += 1
        else:
            nisslslicedirectoryname = altslicedirectoryname + patientnumber + "N"
            aavslicedirectoryname = altslicedirectoryname + patientnumber + "F"
            aavslicedirectory = os.listdir(aavslicedirectoryname)
            nisslslicedirectory = os.listdir(nisslslicedirectoryname)
            for f in aavslicedirectory:
                if f.find('.png') != -1:
                    uind = f.find('.png')
                    aavlist[ka] = int(f[uind-4:uind])
                    aavnamelist[ka] = f[0:uind]
                    ka += 1
            for f in nisslslicedirectory:
                if f.find('.png') != -1:
                    uind = f.find('.png')
                    nissllist[kn] = int(f[uind-4:uind])
                    kn += 1
    
    #aavlist = filter(None, aavlist)
    #aavnamelist = filter(None, aavnamelist)
    #nissllist = filter(None, nissllist)
    #aavidx = [i[0] for i in sorted(enumerate(aavlist), key=lambda x:x[1])]
    #aavnamelist = [ aavnamelist[i] for i in aavidx ]
    #aavlist.sort()
    #nissllist.sort()
    '''
    # read list file into list
    listfile = open(listdirectoryname + '/' + patientnumber + "_" + str.upper('F') + '_List.txt')
    (aavdirectorylist, aavnamelist, aavlist) = parseSlideNumbers.parse(listdirectoryname + '/' + patientnumber + "_" + str.upper('F') + '_List.txt',singlestartind,singleendind,patientnumber)
    listfile = open(listdirectoryname + '/' + patientnumber + "_" + str.upper('N') + '_List.txt')
    (nissldirectorylist, nisslnamelist, nissllist) = parseSlideNumbers.parse(listdirectoryname + '/' + patientnumber + "_" + str.upper('N') + '_List.txt',singlestartind,singleendind,patientnumber)
    print(aavlist)
    
    kk = 0
    # for each slice of the fluoro image, find the closest slice in the Nissl image
    #for f in aavlist:
    for i in range(len(aavlist)):
        f = aavlist[i]
        print('iter ' + str(i) + ', f = ' + str(f) + ', aavlist = ')
        print(aavlist)
        # I'm searching for this aav slice number plus 0.5 in case that nissl slice is missing but the one greater than it exists
        closestnumber = min(nissllist,key=lambda x:abs(x-(f+0.5)))
        
        # extract those two slices
        aavslice = aavImg[:,f-1,:]
        nisslslice = nisslImg[:,closestnumber-1+40,:]
        
        #perform translation registration
        try:
            interpolator = sitk.sitkLinear
            transtransform = sitk.TranslationTransform(dimension)
            registration = sitk.ImageRegistrationMethod()
            registration.SetInterpolator(interpolator)
            registration.SetInitialTransform(transtransform)
            numHistogramBins = 64
            registration.SetMetricAsMattesMutualInformation(numHistogramBins)
            learningRate=0.02
            iterations = 2000
            registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0005)
            #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
            registration.Execute(sitk.SmoothingRecursiveGaussian(nisslslice,0.4),sitk.SmoothingRecursiveGaussian(aavslice,0.4) )
            translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
            outImg = ndreg2D.imgApplyAffine2D(aavslice, translation, size=nisslslice.GetSize())
            outImgnp = sitk.GetArrayFromImage(outImg)
            lastimgnp = sitk.GetArrayFromImage(nisslslice)
        except:
            translation = [1,0,0,1,0,0]
        
        #perform translation registration
        try:
            interpolator = sitk.sitkLinear
            transtransform = sitk.TranslationTransform(dimension)
            transtransform.SetOffset(translation[4:6])
            registration = sitk.ImageRegistrationMethod()
            registration.SetInterpolator(interpolator)
            registration.SetInitialTransform(transtransform)
            numHistogramBins = 64
            registration.SetMetricAsMattesMutualInformation(numHistogramBins)
            learningRate=0.005
            iterations = 2000
            registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate,numberOfIterations=iterations,estimateLearningRate=registration.EachIteration,minStep=0.0001)
            #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
            registration.Execute(sitk.SmoothingRecursiveGaussian(nisslslice,0.35),sitk.SmoothingRecursiveGaussian(aavslice,0.35) )
            translation = identityAffine[0:dimension**2] + list(transtransform.GetOffset())
            outImg = ndreg2D.imgApplyAffine2D(aavslice, translation, size=nisslslice.GetSize())
            outImgnp = sitk.GetArrayFromImage(outImg)
            lastimgnp = sitk.GetArrayFromImage(nisslslice)
        except:
            translation=[1,0,0,1,0,0]
        
        # perform euler2d registration
        try:
            transform = sitk.Euler2DTransform()
            transform.SetTranslation(translation[4:6])
            registration = sitk.ImageRegistrationMethod()
            registration.SetInterpolator(interpolator)
            registration.SetInitialTransform(transform)
            numHistogramBins = 64
            registration.SetMetricAsMattesMutualInformation(numHistogramBins)
            learningRate=0.02
            iterations = 2000
            registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.00005)
            #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
            registration.Execute(sitk.SmoothingRecursiveGaussian(nisslslice,0.2),sitk.SmoothingRecursiveGaussian(aavslice,0.2) )
            euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
            outImg = ndreg2D.imgApplyAffine2D(aavslice, euler2d, size=nisslslice.GetSize())
            outImgnp = sitk.GetArrayFromImage(outImg)
            lastimgnp = sitk.GetArrayFromImage(nisslslice)
        except:
            euler2d=[1,0,0,1,0,0]
        
        # perform euler2d registration
        try:
            transform = sitk.Euler2DTransform()
            transform.SetTranslation(euler2d[4:6])
            transform.SetMatrix(euler2d[0:4])
            registration = sitk.ImageRegistrationMethod()
            registration.SetInterpolator(interpolator)
            registration.SetInitialTransform(transform)
            numHistogramBins = 64
            registration.SetMetricAsMattesMutualInformation(numHistogramBins)
            learningRate=0.005
            iterations = 2000
            registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
            #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
            registration.Execute(sitk.SmoothingRecursiveGaussian(nisslslice,0.06),sitk.SmoothingRecursiveGaussian(aavslice,0.06) )
            euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
            outImg = ndreg2D.imgApplyAffine2D(aavslice, euler2d, size=nisslslice.GetSize())
            outImgnp = sitk.GetArrayFromImage(outImg)
            lastimgnp = sitk.GetArrayFromImage(nisslslice)
        except:
            euler2d = [1,0,0,1,0,0]
        
        # perform euler2d registration
        try:
            transform = sitk.Euler2DTransform()
            transform.SetTranslation(euler2d[4:6])
            transform.SetMatrix(euler2d[0:4])
            registration = sitk.ImageRegistrationMethod()
            registration.SetInterpolator(interpolator)
            registration.SetInitialTransform(transform)
            numHistogramBins = 64
            registration.SetMetricAsMattesMutualInformation(numHistogramBins)
            learningRate=0.002
            iterations = 2000
            registration.SetOptimizerAsRegularStepGradientDescent(learningRate=learningRate, numberOfIterations=iterations, estimateLearningRate=registration.EachIteration,minStep=0.000025)
            #registration.AddCommand(sitk.sitkIterationEvent, lambda: print("{0}.\t {1} \t{2}".format(registration.GetOptimizerIteration(),registration.GetMetricValue(), registration.GetOptimizerLearningRate())))
            registration.Execute(sitk.SmoothingRecursiveGaussian(nisslslice,0.04),sitk.SmoothingRecursiveGaussian(aavslice,0.04) )
            euler2d = list(transform.GetMatrix()) + list(transform.GetTranslation())
            outImg = ndreg2D.imgApplyAffine2D(aavslice, euler2d, size=nisslslice.GetSize())
            outImgnp = sitk.GetArrayFromImage(outImg)
            lastimgnp = sitk.GetArrayFromImage(nisslslice)
        except:
            euler2d= [1,0,0,1,0,0]
        
        outImg = ndreg2D.imgApplyAffine2D(aavslice, euler2d, size=nisslslice.GetSize())
        
        # write out rigid transforms
        mytransformfile = open(outputdirectoryname + patientnumber + "_AAV_registered_rigidtrans/" + aavnamelist[kk] + "_rigidtrans.txt", "w")
        for item in euler2d:
            mytransformfile.write("%s\n" % item)
        
        mytransformfile.close()
        kk = kk+1
        # write out image slice
        if f < 10:
            sitk.WriteImage(outImg, outputdirectoryname + patientnumber + '_AAV_registered/000' + str(f) + '.img')
        elif f < 100:
            sitk.WriteImage(outImg, outputdirectoryname + patientnumber + '_AAV_registered/00' + str(f) + '.img')
        elif f < 1000:
            sitk.WriteImage(outImg, outputdirectoryname + patientnumber + '_AAV_registered/0' + str(f) + '.img')
        else:
            sitk.WriteImage(outImg, outputdirectoryname + patientnumber + '_AAV_registered/' + str(f) + '.img')
    
    
    
    os.system(matlabdirectoryname + " -nodesktop -nojvm -nodisplay -r \"combineRegisteredAAVs_bnb(\'" + patientnumber + "\');exit\"")
    return

if __name__=="__main__":
    main()
