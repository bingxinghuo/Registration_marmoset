#include <iostream>
#include <string.h>
#include <fstream>
#include <cstdlib>
#include "Image.h"
//#include "Array3D.h"
#include "AnalyzeImage.h"
#include "classNRUTILS.h"
#include "moreNRUTILS.h"

#include <sys/time.h>
#include <time.h>
#include <omp.h>


using namespace std;
void deform_label_data(
        Array3D<FLT> & Ilabel,
        Array3D<FLT> & Itemp,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
        double **LABELMATRIX,
        int labelnumber,
        float *defIlabelvector,
        int voxelnumber);

void init_labelmatrix(Array3D<double>& Iseg1, double **LABELMATRIX, int labelnumber);
void interpolateImage_trilinear(
        Array3D<FLT> &Img_in,
        Array3D<FLT> &Img_out,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
        int t_nzI,
        int t_nyI,
        int t_nxI);
void interpolateImage_nearest(
        Array3D<FLT> &Img_in,
        Array3D<FLT> &Img_out,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
        int t_nzI,
        int t_nyI,
        int t_nxI);

void print_usage() {
        cerr<<endl;
        cerr<<"***************USAGE 1***************\n";
        cerr<<"(0)IMG_apply_lddmm_tform2label \n";
        cerr<<"(1)label.img \n";
        cerr<<"(2)Hmap.vtk\n";
        cerr<<"(3)Transformed_label.img (Nearest Neighbour)\n";
        cerr<<"(4)Transformed_label.dat (Linear)\n";
        cerr<<endl;
        cerr<<endl;
}

int main(int argc, char **argv){
	int i, j, k, x, y, z;

        struct timeval checkPoint1, checkPoint2;
        double _elapsed_time0 = 0.0 ;

gettimeofday(&checkPoint1, NULL);


/*
classNRUTILS C1;
double *hist1 = C1.dvector(0,9);
double *hist2 = C1.dvector(0,9);
double s=2;

for (i=0;i<10;i++){
	hist1[i]= exp(-(i-5)*(i-5)/s)/sqrt(2*3.1416*s);
	hist2[i]= 0;
	cout<<hist1[i]<<"\t";
	cout<<hist2[i]<<"\n";
}
cout<<"\n";
 
splineCalc(hist1, 10, hist2);

for (i=0;i<10;i++){
        cout<<hist2[i]<<"\t";
}
cout<<"\n";
cout << splineEval(hist1, hist2, 10, 0.1)<<"\n";
cout << splineEval(hist1, hist2, 10, 9)<<"\n";
C1.free_dvector(hist1, 0, 9);
C1.free_dvector(hist2, 0, 9);
*/


        cout<<"\nINPUTS TO THE PROGRAM\n";
        for(y=0; y<argc; y++) {
                cout << y << "> " << argv[y] << endl;
        }
        cout<<"\n";

	//check if all arguments supplied  
	if(argc != 5){
                print_usage();
                cout<<"**********************************\n";
                cout<<"Exiting, wrong number of arguments\n";
                cout<<"**********************************\n";
                exit(0);
        }
 

	int interp_type=1;

// Reading parameters
	int filenamelength = 800;
	char inputFile[filenamelength];
	char mappingFile[filenamelength];
	char outputFile1[filenamelength];
	char outputFile2[filenamelength];
	strcpy(inputFile, argv[1]);
	strcpy(mappingFile, argv[2]);
	strcpy(outputFile1, argv[3]);
	strcpy(outputFile2, argv[4]);

cout<< "input img file\t"  << inputFile   <<"\n";
cout<< "mapping file\t"    << mappingFile <<"\n";
cout<< "output img file\t" << outputFile1 <<"\n";
cout<< "output dat file\t" << outputFile2 <<"\n";

//Reading the image
	AnalyzeImage <FLT> A(inputFile);
	AnalyzeHeader* H = A.getAnalyzeHeader();

//get Dimensions of Image
	int Nx = A.getNx();  int Ny = A.getNy(); int Nz = A.getNz();
	if( !(Nx*Ny*Nz)) {cerr<<"Load terminating: Image Dimension is Zero "<<endl; exit(0);}


//create deformed Functional Data Image of same size as loaded image
        Array3D<double> It(Nz,Ny,Nx);
        AnalyzeImage <FLT> dI;
        dI=It;

	Array3D<FLT> *Img_in,*Img_out;
	Img_in = (A.getAnalyzeImage());
	Img_out = (dI.getAnalyzeImage());







//Load the Mapping from the files
	Array3D<double> Mapx, Mapy, Mapz;
	Array3D<double>::loadVectorFieldVTK(Mapx,Mapy,Mapz,mappingFile);


	int nxI = Mapx.getNxInner(); if(nxI <= 0){cout<<" Mapx corrupted "<<endl; exit(0);}
	int nyI = Mapx.getNyInner(); if(nyI <= 0){cout<<" Mapy corrupted "<<endl; exit(0);}
	int nzI = Mapx.getNzInner(); if(nzI <= 0){cout<<" Mapz corrupted "<<endl; exit(0);}
//	cout<<"for an image of size  "<<nxI<<"-"<<nyI<<"-"<<nzI<<"\n\n";

	cout<<" Mapx max value is "   <<Mapx.getMaxValue()   <<" and min value is "   << Mapx.getMinValue()<<endl;
	cout<<" Mapy max value is "   <<Mapy.getMaxValue()   <<" and min value is "   <<Mapy.getMinValue()<<endl;
	cout<<" Mapz max value is "   <<Mapz.getMaxValue()   <<" and min value is "   <<Mapz.getMinValue()<<endl;
	cout<<" Mapx absmax value is "<<Mapx.getMaxAbsValue()<<" and absmin value is "<< Mapx.getMinAbsValue()<<endl;
	cout<<" Mapy absmax value is "<<Mapy.getMaxAbsValue()<<" and absmin value is "<<Mapy.getMinAbsValue()<<endl;
	cout<<" Mapz absmax value is "<<Mapz.getMaxAbsValue()<<" and absmin value is "<<Mapz.getMinAbsValue()<<endl;
	cout<<"\n";

//nearest neighbour interpolation of labels
 	double px, py, pz;
        Array3D<double> Itemp1(Nz,Ny,Nx);

        interpolateImage_nearest(Img_in[0], Img_out[0], Mapx,Mapy,Mapz,nzI,nyI,nxI);
        dI.setAnalyzeHeader(H);
	dI.save(outputFile1);

//label number
	int labelnumber = (int) Img_out[0].getMaxValue();
	cout<<"label number=\t" <<labelnumber<<"\n";


	classNRUTILS C1;
	//labelid - counter - voxelnumber - beginindex - endindex - minx - miny - minz - maxx - maxy - maxz
	double **LABELMATRIX = C1.dmatrix(1,labelnumber,1,11);

	init_labelmatrix(Img_out[0], LABELMATRIX, labelnumber);
	int voxelnumber = LABELMATRIX[labelnumber][5];
	cout<<"voxel number=\t" <<voxelnumber<<"\n";


	int numberofelements = voxelnumber+4+labelnumber*6;
        float *defIlabelvector  = new float[numberofelements];
	deform_label_data(Img_in[0], Itemp1, Mapx,Mapy,Mapz, LABELMATRIX, labelnumber, defIlabelvector, voxelnumber);
cout<<"saving\n";
//saving deformed label data;
        fstream myFile1 (outputFile2, ios::out | ios::binary);
        myFile1.write((char *)defIlabelvector, numberofelements*sizeof(float));
        if (!myFile1)
                cout<<"An error occurred!\n";
        myFile1.close();

	C1.free_dmatrix(LABELMATRIX,1,labelnumber,1,11);



gettimeofday(&checkPoint2, NULL);
_elapsed_time0 =  difftime(checkPoint2.tv_sec, checkPoint1.tv_sec) + (((double) (checkPoint2.tv_usec - checkPoint1.tv_usec)) / ((double) 1000000));
cout<<"Total running time (in seconds) of image deformation calculated  "<<_elapsed_time0<<"\n" ;
cout<<"for an image of size  "<<nxI<<"-"<<nyI<<"-"<<nzI<<"\n\n";


	return 0;

}//main




void deform_label_data(
        Array3D<FLT> & Ilabel,
        Array3D<FLT> & Itemp,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
	double **LABELMATRIX,
	int labelnumber,
	float *defIlabelvector,
	int voxelnumber)
{
        int i,j,k,x,y,z,imagevalue;
//image size
        int Nx1,Ny1,Nz1;
        Nx1=Itemp.getNxTotal();        Ny1=Itemp.getNyTotal();        Nz1=Itemp.getNzTotal();

        Array3D<double> Itemp1(Nz1,Ny1,Nx1);

//writing image size to output array
	int c=0;
	defIlabelvector[c]=Nx1;	c++;
	defIlabelvector[c]=Ny1;	c++;
	defIlabelvector[c]=Nz1;	c++;
	defIlabelvector[c]=labelnumber; c++;
//writing bounding box to output array
	for(i=1; i<=labelnumber; i++){
		for(j=6; j<=11; j++){
			defIlabelvector[c]=LABELMATRIX[i][j];
			c++;
		}
	}

	for(i=1; i<=labelnumber; i++){
	        for(z=0; z<Nz1; z++){
        	        for(y=0; y<Ny1; y++){
                	        for(x=0; x<Nx1; x++){
                        	        if((Ilabel.address())[z][y][x]==i)
						(Itemp.address())[z][y][x]=1;
					else
						(Itemp.address())[z][y][x]=0;
				}
			}
		}
		interpolateImage_trilinear(Itemp, Itemp1, Hx,Hy,Hz,Nz1,Ny1,Nx1);

                for(z=LABELMATRIX[i][8]; z<=LABELMATRIX[i][11]; z++){
                        for(y=LABELMATRIX[i][7]; y<=LABELMATRIX[i][10]; y++){
                                for(x=LABELMATRIX[i][6]; x<=LABELMATRIX[i][9]; x++){
		                        defIlabelvector[c]=(Itemp1.address())[z][y][x];
                		        c++;
                                }
                        }
                }
	}

//cout<<c<<"\n";

}


//labelid - counter - voxelnumber - beginindex - endindex - minx - miny - minz - maxx - maxy - maxz
void init_labelmatrix(Array3D<double>& Iseg1, double **LABELMATRIX, int labelnumber){

        int i,j,k,x,y,z,imagevalue;
//image size
        int Nx1,Ny1,Nz1;
        Nx1=Iseg1.getNxTotal();        Ny1=Iseg1.getNyTotal();        Nz1=Iseg1.getNzTotal();

//initialization
        for(i=1; i<=labelnumber; i++){for(j=1; j<=11; j++){LABELMATRIX[i][j]=0;}}
        for(i=1; i<=labelnumber; i++){
                LABELMATRIX[i][1] = i;	//labelid
                LABELMATRIX[i][2] = 1;	//counter
                LABELMATRIX[i][6] = Nx1;
                LABELMATRIX[i][7] = Ny1;
                LABELMATRIX[i][8] = Nz1;
        }


        for(z=0; z<Nz1; z++){
                for(y=0; y<Ny1; y++){
                        for(x=0; x<Nx1; x++){
				imagevalue = (int)(Iseg1.address())[z][y][x];
                                if(imagevalue > 0){
					if(x<LABELMATRIX[imagevalue][6])	LABELMATRIX[imagevalue][6]=x;
					if(y<LABELMATRIX[imagevalue][7])	LABELMATRIX[imagevalue][7]=y;
					if(z<LABELMATRIX[imagevalue][8])	LABELMATRIX[imagevalue][8]=z;
					if(x>LABELMATRIX[imagevalue][9])	LABELMATRIX[imagevalue][9]=x;
					if(y>LABELMATRIX[imagevalue][10])	LABELMATRIX[imagevalue][10]=y;
					if(z>LABELMATRIX[imagevalue][11])	LABELMATRIX[imagevalue][11]=z;
                                }
                        }
                }
        }

	for(i=1; i<=labelnumber; i++){
		for(j=1; j<=3; j++){
			LABELMATRIX[i][5+j]--;
			LABELMATRIX[i][8+j]++;
		}
	}

	for(i=1; i<=labelnumber; i++){
		if(LABELMATRIX[i][6]<0) LABELMATRIX[i][6]=0;
		if(LABELMATRIX[i][7]<0) LABELMATRIX[i][7]=0;
		if(LABELMATRIX[i][8]<0) LABELMATRIX[i][8]=0;
		if(LABELMATRIX[i][9]>=Nx1) LABELMATRIX[i][9]=Nx1-1;
		if(LABELMATRIX[i][10]>=Ny1) LABELMATRIX[i][10]=Ny1-1;
		if(LABELMATRIX[i][11]>=Nz1) LABELMATRIX[i][11]=Nz1-1;
	}

	for(i=1; i<=labelnumber; i++){
		LABELMATRIX[i][3] = (LABELMATRIX[i][9]-LABELMATRIX[i][6]+1)*(LABELMATRIX[i][10]-LABELMATRIX[i][7]+1)*(LABELMATRIX[i][11]-LABELMATRIX[i][8]+1);
	}

	LABELMATRIX[1][4]=1;	LABELMATRIX[1][5]=LABELMATRIX[1][3];
	for(i=2; i<=labelnumber; i++){
		LABELMATRIX[i][4]=LABELMATRIX[i-1][5]+1;
		LABELMATRIX[i][5]=LABELMATRIX[i-1][5]+LABELMATRIX[i][3];
	}
//	printmatrix(LABELMATRIX,labelnumber,11);
}



/////////////////////////////////////////////////////////////////////////////////////////////////// 
// interpolateImage() 
/////////////////////////////////////////////////////////////////////////////////////////////////// 
// THIS FUNCTION TRANSFORMS AN IMAGE USING THE TRANSFORMATION ARRAYS 
//-)SAME AS THE CODE IN MAIN LDDMM PROGRAM 
//-)WRAPPINGS REMOVED 
//-)floor is removed from int(floor()) 
//-)iterators used 
void interpolateImage_nearest(
        Array3D<FLT> &Img_in,
        Array3D<FLT> &Img_out,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
        int t_nzI,
        int t_nyI,
        int t_nxI)
{
    FLT ***InputPPPtr = Img_in.address();
    FLT ***OutputPPPtr = Img_out.address();
    FLT ***hxPtr = Hx.address();
    FLT ***hyPtr = Hy.address();
    FLT ***hzPtr = Hz.address();

    double zz, yy, xx;
    int x0, y0, z0, x1, y1, z1;
    double fz, fy, fx;

    //get the maximum and minimum INDICES of the Image decomposed on this
    //processor and sent here

    //these hodl the image values
    FLT d000, d001, d010, d011, d100, d101, d110, d111;

int BZ=Img_in.getZbegin();
int EZ=Img_in.getZend();
int BY=Img_in.getYbegin();
int EY=Img_in.getYend();
int BX=Img_in.getXbegin();
int EX=Img_in.getXend();
int x,y,z;

    Array3D<FLT>::iterator dI_It = Img_out.begin();
    Array3D<FLT>::iterator x_It = Hx.begin();
    Array3D<FLT>::iterator y_It = Hy.begin();
    Array3D<FLT>::iterator z_It = Hz.begin();
#pragma omp parallel shared(InputPPPtr,OutputPPPtr,hxPtr,hyPtr,hzPtr, BZ,EZ,BY,EY,BX,EX,t_nzI,t_nyI,t_nxI)private(z,y,x, zz,yy,xx, x0,y0,z0, x1,y1,z1, fz,fy,fx, d000, d001, d010, d011, d100, d101, d110, d111, x_It,y_It,z_It,dI_It)
{
    #pragma omp for schedule(dynamic)
    for (z = BZ ; z <= EZ; z++){
        z_It = Hz.begin() + z * t_nyI * t_nxI;
        y_It = Hy.begin() + z * t_nyI * t_nxI;
        x_It = Hx.begin() + z * t_nyI * t_nxI;
        dI_It = Img_out.begin() +  z * t_nyI * t_nxI;

        for (y = BY ; y <= EY ; y++){
            for (x = BX ; x <= EX ; x++){
//                xx = hxPtr[z][y][x];
//                yy = hyPtr[z][y][x];
//                zz = hzPtr[z][y][x];
                  xx = *x_It; // position of point [z][y][x] in X after mapping
                  yy = *y_It; // position of point [z][y][x] in Y after mapping
                  zz = *z_It; // position of point [z][y][x] in Z after mapping


                z0 = zz;
                if (zz<0)       z0--;
                z1 = z0 + 1;    fz = zz - z0;

                y0 = yy;
                if (yy<0)       y0--;
                y1 = y0 + 1;    fy = yy - y0;

                x0 = xx;
                if (xx<0)       x0--;
                x1 = x0 + 1;    fx = xx - x0;

        if (fz < 0.5)	z1 = z0;
        if (fy < 0.5)	y1 = y0;
        if (fx < 0.5)   x1 = x0;

//if(z<BZ+NNz || z>EZ-NNz || y<BY+NNy || y>EY-NNy || x<BX+NNx || x>EX-NNx){
                if(z0<BZ) z0=z0+t_nzI;
                else if(z0>EZ) z0=z0-t_nzI;
                if(z1<BZ) z1=z1+t_nzI;
                else if(z1>EZ) z1=z1-t_nzI;
                if(y0<BY) y0=y0+t_nyI;
                else if(y0>EY) y0=y0-t_nyI;
                if(y1<BY) y1=y1+t_nyI;
                else if(y1>EY) y1=y1-t_nyI;
                if(x0<BX) x0=x0+t_nxI;
                else if(x0>EX) x0=x0-t_nxI;
                if(x1<BX) x1=x1+t_nxI;
                else if(x1>EX) x1=x1-t_nxI;


//                d000=InputPPPtr[z0][y0][x0];    d001=InputPPPtr[z0][y0][x1];    d010=InputPPPtr[z0][y1][x0];    d011=InputPPPtr[z0][y1][x1];
//                d100=InputPPPtr[z1][y0][x0];    d101=InputPPPtr[z1][y0][x1];    d110=InputPPPtr[z1][y1][x0];    d111=InputPPPtr[z1][y1][x1];
//                *(dI_It)  = ((1-fz) * ((1-fy) * ((1-fx) * d000 + fx * d001) + fy * ((1-fx) * d010 + fx * d011)) + fz * ((1-fy) * ((1 - fx) * d100 + fx * d101)  +fy * ((1-fx) * d110 + fx * d111)));
		*(dI_It)=InputPPPtr[z1][y1][x1];
                dI_It++;
                x_It++;
                y_It++;
                z_It++;

            }
        }
    }

}  /* end of parallel section */

}







///////////////////////////////////////////////////////////////////////////////////////////////////
// interpolateImage()
///////////////////////////////////////////////////////////////////////////////////////////////////
// THIS FUNCTION TRANSFORMS AN IMAGE USING THE TRANSFORMATION ARRAYS
//-)SAME AS THE CODE IN MAIN LDDMM PROGRAM
//-)WRAPPINGS REMOVED
//-)floor is removed from int(floor())
//-)iterators used
void interpolateImage_trilinear(
        Array3D<FLT> &Img_in,
        Array3D<FLT> &Img_out,
        Array3D<FLT> & Hx,
        Array3D<FLT> & Hy,
        Array3D<FLT> & Hz,
        int t_nzI,
        int t_nyI,
        int t_nxI)
{
    FLT ***InputPPPtr = Img_in.address();
    FLT ***OutputPPPtr = Img_out.address();
    FLT ***hxPtr = Hx.address();
    FLT ***hyPtr = Hy.address();
    FLT ***hzPtr = Hz.address();

    double zz, yy, xx;
    int x0, y0, z0, x1, y1, z1;
    double fz, fy, fx;

    //get the maximum and minimum INDICES of the Image decomposed on this
    //processor and sent here

    //these hodl the image values
    FLT d000, d001, d010, d011, d100, d101, d110, d111;

int BZ=Img_in.getZbegin();
int EZ=Img_in.getZend();
int BY=Img_in.getYbegin();
int EY=Img_in.getYend();
int BX=Img_in.getXbegin();
int EX=Img_in.getXend();
int x,y,z;

    Array3D<FLT>::iterator dI_It = Img_out.begin();
    Array3D<FLT>::iterator x_It = Hx.begin();
    Array3D<FLT>::iterator y_It = Hy.begin();
    Array3D<FLT>::iterator z_It = Hz.begin();
#pragma omp parallel shared(InputPPPtr,OutputPPPtr,hxPtr,hyPtr,hzPtr, BZ,EZ,BY,EY,BX,EX,t_nzI,t_nyI,t_nxI)private(z,y,x, zz,yy,xx, x0,y0,z0, x1,y1,z1, fz,fy,fx, d000, d001, d010, d011, d100, d101, d110, d111, x_It,y_It,z_It,dI_It)
{
    #pragma omp for schedule(dynamic)
    for (z = BZ ; z <= EZ; z++){
        z_It = Hz.begin() + z * t_nyI * t_nxI;
        y_It = Hy.begin() + z * t_nyI * t_nxI;
        x_It = Hx.begin() + z * t_nyI * t_nxI;
        dI_It = Img_out.begin() +  z * t_nyI * t_nxI;

        for (y = BY ; y <= EY ; y++){
            for (x = BX ; x <= EX ; x++){
//                xx = hxPtr[z][y][x];
//                yy = hyPtr[z][y][x];
//                zz = hzPtr[z][y][x];
                  xx = *x_It; // position of point [z][y][x] in X after mapping
                  yy = *y_It; // position of point [z][y][x] in Y after mapping
                  zz = *z_It; // position of point [z][y][x] in Z after mapping


                z0 = zz;
                if (zz<0)       z0--;
                z1 = z0 + 1;    fz = zz - z0;

                y0 = yy;
                if (yy<0)       y0--;
                y1 = y0 + 1;    fy = yy - y0;

                x0 = xx;
                if (xx<0)       x0--;
                x1 = x0 + 1;    fx = xx - x0;

//if(z<BZ+NNz || z>EZ-NNz || y<BY+NNy || y>EY-NNy || x<BX+NNx || x>EX-NNx){
                if(z0<BZ) z0=z0+t_nzI;
                else if(z0>EZ) z0=z0-t_nzI;
                if(z1<BZ) z1=z1+t_nzI;
                else if(z1>EZ) z1=z1-t_nzI;
                if(y0<BY) y0=y0+t_nyI;
                else if(y0>EY) y0=y0-t_nyI;
                if(y1<BY) y1=y1+t_nyI;
                else if(y1>EY) y1=y1-t_nyI;
                if(x0<BX) x0=x0+t_nxI;
                else if(x0>EX) x0=x0-t_nxI;
                if(x1<BX) x1=x1+t_nxI;
                else if(x1>EX) x1=x1-t_nxI;

                d000=InputPPPtr[z0][y0][x0];    d001=InputPPPtr[z0][y0][x1];    d010=InputPPPtr[z0][y1][x0];    d011=InputPPPtr[z0][y1][x1];
                d100=InputPPPtr[z1][y0][x0];    d101=InputPPPtr[z1][y0][x1];    d110=InputPPPtr[z1][y1][x0];    d111=InputPPPtr[z1][y1][x1];
                *(dI_It)  = ((1-fz) * ((1-fy) * ((1-fx) * d000 + fx * d001) + fy * ((1-fx) * d010 + fx * d011)) + fz * ((1-fy) * ((1 - fx) * d100 + fx * d101)  +fy * ((1-fx) * d110 + fx * d111)));
                dI_It++;
                x_It++;
                y_It++;
                z_It++;

            }
        }
    }

}  /* end of parallel section */

}
