# -*- coding: utf-8 -*-
"""
Spyder Editor

Bingxing Huo
Modified from Brian's code applySTSCompositeTransform_fluoro.py
"""

import SimpleITK as sitk
import numpy as np
import sys
import os
#import cv2
import time

wdir = '/sonas-hs/mitra/hpc/home/kram/StackAlignNew/'

start_time = time.time()

patientnumber = sys.argv[1]
patientnumber=patientnumber.upper()

inputdir=sys.argv[2]

# load the first transform file
#init
transform1matrix = sys.argv[3]
transform1file = sys.argv[4]
#crop
transform2matrix = sys.argv[5]
#sts
transform4matrix = sys.argv[6]
transform4file = sys.argv[7]

#outspacingx = float(sys.argv[9])
#outspacingy = float(sys.argv[10])

#outxsize = int(sys.argv[9])
#outysize = int(sys.argv[10])
# pre-calculated annotation stack
annostack=sitk.ReadImage(sys.argv[8])
regxsize=annostack.GetDepth()
regysize=annostack.GetWidth()


originalpixelsize = float(sys.argv[9])
tifpixelsize=originalpixelsize*64

outxsize=int(regxsize*.08/originalpixelsize)
outysize=int(regysize*.08/originalpixelsize)

tid0 = int(sys.argv[10])-1
tid1 = int(sys.argv[11])-1

outputdir = sys.argv[12]
if not os.path.exists(outputdir):
    os.mkdir(outputdir)
    
# open a temporary directory to store the expanded tif files
tempdir=outputdir + 'temptif/'
if not os.path.exists(tempdir):
    os.mkdir(tempdir)

# load the crop transform matrix
with open(transform2matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

cropmatrix = content[0].split(',')

# load the first transform file
with open(transform1matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

with open(transform1file) as f:
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
with open(transform4matrix) as f:
    content = f.readlines()

content = [x.strip() for x in content]

# load the non-matrix file because for some reason I forgot to save the center in the matrix file
with open(transform4file) as f:
    content2 = f.readlines()

content2line = content2[0].split(',')
rotcenter = content2line[7:9]



# split into list
mylist2 = [[0] * 8 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    mylist2[i][0:6] = myelements[0:6]
    mylist2[i][6:8] = rotcenter


# loop over all images
#registeredimagelist = [None]*int(mylist[-1:][0][0])
#for i in range(len(mylist)):
#    print(i)


for i in range(tid0,tid1+1):
    print('Processing ' + mylist_sorted[i][10] + ' ...')
    # generate crop matrix
    cropobj = sitk.TranslationTransform(2)
    #cropobj.SetMatrix([float(x) for x in cropmatrix[0:4]],tolerance=1e-5)
    #cropobj.SetOffset([float(x) for x in cropmatrix[4:6]])
    cropobj.SetOffset((float(cropmatrix[5]), float(cropmatrix[4])))
    #cropobj.SetCenter([float(x) for x in cropmatrix[6:8]])
    
    # generate first euler2d transform
    euler2dobj1 = sitk.Euler2DTransform()
    rotcenter1 = [float(mylist_sorted[i][7]),float(mylist_sorted[i][8])]
    euler2dobj1.SetCenter([x*tifpixelsize for x in rotcenter1]) # scale the center based on pixel size
    euler2dobj1.SetMatrix([float(x) for x in mylist_sorted[i][1:5]],tolerance=1e-5)
    mytheta = float(mylist_sorted[i][11])
    euler2dobj1.SetTranslation([float(x)*tifpixelsize for x in mylist_sorted[i][5:7]]) # scale translation on pixel size
    
    # generate second euler2d transform
    euler2dobj2 = sitk.Euler2DTransform()
    rotcenter2 = [float(mylist2[i][6]), float(mylist2[i][7])]
    euler2dobj2.SetCenter([x*0.08 for x in rotcenter2]) # scale the center based on pixel size
    euler2dobj2.SetMatrix([float(x) for x in mylist2[i][0:4]],tolerance=1e-5)
    mytheta2 = np.arccos(float(mylist2[i][0]))
    euler2dobj2.SetTranslation([float(x) for x in mylist2[i][4:6]])
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(cropobj)
    compositetransform.AddTransform(euler2dobj2)

    # fluorescent output
    # load the corresponding tif image from stackalign data
#    inSlice = sitk.ReadImage(mylist_sorted[i][9] + mylist_sorted[i][10] + '.tif',sitk.sitkFloat32)
#    inSlice.SetSpacing((originalpixelsize, originalpixelsize))
#    inSlice.SetOrigin((0,0))
#    inSlice.SetDirection((1,0,0,1))
    
#    # resample the image
#    outSlice = sitk.Resample(inSlice, (outxsize*2,outysize*2), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 255.0)
#    #registeredimagelist[int(mylist_sorted[i][0])-1] = outSlice
##    registeredimagelist[truenumberlist[i]-1] = outSlice
#    affine = sitk.AffineTransform(2)
#    identityDirection = (1,0,0,1)
#    outSlice.SetSpacing((tifpixelsize,tifpixelsize))
#    outSlice = sitk.SmoothingRecursiveGaussian(outSlice,0.01)
#    outSlice = sitk.Resample(outSlice, (outxsize,outysize), affine, sitk.sitkLinear, outSlice.GetOrigin(), (outspacingx,outspacingy), identityDirection, 0.0)
#    
#    # adjust 3D
#    dimension=2
#    zeroOrigin = [0]*dimension
#    outSliceNP=sitk.GetArrayFromImage(outSlice)
#    outSliceNP=-1*(outSliceNP-255)
##    outSliceNP= np.rot90(outSliceNP,axes=(1,2))
##    outSliceNP = np.rot90(outSliceNP)
##    outSliceNP = np.rot90(outSliceNP)
#    outSlice=sitk.GetImageFromArray(outSliceNP,sitk.sitkInt8)
#    outSlice.SetSpacing((tifpixelsize,tifpixelsize))
#    outSlice.SetDirection(identityDirection)
#    outSlice.SetOrigin(zeroOrigin)
#    
#    sitk.WriteImage(outSlice, outdir + '/' + patientnumber.lower() + 'F2N/tf' + '%04d' '.tif'%((mylist_sorted[i][0])))
#
#    # cell mask output
    try:
        # Use external kdu script to expand into tif
        if not os.path.exists(outputdir + mylist_sorted[i][10] + '.jp2') or os.stat(outputdir + mylist_sorted[i][10] + '.jp2').st_size==0:
            ret = os.system(wdir+'/Scripts/python/kduexp_marmoset.sh "%s" "%s" %s %s' % (inputdir, mylist_sorted[i][10], tempdir, "expanded"+ str(i) +".tif"))
            if ret != 0:
                break

            print "read"

            inSlice = sitk.ReadImage(tempdir + '/expanded'+ str(i) +'.tif')
            inSlice.SetSpacing((originalpixelsize, originalpixelsize))
            inSlice.SetOrigin((0,0))
            inSlice.SetDirection((1,0,0,1))
            
            print "transform"
    # resample the image 
            outSlice = sitk.Resample(inSlice, (outxsize*2,outysize*2), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 0.0)
            affine = sitk.AffineTransform(2)
            identityDirection = (1,0,0,1)
            outSlice.SetSpacing((originalpixelsize,originalpixelsize))
        #    outSlice = sitk.SmoothingRecursiveGaussian(outSlice,0.01)
            outSlice = sitk.Resample(outSlice, (outxsize,outysize), affine, sitk.sitkLinear, outSlice.GetOrigin(), outSlice.GetSpacing(), identityDirection, 0.0)
            print "writeout"
            sitk.WriteImage(outSlice, tempdir + '/transformed'+ str(i) +'.tif')
            os.remove(tempdir +'/expanded'+str(i) + '.tif')
            
            ret = os.system(wdir+'/Scripts/python/kducomp_marmoset.sh %s/transformed%d.tif %s "%s"' % (tempdir,i,outputdir,mylist_sorted[i][10]))
        
            if ret != 0:
                break

            os.remove(tempdir+'/transformed'+str(i)+'.tif')

        
#        print('Done.')
        print("--- %s seconds ---" % (time.time() - start_time))
#        
    except:
        print('Skipping ' + mylist_sorted[i][10] + '.jp2')
#        pass
        print "Unexpected error:", sys.exc_info()[0]
        raise

        