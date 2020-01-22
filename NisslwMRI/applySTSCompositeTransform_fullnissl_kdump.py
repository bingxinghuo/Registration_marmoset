#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 16 11:47:40 2018

@author: bingxinghuo
Modified based on Brian's code applySTSCompositeTransform_nissl.py
"""
import sys
import SimpleITK as sitk
import os
#import cv2
import time
import multiprocessing as mp

# perform transformation for individual image
def mp_transformer(params): 
    mylist_sorted=params[0]
    cropmatrix=params[1]
    mylist2=params[2]
    tifpixelsize=params[3]
    originalpixelsize=params[4]
    outxsize=params[5]
    outysize=params[6]
    inputdir=params[7]
    outputdir=params[8]
    # open a temporary directory to store the expanded tif files
    tempdir=outputdir + 'temptif/'
    if not os.path.exists(tempdir):
        os.mkdir(tempdir)
    wdir = '/sonas-hs/mitra/hpc/home/bhuo/scripts/kducode'
    
    print('Processing ' + mylist_sorted[10] + ' ...')
    # generate first euler2d transform
    euler2dobj1 = sitk.Euler2DTransform()
    rotcenter1 = [float(mylist_sorted[7]),float(mylist_sorted[8])]
    euler2dobj1.SetCenter([x*tifpixelsize for x in rotcenter1]) # scale the center based on pixel size
    euler2dobj1.SetMatrix([float(x) for x in mylist_sorted[1:5]],tolerance=1e-5)
    euler2dobj1.SetTranslation([float(x)*tifpixelsize for x in mylist_sorted[5:7]]) # scale translation on pixel size
    
    # generate crop matrix
    cropobj = sitk.TranslationTransform(2)
    cropobj.SetOffset((float(cropmatrix[5]), float(cropmatrix[4])))
    
    # generate second euler2d transform
    euler2dobj2 = sitk.Euler2DTransform()
    rotcenter2 = [float(mylist2[6]), float(mylist2[7])]
    euler2dobj2.SetCenter([x for x in rotcenter2])
    euler2dobj2.SetMatrix([float(x) for x in mylist2[0:4]],tolerance=1e-5)
    euler2dobj2.SetTranslation([float(x) for x in mylist2[4:6]])
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(cropobj)
    compositetransform.AddTransform(euler2dobj2)

    try:
        # Use external kdu script to expand into tif
        if not os.path.exists(outputdir + mylist_sorted[10] + '.jp2') or os.stat(outputdir + mylist_sorted[10] + '.jp2').st_size==0:
            os.system(wdir+'/kduexp_marmoset.sh "%s" "%s" %s %s' % (inputdir, mylist_sorted[10], tempdir, "expanded"+ mylist_sorted[10] +".tif"))
            
            inSlice = sitk.ReadImage(tempdir + '/expanded'+ mylist_sorted[10] +'.tif')
            inSlice.SetSpacing((originalpixelsize, originalpixelsize))
            inSlice.SetOrigin((0,0))
            inSlice.SetDirection((1,0,0,1))
            # load the corresponding tif image from stackalign data
            #        inSlice = sitk.ReadImage(mylist_sorted[i][9] + mylist_sorted[i][10] + '.tif',sitk.sitkFloat32)
            #        inSlice.SetSpacing((originalpixelsize, originalpixelsize))
            #        inSlice.SetOrigin((0,0))
            #        inSlice.SetDirection((1,0,0,1))
#            print "transform"
            # resample the image
            outSlice = sitk.Resample(inSlice, (outxsize*2,outysize*2), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), 255.0)
            affine = sitk.AffineTransform(2)
            identityDirection = (1,0,0,1)
            outSlice.SetSpacing((originalpixelsize,originalpixelsize))
            #    outSlice = sitk.SmoothingRecursiveGaussian(outSlice,0.01)
            outSlice = sitk.Resample(outSlice, (outxsize,outysize), affine, sitk.sitkLinear, outSlice.GetOrigin(), outSlice.GetSpacing(), identityDirection, 255.0)
#            print "writeout"
            sitk.WriteImage(outSlice, tempdir + '/transformed'+ mylist_sorted[10] +'.tif')
            os.remove(tempdir +'/expanded'+mylist_sorted[10] + '.tif')
            
            os.system(wdir+'/kducomp_marmoset.sh %s/transformed%s.tif %s "%s"' % (tempdir,mylist_sorted[10],outputdir,mylist_sorted[10]))
            
            os.remove(tempdir+'/transformed'+mylist_sorted[10]+'.tif')

        print("--- %s seconds ---" % (time.time() - start_time))
    except:
        print('Skipping ' + mylist_sorted[10] + '.jp2')
#        pass
        print("Unexpected error:", sys.exc_info()[0])
        raise

# multiple processing of all images        
def mp_handler(allparams):
    p=mp.Pool(10)
    # loop over all image
    p.map(mp_transformer,allparams)


if __name__ == '__main__':
    start_time = time.time()
    
    patientnumber = sys.argv[1]
    inputdir=sys.argv[2]
    # stack alignment
    transform1matrix = sys.argv[3]
    #transform1file = sys.argv[3]
    # crop
    transform2matrix = sys.argv[4]
    # mri alignment
    transform3matrix = sys.argv[5]
    #transform3file = sys.argv[5]
    
    # pre-calculated annotation stack
    annostack=sitk.ReadImage(sys.argv[6])
    regxsize=annostack.GetDepth()
    regysize=annostack.GetWidth()

    originalpixelsize = float(sys.argv[7])
    tifpixelsize=0.00046*2*64
    
    outxsize=int(regxsize*.08/originalpixelsize)
    outysize=int(regysize*.08/originalpixelsize)
#    tid0 = int(sys.argv[9])-1
#    tid1 = int(sys.argv[10])-1
    outputdir = sys.argv[8]
    if not os.path.exists(outputdir):
        os.mkdir(outputdir)
    
    with open(transform1matrix) as f:
        content = f.readlines()
    
    content = [x.strip() for x in content]
    
    # sort the first transform file
    mylist = [[0] * 12 for i in range(len(content))]
    for i in range(len(content)):
        myelements = content[i].split(',')
        mylist[i][1:9] = myelements[2:10]
        mylist[i][0] = int(myelements[0][-4:])
        mylist[i][9] = myelements[1]
        mylist[i][10] = myelements[0]
        
    
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
    
#    allparams=[[] for i in range(tid0,tid1+1)]
    allparams=[[] for i in range(len(mylist))]
    tid0=0
    for i in range(len(mylist)):
#    for i in range(tid1+1-tid0):
        allparams[i]=[[] for x in range(9)]
        
        allparams[i][0]=mylist_sorted[i+tid0]
        allparams[i][1]=cropmatrix
        allparams[i][2]=mylist2[i+tid0]
        allparams[i][3]=tifpixelsize
        allparams[i][4]=originalpixelsize
        allparams[i][5]=outxsize
        allparams[i][6]=outysize
        allparams[i][7]=inputdir
        allparams[i][8]=outputdir
        
    mp_handler(allparams)
