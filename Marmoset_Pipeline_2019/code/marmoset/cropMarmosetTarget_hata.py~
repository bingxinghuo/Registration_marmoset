import SimpleITK as sitk
import histFunctions
import ndreg3D
import sys
sys.path.insert(0,'/sonas-hs/mitra/hpc/home/kram/Marmoset_Pipeline_2019/code/numpy')
import numpy as np

targetfilename = sys.argv[1]
#outputfilename = sys.argv[2]
outputslicefilename = sys.argv[2]
transformfilename = sys.argv[3]

img = sitk.ReadImage(targetfilename)
inflectionpoint = histFunctions.getInflectionPoint(img)
mymask = ndreg3D.imgMakeMask(img,threshold=inflectionpoint)

xmax = np.min((np.where(sitk.GetArrayFromImage(mymask)==1)[0].max()+15,img.GetSize()[2]))
xmin = np.max((np.where(sitk.GetArrayFromImage(mymask)==1)[0].min()-15,0))

ymax = np.min((np.where(sitk.GetArrayFromImage(mymask)==1)[2].max()+15,img.GetSize()[0]))
ymin = np.max((np.where(sitk.GetArrayFromImage(mymask)==1)[2].min()-15,0))

#outImg = img[ymin:ymax,:,xmin:xmax]

#sitk.WriteImage(outImg, outputfilename)

# transform slice by slice
registeredimagelist = [None]*img.GetSize()[1]
transtransform = sitk.TranslationTransform(2)
transtransform.SetOffset((float(ymin)*0.08, float(xmin)*0.08))

for i in range(img.GetSize()[1]):
    registeredimagelist[i] = sitk.Resample(img[:,i,:], (ymax-ymin+1,xmax-xmin+1), transtransform, sitk.sitkLinear,(0,0), (0.08,0.08), (1,0,0,1), 0.0)

dimension = 3
affine = sitk.AffineTransform(3)
identityAffine = list(affine.GetParameters())
identityDirection = list(affine.GetMatrix())
zeroOrigin = [0]*dimension
registeredImg = sitk.JoinSeries(registeredimagelist)
#registeredImgNP = sitk.GetArrayFromImage(registeredImg)
#registeredImgNP = -1*(registeredImgNP-255)
#registeredImgNP = np.rot90(registeredImgNP,axes=(1,2))
#registeredImgNP = np.rot90(registeredImgNP)
#registeredImg = sitk.GetImageFromArray(registeredImgNP,sitk.sitkInt8)
registeredImg = sitk.PermuteAxes(registeredImg,(0,2,1))
registeredImg.SetSpacing((0.08,0.08,0.08))
registeredImg.SetDirection(identityDirection)
registeredImg.SetOrigin(zeroOrigin)

sitk.WriteImage(registeredImg,outputslicefilename)


# write transforms
myxformfile = open(transformfilename,'w')

myxformfile.write("%f,%f,%f,%f,%f,%f,%f,%f\n" % (1,0,0,1,transtransform.GetOffset()[0],transtransform.GetOffset()[1],0,0))
myxformfile.close()
