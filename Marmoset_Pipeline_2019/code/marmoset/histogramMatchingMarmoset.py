import SimpleITK as sitk
import sys

targetfile = sys.argv[1]
atlasfile = sys.argv[2]
outputatlasfile = sys.argv[3]

refImg = sitk.ReadImage(targetfile,sitk.sitkFloat32)
refImg.SetDirection((1,0,0,0,1,0,0,0,1))
refImg.SetOrigin((0,0,0))

inImg = sitk.ReadImage(atlasfile,sitk.sitkFloat32)
inImg.SetDirection((1,0,0,0,1,0,0,0,1))
inImg.SetOrigin((0,0,0))

numBins = 64
numMatchPoints = 8
outImg = sitk.HistogramMatchingImageFilter().Execute(inImg, refImg, numBins, numMatchPoints, True)

sitk.WriteImage(outImg,outputatlasfile)

