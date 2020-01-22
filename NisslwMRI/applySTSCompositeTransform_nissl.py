import sys
sys.path.insert(0,'/sonas-hs/mitra/hpc/home/blee/code')
import SimpleITK as sitk
import numpy as np
import parseSlideNumbers

patientnumber = sys.argv[1]
# stack alignment
transform1matrix = sys.argv[2]
#transform1file = sys.argv[3]
# crop
transform2matrix = sys.argv[3]
# mri alignment
transform3matrix = sys.argv[4]
#transform3file = sys.argv[5]
originalpixelsize = float(sys.argv[5])
outxsize = int(sys.argv[6])
outysize = int(sys.argv[7])
outputfilename = sys.argv[8]
singlestartind = int(sys.argv[9])
singleendind = int(sys.argv[10])
listfilename = sys.argv[11]

(directorynamelist, filenamelist, truenumberlist) = parseSlideNumbers.parse(listfilename, singlestartind, singleendind, patientnumber)

with open(transform1matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

# sort the first transform file
mylist = [[0] * 12 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    #myelements3 = content3[i].split(',')
    mylist[i][1:9] = myelements[2:10]
    mylist[i][0] = int(myelements[0][-4:])
    mylist[i][9] = myelements[1]
    mylist[i][10] = myelements[0]
    #mylist[i][11] = myelements3[8]

mylist_sorted = sorted(mylist,key=lambda x: x[0])

# load the crop transform matrix
with open(transform2matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

cropmatrix = content[0].split(',')


# load the second transform file
with open(transform3matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

# split into list
content2line = content[0].split(',')
rotcenter = content2line[6:8]
mylist2 = [[0] * 8 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    mylist2[i][0:6] = myelements[0:6]
    mylist2[i][6:8] = rotcenter

# set original pixel size based on tifs from stack align dataset
#originalpixelsize = 0.0588

# loop over all images
registeredimagelist = [None]*int(truenumberlist[-1])
for i in range(len(mylist)):
    print(i)
    # generate first euler2d transform
    euler2dobj1 = sitk.Euler2DTransform()
    rotcenter1 = [float(mylist_sorted[i][7]),float(mylist_sorted[i][8])]
    euler2dobj1.SetCenter([x*originalpixelsize for x in rotcenter1]) # scale the center based on pixel size
    euler2dobj1.SetMatrix([float(x) for x in mylist_sorted[i][1:5]],tolerance=1e-5)
    #mytheta = float(mylist_sorted[i][11])
    euler2dobj1.SetTranslation([float(x)*originalpixelsize for x in mylist_sorted[i][5:7]]) # scale translation on pixel size
    
    # generate crop matrix
    cropobj = sitk.TranslationTransform(2)
    #cropobj.SetMatrix([float(x) for x in cropmatrix[0:4]],tolerance=1e-5)
    #cropobj.SetOffset([float(x) for x in cropmatrix[4:6]])
    cropobj.SetOffset((float(cropmatrix[5]), float(cropmatrix[4])))
    #cropobj.SetCenter([float(x) for x in cropmatrix[6:8]])
    
    # generate second euler2d transform
    euler2dobj2 = sitk.Euler2DTransform()
    rotcenter2 = [float(mylist2[i][6]), float(mylist2[i][7])]
    euler2dobj2.SetCenter([x for x in rotcenter2])
    euler2dobj2.SetMatrix([float(x) for x in mylist2[i][0:4]],tolerance=1e-5)
    #mytheta2 = np.arccos(float(mylist2[i][0]))
    euler2dobj2.SetTranslation([float(x) for x in mylist2[i][4:6]])
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(cropobj)
    compositetransform.AddTransform(euler2dobj2)

    # load the corresponding tif image from stackalign data
    inSlice = sitk.ReadImage(mylist_sorted[i][9] + mylist_sorted[i][10] + '.tif',sitk.sitkFloat32)
    inSlice.SetSpacing((originalpixelsize, originalpixelsize))
    inSlice.SetOrigin((0,0))
    inSlice.SetDirection((1,0,0,1))
    
    # resample the image
    outSlice = sitk.Resample(inSlice, tuple((outxsize*2,outysize*2)), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 255.0)
    registeredimagelist[truenumberlist[i]-1] = outSlice
    


# join series on the registered image list
#testzero = sitk.Image(750,563,0,sitk.sitkInt32)
testzeronp = np.ones((outysize*2,outxsize*2))*255
testzero = sitk.GetImageFromArray(testzeronp.astype('int32'))
testzero.SetSpacing((originalpixelsize,originalpixelsize))
noneind = [i for i, x in enumerate(registeredimagelist) if x == None]
for i in noneind:
    registeredimagelist[i] = sitk.Image(testzero)

affine = sitk.AffineTransform(2)
identityDirection = (1,0,0,1)
registeredimagelist40 = [None]*len(registeredimagelist)
for i in range(len(registeredimagelist)):
    tempslice = sitk.Image(registeredimagelist[i])
    tempslice.SetSpacing((originalpixelsize, originalpixelsize))
    tempslice = sitk.SmoothingRecursiveGaussian(tempslice,0.01)
    #tempslice = sitk.Resample(tempslice, tuple([int(np.round(x/(0.08/originalpixelsize))) for x in tempslice.GetSize()]), affine, sitk.sitkLinear, tempslice.GetOrigin(), (0.08,0.08), identityDirection, 0.0)
    tempslice = sitk.Resample(tempslice,(outxsize,outysize), affine, sitk.sitkLinear, tempslice.GetOrigin(), (0.08,0.08), identityDirection, 0.0)
    registeredimagelist40[i] = tempslice


dimension = 3
affine = sitk.AffineTransform(3)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
registeredImg = sitk.JoinSeries(registeredimagelist40)
registeredImgNP = sitk.GetArrayFromImage(registeredImg)
registeredImgNP = -1*(registeredImgNP-255)
registeredImgNP = np.rot90(registeredImgNP,axes=(1,2))
registeredImgNP = np.rot90(registeredImgNP)
registeredImg = sitk.GetImageFromArray(registeredImgNP,sitk.sitkInt8)
registeredImg.SetSpacing((0.08,0.08,0.08))
registeredImg.SetDirection(identityDirection)
registeredImg.SetOrigin(zeroOrigin)

sitk.WriteImage(registeredImg, outputfilename)

