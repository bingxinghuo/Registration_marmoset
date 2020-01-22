#import scipy.signal
import scipy.ndimage
import scipy.optimize
import numpy as np
import SimpleITK as sitk
#import matplotlib.pyplot as plt

def getInflectionPoint(img):
    hist,bin_edges = np.histogram(sitk.GetArrayFromImage(img), bins=255, range=(0,255))
    #sg0 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=0)
    #sg1 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=1)
    #sg2 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=2)
    sg0 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),2, axis=0,order=0)
    sg1 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),2, axis=0,order=1)
    sg2 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),2, axis=0,order=2)

    # find zero crossings of second derivative
    zerocrossings = np.where(np.diff(np.sign(sg2))==2)
    
    rightpeak = -1
    for i in range(zerocrossings[0].shape[0]):
        if sg1[zerocrossings[0][i]] < np.mean(sg1) - 0.2*np.std(sg1):
        #if sg0[zerocrossings[0][i]] > np.mean(sg0):
            rightpeak = i

    '''
    zerocrossings = np.where(np.diff(np.sign(sg1))==-2)# find zero crossings of first derivative (but only the ones from neg to pos)
    rightpeak = -1
    for i in range(zerocrossings[0].shape[0]):
        if sg0[zerocrossings[0][i]] > np.mean(sg0) + np.std(sg0):
        #if sg0[zerocrossings[0][i]] > np.mean(sg0):
            rightpeak = i
    '''

    rightpeakind = zerocrossings[0][rightpeak]
    zerocrossingsplus = np.where(np.diff(np.sign(sg1))==2)# find zero crossings of first derivative (but only the ones from pos to neg)
    inflectionpoint = -1
    for i in range(zerocrossingsplus[0].shape[0]):
        if zerocrossingsplus[0][i] > rightpeakind:
            inflectionpoint = zerocrossingsplus[0][i]-2
            break

    '''
    inflectionpoint
    plt.figure()
    plt.plot(hist)
    plt.plot(sg0)
    plt.plot(sg1)
    plt.plot(sg2)
    plt.show()
    '''
    
    return inflectionpoint

def getInflectionSlicePoint(img):
    hist,bin_edges = np.histogram(sitk.GetArrayFromImage(img), bins=255, range=(0,255))
    #sg0 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=0)
    #sg1 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=1)
    #sg2 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=2)
    sg0 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),5, axis=0,order=0)
    sg1 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),5, axis=0,order=1)
    sg2 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),7, axis=0,order=2)
    
    
    # remove all zero crossings to the right of the last major peak in the histogram (by looking at zc of 1st deriv) (or maybe by looking for the widest peak)
    # first, find the last peak of the histogram
    zc1 = np.where(np.diff(np.sign(sg1))==-2)
    
    # as a first step, remove peaks from zc1 that are way too high
    zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + np.std(sg0))[0])
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 1.2*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 1.4*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 1.6*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 1.8*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 2*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = np.delete(zc1[0],np.where(sg0[zc1[0]] > np.mean(sg0) + 2.5*np.std(sg0))[0])
    
    if zc1trunc.shape[0] == 0:
        zc1trunc = zc1[0]
    
    # as a second step, remove peaks that are way too low
    zc1trunctemp = np.delete(zc1trunc,np.where(np.abs(sg0[zc1trunc]) < np.abs(np.mean(sg0)/15)))
    if zc1trunctemp.shape[0] == 0:
        #reinclude tallest peak
        zc1trunc = np.array([sg0[zc1trunc].argmax()])
    else:
        zc1trunc = np.copy(zc1trunctemp)
    
    zc1rightpeak = -1
    zc2minus = np.where(np.diff(np.sign(sg2))==-2) #left
    zc2plus = np.where(np.diff(np.sign(sg2))==2) #right
    maxdist = -1
    maxind = -1
    for i in range(zc1trunc.shape[0]):
        # find left and right bounds
        templeft = -1
        tempright = -1
        for ii in range(zc2minus[0].shape[0]):
            if zc2minus[0][ii] < zc1trunc[i]:
                templeft = zc2minus[0][ii]
        
        for ii in range(zc2plus[0].shape[0]):
            if zc2plus[0][ii] > zc1trunc[i]:
                tempright = zc2plus[0][ii]
                break
        
        if tempright-templeft > maxdist:
            maxdist = tempright-templeft
            maxind = i
    
    zc1ind = zc1trunc[maxind]
    
    '''
    for i in range(zc1[0].shape[0]):
        if sg0[zc1[0][i]] > np.mean(sg0) + 0.1*np.std(sg0):
        #if sg0[zerocrossings[0][i]] > np.mean(sg0):
            zc1rightpeak = i

    zc1ind = zc1[0][zc1rightpeak]
    '''
    
    # find zero crossings of second derivative
    sg0 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),3, axis=0,order=0)
    sg1 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),3, axis=0,order=1)
    sg2 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),3, axis=0,order=2)
    zerocrossings = np.where(np.diff(np.sign(sg2))==2)
    
    maxind = -1
    for i in range(zerocrossings[0].shape[0]):
        if zerocrossings[0][i] < zc1ind:
            maxind = i

    maxind = maxind + 1
    zerocrossings = np.delete(zerocrossings,range(maxind,zerocrossings[0].shape[0]))

    rightpeak = -1
    for i in range(zerocrossings.shape[0]):
        if sg1[zerocrossings[i]] < np.mean(sg1) - 0.2*np.std(sg1):
        #if sg0[zerocrossings[0][i]] > np.mean(sg0):
            rightpeak = i

    '''
    zerocrossings = np.where(np.diff(np.sign(sg1))==-2)# find zero crossings of first derivative (but only the ones from neg to pos)
    rightpeak = -1
    for i in range(zerocrossings[0].shape[0]):
        if sg0[zerocrossings[0][i]] > np.mean(sg0) + np.std(sg0):
        #if sg0[zerocrossings[0][i]] > np.mean(sg0):
            rightpeak = i
    '''

    rightpeakind = zerocrossings[rightpeak]
    zerocrossingsplus = np.where(np.diff(np.sign(sg1))==2)# find zero crossings of first derivative (but only the ones from pos to neg)
    inflectionpoint = -1
    for i in range(zerocrossingsplus[0].shape[0]):
        if zerocrossingsplus[0][i] > rightpeakind:
            inflectionpoint = zerocrossingsplus[0][i]-2
            break

    '''
    inflectionpoint
    plt.figure()
    plt.plot(hist)
    plt.plot(sg0)
    plt.plot(sg1)
    plt.plot(sg2)
    plt.show()
    '''
    
    return inflectionpoint

def mygaussian(x,a,x0,sigma):
    return a*np.exp(-(x-x0)**2/(2*sigma**2))

def getInflectionPointRANSAC(img):
    hist,bin_edges = np.histogram(sitk.GetArrayFromImage(img), bins=255, range=(0,255))
    #sg0 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=0)
    #sg1 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=1)
    #sg2 = scipy.signal.savgol_filter(hist,window_length=11,polyorder=2,deriv=2)
    histnb = np.copy(hist)
    histnb[0] = 0
    sg0 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),2, axis=0,order=0)
    sg1 = scipy.ndimage.filters.gaussian_filter1d(hist.astype(np.float32),2, axis=0,order=1)
    sg0nb = scipy.ndimage.filters.gaussian_filter1d(histnb.astype(np.float32),2, axis=0,order=0)
    sg1nb = scipy.ndimage.filters.gaussian_filter1d(histnb.astype(np.float32),2, axis=0,order=1)
    sg2nb = scipy.ndimage.filters.gaussian_filter1d(histnb.astype(np.float32),2, axis=0,order=2)
    
    # these are the potential troughs
    #zc1 = np.where(np.sign(np.diff(np.sign(sg1)))==1)[0]
    zc1 = np.where(np.diff(np.sign(sg1))==2)[0]
    
    # add a trough at the left hand side of the histogram?
    zc1temp = list(zc1)
    zc1temp.append(4)
    zc1 = np.array(zc1temp)
    zc1.sort()
    
    # find the rightmost "big" peak, remove every trough to the right
    #zc1peaks = np.where(np.sign(np.diff(np.sign(sg1)))==-1)[0]
    zc1peaks = np.where(np.diff(np.sign(sg1))==-2)[0]
    rightpeak = -1
    for i in range(zc1peaks.shape[0]):
        if sg0nb[zc1peaks[i]] > np.mean(sg0nb):
            rightpeak = zc1peaks[i]
    
    righttroughind = -1
    for i in range(zc1.shape[0]):
        if zc1[i] > rightpeak:
            righttroughind = i
            break
    
    if righttroughind != -1 and righttroughind != 0:
        zc1trunc = np.delete(zc1,np.array(range(righttroughind,zc1.shape[0])))
    else:
        zc1trunc = np.copy(zc1)
    
    # might need to identify the troughs of the first derivative, check that it is low enough
    zc2troughs = np.where(np.diff(np.sign(sg2nb))==2)[0]
    deleteind = []
    for i in range(zc1trunc.shape[0]):
        # find the closest trough in 1st deriv to the left
        if sg1[zc2troughs[np.where(np.diff(np.sign(zc1trunc[i]-zc2troughs))==-2)]] > -0.05:
            deleteind.append(i)
    
    zc1trunctemp = np.delete(zc1trunc,deleteind)
    if zc1trunctemp.shape[0] > 0:
        zc1trunc = np.copy(zc1trunctemp)
    
    # maybe check if the peak on the right is tall
    zc2peaks = np.where(np.diff(np.sign(sg2nb))==-2)[0]
    deleteind = []
    for i in range(zc1trunc.shape[0]):
        # find the closest trough in 1st deriv to the left
        if sg1[zc2peaks[np.where(np.diff(np.sign(zc1trunc[i]-zc2peaks))==-2)[0]+1]] < 0.05:
            deleteind.append(i)
    
    zc1trunctemp = np.delete(zc1trunc,deleteind)
    if zc1trunctemp.shape[0] > 0:
        zc1trunc = np.copy(zc1trunctemp)
    
    mse = -1*np.ones((zc1trunc.shape[0],1))
    for i in range(zc1trunc.shape[0]): #try the zc points instead of every point
        try:
            popt,pcov = scipy.optimize.curve_fit(mygaussian, np.array(range(zc1trunc[i],255)), sg0[zc1trunc[i]:255], p0=[1,255/3,5])
            #mse[i] = np.mean((sg0[zc1trunc[i]:255] - mygaussian(np.array(range(zc1trunc[i],255)), *popt))**2) + zc1trunc[i]*5 + (sg0[zc1trunc[i]]*2)
            mse[i] = np.mean((sg0[zc1trunc[i]:255] - mygaussian(np.array(range(zc1trunc[i],255)), *popt))**2) + np.sum(sg0nb[0:zc1trunc[i]])*0.5 + (sg0[zc1trunc[i]]*2) # charge by area of curve being chopped off
            #plt.figure()
            #plt.plot(np.array(range(zc1trunc[i],255)),sg0[zc1trunc[i]:255])
            #plt.plot(np.array(range(zc1trunc[i],255)),mygaussian(np.array(range(zc1trunc[i],255)),*popt),'ro')
            #plt.show()
        except RuntimeError:
            if i == 0:
                mse[i] = 99999999999
            else:
                mse[i] = mse[i-1] + (zc1trunc[i]-zc1trunc[i-1])*5
    
    
            #print(str(zc1trunc[i]) + ", " + str(mse[i]))
    
    #plt.figure()
    #plt.plot(hist)
    #plt.plot(sg0)
    #plt.plot(sg1)
    #plt.plot(sg2nb)
    #plt.plot(zc1trunc[mse.argmin()],0,'ko', markersize=10)
    #plt.axis([0,300,0,800])
    #plt.show()
    
    return zc1trunc[mse.argmin()]
