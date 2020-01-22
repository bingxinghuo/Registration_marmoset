import sys
sys.path.insert(0,'/sonas-hs/mitra/hpc/home/blee/code')
import SimpleITK as sitk
#import numpy as np
import os
import sys
#import cv2
#import parseSlideNumbers
import time

wdir = '/sonas-hs/mitra/hpc/home/kram/StackAlignNew/'

start_time = time.time()

patientnumber = sys.argv[1]
#init
transform1matrix = sys.argv[2]
transform1file = sys.argv[3]
#crop
transform2matrix = sys.argv[4]
#firstalign
transform3matrix = sys.argv[5]
#sts
transform4matrix = sys.argv[6]
transform4file = sys.argv[7]
#finalalign
transform5matrix = sys.argv[8]

originalpixelsize = 0.00092 
tifpixelsize=0.0058
outxsize = int(sys.argv[9])
outysize = int(sys.argv[10])

tid0 = int(sys.argv[11])-1
tid1 = int(sys.argv[12])-1

#inputdir = sys.argv[13]
outputdir = sys.argv[13]
# output directory
#outbase = '/sonas-hs/mitra/hpc/home/bhuo'
#outdir = outbase+'/'+patientnumber.lower()+'/' + patientnumber.lower() + 'nissl/'


# set original pixel size based on tifs from stack align dataset
#originalpixelsize = 0.00092  
# mm per pix (each pix is 64*0.46 um = 64*0.46/1000 mm)
#tifpixelsize = originalpixelsize *64    
# spacing
#outspacingx=0.08
#outspacingy=0.08


if not os.path.exists(outdir):
    os.mkdir(outdir)

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

# load the final rotation
with open(transform5matrix) as f:
    content4 = f.readlines()

content4 = [x.strip() for x in content4]
content4line = content4[0].split(',')

# load the first rotation
with open(transform3matrix) as f:
    content5 = f.readlines()

content5 = [x.strip() for x in content5]
content5line = content5[0].split(',')

# split into list
mylist2 = [[0] * 8 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    mylist2[i][0:6] = myelements[0:6]
    mylist2[i][6:8] = rotcenter

# set original pixel size based on tifs from stack align dataset
#originalpixelsize = 0.01472

# loop over all images
#registeredimagelist = [None]*int(mylist[-1:][0][0])
#registeredimagelist = [None]*int(truenumberlist[-1])
for i in range(tid0,tid1+1):
    print(mylist_sorted[i][10])
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
    
    # generate first global transform
    euler2dobj4 = sitk.Euler2DTransform()
    euler2dobj4.SetCenter((float(content5line[7]),float(content5line[6])))
    euler2dobj4.SetTranslation((float(content5line[5]),float(content5line[4])))
    euler2dobj4.SetMatrix((float(content5line[0]),-float(content5line[1]),-float(content5line[2]),float(content5line[3])),tolerance=1e-5)
    
    # generate second euler2d transform
    euler2dobj2 = sitk.Euler2DTransform()
    rotcenter2 = [float(mylist2[i][6]), float(mylist2[i][7])]
    euler2dobj2.SetCenter([x*0.08 for x in rotcenter2]) # scale the center based on pixel size
    euler2dobj2.SetMatrix([float(x) for x in mylist2[i][0:4]],tolerance=1e-5)
#    mytheta2 = np.arccos(float(mylist2[i][0]))
    euler2dobj2.SetTranslation([float(x) for x in mylist2[i][4:6]])
    
    # generate last euler2d transform
    euler2dobj3 = sitk.Euler2DTransform()
    euler2dobj3.SetCenter((float(content4line[7]),float(content4line[6])))
    euler2dobj3.SetTranslation((float(content4line[5]),float(content4line[4])))
    euler2dobj3.SetMatrix((float(content4line[0]),-float(content4line[1]),-float(content4line[2]),float(content4line[3])),tolerance=1e-5)
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(cropobj)
    compositetransform.AddTransform(euler2dobj4)
    compositetransform.AddTransform(euler2dobj2)
    compositetransform.AddTransform(euler2dobj3)


    try:
        # Use external kdu script to expand into tif
        if not os.path.exists(outputdir + mylist_sorted[i][10] + '.jp2') or os.stat(outputdir + mylist_sorted[i][10] + '.jp2').st_size==0:
            ret = os.system(wdir+'/Scripts/python/kduexp_marmoset.sh "%s" "%s" %s %s' % (inputdir, mylist_sorted[i][10], tempdir, "expanded"+ str(i) +".tif"))
            if ret != 0:
                break
    
            inSlice = sitk.ReadImage(tempdir + '/expanded'+ str(i) +'.tif')
            inSlice.SetSpacing((originalpixelsize, originalpixelsize))
            inSlice.SetOrigin((0,0))
            inSlice.SetDirection((1,0,0,1))
            
            # resample the image
            outSlice = sitk.Resample(inSlice, (outxsize*2,outysize*2), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 255.0)
            affine = sitk.AffineTransform(2)
            identityDirection = (1,0,0,1)
            outSlice.SetSpacing((originalpixelsize,originalpixelsize))
        #    outSlice = sitk.SmoothingRecursiveGaussian(outSlice,0.01)
            outSlice = sitk.Resample(outSlice, (outxsize,outysize), affine, sitk.sitkLinear, outSlice.GetOrigin(), outSlice.GetSpacing(), identityDirection, 255.0)
        #
            sitk.WriteImage(outSlice, tempdir + '/transformed'+ str(i) +'.tif')
            os.remove(tempdir +'/expanded'+str(i) + '.tif')
            
            ret = os.system(wdir+'/Scripts/python/kducomp_marmoset.sh %s/transformed%d.tif %s "%s"' % (tempdir,i,outputdir,mylist_sorted[i][10]))
            
            if ret != 0:
                break
            
            os.remove(tempdir+'/transformed'+str(i)+'.tif')

        print("--- %s seconds ---" % (time.time() - start_time))
        
    except:
        print('Skipping ' + mylist_sorted[i][10] + '.jp2')
        #        pass
        print "Unexpected error:", sys.exc_info()[0]
        raise



