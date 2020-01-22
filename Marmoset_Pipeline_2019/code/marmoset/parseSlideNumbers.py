import os
import numpy as np

#listfilename = sys.argv[1]
#singlestartind = int(sys.argv[2])
#singleendind = int(sys.argv[3])
#patientnumber = sys.argv[4]

def parse(listfilename, singlestartind, singleendind, patientnumber):
    listfile = open(listfilename)
    slicedirectory = listfile.read().split('\n')
    
    slidelist = []
    seclist = []
    truenumberlist = []
    filenamelist = []
    directorynamelist = []
    
    for f in slicedirectory:
        if f.find('.tif') != -1 or f.find('.jp2') != -1:
            uind = f.find('_')
            seclist.append(int(f[uind+1]))
            dashind = f.find('--')
            nameind = f.find(patientnumber + '-')
            slidelist.append(int(f[nameind+len(patientnumber)+2:dashind]))
            slashind = f.rfind('/')
            directorynamelist.append(f[0:slashind+1])
            filenamelist.append(f[slashind+1::])
    
    secmin = np.min(seclist)
    for i in range(len(seclist)):
        seclist[i] = seclist[i] - (secmin-1)
    
    for i in range(len(seclist)):
        if slidelist[i] < singlestartind:
            truenumberlist.append(int((slidelist[i]-1)*2 + seclist[i]))
        elif slidelist[i] >= singlestartind and slidelist[i] <= singleendind:
            truenumberlist.append(int((singlestartind-1)*2 + slidelist[i] - singlestartind + 1))
        else:
            truenumberlist.append(int((singlestartind-1)*2 + singleendind - singlestartind + 1 + (slidelist[i] - singleendind - 1)*2 + seclist[i]))
    
    return directorynamelist, filenamelist, truenumberlist
