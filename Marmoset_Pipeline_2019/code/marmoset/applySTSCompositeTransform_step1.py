import SimpleITK as sitk
import numpy as np
import sys

# load the first transform file
patientnumber = sys.argv[1]
transformfile1matrix = sys.argv[2]
transformfile1 = sys.argv[3]
transformfile2matrix = sys.argv[4]
#transformfile2 = sys.argv[5]
outputdirectoryname = sys.argv[5]

#with open('/sonas-hs/mitra/hpc/home/blee/data/stackalign/' + patientnumber + 'N/' + patientnumber + '_N_XForm_matrix.txt') as f:
with open(transformfile1matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

#with open('/sonas-hs/mitra/hpc/home/blee/data/stackalign/' + patientnumber + 'N/' + patientnumber + '_N_XForm.txt') as f:
with open(transformfile1) as f:
    content3 = f.readlines()

content3 = [x.strip() for x in content3]

# sort the first transform file
mylist = [[0] * 12 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    myelements3 = content3[i].split(',')
    mylist[i][1:9] = myelements[2:10]
    mylist[i][0] = int(myelements[0][-4:])
    mylist[i][9] = myelements[1]
    mylist[i][10] = myelements[0]
    mylist[i][11] = myelements3[8]

mylist_sorted = sorted(mylist,key=lambda x: x[0])

# load the second transform file
#with open('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/transforms/' + patientnumber + '_XForm_matrix.txt') as f:
#with open(transformfile2matrix) as f:
#    content = f.readlines()
#
#content = [x.strip() for x in content]

# load the non-matrix file because for some reason I forgot to save the center in the matrix file
#with open('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/transforms/' + patientnumber + '_XForm.txt') as f:
#with open(transformfile2) as f:
#    content2 = f.readlines()
#
#content2line = content2[0].split(',')
#rotcenter = content2line[7:9]

# load the final rotation
#with open('/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/transforms/' + patientnumber + '_XForm_finalrotation_matrix.txt') as f:
with open(transformfile2matrix) as f:
    content4 = f.readlines()

content4 = [x.strip() for x in content4]
content4line = content4[0].split(',')


# split into list
#mylist2 = [[0] * 8 for i in range(len(content))]
#for i in range(len(content)):
#    myelements = content[i].split(',')
#    mylist2[i][0:6] = myelements[0:6]
#    mylist2[i][6:8] = rotcenter

# set original pixel size based on tifs from stack align dataset
originalpixelsize = 0.0588

# loop over all images
registeredimagelist = [None]*int(mylist[-1:][0][0])
for i in range(len(mylist)):
    print(i)
    # generate first euler2d transform
    euler2dobj1 = sitk.Euler2DTransform()
    rotcenter1 = [float(mylist_sorted[i][7]),float(mylist_sorted[i][8])]
    euler2dobj1.SetCenter([x*originalpixelsize for x in rotcenter1]) # scale the center based on pixel size
    euler2dobj1.SetMatrix([float(x) for x in mylist_sorted[i][1:5]],tolerance=1e-5)
    mytheta = float(mylist_sorted[i][11])
    euler2dobj1.SetTranslation([float(x)*originalpixelsize for x in mylist_sorted[i][5:7]]) # scale translation on pixel size
    
    # generate second euler2d transform
    #euler2dobj2 = sitk.Euler2DTransform()
    #rotcenter2 = [float(mylist2[i][6]), float(mylist2[i][7])]
    #euler2dobj2.SetCenter([x*0.04 for x in rotcenter2]) # scale the center based on pixel size
    #euler2dobj2.SetMatrix([float(x) for x in mylist2[i][0:4]],tolerance=1e-5)
    #mytheta2 = np.arccos(float(mylist2[i][0]))
    #euler2dobj2.SetTranslation([float(x) for x in mylist2[i][4:6]])
    
    # generate last euler2d transform
    euler2dobj3 = sitk.Euler2DTransform()
    euler2dobj3.SetCenter((float(content4line[7]),float(content4line[6])))
    euler2dobj3.SetTranslation((float(content4line[5]),float(content4line[4])))
    euler2dobj3.SetMatrix((float(content4line[0]),-float(content4line[1]),-float(content4line[2]),float(content4line[3])),tolerance=1e-5)
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(euler2dobj3)
    #compositetransform.AddTransform(euler2dobj3)

    # load the corresponding tif image from stackalign data
    inSlice = sitk.ReadImage(mylist_sorted[i][9] + mylist_sorted[i][10] + '.tif',sitk.sitkFloat32)
    inSlice.SetSpacing((originalpixelsize, originalpixelsize))
    inSlice.SetOrigin((0,0))
    inSlice.SetDirection((1,0,0,1))
    
    # resample the image
    outSlice = sitk.Resample(inSlice, (750,563), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 255.0)
    registeredimagelist[int(mylist_sorted[i][0])-1] = outSlice
    


# join series on the registered image list
testzeronp = np.ones((563,750))*255
testzero = sitk.GetImageFromArray(testzeronp.astype('int32'))
#testzero = sitk.Image(750,563,0,sitk.sitkInt32)
testzero.SetSpacing((0.0588,0.0588))
noneind = [i for i, x in enumerate(registeredimagelist) if x == None]
for i in noneind:
    registeredimagelist[i] = sitk.Image(testzero)

affine = sitk.AffineTransform(2)
identityDirection = (1,0,0,1)
registeredimagelist40 = [None]*len(registeredimagelist)
for i in range(len(registeredimagelist)):
    tempslice = sitk.Image(registeredimagelist[i])
    tempslice.SetSpacing((0.0588,0.0588))
    tempslice = sitk.SmoothingRecursiveGaussian(tempslice,0.02)
    tempslice = sitk.Resample(tempslice, tuple([int(np.round(x/(0.08/0.0588))) for x in tempslice.GetSize()]), affine, sitk.sitkLinear, tempslice.GetOrigin(), (0.08,0.08), identityDirection, 0.0)
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

# also generate 100um version
registeredImg100 = sitk.Resample(sitk.SmoothingRecursiveGaussian(registeredImg,0.025), tuple([int(np.round(x/(0.1/0.08))) for x in registeredImg.GetSize()]), affine, sitk.sitkLinear, registeredImg.GetOrigin(), (0.1, 0.1, 0.1), identityDirection, 0.0)
sitk.WriteImage(registeredImg100, outputdirectoryname + '/' + patientnumber + '_100_full_firstalign.img')
#sitk.WriteImage(registeredImg100, '/sonas-hs/mitra/hpc/home/blee/data/target_images/' + patientnumber + '/' + patientnumber + '_100_full.img')


#outputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output'
sitk.WriteImage(registeredImg, outputdirectoryname + '/' + patientnumber + '_80_full_firstalign.img')


