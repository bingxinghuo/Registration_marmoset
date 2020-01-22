#Create downsampled image for registration
import numpy as np
import cv2
import glob
import re
import SimpleITK as sitk
import skimage.transform
import sys

def main():
    BRAINNO = sys.argv[1]
    LIST_DIR = sys.argv[2]
    OUTPUT_DIR = sys.argv[3]

    with open(LIST_DIR + '/' + BRAINNO + '_List.txt') as f:
        lines = f.read().splitlines()

    original_res = 13.6 #change this if original resolution is changed.
    target_res = 25 #change this to atlas resolution if needed

    imgstack = []
    for element in lines:
        print(element)
        img = cv2.imread(element, -1)
        imgDown = skimage.transform.resize(img, (int(img.shape[0] * original_res / target_res), 
                                             int(img.shape[1] * original_res / target_res)), order=0)
        imgDown = np.asarray(imgDown * 65535, dtype = 'uint16')
        # imgDown = np.asarray(imgDown, dtype = 'uint16')
        imgstack.append(imgDown)

    imgstack = np.asarray(imgstack)
    imgstack = np.swapaxes(imgstack, 0, 1)
    imgstack = np.swapaxes(imgstack, 1, 2)

    print(imgstack.shape)

    sitkimg = sitk.GetImageFromArray(imgstack)
    sitkimg.SetSpacing((0.025, 0.025, 0.025)) #change this if atlas is changed
    sitkimg.SetOrigin((0.0, 0.0, 0.0))

    sitk.WriteImage(sitkimg, OUTPUT_DIR + '/' + BRAINNO + '_25.img')


if __name__ == "__main__":
    main()
