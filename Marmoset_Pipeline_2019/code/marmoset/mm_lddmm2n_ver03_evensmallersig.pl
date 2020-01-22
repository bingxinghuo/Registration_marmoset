#!/usr/bin/perl

#************************INPUTS TO THIS SCRIPT****************************
#
#	MM_LDDMM WITH NO HIST MATCHING
#
#	channel_number
#	template_image 1 
#	target_image 1 
#	template_sigma 1 
#  		.
#  		.
#  		.
#	template_image N
#	target_image N
#	template_sigma N
#	output_folder
#	iteration_number
#	alpha1
#	timestep1
#	alpha2
#	timestep2
#		.
#	  	.
#	  	.
#	alphaN
#	timestepN
#	outputlevel		1->only final Hmap/Kimap 2->intermediate Hmap/Kimap	3->deformed data at each step
#	interpolationtype	1->linear		 2->nearest neighbour
#	scaling factor		[0.25-1]	(use a lower value for faster lddmm calculations)


#use Time::HiRes qw( time );
use POSIX;
#my $starttime = time();
$STARTTIME1=`date +%s`;


#PROGRAM NAMES
use File::Basename;
#my $dirname = dirname(__FILE__);
$dirname = "\/sonas-hs\/mitra\/hpc\/home\/blee\/code\/can";
#$dirname = "\/cis\/home\/can\/smallprj11\/dtipipeline\/4_newscripts_c.cis";
$SCRIPTS_BIN_DIRECTORY_FILENAME = "$dirname\/bin_scripts_directory.txt";
read_BIN_SCRIPTS_directory($SCRIPTS_BIN_DIRECTORY_FILENAME);



#PROGRAM NAMES
$VTK_combine_maps_ver5 	= "$BIN_DIRECTORY\/VTK_combine_maps_ver5";
$MM_LDDMM       	= "$BIN_DIRECTORY\/mmlddmm_ver4.0.0";
$IMG_TRANSFORM  	= "$BIN_DIRECTORY\/IMG_apply_lddmm_tform1";


$IMG_pad_ver02  	= "$BIN_DIRECTORY\/IMG_pad_ver02";
$IMG_resample1  	= "$BIN_DIRECTORY\/IMG_resample1";
$VTK_pad_ver02  	= "$BIN_DIRECTORY\/VTK_pad_ver02";
$VTK_resample2  	= "$BIN_DIRECTORY\/VTK_resample2";
$IMG_saveimgsize_resolution = "$BIN_DIRECTORY\/IMG_saveimgsize_resolution";




#READING INPUTS
	print "$#ARGV\n";

        for($i=0; $i<=$#ARGV; $i++) {
                print "$i = $ARGV[$i]\n";
        }
 	print "\n";

$index=0;
	$channel_number = $ARGV[$index];
        for($i=0; $i<$channel_number; $i++) {
		$j = 3 * $i + 1 ; 
		$templatefilelist[$i]=$ARGV[$j];
		$j = 3 * $i + 2 ; 
		$targetfilelist[$i]=$ARGV[$j];
		$j = 3 * $i + 3 ; 
		$sigmalist[$i]=$ARGV[$j];
        }


	$j = 3 * $channel_number + 1 ;
	$output_folder = $ARGV[$j];
	$j = 3 * $channel_number + 2 ;
	$iteration_number = $ARGV[$j];


        for($i=0; $i<$iteration_number; $i++) {
                $j = 3 * $channel_number + 3 + 2*$i ;
                $alphalist[$i]=$ARGV[$j];		
                $j = 3 * $channel_number + 3 + 2*$i + 1 ;
                $timesteplist[$i]=$ARGV[$j];		
                $deltalist[$i] = 1 / $timesteplist[$i];		
        }
	$index = $j +1;
	$outputlevel=$ARGV[$index];
	$index = $index+1;
        $interpolationtype=$ARGV[$index];
	$index = $index+1;
        $scaling_factor=$ARGV[$index];


print "Output_folder    :   $output_folder\n";
print "\n";

print "Channel_number   :   $channel_number\n";	
for($i=0; $i<$channel_number; $i++) {	
$j = $i+1;
print "Channel $j\n";
	print "\tTemplate     :   $templatefilelist[$i]\n";	
	print "\tTarget       :   $targetfilelist[$i]\n";	
	print "\tSigma        :   $sigmalist[$i]\n";
}
print "\n";

print "Cascading iteration_number :   $iteration_number\n";	
print "Alphas                     :   \t";	
for($i=0; $i<$iteration_number; $i++) {	print "$alphalist[$i]\t";}	print "\n";
print "Number of timesteps        :   \t";	
for($i=0; $i<$iteration_number; $i++) {	print "$timesteplist[$i]\t";}	print "\n";
print "Deltas                     :   \t";	
for($i=0; $i<$iteration_number; $i++) {	print "$deltalist[$i]\t";}	print "\n";
print "\n";

print "Output level               :   $outputlevel\n";
if($outputlevel==1){	print "\tOnly final Hmap/Kimap saved\n";	}
elsif($outputlevel==2){	print "\tBoth final and intermediate step Hmap/Kimap saved\n";	}
elsif($outputlevel==3){	print "\tDeformed data at each iteration steps saved\n";	}
elsif($outputlevel>3){ 
	print "ERROR: outputlevel can be 1, 2 or 3 \n";
	print "exiting...";
	exit;	
}
print "Interpolation type         :   $interpolationtype\n";
if($interpolationtype==1){    print "\tLinear interpolation\n";        }
elsif($interpolationtype==2){ print "\tNearest neighbourhood interpolation\n";  }
else{
        print "ERROR: interpolationtype can be 1 or 2 \n";
        print "exiting...";
        exit;
}

print "Scaling factor             :   $scaling_factor\n";
if($scaling_factor<0.25 || $scaling_factor>1){    
        print "ERROR: scaling factor should be in [0.25-1]range \n";
        print "exiting...";
        exit;
}



print "\n";
print "**************************************************************************\n";
print "*                                 STEP-1                                 *\n";
print "**************************************************************************\n";
print "copying files into output folder \n";
print "\n";

#STEP-1
#creating output subdirectory
$sim1 = `mkdir "$output_folder"`;
$sim1 = `mkdir "$output_folder/imgfiles"`;


#STEP-1.5
#copying imgfiles into the running subdirectory "imgfiles"
for($i=0; $i<$channel_number; $i++) {
	$j = $i+1;
#removing the path from the file lists
	$shorttemplateimglist[$i]=$templatefilelist[$i];
	chomp $shorttemplateimglist[$i];
        $shorttemplateimglist[$i] =~ /^.+\/(.+)/;
        $shorttemplateimglist[$i] =$1;
#        $shorttemplateimglist[$i] =~ s/.img/_template.img/g ;
        $temp1 = ".img";
        $temp2 = "_template_$j\.img";
        $shorttemplateimglist[$i] =~ s/$temp1/$temp2/g ;
#creating hdr file lists
        $shorttemplatehdrlist[$i] =$shorttemplateimglist[$i];
        $shorttemplatehdrlist[$i] =~ s/.img/.hdr/g ;
        $templatehdrlist[$i] =$templatefilelist[$i];
#        $templatehdrlist[$i] =~ s/.img/.hdr/g ;	
        $temp1 = ".img";
        $temp2 = ".hdr";
        $templatehdrlist[$i] =~ s/$temp1/$temp2/g ;

#removing the path from the file lists
	$shorttargetimglist[$i]=$targetfilelist[$i];
	chomp $shorttargetimglist[$i];
        $shorttargetimglist[$i] =~ /^.+\/(.+)/;
        $shorttargetimglist[$i] =$1;
#        $shorttargetimglist[$i] =~ s/.img/_target.img/g ;
        $temp1 = ".img";
	$temp2 = "_target_$j\.img";
        $shorttargetimglist[$i] =~ s/$temp1/$temp2/g ;

#creating hdr file lists
        $shorttargethdrlist[$i] =$shorttargetimglist[$i];
        $shorttargethdrlist[$i] =~ s/.img/.hdr/g ;
        $targethdrlist[$i] =$targetfilelist[$i];
#        $targethdrlist[$i] =~ s/.img/.hdr/g ;	
        $temp1 = ".img";
        $temp2 = ".hdr";
        $targethdrlist[$i] =~ s/$temp1/$temp2/g ;

	$sim1 = `cp $templatefilelist[$i] $output_folder/imgfiles/$shorttemplateimglist[$i]`;
	$sim1 = `cp $templatehdrlist[$i] $output_folder/imgfiles/$shorttemplatehdrlist[$i]`;
	$sim1 = `cp $targetfilelist[$i] $output_folder/imgfiles/$shorttargetimglist[$i]`;
	$sim1 = `cp $targethdrlist[$i] $output_folder/imgfiles/$shorttargethdrlist[$i]`;

	$sim1 = `cp $templatefilelist[$i] $output_folder/$shorttemplateimglist[$i]`;
	$sim1 = `cp $templatehdrlist[$i] $output_folder/$shorttemplatehdrlist[$i]`;
	$sim1 = `cp $targetfilelist[$i] $output_folder/$shorttargetimglist[$i]`;
	$sim1 = `cp $targethdrlist[$i] $output_folder/$shorttargethdrlist[$i]`;
}


print "\n";
print "**************************************************************************\n";
print "*                                 STEP-2                                 *\n";
print "**************************************************************************\n";
print "padding files if necessary \n";
print "\n";

#STEP-1.6
#padding input imgfiles if necessary
for($i=0; $i<$channel_number; $i++) {
	$temp11 = "$output_folder/imgfiles/$shorttemplateimglist[$i]";
	$temp22 = "$output_folder/imgfiles/$shorttemplateimglist[$i]\sizeres";
	$sim1 = `$IMG_saveimgsize_resolution $temp11 $temp22`;
#print "$temp11\n";
#print "$temp22\n";
        open(DAT, $temp22) || die("Could not open directory file!");        @params1=<DAT>;        close(DAT);
        $ii=0;
        $temp = $params1[$ii];   $ii=$ii+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $TEMPLATE_SIZE[$i][$jj] = "$temp1[$jj]";        }
        $temp = $params1[$ii];   $ii=$ii+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $TEMPLATE_RES[$i][$jj] = "$temp1[$jj]";        }


	$temp11 = "$output_folder/imgfiles/$shorttargetimglist[$i]";
	$temp22 = "$output_folder/imgfiles/$shorttargetimglist[$i]\sizeres";
#print "$temp11\n";
#print "$temp22\n";
	$sim1 = `$IMG_saveimgsize_resolution $temp11 $temp22`;
        open(DAT, $temp22) || die("Could not open directory file!");        @params1=<DAT>;        close(DAT);
        $ii=0;
        $temp = $params1[$ii];   $ii=$ii+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $TARGET_SIZE[$i][$jj] = "$temp1[$jj]";        }
        $temp = $params1[$ii];   $ii=$ii+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $TARGET_RES[$i][$jj] = "$temp1[$jj]";        }
}

#checking if all images have same size
for($jj=0; $jj<3; $jj++) {$MAIN_SIZE[$jj] =  $TEMPLATE_SIZE[0][$jj];}
$same_size=1;
for($i=0; $i<$channel_number; $i++) {
for($jj=0; $jj<3; $jj++){
	$same_size = $same_size * ($TEMPLATE_SIZE[$i][$jj]==$TARGET_SIZE[$i][$jj]);
}
}

if($same_size==0){
print "ERROR: All input images should have same size\n";
print "exiting... \n";
exit;
#print "same_size = $same_size \n";
}

$even_size=0; #even size true
if($scaling_factor == 1){
	for($jj=0; $jj<3; $jj++) {
		$MOD_MAIN_SIZE[$jj] = $MAIN_SIZE[$jj] % 2 ;
		$even_size = $even_size + $MOD_MAIN_SIZE[$jj] ;
	}
}
else{
	for($jj=0; $jj<3; $jj++) {
		$ORIG_SIZE[$jj] = $TEMPLATE_SIZE[0][$jj] ;
		$NEW_SIZE[$jj]  = ceil($TEMPLATE_SIZE[0][$jj] * $scaling_factor); 
		$NEW_SIZE[$jj]  = $NEW_SIZE[$jj] + ($NEW_SIZE[$jj] % 2);
	}
}

if($even_size==0){
	if($scaling_factor == 1){
	print "No padding neccessary\n";
	}
	else{
	print "data is being downsampled \n";
	}
}
else {
	print "data is being padded \n";
}

for($i=0; $i<$channel_number; $i++) { for($jj=0; $jj<3; $jj++) { print "$TEMPLATE_SIZE[$i][$jj] \t"; } print "\n"; }
for($i=0; $i<$channel_number; $i++) { for($jj=0; $jj<3; $jj++) { print "$TARGET_SIZE[$i][$jj] \t"; } print "\n"; }
for($jj=0; $jj<3; $jj++) { print "$ORIG_SIZE[$jj] \t"; } print "\n"; 
for($jj=0; $jj<3; $jj++) { print "$NEW_SIZE[$jj] \t"; } print "\n"; 
if($even_size>0){
	for($i=0; $i<$channel_number; $i++) {
		$temp1 = "$output_folder/imgfiles/$shorttemplateimglist[$i]";
		$sim1 = `$IMG_pad_ver02 $temp1 $temp1 0 0 0 $MOD_MAIN_SIZE[0] $MOD_MAIN_SIZE[1] $MOD_MAIN_SIZE[2]`;
		$temp1 = "$output_folder/imgfiles/$shorttargetimglist[$i]";
		$sim1 = `$IMG_pad_ver02 $temp1 $temp1 0 0 0 $MOD_MAIN_SIZE[0] $MOD_MAIN_SIZE[1] $MOD_MAIN_SIZE[2]`;
	}
}
else{
	if($scaling_factor < 1){
		for($i=0; $i<$channel_number; $i++) {
		$j = $scaling_factor;
		$temp1 = "$output_folder/imgfiles/$shorttemplateimglist[$i]";
		$sim1 = `$IMG_resample1 $temp1 $temp1 $j $j $j $NEW_SIZE[0] $NEW_SIZE[1] $NEW_SIZE[2] $interpolationtype`;
		$temp1 = "$output_folder/imgfiles/$shorttargetimglist[$i]";
		$sim1 = `$IMG_resample1 $temp1 $temp1 $j $j $j $NEW_SIZE[0] $NEW_SIZE[1] $NEW_SIZE[2] $interpolationtype`;
		}
	}
}



for($i=0; $i<$channel_number; $i++) {
	$j = $i +1;
#new lists
	$currentshorttargetimglist[$i] = $shorttargetimglist[$i];
        $temp1 = "_target_$j\.img";
        $temp2 = "_curtarget_$j\.img";
        $currentshorttargetimglist[$i] =~ s/$temp1/$temp2/g ;
#       $currentshorttargetimglist[$i] =~ s/_target.img/_curtarget.img/g ;

	$currentshorttargethdrlist[$i] = $shorttargethdrlist[$i];
        $temp1 = "_target_$j\.hdr";
        $temp2 = "_curtarget_$j\.hdr";
        $currentshorttargethdrlist[$i] =~ s/$temp1/$temp2/g ;
#        $currentshorttargethdrlist[$i] =~ s/_target.hdr/_curtarget.hdr/g ;

	$currentshorttemplateimglist[$i] = $shorttemplateimglist[$i];
        $temp1 = "_template_$j\.img";
        $temp2 = "_curtemplate_$j\.img";
        $currentshorttemplateimglist[$i] =~ s/$temp1/$temp2/g ;
#        $currentshorttemplateimglist[$i] =~ s/_template.img/_curtemplate.img/g ;

	$currentshorttemplatehdrlist[$i] = $shorttemplatehdrlist[$i];
        $temp1 = "_template_$j\.hdr";
        $temp2 = "_curtemplate_$j\.hdr";
        $currentshorttemplatehdrlist[$i] =~ s/$temp1/$temp2/g ;
#        $currentshorttemplatehdrlist[$i] =~ s/_template.hdr/_curtemplate.hdr/g ;

	$temp1 = "$output_folder/imgfiles/$shorttemplateimglist[$i]";
	$sim1 = `cp $temp1 $output_folder/imgfiles/$currentshorttemplateimglist[$i]`;
	$temp1 = "$output_folder/imgfiles/$shorttemplatehdrlist[$i]";
	$sim1 = `cp $temp1 $output_folder/imgfiles/$currentshorttemplatehdrlist[$i]`;
	$temp1 = "$output_folder/imgfiles/$shorttargetimglist[$i]";
	$sim1 = `cp $temp1 $output_folder/imgfiles/$currentshorttargetimglist[$i]`;
	$temp1 = "$output_folder/imgfiles/$shorttargethdrlist[$i]";
	$sim1 = `cp $temp1 $output_folder/imgfiles/$currentshorttargethdrlist[$i]`;
	
#	print "$templatefilelist[$i]\n";
#	print "$templatehdrlist[$i]\n";
# 	print "$shorttemplateimglist[$i]\n";
# 	print "$shorttemplatehdrlist[$i]\n";
# 	print "$currentshorttemplateimglist[$i]\n";
# 	print "$currentshorttemplatehdrlist[$i]\n";
# 	print "$targetfilelist[$i]\n";
# 	print "$targethdrlist[$i]\n";
# 	print "$shorttargetimglist[$i]\n";
# 	print "$shorttargethdrlist[$i]\n";
# 	print "$currentshorttargetimglist[$i]\n";
# 	print "$currentshorttargethdrlist[$i]\n";
# 	print "$sigmalist[$i]\n";
}






print "\n";
print "**************************************************************************\n";
print "*                                 STEP-3                                 *\n";
print "**************************************************************************\n";
print "lddmm \n";
print "\n";

#STEP-2
#changing directory to output folder
$current_folder = `pwd`;
chdir $output_folder if $output_folder;
$sim3 = `pwd`;

#setting thread number
#        $ENV{OMP_NUM_THREADS} = '4';

        $startfile = "startdate.txt";
        $endfile   = "enddate.txt";
        $stdfile   = "stdout.txt";


        $sim1 = `date > "$startfile"`;



for($j=0; $j<$channel_number; $j++) {
	$currentshorttargetimg[$j] = "./imgfiles/$currentshorttargetimglist[$j]";
	$currentshorttemplateimg[$j] = "./imgfiles/$currentshorttemplateimglist[$j]";
}


#mm_lddmm
for($i=0; $i<$iteration_number; $i++) {
	$j = $i + 1;
        $Hfile = "Hmap\_00$j.vtk";
        $Kfile = "Kimap\_00$j.vtk";
print "\titeration no:	$j\n";

#print "$startfile\n";
#print "$endfile\n";
#print "$stdfile\n";
#print "$Hfile\n";
#print "$Kfile\n";



#STEP-3
#mappings in the new directory

	$parameters1 = "$channel_number img";
	$parameters2 = "";
	for($j=0; $j<$channel_number; $j++) {
		if($j == 0) {
			$parameters2 = "$parameters2$currentshorttemplateimg[$j] $currentshorttargetimg[$j] $sigmalist[$j]";	
		}
		else {
			$parameters2 = "$parameters2 $currentshorttemplateimg[$j] $currentshorttargetimg[$j] $sigmalist[$j]";	
		}
	}
	if($i == 0) {
                # leebc - changed epsilon from 1e-10 to 1e-11 to 5e-13
		$parameters3 =  "1000 $timesteplist[$i] $deltalist[$i] 0.0000000000005 $alphalist[$i] 1 1 1000 0 0.02 25"
	}
	else {
		$parameters3 =  "1000 $timesteplist[$i] $deltalist[$i] 0.0000000000005 $alphalist[$i] 1 1 1000 0 0.02 25"
	}
	$parameters = "$parameters1 $parameters2 $parameters3";
#print "$parameters\n";

        if($i == 0) {
                $sim1 = `$MM_LDDMM $parameters > $stdfile`;
        }
        else {
                $sim1 = `$MM_LDDMM $parameters >> $stdfile`;
        }


	$sim1 = `cp Kimap000.vtk $Kfile`;
	$sim1 = `cp Hmap000.vtk $Hfile`;

#STEP-4
#transformation of current target img file with the calculated transformation files
        for($j=0; $j<$channel_number; $j++) {
                $k = $i + 1;
                if($j == 1) {
                    # leebc - set interpolation to nearest neighbor for 2nd channel
                    $parameters3 = "$currentshorttargetimg[$j] ./$Kfile $currentshorttargetimg[$j] 2";
                }
                else {
                    $parameters3 = "$currentshorttargetimg[$j] ./$Kfile $currentshorttargetimg[$j] $interpolationtype";
                }
		#$parameters3 = "$currentshorttargetimg[$j] ./$Kfile $currentshorttargetimg[$j] $interpolationtype";
		$sim1 = `$IMG_TRANSFORM $parameters3`;
	}

}



print "\n";
print "**************************************************************************\n";
print "*                                 STEP-4                                 *\n";
print "**************************************************************************\n";
print "combining transformation files \n";
print "\n";


#STEP-5
#combining transformation files
if($iteration_number > 1) {
for($i=1; $i<$iteration_number; $i++) {
	$j = $i +1;
        $Kfile1 = "Kimap\_00$i.vtk";
        $Kfile2 = "Kimap\_00$j.vtk";
	$sim1 = `$VTK_combine_maps_ver5 2 $Kfile2 $Kfile1 $Kfile2`;
        $Hfile1 = "Hmap\_00$i.vtk";
        $Hfile2 = "Hmap\_00$j.vtk";
	$sim1 = `$VTK_combine_maps_ver5 2 $Hfile1 $Hfile2 $Hfile2`;
}
}

        $i = $iteration_number;
        $Kfile1 = "Kimap\_00$i.vtk";
        $Kfile2 = "Kimap000.vtk";
        $sim1 = `cp $Kfile1 $Kfile2`;
        $Hfile1 = "Hmap\_00$i.vtk";
        $Hfile2 = "Hmap000.vtk";
        $sim1 = `cp $Hfile1 $Hfile2`;

if($even_size>0){
	print "padding removed from deformation files \n";
        $temp1 = "Kimap000.vtk";
        $sim1 = `$VTK_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
        $temp1 = "Hmap000.vtk";
        $sim1 = `$VTK_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
}
else{
	if($scaling_factor < 1){
	print "upsampling deformation files \n";
	$j = 1.0 / $scaling_factor;
        $temp1 = "Kimap000.vtk";
        $sim1 = `$VTK_resample2 $temp1 $temp1 $j $j $j $ORIG_SIZE[0] $ORIG_SIZE[1] $ORIG_SIZE[2] 1`;
        $temp1 = "Hmap000.vtk";
        $sim1 = `$VTK_resample2 $temp1 $temp1 $j $j $j $ORIG_SIZE[0] $ORIG_SIZE[1] $ORIG_SIZE[2] 1`;
	}
}
if($outputlevel<2){
	for($i=1; $i<=$iteration_number; $i++) {
        	$Kfile1 = "Kimap\_00$i.vtk";
	        $sim1 = `rm $Kfile1`;
        	$Hfile1 = "Hmap\_00$i.vtk";
	        $sim1 = `rm $Hfile1`;
	}
}
else {
if($even_size>0){
	print "padding removed from deformation files \n";
	for($i=1; $i<=$iteration_number; $i++) {
       	$temp1 = "Kimap\_00$i.vtk";
        $sim1 = `$VTK_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
       	$temp1 = "Hmap\_00$i.vtk";
        $sim1 = `$VTK_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
	}
}
else{
	if($scaling_factor < 1){
	print "upsampling deformation files \n";
	$j = 1.0 / $scaling_factor;
	for($i=1; $i<=$iteration_number; $i++) {
        $temp1 = "Kimap\_00$i.vtk";
        $sim1 = `$VTK_resample2 $temp1 $temp1 $j $j $j $ORIG_SIZE[0] $ORIG_SIZE[1] $ORIG_SIZE[2] 1`;
        $temp1 = "Hmap\_00$i.vtk";
        $sim1 = `$VTK_resample2 $temp1 $temp1 $j $j $j $ORIG_SIZE[0] $ORIG_SIZE[1] $ORIG_SIZE[2] 1`;
	}
	}
}
}


for($j=0; $j<$channel_number; $j++) {
	$temp1 = "./$shorttemplateimglist[$j]";
	$temp2 = "./imgfiles/$shortnewtemplateimglist[$j]";
	$sim1 = `mv $temp1 $temp2`;
#print "$sim1\n";
	$temp1 = "./$shorttargetimglist[$j]";
	$temp2 = "./imgfiles/$shortnewtargetimglist[$j]";
	$sim1 = `mv $temp1 $temp2`;
	$temp1 = "./$shorttemplatehdrlist[$j]";
	$temp2 = "./imgfiles/$shortnewtemplatehdrlist[$j]";
	$sim1 = `mv $temp1 $temp2`;
	$temp1 = "./$shorttargethdrlist[$j]";
	$temp2 = "./imgfiles/$shortnewtargethdrlist[$j]";
	$sim1 = `mv $temp1 $temp2`;
}



if($outputlevel==3){
print "\n";
print "**************************************************************************\n";
print "*                                 STEP-5                                 *\n";
print "**************************************************************************\n";
print "deformation of image files \n";
print "\n";

#if($even_size>0){
#print "padding is being removed from image files\n";
#        for($j=0; $j<$channel_number; $j++) {
#		$temp1 = "./imgfiles/$shorttemplateimglist[$j]";
#	        $sim1 = `$IMG_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
#        print "$sim1\n";
#		$temp1 = "./imgfiles/$shorttargetimglist[$j]";
#	        $sim1 = `$IMG_pad_ver02 $temp1 $temp1 0 0 0 -$MOD_MAIN_SIZE[0] -$MOD_MAIN_SIZE[1] -$MOD_MAIN_SIZE[2]`;
#        print "$sim1\n";
#	}
#}
for($i=0; $i<$iteration_number; $i++) {
        $k = $i + 1;
        $Hfile = "Hmap\_00$k.vtk";
        $Kfile = "Kimap\_00$k.vtk";

        for($j=0; $j<$channel_number; $j++) {
	        $jj = $j + 1;
		$shortnewtemplateimglist[$j] = $shorttemplateimglist[$j];
	        $temp1 = "_template_$jj\.img";
        	$temp2 = "_template_$jj\_$k\.img";
        	$shortnewtemplateimglist[$j] =~ s/$temp1/$temp2/g ;
#		$shortnewtemplateimglist[$j]  =~ s/_template.img/_deftemplate\_00$k.img/g ;

		$shortnewtargetimglist[$j] = $shorttargetimglist[$j];
	        $temp1 = "_target_$jj\.img";
        	$temp2 = "_target_$jj\_$k\.img";
        	$shortnewtargetimglist[$j] =~ s/$temp1/$temp2/g ;
#		$shortnewtargetimglist[$j]  =~ s/_target.img/_deftarget\_00$k.img/g ;

#		print "$shortnewtemplateimglist[$j] \n";
#		print "$shortnewtargetimglist[$j] \n";

                $parameters3 = "./imgfiles/$shorttemplateimglist[$j] ./$Hfile ./imgfiles/$shortnewtemplateimglist[$j] $interpolationtype";
#                $parameters3 = "./$shorttemplateimglist[$j] ./$Hfile ./imgfiles/$shortnewtemplateimglist[$j] $interpolationtype";
                $sim1 = `$IMG_TRANSFORM $parameters3`;
#print "$sim1\n";
                $parameters3 = "./imgfiles/$shorttargetimglist[$j] ./$Kfile ./imgfiles/$shortnewtargetimglist[$j] $interpolationtype";
#                $parameters3 = "./$shorttargetimglist[$j] ./$Kfile ./imgfiles/$shortnewtargetimglist[$j] $interpolationtype";
                $sim1 = `$IMG_TRANSFORM $parameters3`;
#print "$sim1\n";
#print "$can\n";
	}
}
}

if($outputlevel<3){ 
       $sim1 = `rm ./imgfiles/*`;
       $sim1 = `rmdir imgfiles`;
       $sim1 = `rm -R -f imgfiles`;
}

        $sim1 = `rm -f Movie*`;
        $sim1 = `rm -f *Velocity*`;

if($channel_number == 1){
	$sim1 = `rm gradI0000.vtk`;
	$sim1 = `rm Atlas000.vtk`;
	$sim1 = `rm defAtlas000.vtk`;
	$sim1 = `rm Patient000.vtk`;
	$sim1 = `rm defPatient000.vtk`;
	$sim1 = `rm Atlas.img`;
	$sim1 = `rm Atlas.hdr`;
	$sim1 = `rm defAtlas.img`;
	$sim1 = `rm defAtlas.hdr`;
	$sim1 = `rm Patient.img`;
	$sim1 = `rm Patient.hdr`;
	$sim1 = `rm defPatient.img`;
	$sim1 = `rm defPatient.hdr`;
}

        $sim1 = `date > "$endfile"`;

$ENDTIME1=`date +%s`;
$DIFFTIME1=$ENDTIME1 - $STARTTIME1;

print "\n";
print "...Completed\n";
print "Total running time is $DIFFTIME1 seconds\n";
print "\n";

#my $endtime = time();
#my $totaltime = floor(1000 * ($endtime - $starttime) / 60)/1000;
#print "\n";
#print "...Completed\n";
#print "Total running time is $totaltime minutes\n";
#print "\n";


sub read_BIN_SCRIPTS_directory{
        my($SCRIPTS_BIN_DIRECTORY_FILENAME)    = $_[0];
        open(DAT, $SCRIPTS_BIN_DIRECTORY_FILENAME) || die("Could not open directory file!");               @params1=<DAT>;        close(DAT);

        $i=0;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $BIN_DIRECTORY = $temp1[0];
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $SCRIPTS_DIRECTORY = $temp1[0];
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $AIR_BIN_DIRECTORY = $temp1[0];

print "BIN_DIRECTORY              : $BIN_DIRECTORY\n";
print "SCRIPTS_DIRECTORY          : $SCRIPTS_DIRECTORY\n";
print "AIR_BIN_DIRECTORY          : $AIR_BIN_DIRECTORY\n";
print "\n\n";

}



