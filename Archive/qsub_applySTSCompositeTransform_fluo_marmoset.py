import SimpleITK as sitk
import numpy as np
import sys
import os

# load the first transform file
patientnumber = sys.argv[1]
stype = sys.argv[2]
tid = int(sys.argv[3])-1


wdir = '/sonas-hs/mitra/hpc/home/kram/StackAlignNew/'
workingdir = '/sonas-hs/mitra/hpc/home/blee/'
outbase = '/sonas-hs/mitra/hpc/home/kram/mitra2/PORTALJP2/'
outdir = outbase+'/'+patientnumber+'/'
tempbase = wdir+'/Scripts/python/forApplyTform/'
tempdir = tempbase+'/'+patientnumber+stype+'/'

if not os.path.exists(outdir):
    os.mkdir(outdir)
if not os.path.exists(tempdir):
    os.mkdir(tempdir)

with open(workingdir+'/data/stackalign/' + patientnumber + stype + '_maskimg/' + patientnumber + '_' + stype + '_XForm_matrix.txt') as f:
    content = f.readlines()

content = [x.strip() for x in content]

if tid > len(content):
    sys.exit(0) # no work


PIXVAL=0.0
if stype=="IHC":
    PIXVAL=255.0

with open(workingdir+'/data/stackalign/' + patientnumber + stype + '_maskimg/' + patientnumber + '_' + stype + '_XForm.txt') as f:
    content3 = f.readlines()

content3 = [x.strip() for x in content3]


with open(workingdir+'/data/stackalign/' + patientnumber + stype + '_maskimg/' + patientnumber + '_' + stype + '_XForm_crop_matrix.txt') as f:
    contenttrans = f.readlines()

contenttrans = [x.strip() for x in contenttrans] # should have only one line
contenttransline = contenttrans[0].split(',') 
croptranslation = contenttransline[4:6]

# sort the first transform file
mylist = [[0] * 12 for i in range(len(content))]
for i in range(len(content)):
    myelements = content[i].split(',')
    myelements3 = content3[i].split(',')
    mylist[i][1:9] = myelements[2:10]
    mylist[i][0] = int(myelements[0][-4:]) # secno
    mylist[i][9] = myelements[1]
    mylist[i][10] = myelements[0]
    mylist[i][11] = myelements3[8]

mylist_sorted = sorted(mylist,key=lambda x: x[0])

# load the second transform file
#FIXME: not used fluorodir
fluorodir = workingdir+'/data3/registration/' + patientnumber + '/fluoro/'+patientnumber+'_AAV_registered_rigidtrans/'

with open(workingdir+'/data/registration/' + patientnumber + '/fluoro/fluoro_transforms/' + patientnumber + '_fluoro_XForm_matrix.txt') as f:
    content4 = f.readlines()

content4 = [x.strip() for x in content4]
#content = [x.strip() for x in content]

# load the non-matrix file because for some reason I forgot to save the center in the matrix file
with open(workingdir+'/data/registration/' + patientnumber + '/fluoro/fluoro_transforms/' + patientnumber + '_fluoro_XForm.txt') as f:
    content2 = f.readlines()

content2line = content2[0].split(',')
rotcenter = content2line[7:9]

# load the final rotation
#with open(workingdir+'/data3/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output/transforms/' + patientnumber + '_XForm_finalrotation_matrix.txt') as f:
#    content4 = f.readlines()

#content4 = [x.strip() for x in content4]
#content4line = content4[0].split(',')

#XXX: not present for marmoset
# load the first rotation
#with open(workingdir+'/data3/registration/' + patientnumber + '/fluoro/' + patientnumber + '_XForm_firstrotation_matrix.txt') as f:
#    content5 = f.readlines()

#content5 = [x.strip() for x in content5]
#content5line = content5[0].split(',')


# split into list
mylist2 = [[0] * 8 for i in range(len(content4))]
for i in range(len(content4)):
    myelements = content4[i].split(',')
    mylist2[i][0:6] = myelements[0:6]
    mylist2[i][6:8] = rotcenter

# set original pixel size based on tifs from stack align dataset
originalpixelsize = 0.00092  
# mm per pix (each pix is 64*0.46 um = 64*0.46/1000 mm)
tifpixelsize = 0.05888 

# loop over all images
registeredimagelist = [None]*int(mylist[-1:][0][0])
#for i in range(len(mylist)):
#    print(i)

transtransform = sitk.TranslationTransform(2)
#transtransform.SetOffset([float(x)*0.08 for x in croptranslation])
transtransform.SetOffset((float(croptranslation[1]),float(croptranslation[0])))

for i in range(tid,tid+1):
    print(i)
    # generate first euler2d transform
    euler2dobj1 = sitk.Euler2DTransform()
    rotcenter1 = [float(mylist_sorted[i][7]),float(mylist_sorted[i][8])]
    euler2dobj1.SetCenter([x*tifpixelsize for x in rotcenter1]) # scale the center based on pixel size
    euler2dobj1.SetMatrix([float(x) for x in mylist_sorted[i][1:5]],tolerance=1e-5)
    mytheta = float(mylist_sorted[i][11])
    trans = [float(x)*tifpixelsize for x in mylist_sorted[i][5:7]] # change from pixel to mm
    # XXX: removed for debugging
    #trans[0] = trans[0]+float(croptranslation[0]) # add in mm
    #trans[1] = trans[1]+float(croptranslation[1])
    euler2dobj1.SetTranslation(trans)# scale translation on pixel size

    #XXX: Not for marmoset
    # generate first global transform
    #euler2dobj4 = sitk.Euler2DTransform()
    #euler2dobj4.SetCenter((float(content5line[7]),float(content5line[6])))
    #euler2dobj4.SetTranslation((float(content5line[5]),float(content5line[4])))
    #euler2dobj4.SetMatrix((float(content5line[0]),-float(content5line[1]),-float(content5line[2]),float(content5line[3])),tolerance=1e-5)

    # global translation transform (special for marmoset)


    #XXX: Older method
    #euler2dobj2 = sitk.Euler2DTransform()
    #euler2dobj2.SetMatrix(np.ndarray.tolist(np.ndarray.flatten(fluoroRinv[0:2,0:2].reshape((1,4)))))
    #euler2dobj2.SetTranslation(np.ndarray.tolist(np.ndarray.flatten(fluoroRinv[0:2,2].reshape((1,2)))))

   
    # generate second euler2d transform
    euler2dobj2 = sitk.Euler2DTransform()
    rotcenter2 = [float(mylist2[i][6]), float(mylist2[i][7])]
    euler2dobj2.SetCenter([x*0.08 for x in rotcenter2]) # scale the center based on pixel size
    euler2dobj2.SetMatrix([float(x) for x in mylist2[i][0:4]],tolerance=1e-5)
    mytheta2 = np.arccos(float(mylist2[i][0]))
    euler2dobj2.SetTranslation([float(x) for x in mylist2[i][4:6]])
    
    # generate last euler2d transform
    #euler2dobj3 = sitk.Euler2DTransform()
    #euler2dobj3.SetCenter((float(content4line[7]),float(content4line[6])))
    #euler2dobj3.SetTranslation((float(content4line[5]),float(content4line[4])))
    #euler2dobj3.SetMatrix((float(content4line[0]),-float(content4line[1]),-float(content4line[2]),float(content4line[3])),tolerance=1e-5)
    
    # combine transforms
    compositetransform = sitk.Transform(2,sitk.sitkComposite)
    compositetransform.AddTransform(euler2dobj1)
    compositetransform.AddTransform(transtransform) # XXX removed for debugging
    #compositetransform.AddTransform(euler2dobj4) #XXX Not for marmoset
    compositetransform.AddTransform(euler2dobj2)
    #compositetransform.AddTransform(euler2dobj3)


    inSlice = sitk.ReadImage(mylist_sorted[i][9] + mylist_sorted[i][10] + '.tif')
    inSlice.SetSpacing((tifpixelsize, tifpixelsize))
    inSlice.SetOrigin((0,0))
    inSlice.SetDirection((1,0,0,1))

    # resample the image
    outSlice = sitk.Resample(inSlice, (500,375), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), PIXVAL)
    #secno = mylist_sorted[i][0]
    registeredimagelist[int(mylist_sorted[i][0])-1] = outSlice
    sitk.WriteImage(outSlice, outdir + '/07' + '%04d' '.tif'%((mylist_sorted[i][0])))
    #sitk.WriteImage(inSlice, outdir + '/' + 'input%04d' '.tif'%((mylist_sorted[i][0])))

    continue # XXX don't run the below lines

    # load the corresponding tif image from stackalign data
    call_imgdir=mylist_sorted[i][9]+'/../JP2/'
    call_imgfile=mylist_sorted[i][10]
    call_outdir=tempdir
    call_outname="expanded"+ str(i) +".tif"

    if not os.path.exists(outdir+'/'+call_imgfile+ '.jp2') or os.stat(outdir+'/'+call_imgfile+'.jp2').st_size==0:
        ret = os.system(wdir+'/Scripts/python/kduexp_marmoset.sh "%s" "%s" %s %s' % (call_imgdir, call_imgfile, call_outdir, call_outname))
        if ret != 0:
            break

        print "read"

        inSlice = sitk.ReadImage(tempdir + '/expanded'+ str(i) +'.tif')
        inSlice.SetSpacing((originalpixelsize, originalpixelsize))
        inSlice.SetOrigin((0,0))
        inSlice.SetDirection((1,0,0,1))

        print "transform"
    
        # resample the image
        outSlice = sitk.Resample(inSlice, (48000,36032), compositetransform, sitk.sitkLinear, inSlice.GetOrigin(), inSlice.GetSpacing(), (1,0,0,1), PIXVAL)
        #secno = mylist_sorted[i][0]
        #registeredimagelist[int(mylist_sorted[i][0])-1] = outSlice

        print "writeout"

        sitk.WriteImage(outSlice, tempdir + '/transformed'+ str(i) +'.tif')
        os.unlink(tempdir +'/expanded'+str(i) + '.tif')

        ret = os.system(wdir+'/Scripts/python/kducomp_marmoset.sh %s/transformed%d.tif %s "%s"' % (tempdir,i,outdir,call_imgfile))
        
        if ret != 0:
            break

        os.unlink(tempdir+'/transformed'+str(i)+'.tif')
        
        if stype=="IHC":

            ret = os.system(wdir+'/Scripts/python/kduexp_jpg.sh "%s" "%s"' % (outdir,call_imgfile))
            if ret != 0:
                break
        else:
            ret = os.system(wdir+'/Scripts/python/kduexp_jpg_12bit.sh "%s" "%s"' % (outdir,call_imgfile))
            if ret != 0:
                break

    
    

"""
# join series on the registered image list
testzero = sitk.Image(750,563,0,sitk.sitkInt32)
testzero.SetSpacing((0.05888,0.05888))
noneind = [i for i, x in enumerate(registeredimagelist) if x == None]
for i in noneind:
    registeredimagelist[i] = sitk.Image(testzero)

affine = sitk.AffineTransform(2)
identityDirection = (1,0,0,1)
registeredimagelist40 = [None]*len(registeredimagelist)
for i in range(len(registeredimagelist)):
    tempslice = sitk.Image(registeredimagelist[i])
    tempslice.SetSpacing((0.05888,0.05888))
    tempslice = sitk.SmoothingRecursiveGaussian(tempslice,0.01)
    tempslice = sitk.Resample(tempslice, tuple([int(np.round(x/(0.08/0.05888))) for x in tempslice.GetSize()]), affine, sitk.sitkLinear, tempslice.GetOrigin(), (0.08,0.08), identityDirection, 0.0)
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

#outputdirectoryname = workingdir+'/data3/registration/' + patientnumber + '/' + patientnumber + '_STSpipeline_output'
#sitk.WriteImage(registeredImg, outputdirectoryname + '/' + patientnumber + '_80_full_fromraw.img')
sitk.WriteImage(registeredImg, outdir + '/' + patientnumber + '_80_full_fromraw.img')
"""
