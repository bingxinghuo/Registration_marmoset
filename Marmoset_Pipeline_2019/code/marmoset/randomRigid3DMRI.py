import SimpleITK as sitk
import sys
import numpy as np

mrifilename = sys.argv[1]
outimgfilename = sys.argv[2]
transformfilename = sys.argv[3]

mri = sitk.ReadImage(mrifilename)
mri.SetDirection((1,0,0,0,1,0,0,0,1))
mri.SetOrigin((0,0,0))

theta_x = np.deg2rad(np.random.randn())*3.0
theta_y = np.deg2rad(np.random.randn())*3.0
theta_z = np.deg2rad(np.random.randn())*3.0

a = np.random.randn()*3.0*mri.GetSpacing()[0]
b = np.random.randn()*3.0*mri.GetSpacing()[0]
c = np.random.randn()*3.0*mri.GetSpacing()[0]

R1 = np.zeros((3,3))
R2 = np.zeros((3,3))
R3 = np.zeros((3,3))

R1[0,0] = 1
R1[1,1] = np.cos(theta_x)
R1[1,2] = -np.sin(theta_x)
R1[2,1] = np.sin(theta_x)
R1[2,2] = np.cos(theta_x)

R2[1,1] = 1
R2[0,0] = np.cos(theta_y)
R2[0,2] = np.sin(theta_y)
R2[2,0] = -np.sin(theta_y)
R2[2,2] = np.cos(theta_y)

R3[2,2] = 1
R3[0,0] = np.cos(theta_z)
R3[0,1] = -np.sin(theta_z)
R3[1,0] = np.sin(theta_z)
R3[1,1] = np.cos(theta_z)

Ra = np.dot(R1,R2)
Rb = np.dot(Ra,R3)

transform = sitk.Euler3DTransform()
transform.SetMatrix(tuple(map(tuple,Rb[0:3,0:3].reshape(1,9)))[0])
transform.SetTranslation([a,b,c])
transform.SetCenter([x/2.0*mri.GetSpacing()[0] for x in mri.GetSize()])

outImg = sitk.Resample(mri, mri.GetSize(), transform, sitk.sitkLinear, mri.GetOrigin(), mri.GetSpacing(), (1,0,0,0,1,0,0,0,1), 0.0)

sitk.WriteImage(outImg, outimgfilename)

myxformfile = open(transformfilename,'w')
myxformfile.write("%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n" % (Rb[0,0],Rb[0,1],Rb[0,2],Rb[1,0],Rb[1,1],Rb[1,2],Rb[2,0],Rb[2,1],Rb[2,2],a,b,c,mri.GetSize()[0]/2.0*mri.GetSpacing()[0],mri.GetSize()[1]/2.0*mri.GetSpacing()[1],mri.GetSize()[2]/2.0*mri.GetSpacing()[2]))
myxformfile.close()
