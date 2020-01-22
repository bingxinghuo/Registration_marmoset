import SimpleITK as sitk
import numpy as np
import scipy.ndimage
import histFunctions
import ndreg3D
import sys

targetfilename = sys.argv[1]
outputfilename = sys.argv[2]
outputtargetfilename = sys.argv[3]
useWhiten = True
maskBeforeSmooth = True
smoothMask = False
greyBackground = True
smoothAtlasAgain = True
blackVentricles = True
multicolorMask = False


target = sitk.ReadImage(targetfilename)
refImg = sitk.ReadImage(targetfilename)
origRefImg = sitk.ReadImage(targetfilename)
inflectionpoint = histFunctions.getInflectionPoint(target)
mymask = ndreg3D.imgMakeMask(target,threshold=inflectionpoint)

mymaskarray = sitk.GetArrayFromImage(mymask)
refImg = ndreg3D.imgMask(refImg,mymask)

# now go slice by slice to remove the ventricles from the mask
mymaskarray = sitk.GetArrayFromImage(mymask)
structure = [[1,1,1],[1,1,1],[1,1,1]]
#241 - might need to add a zero onto zc1trunc for the case where nothing needs to be cut
labelarray = -1*np.ones(mymaskarray.shape)
for i in range(0,origRefImg.GetSize()[1]):
    if np.unique(sitk.GetArrayFromImage(refImg[:,i,:])).shape[0] < 2:
        temparray = np.ones((labelarray.shape[0],labelarray.shape[2]))
        temparray[2:temparray.shape[0]-2,2:temparray.shape[1]-2] = np.zeros((temparray.shape[0]-4, temparray.shape[1]-4))
        labelarray[:,i,:] = temparray
        continue
    else:
        inflectionpoint = histFunctions.getInflectionPointRANSAC(refImg[:,i,:])
        myslicemask = ndreg3D.imgMakeSliceMask(refImg[:,i,:],threshold=inflectionpoint, openingRadiusMM = 0.04)
        # look for connected components, filter out anything that doesn't have enough pixels
        myslicemaskarray = sitk.GetArrayFromImage(myslicemask)
        myslicemaskarray = myslicemaskarray + 1
        myslicemaskarray[np.where(myslicemaskarray==2)[0],np.where(myslicemaskarray==2)[1]] = 0
        label, num_features = scipy.ndimage.measurements.label(myslicemaskarray,structure)
        for ii in np.add(range(num_features-1),2):#at this point, 1 = background, 0 = brain
            if len(np.where(label==ii)[0]) < 8:
	        label[np.where(label==ii)[0], np.where(label==ii)[1]] = 0
	    else:
	        label[np.where(label==ii)[0], np.where(label==ii)[1]] = 1

        # swap back to background = 0, brain = 1
        labelarray[:,i,:] = label

# now search for connected components (other than background obviously) and accept the big ones
labelarray[np.where(labelarray==-1)] = 0
labelarrayint = np.copy(labelarray.astype(np.int))

labelarrayimg = sitk.VotingBinaryHoleFilling(sitk.GetImageFromArray(labelarrayint), radius=(1,1,1), majorityThreshold=1, foregroundValue = 0., backgroundValue = 1.)
labelarrayimgout = np.copy(sitk.GetArrayFromImage(labelarrayimg))
labelarrayimgout = labelarrayimgout + 1
labelarrayimgout[np.where(labelarrayimgout==2)] = 0

structure = [[[1,1,1],[1,1,1],[1,1,1]],[[1,1,1],[1,1,1],[1,1,1]],[[1,1,1],[1,1,1],[1,1,1]]]
label, num_features = scipy.ndimage.measurements.label(sitk.GetArrayFromImage(labelarrayimg),structure)

for i in range(num_features):
    print(str(i) + "," + str(np.where(label==i)[0].shape[0]))

# now remove all large regions from the original mask (mymaskarray). Ignore regions 0 and 1 because they are brain and background
for i in range(2,num_features):
    if np.where(label==i)[0].shape[0] > 250:
        mymaskarray[np.where(label==i)] = 0

# after this phase, try replacing the slices in mymaskarray with the slices in labelarrayimg if there are not too many pixels different
pixelsperslice = mymaskarray[:,0,:].shape[0] * mymaskarray[:,0,:].shape[1]
mymaskarraycurated = -1*np.ones(mymaskarray.shape)
for i in range(mymaskarray.shape[1]):
    if np.unique(sitk.GetArrayFromImage(origRefImg[:,i,:])).shape[0] < 2:
        mymaskarraycurated[:,i,:] = np.copy(mymaskarray[:,i,:])
    else:
        if np.where((mymaskarray[:,i,:] == labelarrayimgout[:,i,:])==False)[0].shape[0]/float(pixelsperslice) < 0.18:
            mymaskarraycurated[:,i,:] = np.copy(labelarrayimgout[:,i,:])
        else:
            mymaskarraycurated[:,i,:] = np.copy(mymaskarray[:,i,:])

# if i want a multicolor mask then remove regions again
if multicolorMask == True:
    for i in range(2,num_features):
        if np.where(label==i)[0].shape[0] > 250:
            mymaskarraycurated[np.where(label==i)] = -1
   
    # set brain to 2, background to 1, ventricles to 0
    mymaskarraycurated[np.where(mymaskarraycurated==1)] = 2
    mymaskarraycurated[np.where(mymaskarraycurated==0)] = 1
    mymaskarraycurated[np.where(mymaskarraycurated==-1)] = 0
    
if blackVentricles == True:
    mymcmask = np.copy(mymaskarraycurated)
    for i in range(2,num_features+1):
        if np.where(label==i)[0].shape[0] > 250:
            mymcmask[np.where(label==i)] = -1

    # set brain to 2, background to 1, ventricles to 0
    mymcmask[np.where(mymcmask==1)] = 2
    mymcmask[np.where(mymcmask==0)] = 1
    mymcmask[np.where(mymcmask==-1)] = 0

# add something here to do ventricle masking slice by slice. maybe in both coronal and sagittal planes
structure = [[1,1,1],[1,1,1],[1,1,1]]
for i in range(mymcmask.shape[1]):
    label, num_features = scipy.ndimage.measurements.label(np.squeeze(-1.0*(mymaskarraycurated[:,i,:]-1)),structure) # here 1 = background, 0 = brain, everything else = ventricles
    for ii in range(2,num_features+1):
	# check if the label touches the boundary of the image
	if np.max(np.where(label==ii)[0]) == label.shape[0]-1 or np.max(np.where(label==ii)[1]) == label.shape[1]-1 or np.min(np.where(label==ii)[0]) == 0 or np.min(np.where(label==ii)[1]) == 0:
	    continue

	if len(np.where(label==ii)[0]) > 8:
	    tempslice = np.squeeze(mymcmask[:,i,:])
	    tempslice[np.where(label==ii)] = 0
	    mymcmask[:,i,:] = tempslice

for i in range(mymcmask.shape[0]):
    label, num_features = scipy.ndimage.measurements.label(np.squeeze(-1.0*(mymaskarraycurated[i,:,:]-1)),structure) # here 1 = background, 0 = brain, everything else = ventricles
    for ii in range(2,num_features+1):
	# check if the label touches the boundary of the image
	if np.max(np.where(label==ii)[0]) == label.shape[0]-1 or np.max(np.where(label==ii)[1]) == label.shape[1]-1 or np.min(np.where(label==ii)[0]) == 0 or np.min(np.where(label==ii)[1]) == 0:
	    continue

	if len(np.where(label==ii)[0]) > 8:
	    tempslice = np.squeeze(mymcmask[i,:,:])
	    tempslice[np.where(label==ii)] = 0
	    mymcmask[i,:,:] = tempslice


# save for STS
mymcmaskimg = sitk.GetImageFromArray(mymcmask)
mymcmaskimg.SetDirection((1,0,0,0,1,0,0,0,1))
mymcmaskimg.SetOrigin((0,0,0))
mymcmaskimg.SetSpacing(origRefImg.GetSpacing())
#sitk.WriteImage(mymcmaskimg,outputdirectoryname + '/' + patientnumber + '_mymcmask.img')
if smoothMask == True:
    mymaskarraycuratedimg = sitk.GetImageFromArray(mymaskarraycurated.astype(np.float32))
    mymaskarraycuratedimg.SetDirection((1,0,0,0,1,0,0,0,1))
    mymaskarraycuratedimg.SetOrigin((0,0,0))
    mymaskarraycuratedimg.SetSpacing(origRefImg.GetSpacing())
    ndreg3D.imgWrite(sitk.SmoothingRecursiveGaussian(mymaskarraycuratedimg,0.04),outputfilename)
else:
    mymaskarraycuratedimg = sitk.GetImageFromArray(mymaskarraycurated.astype(np.int8))
    mymaskarraycuratedimg.SetDirection((1,0,0,0,1,0,0,0,1))
    mymaskarraycuratedimg.SetOrigin((0,0,0))
    mymaskarraycuratedimg.SetSpacing(origRefImg.GetSpacing())
    ndreg3D.imgWrite(mymaskarraycuratedimg,outputfilename)




#mymaskarrayfilled = scipy.ndimage.morphology.binary_fill_holes(mymaskarray,np.ones((5,5,5)))
#mymaskarrayfilledimg = sitk.GetImageFromArray(mymaskarrayfilled.astype('int8'))
#mymaskarrayfilledimg.SetSpacing(target.GetSpacing())

#sitk.WriteImage(mymaskarrayfilledimg,outputfilename)

targetmasked = ndreg3D.imgMask(target,mymaskarraycuratedimg)
sitk.WriteImage(targetmasked,outputtargetfilename)
