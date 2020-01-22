#!/usr/bin/perl

###################################################################################################
################################ INPUTS TO THIS SCRIPT ############################################
###################################################################################################
#
####### USAGES ########
#	(1) dtipipeline_MA_ver01.pl atlas_filelist.txt other_params.txt
#

use Time::HiRes qw( time );
use POSIX;
my $starttime = time();

use File::Basename;
my $dirname = dirname(__FILE__);
$SCRIPTS_BIN_DIRECTORY_FILENAME = "$dirname\/bin_scripts_directory.txt";
read_BIN_SCRIPTS_directory($SCRIPTS_BIN_DIRECTORY_FILENAME);




print "*************************************************\n";
print "*********************STEP1***********************\n";
print "*************************************************\n\n";
#Printing input arguments and checking inputs and outputs
print "Printing input arguments and checking inputs and outputs\n";
        print "\nNumber of input arguments = \n";
        print "\t$no_of_inputs\n";
        print "Parameters = \n";
        for($i=0; $i<=$#ARGV; $i++) {
                print "\t$i = $ARGV[$i]\n";
        }
        print "\n";

#READING INPUTS
$no_of_inputs = $#ARGV + 1;
if ( $no_of_inputs < 2 ){        print "\n\tERROR: Wrong number of inputs\n";        print "EXITING...\n";        exit;}

#Reading input param file
$ATLAS_PARAM_FILE = $ARGV[0];
$SUBJECT_PARAM_FILE = $ARGV[1];	

#read_parameter_file_format($INPUT_PARAM_FILE);	
exit;	
if($PARAMETER_FILE_FORMAT == 1) {
#	read_atlas_parameter_file1($INPUT_PARAM_FILE);
#check_print_parameters1();
}
else {
	
}
	

my $endtime = time();
my $totaltime = floor(1000 * ($endtime - $starttime) / 60)/1000;


print "Total running time is $totaltime minutes\n";

exit;




$USE_ORIGINAL_FNAMES_TRUE = 0 ;	
$DO_LDDMM_TRUE 			  = 1;


#executables used
$IMG_change_raw2analyze			= "$BIN_DIRECTORY\/IMG_change_raw2analyze";
$IMG_mask				= "$BIN_DIRECTORY\/IMG_mask";
$maskTensorImg				= "$BIN_DIRECTORY\/maskTensorImg";
$IMG_saveimgsize_resolution		= "$BIN_DIRECTORY\/IMG_saveimgsize_resolution";
$IMG_saveimgsize		        = "$BIN_DIRECTORY\/IMG_saveimgsize";
$IMG_saveimgformat		        = "$BIN_DIRECTORY\/IMG_saveimgformat";
$IMG_resample1          		= "$BIN_DIRECTORY\/IMG_resample1";
$resampletensor         	 	= "$BIN_DIRECTORY\/resampletensor";
$resampletensor1      	    		= "$BIN_DIRECTORY\/resampletensor1";
$maptensors          			= "$BIN_DIRECTORY\/maptensors";
$maptensors_air        			= "$BIN_DIRECTORY\/maptensors_air";
$maptensors_air1        	 	= "$BIN_DIRECTORY\/maptensors_air1";
$calceigensystem1       		= "$BIN_DIRECTORY\/calceigensystem1";

$SkullStripOneImage			= "$BIN_DIRECTORY\/SkullStripOneImage_3";
$changeTensorImgType			= "$BIN_DIRECTORY\/changeTensorImgType";
$IMG_flip	          		= "$BIN_DIRECTORY\/IMG_flip";
$VTK_flip	          		= "$BIN_DIRECTORY\/VTK_flip";

$IMG_histmatch4				= "$BIN_DIRECTORY\/IMG_histmatch4";
$IMG_apply_lddmm_tform2label		= "$BIN_DIRECTORY\/IMG_apply_lddmm_tform2label1";
$IMG_apply_AIR_tform			= "$BIN_DIRECTORY\/IMG_apply_AIR_tform1";
$IMG_apply_lddmm_tform			= "$BIN_DIRECTORY\/IMG_apply_lddmm_tform1";
$combine_AIR_Hmap			= "$BIN_DIRECTORY\/combine_AIR_Hmap";
$combine_AIR_Kimap              	= "$BIN_DIRECTORY\/combine_AIR_Kimap1";

$IMG_normalization2float1		= "$BIN_DIRECTORY\/IMG_normalization2float1";
$IMG_normalization2float2		= "$BIN_DIRECTORY\/IMG_normalization2float2";

$IMG_calc_label_stats			= "$BIN_DIRECTORY\/IMG_calc_label_stats";

#scripts used
$AIR_registration1_1024         	= "$SCRIPTS_DIRECTORY\/AIR_registration2_1024.pl";
$mm_lddmm1				= "$SCRIPTS_DIRECTORY\/mm_lddmm1n.pl";
$mm_lddmm2				= "$SCRIPTS_DIRECTORY\/mm_lddmm2n.pl";



$no_of_inputs = $#ARGV + 1;

#initialize_parameters();
#check_print_parameters();


#Reading input param file
	$INPUT_PARAM_FILE = $ARGV[0];
	read_parameter_file_format($INPUT_PARAM_FILE);	
	
	if($PARAMETER_FILE_FORMAT == 1) {
		read_parameter_file1($INPUT_PARAM_FILE);
		check_print_parameters1();
	}
	else {
	
	}

#$USE_ORIGINAL_FNAMES_TRUE = 0 ;	

print "*************************************************\n";
print "*********************STEP2***********************\n";
print "*************************************************\n\n";
#Creating output directory and subdirectories copying files 
#Making any necessary format changes (scalar raw data -> analyze, tensor format -> 2  )


	$sim1 = `mkdir "$OUTPUT_FOLDER"`;
#Changing current directory to $OUTPUT_FOLDER
	chdir $OUTPUT_FOLDER if $OUTPUT_FOLDER;
	$output_path = $OUTPUT_FOLDER;

#creating output subdirectories
print "Creating output directory and subdirectories\n";
	create_main_subdirectories();
	create_other_subdirectories();

#removing paths from filenames
	remove_paths_from_filenames();


	
	
#copying files
print "Copying files\n";
	copy_channel_data_1();
	copy_other_data_1();
	

#changing formats to analyze if necessary
print "Changing format of data\n\n";
	formatchange_channel_data();
	formatchange_other_data();


#creating tensor trace for lddmm ch1
print "Calculating subject and/or atlas tensor traces if necessary\n\n";
	create_tensor_trace_4_lddmm_1();	
	


print "*************************************************\n";
print "*********************STEP3***********************\n";
print "*************************************************\n\n";
#If necessary creating a mask and masking subject data
print "Calculate a subject mask image if necessary\n\n";
	create_subject_mask_file();


print "Masking subject data\n\n";
	mask_channel_data();
	mask_other_data();

print "*************************************************\n";
print "*********************STEP4***********************\n";
print "*************************************************\n\n";
#resampling subject data onto atlas
print "Resampling subject data onto atlas\n\n";
	resample_data();

print "*************************************************\n";
print "*********************STEP5***********************\n";
print "*************************************************\n\n";
#air lddmm
print "Calculating air and lddmm\n\n";
	calculate_air();	
	calculate_histmatching();
	calculate_lddmm();



print "*************************************************\n";
print "*********************STEP6***********************\n";
print "*************************************************\n\n";
#moving and organizing data
print "Moving and organizing data\n\n";
#	move_organize_data();	

print "*************************************************\n";
print "*********************STEP7***********************\n";
print "*************************************************\n\n";
#calculating deformations
print "Calculating deformations\n\n";
	calculate_deformations();

print "*************************************************\n";
print "*********************STEP8***********************\n";
print "*************************************************\n\n";
#processing intermediate lddmm data
print "Processing intermediate lddmm data\n\n";
	process_intermediate_lddmm();

	calculate_atlas_ROI_stats_on_subject();



my $endtime = time();
my $totaltime = floor(1000 * ($endtime - $starttime) / 60)/1000;


print "Total running time is $totaltime minutes\n";












sub read_atlas_parameter_file1{

	my($INPUT_PARAM_FILE)    = $_[0];
	print "INPUT PARAMETER FILE              : $INPUT_PARAM_FILE\n";
	open(DAT, $INPUT_PARAM_FILE) || die("Could not open param file!");        @params1=<DAT>;        close(DAT);

	$search_string = "PARAMETER_FILE_FORMAT";	 
	my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
	$PARAMETER_FILE_FORMAT = $temp1[0];

$search_string = "OUTPUT_FOLDER";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
        $OUTPUT_FOLDER = $temp1[0];

$search_string = "DO_SUBJECT_SKULLSTRIP_TRUE";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
        $DO_SUBJECT_SKULLSTRIP_TRUE = $temp1[0];

if($DO_SUBJECT_SKULLSTRIP_TRUE==1 || $DO_SUBJECT_SKULLSTRIP_TRUE==2 || $DO_SUBJECT_SKULLSTRIP_TRUE==3){
	$temp = $params1[$i];   $i=$i+1;                chomp $temp;    @temp1 = split(' ',$temp);
        $SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]	= $temp1[0];
	$SUBJECT_SKULLSTRIP_FILENAME[0]		= $temp1[1];
	$temp = $params1[$i];   $i=$i+1;                chomp $temp;    @temp1 = split(' ',$temp);
	$SKULLSTRIPPING_W5_PARAM 		= $temp1[0];
}
else{
	$DO_SUBJECT_SKULLSTRIP_TRUE=0;
}

$search_string = "DO_AIR_TRUE";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
        $DO_AIR_TRUE = $temp1[0];
if($DO_AIR_TRUE==1 || $DO_AIR_TRUE==2){
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
        $SUBJECT_AIR_FILENAME_FORMAT[0] 	= $temp1[0];
        $SUBJECT_AIR_FILENAME[0]        	= $temp1[1];
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
        $ATLAS_AIR_FILENAME_FORMAT[0]		= $temp1[0];
        $ATLAS_AIR_FILENAME[0]			= $temp1[1];
}
else{
        $DO_AIR_TRUE=0;
}


$search_string = "LDDMM_PARAMETERS";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
#my $index1 = first_index { /LDDMM_PARAMETERS/ }		@params1;	$i=$index1+1;
#	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
#        $DO_LDDMM_TRUE = $temp1[0];
	$DO_LDDMM_TRUE =1;

        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $LDDMM_OUTPUT_LEVEL 			= $temp1[0];

	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$lddmm_cascading_iteration_type = $temp1[0];

	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$lddmm_cascading_iteration_number = $temp1[0];

        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($k=0; $k<$lddmm_cascading_iteration_number; $k++) {	$lddmm_alphalist[$k]=$temp1[$k];	}

        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($k=0; $k<$lddmm_cascading_iteration_number; $k++) { $lddmm_timesteplist[$k]=$temp1[$k];	}

	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$CHANNEL_NO = $temp1[0];

	for($k=0; $k<$CHANNEL_NO; $k++) {
	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$SUBJECT_CHANNEL_FILENAME_FORMAT[$k]	= $temp1[0];	
	$SUBJECT_CHANNEL_FILENAME[$k]		= $temp1[1];
	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$ATLAS_CHANNEL_FILENAME_FORMAT[$k]	= $temp1[0];
	$ATLAS_CHANNEL_FILENAME[$k]		= $temp1[1];
	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$lddmm_sigma[$k] 			= $temp1[0];
	$temp = $params1[$i];	$i=$i+1;	chomp $temp;	@temp1 = split(' ',$temp);
	$lddmm_histmatch_true[$k]		= $temp1[0];
	}

$search_string = "SUBJECT_SIZERES_GIVEN";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$SUBJECT_SIZERES_GIVEN = $temp1[0];
if($SUBJECT_SIZERES_GIVEN==1){
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($k=0; $k<3; $k++) {	$INPUT_SUBJECT_SIZE[$k]=$temp1[$k];	}
        for($k=0; $k<3; $k++) {	$j=$k+3;	$INPUT_SUBJECT_RES[$k]=$temp1[$j];	}
}
else{
	$SUBJECT_SIZERES_GIVEN=0;
}


$search_string = "ATLAS_SIZERES_GIVEN";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$ATLAS_SIZERES_GIVEN = $temp1[0];
if($ATLAS_SIZERES_GIVEN==1){
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($k=0; $k<3; $k++) {	$INPUT_ATLAS_SIZE[$k]=$temp1[$k];	}
        for($k=0; $k<3; $k++) {	$j=$k+3;	$INPUT_ATLAS_RES[$k]=$temp1[$j];	}
}
else{
	$ATLAS_SIZERES_GIVEN=0;
}


$search_string = "ANALYZE_Y_FLIPPING_TRUE";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $ANALYZE_Y_FLIPPING_TRUE = $temp1[0];


$search_string = "SUBJECT_TENSOR_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $SUBJECT_TENSOR_GIVEN = $temp1[0];
	if($SUBJECT_TENSOR_GIVEN==1){
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$SUBJECT_TENSOR_FILENAME_FORMAT = $temp1[0];
		$SUBJECT_TENSOR_FILENAME 	= $temp1[1];
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$SUBJECT_TENSOR_OUTPUT_LEVEL = $temp1[0];
	}

$search_string = "SUBJECT_GRAYSCALE_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $SUBJECT_GRAYS_GIVEN = $temp1[0];
	if($SUBJECT_GRAYS_GIVEN>0){
	        for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {	
        	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$SUBJECT_GRAYS_FILENAME_FORMAT[$k]	= $temp1[0];
		$SUBJECT_GRAYS_FILENAME[$k] 		= $temp1[1];
		}
	}

$search_string = "SUBJECT_LABEL_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $SUBJECT_LABEL_GIVEN = $temp1[0];
	if($SUBJECT_LABEL_GIVEN>0){
	        for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {	
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$SUBJECT_LABEL_FILENAME_FORMAT[$k]	= $temp1[0];
		$SUBJECT_LABEL_FILENAME[$k]		= $temp1[1];
		}
	}

$search_string = "ATLAS_TENSOR_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $ATLAS_TENSOR_GIVEN = $temp1[0];
	if($ATLAS_TENSOR_GIVEN==1){
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$ATLAS_TENSOR_FILENAME_FORMAT	= $temp1[0];
		$ATLAS_TENSOR_FILENAME		= $temp1[1];
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$ATLAS_TENSOR_OUTPUT_LEVEL = $temp1[0];
	}

$search_string = "ATLAS_GRAYSCALE_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $ATLAS_GRAYS_GIVEN = $temp1[0];
	if($ATLAS_GRAYS_GIVEN>0){
	        for($k=0; $k<$ATLAS_GRAYS_GIVEN; $k++) {	
        	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$ATLAS_GRAYS_FILENAME_FORMAT[$k]	= $temp1[0];
		$ATLAS_GRAYS_FILENAME[$k]		= $temp1[1];
		}
	}

$search_string = "ATLAS_LABEL_DATA";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $ATLAS_LABEL_GIVEN = $temp1[0];
	if($ATLAS_LABEL_GIVEN>0){
	        for($k=0; $k<$ATLAS_LABEL_GIVEN; $k++) {	
	        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
		$ATLAS_LABEL_FILENAME_FORMAT[$k]	= $temp1[0];
		$ATLAS_LABEL_FILENAME[$k]		= $temp1[1];
		}
	}

$search_string = "USERNAME";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $USERNAME = $temp1[0];
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        $USEREMAIL = $temp1[0];

$search_string = "USE_ORIGINAL_FILENAMES";	 
my $index1 = find_stringindex_instringarray($search_string,\@params1);	
if($index1!=-1){
	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$USE_ORIGINAL_FNAMES_TRUE = $temp1[0];
}

						
}


sub find_stringindex_instringarray(){
	my($search_string)	= $_[0];
	my($params1ref) 	= $_[1];
	my(@params1)	= @$params1ref ; 

	my $found_index = -1;
	for($j=0; $j<=$#params1; $j++) {
		$temp1 = $params1[$j];
		my $result = index($temp1, $search_string);
		if ($result>-1){
			$found_index = $j;
			last;
		}
	}
	return $found_index;
}

sub read_BIN_SCRIPTS_directory{
	my($SCRIPTS_BIN_DIRECTORY_FILENAME)    = $_[0];
	open(DAT, $SCRIPTS_BIN_DIRECTORY_FILENAME) || die("Could not open directory file!");        @params1=<DAT>;        close(DAT);

	$i=0;
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$BIN_DIRECTORY = $temp1[0];
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$SCRIPTS_DIRECTORY = $temp1[0];
	$temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
	$AIR_BIN_DIRECTORY = $temp1[0];

	print "\n";
	print "BIN_DIRECTORY              : $BIN_DIRECTORY\n";
	print "SCRIPTS_DIRECTORY          : $SCRIPTS_DIRECTORY\n";
	print "AIR_BIN_DIRECTORY          : $AIR_BIN_DIRECTORY\n";
	print "\n";
}



















sub calculate_atlas_ROI_stats_on_subject{
	if($ATLAS_LABEL_GIVEN > 0){
#native space orginal subject size resolution
		$subject_path		= $subdirectory2  ;
		$label_path			= $subdirectory2  ;
		$stats_file_path	= $output_path ;			 
		
		$params1 = "";
		$count = 0;		
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$subject_path/$short_subject_channel[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
		}	
		if($SUBJECT_GRAYS_GIVEN > 0){
			for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {		
			$temp1 = "$subject_path/$s_other/$short_subject_grays[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
			}
		}	
		if($SUBJECT_TENSOR_GIVEN == 1 && $SUBJECT_TENSOR_OUTPUT_LEVEL==2){
			$temp1 = "$subject_path/$s_tensor/$short_subject_tensor\.trace.img";
			$temp2 = "$subject_path/$s_tensor/$short_subject_tensor\.fa.img";			
			$temp3 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval1.img";
			$temp4 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval2.img";			
			$temp5 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval3.img";						
			$params1 = "$params1 $temp1 $temp2 $temp3 $temp4 $temp5";
        	$count = $count + 5;			
		}
			
		for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
			$j = $i +1;
			$label_file = "$label_path/$a_other/$short_atlas_label[$i]\.img";
			$stats_file = "$stats_file_path\/sub_roi_stats_native_$j\.txt";	
			$params2 =  "$label_file $stats_file $count $params1"; 		
			$sim1 = `$IMG_calc_label_stats $params2`;			
		}		
		
#after resampling to atlas
		$subject_path		= $subdirectory3  ;
		$label_path			= $subdirectory3  ;
		$stats_file_path	= $output_path ;			 
		
		$params1 = "";
		$count = 0;		
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$subject_path/$short_subject_channel[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
		}	
		if($SUBJECT_GRAYS_GIVEN > 0){
			for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {		
			$temp1 = "$subject_path/$s_other/$short_subject_grays[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
			}
		}	
		if($SUBJECT_TENSOR_GIVEN == 1 && $SUBJECT_TENSOR_OUTPUT_LEVEL==2){
			$temp1 = "$subject_path/$s_tensor/$short_subject_tensor\.trace.img";
			$temp2 = "$subject_path/$s_tensor/$short_subject_tensor\.fa.img";			
			$temp3 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval1.img";
			$temp4 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval2.img";			
			$temp5 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval3.img";						
			$params1 = "$params1 $temp1 $temp2 $temp3 $temp4 $temp5";
        	$count = $count + 5;			
		}
			
		for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
			$j = $i +1;
			$label_file = "$label_path/$a_other/$short_atlas_label[$i]\.img";
			$stats_file = "$stats_file_path\/sub_roi_stats_resampled_$j\.txt";	
			$params2 =  "$label_file $stats_file $count $params1"; 		
			$sim1 = `$IMG_calc_label_stats $params2`;			
		}		

#after air
		$subject_path		= $subdirectory4  ;
		$label_path			= $subdirectory4  ;
		$stats_file_path	= $output_path ;			 
		
		$params1 = "";
		$count = 0;		
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$subject_path/$short_subject_channel[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
		}	
		if($SUBJECT_GRAYS_GIVEN > 0){
			for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {		
			$temp1 = "$subject_path/$s_other/$short_subject_grays[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
			}
		}	
		if($SUBJECT_TENSOR_GIVEN == 1 && $SUBJECT_TENSOR_OUTPUT_LEVEL==2){
			$temp1 = "$subject_path/$s_tensor/$short_subject_tensor\.trace.img";
			$temp2 = "$subject_path/$s_tensor/$short_subject_tensor\.fa.img";			
			$temp3 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval1.img";
			$temp4 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval2.img";			
			$temp5 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval3.img";						
			$params1 = "$params1 $temp1 $temp2 $temp3 $temp4 $temp5";
        	$count = $count + 5;			
		}
			
		for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
			$j = $i +1;
			$label_file = "$label_path/$a_other/$short_atlas_label[$i]\.img";
			$stats_file = "$stats_file_path\/sub_roi_stats_air_$j\.txt";	
			$params2 =  "$label_file $stats_file $count $params1"; 		
			$sim1 = `$IMG_calc_label_stats $params2`;			
		}		

#after lddmm
		$subject_path		= $subdirectory6  ;
		$label_path			= $subdirectory1  ;
		$stats_file_path	= $output_path ;			 
		
		$params1 = "";
		$count = 0;		
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$subject_path/$short_subject_channel[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
		}	
		if($SUBJECT_GRAYS_GIVEN > 0){
			for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {		
			$temp1 = "$subject_path/$s_other/$short_subject_grays[$i]\.img";		
			$params1 = "$params1 $temp1";
        	$count = $count + 1;
			}
		}	
		if($SUBJECT_TENSOR_GIVEN == 1 && $SUBJECT_TENSOR_OUTPUT_LEVEL==2){
			$temp1 = "$subject_path/$s_tensor/$short_subject_tensor\.trace.img";
			$temp2 = "$subject_path/$s_tensor/$short_subject_tensor\.fa.img";			
			$temp3 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval1.img";
			$temp4 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval2.img";			
			$temp5 = "$subject_path/$s_tensor/$short_subject_tensor\.eigval3.img";						
			$params1 = "$params1 $temp1 $temp2 $temp3 $temp4 $temp5";
        	$count = $count + 5;			
		}
			
		for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
			$j = $i +1;
			$label_file = "$label_path/$a_other/$short_atlas_label[$i]\.img";
			$stats_file = "$stats_file_path\/sub_roi_stats_lddmm_$j\.txt";	
			$params2 =  "$label_file $stats_file $count $params1"; 		
			$sim1 = `$IMG_calc_label_stats $params2`;			
		}		
		
		
	}



}

sub process_intermediate_lddmm{
if($LDDMM_OUTPUT_LEVEL==2){
	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
		$full_subdirectory666 = "$full_subdirectory66\/iterno_$kkk";
	
		if($ANALYZE_Y_FLIPPING_TRUE==1 && ($SUBJECT_TENSOR_GIVEN == 1 || $ATLAS_TENSOR_GIVEN == 1)){
			$Hmap0  = "$full_subdirectory66\/Hmap_00$kkk\.vtk";
			$Kimap0 = "$full_subdirectory66\/Kimap_00$kkk\.vtk";
			$Hmap   = "$full_subdirectory66\/Hmap_00$kkk\_f.vtk";
			$Kimap  = "$full_subdirectory66\/Kimap_00$kkk\_f.vtk";
			$sim1 = `$VTK_flip $Hmap0 $Hmap 2`;
			$sim1 = `$VTK_flip $Kimap0 $Kimap 2`;
		}

		for($i=0; $i<$CHANNEL_NO; $i++) {
				$temp1 = "$full_subdirectory4/$short_subject_channel[$i]\.img";
				$temp2 = "$full_subdirectory666/$short_subject_channel[$i]\.img";
				$Kimap = "$full_subdirectory66/Hmap_00$kkk\.vtk";
				$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
		}
		if($SUBJECT_LABEL_GIVEN > 0 ){
			for($i=0; $i<$SUBJECT_LABEL_GIVEN; $i++) {
				$temp1 = "$full_subdirectory4/$s_other/$short_subject_label[$i]\.img";
				$temp2 = "$full_subdirectory666/$s_other/$short_subject_label[$i]\.img";
				$Kimap = "$full_subdirectory66/Hmap_00$kkk\.vtk";
				$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
			}
		}
		if($SUBJECT_GRAYS_GIVEN > 0 ){
			for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {
				$temp1 = "$full_subdirectory4/$s_other/$short_subject_grays[$i]\.img";
				$temp2 = "$full_subdirectory666/$s_other/$short_subject_grays[$i]\.img";
				$Kimap = "$full_subdirectory66/Hmap_00$kkk\.vtk";
				$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
			}
		}
		if($SUBJECT_TENSOR_GIVEN == 1 ){
#        	$temp1 = "$full_subdirectory4/$s_tensor/$short_subject_tensor\.d";
#	        $temp2 = "$full_subdirectory666/$s_tensor/$short_subject_tensor\.d";
	       	$temp1 = "$full_subdirectory4/$s_tensor/$short_subject_tensor";
	        $temp2 = "$full_subdirectory666/$s_tensor/$short_subject_tensor";

        	if($ANALYZE_Y_FLIPPING_TRUE==1){ 	
				$Hmap   = "$full_subdirectory66\/Hmap_00$kkk\_f.vtk";
				$Kimap  = "$full_subdirectory66\/Kimap_00$kkk\_f.vtk";
				$sim1 = `$maptensors $temp1 $Hmap $Kimap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
			}
			else{
				$Hmap  = "$full_subdirectory66\/Hmap_00$kkk\.vtk";
				$Kimap = "$full_subdirectory66\/Kimap_00$kkk\.vtk";
				$sim1 = `$maptensors $temp1 $Hmap $Kimap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
			}
		}

#transforming atlas data
		for($i=0; $i<$CHANNEL_NO; $i++) {
        	$temp1 = "$full_subdirectory1/$short_atlas_channel[$i]\.img";
	        $temp2 = "$full_subdirectory666/$short_atlas_channel[$i]\.img";
        	$Kimap = "$full_subdirectory66/Kimap_00$kkk\.vtk";
	        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
		}
		if($ATLAS_LABEL_GIVEN > 0){
			for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
				$temp1 = "$full_subdirectory1/$a_other/$short_atlas_label[$i]\.img";
				$temp2 = "$full_subdirectory666/$a_other/$short_atlas_label[$i]\.img";
				$Kimap = "$full_subdirectory66/Kimap_00$kkk\.vtk";
				$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 2`;
			}
		}
		if($ATLAS_GRAYS_GIVEN > 0){
			for($i=0; $i<$ATLAS_GRAYS_GIVEN; $i++) {
				$temp1 = "$full_subdirectory1/$a_other/$short_atlas_grays[$i]\.img";
				$temp2 = "$full_subdirectory666/$a_other/$short_atlas_grays[$i]\.img";
				$Kimap = "$full_subdirectory66/Kimap_00$kkk\.vtk";
				$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
			}
		}

		if($ATLAS_TENSOR_GIVEN == 1 ){
#        	$temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor\.d";
#	        $temp2 = "$full_subdirectory666/$a_tensor/$short_atlas_tensor\.d";
        	$temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor";
	        $temp2 = "$full_subdirectory666/$a_tensor/$short_atlas_tensor";

	        if($ANALYZE_Y_FLIPPING_TRUE==1){ 	
				$Hmap   = "$full_subdirectory66\/Hmap_00$kkk\_f.vtk";
				$Kimap  = "$full_subdirectory66\/Kimap_00$kkk\_f.vtk";
				$sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
			}
			else{
				$Hmap  = "$full_subdirectory66\/Hmap_00$kkk\.vtk";
				$Kimap = "$full_subdirectory66\/Kimap_00$kkk\.vtk";
				$sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
			}
		}

		if($ANALYZE_Y_FLIPPING_TRUE==1 && ($SUBJECT_TENSOR_GIVEN == 1 || $ATLAS_TENSOR_GIVEN == 1)){
			$Hmap   = "$full_subdirectory66\/Hmap_00$kkk\_f.vtk";
			$Kimap  = "$full_subdirectory66\/Kimap_00$kkk\_f.vtk";
			$sim1 = `rm $Hmap`;
			$sim1 = `rm $Kimap`;
		}
	}
}
	if($ANALYZE_Y_FLIPPING_TRUE==1 && ($SUBJECT_TENSOR_GIVEN == 1 || $ATLAS_TENSOR_GIVEN == 1)){
		$Hmap   = "$full_subdirectory6\/Hmap000_f.vtk";
		$Kimap  = "$full_subdirectory6\/Kimap000_f.vtk";
		$sim1 = `rm $Hmap`;
		$sim1 = `rm $Kimap`;
		$Hmap   = "$full_subdirectory6\/AIR_Hmap000_f.vtk";
		$Kimap  = "$full_subdirectory6\/AIR_Kimap000_f.vtk";
		$sim1 = `rm $Hmap`;
		$sim1 = `rm $Kimap`;
	}

}


sub move_organize_data{

        my @old_files = glob "$subdirectory4\/2_air/*.air";
        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory4a`;  }
        my @old_files = glob "$subdirectory4\/2_air/*_air.txt";
        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory4a`;  }

        my @old_files = glob "$subdirectory4\/3_lddmm/stdout*";
        foreach my $old_file (@old_files) { $sim1 = `mv $old_file $subdirectory4b`; }
        my @old_files = glob "$subdirectory4\/4_deformations/*.vtk";
        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory4b`;  }

#        my @old_files = glob "$subdirectory4\/4_deformations/AIR_LDDMM_*";
#        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory4b`;  }
#        my @old_files = glob "$subdirectory4\/4_deformations/AIR_*";
#        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory4a`;  }

if($LDDMM_OUTPUT_LEVEL==2){
        my @old_files = glob "$subdirectory4\/5_lddmm_temp/*";
        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $subdirectory5`;  }	
}

        my @old_files = glob "$subdirectory4\/0_origdata/*";
        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }
        my @old_files = glob "$subdirectory4\/1_histmatch/*";
        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }
        my @old_files = glob "$subdirectory4\/2_air/*";
        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }
        my @old_files = glob "$subdirectory4\/3_lddmm/*";
        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }
        my @old_files = glob "$subdirectory4\/4_deformations/*";
        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }
        my @old_files = glob "$subdirectory4\/*";
        foreach my $old_file (@old_files) {     $sim1 = `rmdir $old_file`; }
	$sim1 =`rmdir $subdirectory4`;

#	$sim1 =`rm -R $subdirectory4`;
#	print "$sim1";




#	my @old_files = glob "$subdirectory1\/*";
#	foreach my $old_file (@old_files) {	$sim1 = `rm $old_file`;	}
#	my @old_files = glob "$subdirectory2\/*";
#	foreach my $old_file (@old_files) {	$sim1 = `rm $old_file`;	}
#	my @old_files = glob "$subdirectory3\/*.img";
#	foreach my $old_file (@old_files) {	$sim1 = `mv $old_file $subdirectory5`;	}
#	my @old_files = glob "$subdirectory3\/*.hdr";
#	foreach my $old_file (@old_files) {	$sim1 = `mv $old_file $subdirectory5`;	}
#	my @old_files = glob "$subdirectory3\/*.d";
#	foreach my $old_file (@old_files) {	$sim1 = `mv $old_file $subdirectory5`;	}
#        my @old_files = glob "$subdirectory3\/*";
#        foreach my $old_file (@old_files) {     $sim1 = `rm $old_file`; }


#        my @old_files = glob "$subdirectory5\/*";
#        foreach my $old_file (@old_files) {     $sim1 = `mv $old_file ./`;  }

#	$sim1 = `rmdir $subdirectory1`;
#	$sim1 = `rmdir $subdirectory2`;
#	$sim1 = `rmdir $subdirectory3`;
#	$sim1 = `rmdir $subdirectory4`;
#	$sim1 = `rmdir $subdirectory5`;


}


sub calculate_deformations{

#transforming subject data
for($i=0; $i<$CHANNEL_NO; $i++) {
	$temp1 = "$full_subdirectory3\/$short_subject_channel[$i]\.img";
	$temp2 = "$full_subdirectory6\/$short_subject_channel[$i]\.img";
	$Kimap = "$full_subdirectory6\/AIR_Hmap000.vtk";
	$sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
	#print "$sim1";			
}

#transforming subject label data
if($SUBJECT_LABEL_GIVEN > 0 ){
	for($i=0; $i<$SUBJECT_LABEL_GIVEN; $i++) {
#        $temp1 = "$full_subdirectory3/$s_other/$short_subject_label[$i]\.img";
#        $temp2 = "$full_subdirectory6/$s_other/$short_subject_label[$i]\.img";
#        $Kimap = "$full_subdirectory6/AIR_Hmap000.vtk";
#        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
#        print "$sim1";
        $temp1 = "$full_subdirectory3/$s_other/$short_subject_label[$i]\.img";
        $temp2 = "$full_subdirectory6/$s_other/$short_subject_label[$i]\.img";
        $temp3 = "$full_subdirectory6/$s_other/$short_subject_label[$i]\.ldat";
        $Kimap = "$full_subdirectory6/AIR_Hmap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform2label $temp1 $Kimap $temp2 $temp3`;
	}
}
#transforming subject grays data
if($SUBJECT_GRAYS_GIVEN > 0 ){
	for($i=0; $i<$SUBJECT_GRAYS_GIVEN; $i++) {
        $temp1 = "$full_subdirectory3/$s_other/$short_subject_grays[$i]\.img";
        $temp2 = "$full_subdirectory6/$s_other/$short_subject_grays[$i]\.img";
        $Kimap = "$full_subdirectory6/AIR_Hmap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
	}
}


#transforming subject tensor		
if($SUBJECT_TENSOR_GIVEN == 1 ){
#        $temp1 = "$full_subdirectory3/$s_tensor/$short_subject_tensor\.d";
#        $temp2 = "$full_subdirectory6/$s_tensor/$short_subject_tensor\.d";
	$temp1 = "$full_subdirectory3/$s_tensor/$short_subject_tensor";
	$temp2 = "$full_subdirectory6/$s_tensor/$short_subject_tensor";

	if($ANALYZE_Y_FLIPPING_TRUE==1){	
		$Hmap0  = "$full_subdirectory6\/AIR_Hmap000.vtk";
		$Kimap0 = "$full_subdirectory6\/AIR_Kimap000.vtk";
		$Hmap   = "$full_subdirectory6\/AIR_Hmap000_f.vtk";
		$Kimap  = "$full_subdirectory6\/AIR_Kimap000_f.vtk";
		$sim1 = `$VTK_flip $Hmap0 $Hmap 2`;
		$sim1 = `$VTK_flip $Kimap0 $Kimap 2`;
		$sim1 = `$maptensors $temp1 $Hmap $Kimap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
	}
	else{
		$Hmap  = "$full_subdirectory6\/AIR_Hmap000.vtk";
		$Kimap = "$full_subdirectory6\/AIR_Kimap000.vtk";
		$sim1 = `$maptensors $temp1 $Hmap $Kimap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
	}
}

#transforming atlas data
for($i=0; $i<$CHANNEL_NO; $i++) {
        $temp1 = "$full_subdirectory1/$short_atlas_channel[$i]\.img";
        $temp2 = "$full_subdirectory4/$short_atlas_channel[$i]\.img";
        $Kimap = "$full_subdirectory6/Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
#        print "$sim1";

        $temp1 = "$full_subdirectory1\/$short_atlas_channel[$i]\.img";
        $temp2 = "$full_subdirectory3\/$short_atlas_channel[$i]\.img";
        $Kimap = "$full_subdirectory6\/AIR_Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
#        print "$sim1";			

        $temp1 = "$full_subdirectory3\/$short_atlas_channel[$i]\.img";
        $temp2 = "$full_subdirectory2\/$short_atlas_channel[$i]\.img";
		$sim1 = `$IMG_resample1 $temp1 $temp2 $INV_SCALE_FACTOR[0] $INV_SCALE_FACTOR[1] $INV_SCALE_FACTOR[2] $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] 1`;
#        print "$sim1";			
}


#transforming atlas label data
if($ATLAS_LABEL_GIVEN > 0){
for($i=0; $i<$ATLAS_LABEL_GIVEN; $i++) {
        $temp1 = "$full_subdirectory1/$a_other/$short_atlas_label[$i]\.img";
        $temp2 = "$full_subdirectory4/$a_other/$short_atlas_label[$i]\.img";
        $Kimap = "$full_subdirectory6/Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 2`;
#        print "$sim1";

        $temp1 = "$full_subdirectory1/$a_other/$short_atlas_label[$i]\.img";
        $temp2 = "$full_subdirectory3/$a_other/$short_atlas_label[$i]\.img";
        $Kimap = "$full_subdirectory6/AIR_Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 2`;
#        print "$sim1";			
        $temp1 = "$full_subdirectory1/$a_other/$short_atlas_label[$i]\.img";
        $temp2 = "$full_subdirectory3/$a_other/$short_atlas_label[$i]\.img";
        $temp3 = "$full_subdirectory3/$a_other/$short_atlas_label[$i]\.ldat";
        $Kimap = "$full_subdirectory6/AIR_Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform2label $temp1 $Kimap $temp2 $temp3`;

        $temp1 = "$full_subdirectory3/$a_other/$short_atlas_label[$i]\.img";
        $temp2 = "$full_subdirectory2/$a_other/$short_atlas_label[$i]\.img";
	$sim1 = `$IMG_resample1 $temp1 $temp2 $INV_SCALE_FACTOR[0] $INV_SCALE_FACTOR[1] $INV_SCALE_FACTOR[2] $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] 2`;
#        print "$sim1";			
}
}

#transforming atlas grayscale data
if($ATLAS_GRAYS_GIVEN > 0){
for($i=0; $i<$ATLAS_GRAYS_GIVEN; $i++) {
        $temp1 = "$full_subdirectory1/$a_other/$short_atlas_grays[$i]\.img";
        $temp2 = "$full_subdirectory4/$a_other/$short_atlas_grays[$i]\.img";
        $Kimap = "$full_subdirectory6/Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
#        print "$sim1";

        $temp1 = "$full_subdirectory1/$a_other/$short_atlas_grays[$i]\.img";
        $temp2 = "$full_subdirectory3/$a_other/$short_atlas_grays[$i]\.img";
        $Kimap = "$full_subdirectory6/AIR_Kimap000.vtk";
        $sim1 = `$IMG_apply_lddmm_tform $temp1 $Kimap $temp2 1`;
#        print "$sim1";			

        $temp1 = "$full_subdirectory3/$a_other/$short_atlas_grays[$i]\.img";
        $temp2 = "$full_subdirectory2/$a_other/$short_atlas_grays[$i]\.img";
	$sim1 = `$IMG_resample1 $temp1 $temp2 $INV_SCALE_FACTOR[0] $INV_SCALE_FACTOR[1] $INV_SCALE_FACTOR[2] $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] 2`;
#        print "$sim1";			
}
}


#transforming subject tensor		
if($ATLAS_TENSOR_GIVEN == 1 ){
#        $temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor\.d";
#        $temp2 = "$full_subdirectory4/$a_tensor/$short_atlas_tensor\.d";
        $temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor";
        $temp2 = "$full_subdirectory4/$a_tensor/$short_atlas_tensor";

        if($ANALYZE_Y_FLIPPING_TRUE==1){ 	
	$Hmap0  = "$full_subdirectory6\/Hmap000.vtk";
	$Kimap0 = "$full_subdirectory6\/Kimap000.vtk";
	$Hmap   = "$full_subdirectory6\/Hmap000_f.vtk";
	$Kimap  = "$full_subdirectory6\/Kimap000_f.vtk";
	$sim1 = `$VTK_flip $Hmap0 $Hmap 2`;
	$sim1 = `$VTK_flip $Kimap0 $Kimap 2`;
        $sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
#	print "$sim1";
#	$sim1 = `rm $Hmap`;
#	$sim1 = `rm $Kimap`;
	}
	else{
	$Hmap  = "$full_subdirectory6\/Hmap000.vtk";
	$Kimap = "$full_subdirectory6\/Kimap000.vtk";
        $sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
#	print "$sim1";
	}

#        $temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor\.d";
#        $temp2 = "$full_subdirectory3/$a_tensor/$short_atlas_tensor\.d";
        $temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor";
        $temp2 = "$full_subdirectory3/$a_tensor/$short_atlas_tensor";
        if($ANALYZE_Y_FLIPPING_TRUE==1){ 	
	$Hmap   = "$full_subdirectory6\/AIR_Hmap000_f.vtk";
	$Kimap  = "$full_subdirectory6\/AIR_Kimap000_f.vtk";
        $sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
#	print "$sim1";
#	$sim1 = `rm $Hmap`;
#	$sim1 = `rm $Kimap`;
	}
	else{
	$Hmap  = "$full_subdirectory6\/AIR_Hmap000.vtk";
	$Kimap = "$full_subdirectory6\/AIR_Kimap000.vtk";
        $sim1 = `$maptensors $temp1 $Kimap $Hmap $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
#	print "$sim1";
	}

#	$temp1 = "$full_subdirectory3/$a_tensor/$short_atlas_tensor\.d";
#	$temp2 = "$full_subdirectory2/$a_tensor/$short_atlas_tensor\.d";
	$temp1 = "$full_subdirectory3/$a_tensor/$short_atlas_tensor";
	$temp2 = "$full_subdirectory2/$a_tensor/$short_atlas_tensor";
        if($ANALYZE_Y_FLIPPING_TRUE==1){ 
	        $sim1 = `$resampletensor1 $temp1 $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2] $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] $INPUT_RES[0] $INPUT_RES[1] $INPUT_RES[2]`;
	}
	else{
	        $sim1 = `$resampletensor $temp1 $temp2 $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2] $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] $INPUT_RES[0] $INPUT_RES[1] $INPUT_RES[2]`;
	}


}


		
#to be done
	if($SUBJECT_TENSOR_GIVEN == 1 && $SUBJECT_TENSOR_OUTPUT_LEVEL==2){
		$tensor_path = "$full_subdirectory1/$s_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_subject_tensor, \@INPUT_SIZE,  \@INPUT_RES);
		$tensor_path = "$full_subdirectory2/$s_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_subject_tensor, \@INPUT_SIZE,  \@INPUT_RES);
		$tensor_path = "$full_subdirectory3/$s_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_subject_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);
		$tensor_path = "$full_subdirectory4/$s_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_subject_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);       
		$tensor_path = "$full_subdirectory6/$s_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_subject_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);
	}

	if($ATLAS_TENSOR_GIVEN == 1  && $ATLAS_TENSOR_OUTPUT_LEVEL==2){
		$tensor_path = "$full_subdirectory1/$a_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_atlas_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);
		$tensor_path = "$full_subdirectory2/$a_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_atlas_tensor, \@INPUT_SIZE,  \@INPUT_RES);
		$tensor_path = "$full_subdirectory3/$a_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_atlas_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);
		$tensor_path = "$full_subdirectory4/$a_tensor";	
		calculate_data_from_tensor_file($tensor_path, $short_atlas_tensor, \@OUTPUT_SIZE, \@OUTPUT_RES);
	}

}



sub calculate_data_from_tensor_file(){
	my($tensor_path)	= $_[0];	
	my($tensor_file)	= $_[1];		
	my($size_array_ref) = $_[2];
	my(@size_array)		= @$size_array_ref ; 
	my($res_array_ref)	= $_[3];
	my(@res_array)		= @$res_array_ref ;	
	
	$temp1 = "$tensor_path/$tensor_file";
	$sim1  = `$calceigensystem1 $temp1 $temp1 $size_array[0] $size_array[1] $size_array[2]`;
	
	$temp1 = "$tensor_path/$tensor_file\.trace";
	$temp2 = "$tensor_path/$tensor_file\.trace.img";
	$params1 = "3 $size_array[0] $size_array[1] $size_array[2] $res_array[0] $res_array[1] $res_array[2]";
	$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
	if($ANALYZE_Y_FLIPPING_TRUE==1){	$sim1 = `$IMG_flip $temp2 $temp2 2`;	}
	$sim1 = `rm $temp1`;
	
	$temp1 = "$tensor_path/$tensor_file\.fa";
	$temp2 = "$tensor_path/$tensor_file\.fa.img";
	$params1 = "3 $size_array[0] $size_array[1] $size_array[2] $res_array[0] $res_array[1] $res_array[2]";
	$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
	if($ANALYZE_Y_FLIPPING_TRUE==1){	$sim1 = `$IMG_flip $temp2 $temp2 2`;	}
	$sim1 = `rm $temp1`;
	
	$temp1 = "$tensor_path/$tensor_file\.eigval1";
	$temp2 = "$tensor_path/$tensor_file\.eigval1.img";
	$params1 = "3 $size_array[0] $size_array[1] $size_array[2] $res_array[0] $res_array[1] $res_array[2]";
	$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
	if($ANALYZE_Y_FLIPPING_TRUE==1){	$sim1 = `$IMG_flip $temp2 $temp2 2`;	}
	$sim1 = `rm $temp1`;
	
	$temp1 = "$tensor_path/$tensor_file\.eigval2";
	$temp2 = "$tensor_path/$tensor_file\.eigval2.img";
	$params1 = "3 $size_array[0] $size_array[1] $size_array[2] $res_array[0] $res_array[1] $res_array[2]";
	$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
	if($ANALYZE_Y_FLIPPING_TRUE==1){	$sim1 = `$IMG_flip $temp2 $temp2 2`;	}
	$sim1 = `rm $temp1`;
	
	$temp1 = "$tensor_path/$tensor_file\.eigval3";
	$temp2 = "$tensor_path/$tensor_file\.eigval3.img";
	$params1 = "3 $size_array[0] $size_array[1] $size_array[2] $res_array[0] $res_array[1] $res_array[2]";
	$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
	if($ANALYZE_Y_FLIPPING_TRUE==1){	$sim1 = `$IMG_flip $temp2 $temp2 2`;	}
	$sim1 = `rm $temp1`;
	
}





sub calculate_lddmm{
	$params1 = "$CHANNEL_NO";
	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp1  = "$full_subdirectory5/$lddmminputs/$short_subject_channel[$i]\.img";
		$temp2  = "$full_subdirectory5/$lddmminputs/$short_atlas_channel[$i]\.img";
		$params1 = "$params1 $temp1 $temp2 $lddmm_sigma[$i]";
	}
	$params1 = "$params1 $full_subdirectory6 $lddmm_cascading_iteration_number";
	for($k=0; $k<$lddmm_cascading_iteration_number; $k++) {
		$params1 = "$params1 $lddmm_alphalist[$k] $lddmm_timesteplist[$k]";
	}
	$params1 = "$params1 $LDDMM_OUTPUT_LEVEL 1"; 

	if($lddmm_cascading_iteration_type ==1 ){
		$sim1 = `$mm_lddmm2 $params1`;
	}
	else{
		$sim1 = `$mm_lddmm1 $params1`;
	}

	if($DO_AIR_TRUE > 0){
#combine air with Hmap/Kimap
        $deffile1         = "$full_subdirectory4/affine_air.txt";
        $deffile2         = "$full_subdirectory6/Hmap000.vtk";
        $deffile3         = "$full_subdirectory6/AIR_Hmap000.vtk";
        $sim1 = `$combine_AIR_Hmap $deffile1 1 $deffile2 $deffile3`;
#print "$sim1\n";
        $deffile1         = "$full_subdirectory4/affine_air.txt";
        $deffile2         = "$full_subdirectory6/Kimap000.vtk";
        $deffile3         = "$full_subdirectory6/AIR_Kimap000.vtk";
        $sim1 = `$combine_AIR_Kimap $deffile1 2 $deffile2 $deffile3`;
#print "$sim1\n";
	}
	else{
        $deffile1         = "$full_subdirectory4/affine_air.txt";
        $deffile2         = "$full_subdirectory6/Hmap000.vtk";
        $deffile3         = "$full_subdirectory6/AIR_Hmap000.vtk";
        $sim1 = `$cp $deffile2 $deffile3`;
        $deffile1         = "$full_subdirectory4/affine_air.txt";
        $deffile2         = "$full_subdirectory6/Kimap000.vtk";
        $deffile3         = "$full_subdirectory6/AIR_Kimap000.vtk";
        $sim1 = `$cp $deffile2 $deffile3`;
	}

	my @old_files = glob "$full_subdirectory6\/*.txt";
	$temp1 = "$full_subdirectory6\/$lddmmtxt/";
	foreach my $old_file (@old_files) {     $sim1 = `mv $old_file $temp1`;  }

if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
	for($i=0; $i<$lddmm_cascading_iteration_number; $i++) {
		$j =$i +1;
		$deffile1	= "$full_subdirectory6\/Hmap_00$j\.vtk";
		$deffile2       = "$full_subdirectory66\/Hmap_00$j\.vtk";
		$sim1 = `mv $deffile1 $deffile2`;
#print "$deffile1\n";
#print "$deffile2\n";
		$deffile1	= "$full_subdirectory6\/Kimap_00$j\.vtk";
		$deffile2       = "$full_subdirectory66\/Kimap_00$j\.vtk";
		$sim1 = `mv $deffile1 $deffile2`;
}
	$j =$lddmm_cascading_iteration_number;	
	$deffile1       = "$full_subdirectory66/Hmap_00$j\.vtk";
	$sim1 = `rm $deffile1`;	
#print "$deffile1\n";
	$deffile1       = "$full_subdirectory66/Kimap_00$j\.vtk";
	$sim1 = `rm $deffile1`;	
#print "$deffile1\n";

}






}


sub calculate_histmatching{
	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp1a  = "$full_subdirectory4/$short_subject_channel[$i]\.img";
        $temp2a  = "$full_subdirectory1/$short_atlas_channel[$i]\.img";
		$temp1b  = "$full_subdirectory5/$short_subject_channel[$i]\.img";
		$temp2b  = "$full_subdirectory5/$short_atlas_channel[$i]\.img";
		$temp1ah = "$full_subdirectory5/$short_subject_channel[$i]\_s.hist";
		$temp2ah = "$full_subdirectory5/$short_atlas_channel[$i]\_a.hist";
		$temp1bh = "$full_subdirectory5/$short_subject_channel[$i]\_sn.hist";
		$temp2bh = "$full_subdirectory5/$short_atlas_channel[$i]\_an.hist";
		$sim1 = `$IMG_histmatch4 $temp1a $temp2a $temp1b $temp2b 1024 3 0 1 $temp1ah $temp2ah $temp1bh $temp2bh`;
#print "$sim1\n";
	}

	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp1a  = "$full_subdirectory4/$short_subject_channel[$i]\.img";
		$temp2a  = "$full_subdirectory1/$short_atlas_channel[$i]\.img";
		$temp1b  = "$full_subdirectory5/$lddmminputs/$short_subject_channel[$i]\.img";
		$temp2b  = "$full_subdirectory5/$lddmminputs/$short_atlas_channel[$i]\.img";
		$temp1ah = "$full_subdirectory5/$lddmminputs/$short_subject_channel[$i]\_sn.hist";
		$temp2ah = "$full_subdirectory5/$lddmminputs/$short_atlas_channel[$i]\_an.hist";
		$temp1bh = "$full_subdirectory5/$lddmminputs/$short_subject_channel[$i]\_sn.hist";
		$temp2bh = "$full_subdirectory5/$lddmminputs/$short_atlas_channel[$i]\_an.hist";

		if($lddmm_histmatch_true[$i]==1){
			$sim1 = `$IMG_histmatch4 $temp1a $temp2a $temp1b $temp2b 1024 3 0 1 $temp1ah $temp2ah $temp1bh $temp2bh`;
		}
		elsif($lddmm_histmatch_true[$i]==2){
			$sim1 = `$IMG_normalization2float2 $temp1a $temp1b`;
			$sim1 = `$IMG_normalization2float2 $temp2a $temp2b`;
		}
		else{
			$sim1 = `$IMG_normalization2float1 $temp1a $temp1b`;
			$sim1 = `$IMG_normalization2float1 $temp2a $temp2b`;
		}
#print "$sim1\n";
	}
	
}



sub calculate_air{
	if($DO_AIR_TRUE == 1){
		$temp1 = "$full_subdirectory3/$short_subject_air[0]\.img";
		$temp2 = "$full_subdirectory1/$short_atlas_air[0]\.img";
		$sim1 = `$AIR_registration1_1024 $temp1 $temp2 $full_subdirectory4 1 "affine.img"`;
	}
	if($DO_AIR_TRUE == 2){
		$temp1 = "$full_subdirectory3/$short_subject_channel[0]\.img";
		$temp2 = "$full_subdirectory1/$short_atlas_channel[0]\.img";
		$sim1 = `$AIR_registration1_1024 $temp1 $temp2 $full_subdirectory4 1 "affine.img"`;
	}


	if($DO_AIR_TRUE > 0){
		$deffile = "$full_subdirectory4/affine_air.txt";
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$full_subdirectory3/$short_subject_channel[$i]\.img";
			$temp2 = "$full_subdirectory4/$short_subject_channel[$i]\.img";
			$sim1 = `$IMG_apply_AIR_tform $temp1 $temp2 $deffile 1 1`;
		}

		if($SUBJECT_TENSOR_GIVEN == 1){
			$temp1 = "$full_subdirectory3/$s_tensor/$short_subject_tensor";
			$temp2 = "$full_subdirectory4/$s_tensor/$short_subject_tensor";
			if($ANALYZE_Y_FLIPPING_TRUE==1){
				$sim1 = `$maptensors_air1 $temp1 $deffile $temp2`;
			}
			else{
				$sim1 = `$maptensors_air $temp1 $deffile $temp2`;
			}
		}
#print "$sim1";

		if($SUBJECT_LABEL_GIVEN > 0){
			for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      $j=$k+1;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_label[$k]\.img";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_label[$k]\.img";
				$sim1 = `$IMG_apply_AIR_tform $temp1 $temp2 $deffile 1 2`;
			}
		}
#print "$sim1";

		if($SUBJECT_GRAYS_GIVEN > 0 ){
			for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      $j=$k+1;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_grays[$k]\.img";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_grays[$k]\.img";
				$sim1 = `$IMG_apply_AIR_tform $temp1 $temp2 $deffile 1 1`;
			}
		}
#print "$sim1";
	}
	else {
		for($i=0; $i<$CHANNEL_NO; $i++) {
			$temp1 = "$full_subdirectory3/$short_subject_channel[$i]\.img";
			$temp2 = "$full_subdirectory4/$short_subject_channel[$i]\.img";
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$full_subdirectory3/$short_subject_channel[$i]\.hdr";
			$temp2 = "$full_subdirectory4/$short_subject_channel[$i]\.hdr";
			$sim1 = `cp $temp1 $temp2`;
		}
        if($DO_AIR_TRUE == 1){
			$temp1 = "$full_subdirectory3/$short_subject_air[0]\.img";
			$temp2 = "$full_subdirectory4/$short_subject_air[0]\.img";
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$full_subdirectory3/$short_subject_air[0]\.hdr";
			$temp2 = "$full_subdirectory4/$short_subject_air[0]\.hdr";
			$sim1 = `cp $temp1 $temp2`;
        }

		if($SUBJECT_TENSOR_GIVEN == 1){
			$temp1 = "$full_subdirectory3/$s_tensor/$short_subject_tensor";
        	$temp2 = "$full_subdirectory4/$s_tensor/$short_subject_tensor";
	        $sim1 = `cp $temp1 $temp2`;
		}
		if($SUBJECT_LABEL_GIVEN > 0){
			for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      $j=$k+1;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_label[$k]\.img";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_label[$k]\.img";
				$sim1 = `cp $temp1 $temp2`;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_label[$k]\.hdr";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_label[$k]\.hdr";
				$sim1 = `cp $temp1 $temp2`;
			}
		}
		if($SUBJECT_GRAYS_GIVEN > 0 ){
			for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      $j=$k+1;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_grays[$k]\.img";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_grays[$k]\.img";
				$sim1 = `cp $temp1 $temp2`;
				$temp1 = "$full_subdirectory3/$s_other/$short_subject_grays[$k]\.hdr";
				$temp2 = "$full_subdirectory4/$s_other/$short_subject_grays[$k]\.hdr";
				$sim1 = `cp $temp1 $temp2`;
			}
		}
	}


}



sub resample_data{

	for($jj=0; $jj<3; $jj++) { 	$INPUT_RES[$jj]   = $INPUT_SUBJECT_RES[$jj];	}
	for($jj=0; $jj<3; $jj++) { 	$INPUT_SIZE[$jj]  = $INPUT_SUBJECT_SIZE[$jj];	}
	for($jj=0; $jj<3; $jj++) { 	$OUTPUT_RES[$jj]  = $INPUT_ATLAS_RES[$jj];	}
	for($jj=0; $jj<3; $jj++) { 	$OUTPUT_SIZE[$jj] = $INPUT_ATLAS_SIZE[$jj];	}

	for($jj=0; $jj<3; $jj++) {      print "$INPUT_SIZE[$jj]\t";        }
	for($jj=0; $jj<3; $jj++) {      print "$INPUT_RES[$jj]\t";         }	print "\n";
	for($jj=0; $jj<3; $jj++) {      print "$OUTPUT_SIZE[$jj]\t";       }
	for($jj=0; $jj<3; $jj++) {      print "$OUTPUT_RES[$jj]\t";        }	print "\n";

	for($jj=0; $jj<3; $jj++) { 	$SCALE_FACTOR[$jj] = $INPUT_RES[$jj] / $OUTPUT_RES[$jj];		}
	for($jj=0; $jj<3; $jj++) { 	$INV_SCALE_FACTOR[$jj] = $OUTPUT_RES[$jj] / $INPUT_RES[$jj];	}

#resampling subject air file
	if($DO_AIR_TRUE == 1){
		$temp1 = "$full_subdirectory2/$short_subject_air[0]\.img";
		$temp2 = "$full_subdirectory3/$short_subject_air[0]\.img";
		$sim1 = `$IMG_resample1 $temp1 $temp2 $SCALE_FACTOR[0] $SCALE_FACTOR[1] $SCALE_FACTOR[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] 1`;
	}


#resampling subject channels		
	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp1 = "$full_subdirectory2/$short_subject_channel[$i]\.img";
		$temp2 = "$full_subdirectory3/$short_subject_channel[$i]\.img";
		$sim1 = `$IMG_resample1 $temp1 $temp2 $SCALE_FACTOR[0] $SCALE_FACTOR[1] $SCALE_FACTOR[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] 1`;
	}

#resampling subject tensor		
	if($SUBJECT_TENSOR_GIVEN == 1){
		$temp1 = "$full_subdirectory2/$s_tensor/$short_subject_tensor";
		$temp2 = "$full_subdirectory3/$s_tensor/$short_subject_tensor";
		if($ANALYZE_Y_FLIPPING_TRUE==1){ 
			$sim1 = `$resampletensor1 $temp1 $temp2 $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] $INPUT_RES[0] $INPUT_RES[1] $INPUT_RES[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
		}
		else{
			$sim1 = `$resampletensor $temp1 $temp2 $INPUT_SIZE[0] $INPUT_SIZE[1] $INPUT_SIZE[2] $INPUT_RES[0] $INPUT_RES[1] $INPUT_RES[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] $OUTPUT_RES[0] $OUTPUT_RES[1] $OUTPUT_RES[2]`;
		}
	}

#resampling subject labels		
	if($SUBJECT_LABEL_GIVEN >0 ){
		for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {
	        $temp1 = "$full_subdirectory2/$s_other/$short_subject_label[$k]\.img";
        	$temp2 = "$full_subdirectory3/$s_other/$short_subject_label[$k]\.img";
			$sim1 = `$IMG_resample1 $temp1 $temp2 $SCALE_FACTOR[0] $SCALE_FACTOR[1] $SCALE_FACTOR[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] 1`;
		}
	}

#resampling subject grayscale data		
	if($SUBJECT_GRAYS_GIVEN >0 ){
		for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {
	        $temp1 = "$full_subdirectory2/$s_other/$short_subject_grays[$k]\.img";
        	$temp2 = "$full_subdirectory3/$s_other/$short_subject_grays[$k]\.img";
			$sim1 = `$IMG_resample1 $temp1 $temp2 $SCALE_FACTOR[0] $SCALE_FACTOR[1] $SCALE_FACTOR[2] $OUTPUT_SIZE[0] $OUTPUT_SIZE[1] $OUTPUT_SIZE[2] 1`;
		}
	}
}



sub mask_channel_data{

#masking subject channel data
if($DO_SUBJECT_SKULLSTRIP_TRUE >0){
	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp3 = "$full_subdirectory1/$short_subject_mask\.img";
		$temp1 = "$full_subdirectory1/$short_subject_channel[$i]\.img";
		$temp2 = "$full_subdirectory2/$short_subject_channel[$i]\.img";
		$sim1 = `$IMG_mask $temp1 $temp3 $temp2`;
	}
	if($DO_AIR_TRUE == 1){
		$temp3 = "$full_subdirectory1/$short_subject_mask\.img";
		$temp1 = "$full_subdirectory1/$short_subject_air[0]\.img";
		$temp2 = "$full_subdirectory2/$short_subject_air[0]\.img";
		$sim1 = `$IMG_mask $temp1 $temp3 $temp2`;
	}
}
else{
	for($i=0; $i<$CHANNEL_NO; $i++) {
		$temp1 = "$full_subdirectory1/$short_subject_channel[$i]\.img";
		$temp2 = "$full_subdirectory2/$short_subject_channel[$i]\.img";
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$full_subdirectory1/$short_subject_channel[$i]\.hdr";
		$temp2 = "$full_subdirectory2/$short_subject_channel[$i]\.hdr";
		$sim1 = `cp $temp1 $temp2`;
	}
	if($DO_AIR_TRUE == 1){
		$temp1 = "$full_subdirectory1/$short_subject_air[0]\.img";
		$temp2 = "$full_subdirectory2/$short_subject_air[0]\.img";
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$full_subdirectory1/$short_subject_air[0]\.hdr";
		$temp2 = "$full_subdirectory2/$short_subject_air[0]\.hdr";
		$sim1 = `cp $temp1 $temp2`;
	}
}


}


sub mask_other_data{

if($DO_SUBJECT_SKULLSTRIP_TRUE >0){

#masking subject tensor data
	if($SUBJECT_TENSOR_GIVEN == 1){
		$temp3 = "$full_subdirectory1/$short_subject_mask\_d.img";
		$temp1 = "$full_subdirectory1/$s_tensor/$short_subject_tensor";
		$temp2 = "$full_subdirectory2/$s_tensor/$short_subject_tensor";
		$sim1 = `$maskTensorImg $temp1 $temp3 $temp2`;
	}

#masking subject label data
	if($SUBJECT_LABEL_GIVEN > 0){
		for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      $j=$k+1;
			$temp3 = "$full_subdirectory1/$short_subject_mask\.img";
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_label[$k]\.img";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_label[$k]\.img";
	        $sim1 = `$IMG_mask $temp1 $temp3 $temp2`;
		}
	}

#masking subject grays data
	if($SUBJECT_GRAYS_GIVEN > 0 ){
		for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      $j=$k+1;
			$temp3 = "$full_subdirectory1/$short_subject_mask\.img";
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_grays[$k]\.img";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_grays[$k]\.img";
	        $sim1 = `$IMG_mask $temp1 $temp3 $temp2`;
		}
	}

}
else{ 
	if($SUBJECT_TENSOR_GIVEN == 1){
		$temp1 = "$full_subdirectory1/$s_tensor/$short_subject_tensor";
		$temp2 = "$full_subdirectory2/$s_tensor/$short_subject_tensor";
		$sim1 = `cp $temp1 $temp2`;
	}
	if($SUBJECT_LABEL_GIVEN > 0){
		for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      $j=$k+1;
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_label[$k]\.img";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_label[$k]\.img";
	        $sim1 = `cp $temp1 $temp2`;
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_label[$k]\.hdr";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_label[$k]\.hdr";
	        $sim1 = `cp $temp1 $temp2`;
		}
	}
	if($SUBJECT_GRAYS_GIVEN > 0 ){
		for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      $j=$k+1;
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_grays[$k]\.img";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_grays[$k]\.img";
	        $sim1 = `cp $temp1 $temp2`;
			$temp1 = "$full_subdirectory1/$s_other/$short_subject_grays[$k]\.hdr";
        	$temp2 = "$full_subdirectory2/$s_other/$short_subject_grays[$k]\.hdr";
	        $sim1 = `cp $temp1 $temp2`;
		}
	}
}



}


sub create_subject_mask_file{

if($DO_SUBJECT_SKULLSTRIP_TRUE == 1 || $DO_SUBJECT_SKULLSTRIP_TRUE == 3){
	if($DO_SUBJECT_SKULLSTRIP_TRUE == 1){
		$short_subject_mask = "$short_subject_skullstrip[0]\_mask";
		$temp1  = "$full_subdirectory1/$short_subject_skullstrip[0]\.img";
	}
	elsif($DO_SUBJECT_SKULLSTRIP_TRUE == 3){
		$short_subject_mask = "$short_subject_channel[0]\_mask";
		$temp1  = "$full_subdirectory1/$short_subject_channel[0]\.img";
	}

	$temp2  = "$full_subdirectory1/$short_subject_mask\.img";		#mask for img files
	$temp23 = "$full_subdirectory1/$short_subject_mask\_d.img";		#mask for tensor

	$temp11 = "$full_subdirectory1/mask.imgformat"; 
	$sim1 = `$IMG_saveimgformat $temp1 $temp11`;	
#print "can1\n";

	open(DAT, $temp11) || die("Could not open directory file!");        @params2=<DAT>;        close(DAT);
	$i=0;
	$temp111 = $params2[$i];   $i=$i+1;        chomp $temp111;    @temp1111 = split(' ',$temp111);
	$temp3 = $temp1111[0];
#print "$temp3\n";
	if( ($temp3 ne "byte") && ($temp3 ne "word") && ($temp3 ne "float")){	
		print "ERROR: Unrecognized analyze image data format for mask creation\n";
		print "...exiting\n\n";
		exit;
	}
#	if($temp3 ne "float1"){	print "can4\n";	}
#print "can5\n";
	$sil1 = "$full_subdirectory1/\sil1";
	$sil2 = "$full_subdirectory1/\sil2";

	if($ANALYZE_Y_FLIPPING_TRUE==1){ 
		$sim1 = `$IMG_flip $temp1 $temp2 2`;
		$params1 = "$SKULLSTRIPPING_W5_PARAM $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $temp2 $temp3 $temp2 $sil1 $sil2"; 
		$sim1 = `$SkullStripOneImage $params1`;
		$params1 = "1 $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";	
		$sim1 = `$IMG_change_raw2analyze $temp2 $params1 $temp2`;	
		$sim1 = `$IMG_change_raw2analyze $temp2 $params1 $temp23`;	
		$sim1 = `$IMG_flip $temp2 $temp2 2`;
	}
	else {
		$params1 = "$SKULLSTRIPPING_W5_PARAM $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $temp1 $temp3 $temp2 $sil1 $sil2"; 
		$sim1 = `$SkullStripOneImage $params1`;
#print "$sim1\n";
		$params1 = "1 $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";	
		$sim1 = `$IMG_change_raw2analyze $temp2 $params1 $temp2`;	
		$sim1 = `$IMG_change_raw2analyze $temp2 $params1 $temp23`;	
#print "$sim1\n";
	}


}

if($DO_SUBJECT_SKULLSTRIP_TRUE == 2){

	$short_subject_mask = "$short_subject_skullstrip[0]\_mask";
	$temp1  = "$full_subdirectory1/$short_subject_skullstrip[0]\.img";
	$temp2  = "$full_subdirectory1/$short_subject_mask\.img";		#mask for img files
	$temp23 = "$full_subdirectory1/$short_subject_mask\_d.img";		#mask for tensor

	$sim1 = `cp $temp1 $temp2`;
	$sim1 = `cp $temp1 $temp23`;

	$temp1  = "$full_subdirectory1/$short_subject_skullstrip[0]\.hdr";
	$temp2  = "$full_subdirectory1/$short_subject_mask\.hdr";		#mask for img files
	$temp23 = "$full_subdirectory1/$short_subject_mask\_d.hdr";		#mask for tensor

	$sim1 = `cp $temp1 $temp2`;
	$sim1 = `cp $temp1 $temp23`;

	if($ANALYZE_Y_FLIPPING_TRUE==1){
		$sim1 = `$IMG_flip $temp23 $temp23 2`;
	}

}

print "short_subject_mask      :\t $short_subject_mask \n\n";



}

sub create_tensor_trace_4_lddmm_1{
	if($tensortrace_4subject_lddmmch1_true){
		$temp1 = "$full_subdirectory1/$s_tensor/$short_subject_tensor";			
		$temp2 = "$full_subdirectory1/$s_tensor/$short_subject_tensor";		
		$sim1 = `$calceigensystem1 $temp1 $temp2 $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2]`;
		
		$temp1 = "$full_subdirectory1/$s_tensor/$short_subject_tensor\.trace";
		if($USE_ORIGINAL_FNAMES_TRUE != 1)	{	$temp2 = "$full_subdirectory1/$short_subject_channel[0]\.img";		}
		else								{	$temp2 = "$full_subdirectory1/$short_subject_tensor\_trace.img";	}
		$params1 = "3 $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){
			$sim1 = `$IMG_flip $temp2 $temp2 2`;
		}
		if($USE_ORIGINAL_FNAMES_TRUE == 1)	{	$short_subject_channel[0] = "$short_subject_tensor\_trace";		}
	}

	if($tensortrace_4atlas_lddmmch1_true){
		$temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor";
		$temp2 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor";
		$sim1 = `$calceigensystem1 $temp1 $temp2 $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2]`;
		
		$temp1 = "$full_subdirectory1/$a_tensor/$short_atlas_tensor\.trace";
		if($USE_ORIGINAL_FNAMES_TRUE != 1)	{	$temp2 = "$full_subdirectory1/$short_atlas_channel[0]\.img";	}
		else								{	$temp2 = "$full_subdirectory1/$short_atlas_tensor\_trace.img";	}
		$params1 = "3 $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){
			$sim1 = `$IMG_flip $temp2 $temp2 2`;
		}
		if($USE_ORIGINAL_FNAMES_TRUE == 1)	{	$short_atlas_channel[0] = "$short_atlas_tensor\_trace";		}		
	}

}





sub formatchange_other_data{
	if($SUBJECT_TENSOR_GIVEN == 1){
		if($SUBJECT_TENSOR_FILENAME_FORMAT == 1){
			$temp1 = "$full_subdirectory0/$s_tensor/$short_subject_tensor";
			$sim1 = `cp $temp1 "$full_subdirectory1/$s_tensor"`;
		}
		else{
			$temp1 = "$full_subdirectory0/$s_tensor/$short_subject_tensor";
			$temp2 = "$full_subdirectory1/$s_tensor/$short_subject_tensor";
			$sim1 = `$changeTensorImgType $temp1 $temp2 $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] 2 1`;
		}
	}
	if($SUBJECT_LABEL_GIVEN > 0 ){
		for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      $j=$k+1;
			if($SUBJECT_LABEL_FILENAME_FORMAT[$k] == 0){
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_label[$k]\.img";
				$sim1 = `cp $temp1 "$full_subdirectory1/$s_other"`;
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_label[$k]\.hdr";
				$sim1 = `cp $temp1 "$full_subdirectory1/$s_other"`;
			}
			else{
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_label[$k]";
				$temp2 = "$full_subdirectory1/$s_other/$short_subject_label[$k]\.img";
				$params1 = "$SUBJECT_LABEL_FILENAME_FORMAT[$k] $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
				$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
				if($ANALYZE_Y_FLIPPING_TRUE==1){
					$sim1 = `$IMG_flip $temp2 $temp2 2`;
				}
			}
		}
	}
	if($SUBJECT_GRAYS_GIVEN > 0){
		for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      $j=$k+1;		
			if($SUBJECT_GRAYS_FILENAME_FORMAT[$k] == 0){
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]\.img";
				$sim1 = `cp $temp1 "$full_subdirectory1/$s_other"`;
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]\.hdr";
				$sim1 = `cp $temp1 "$full_subdirectory1/$s_other"`;
			}
			else{
				$temp1 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]";
				$temp2 = "$full_subdirectory1/$s_other/$short_subject_grays[$k]\.img";
				$params1 = "$SUBJECT_GRAYS_FILENAME_FORMAT[$k] $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
				$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
				if($ANALYZE_Y_FLIPPING_TRUE==1){
					$sim1 = `$IMG_flip $temp2 $temp2 2`;
				}
			}
		}		
	}
	if($ATLAS_TENSOR_GIVEN == 1){
		if($ATLAS_TENSOR_FILENAME_FORMAT == 1){
			$temp1 = "$full_subdirectory0/$a_tensor/$short_atlas_tensor";
			$sim1 = `cp $temp1 "$full_subdirectory1/$a_tensor"`;
		}
		else{
			$temp1 = "$full_subdirectory0/$a_tensor$short_atlas_tensor";
			$temp2 = "$full_subdirectory1/$a_tensor$short_atlas_tensor";
			$sim1 = `$changeTensorImgType $temp1 $temp2 $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] 2 1`;
		}
	}

	if($ATLAS_LABEL_GIVEN > 0){
		for($k=0; $k<$ATLAS_LABEL_GIVEN; $k++) {      $j=$k+1;		
			if($ATLAS_LABEL_FILENAME_FORMAT[$k] == 0){
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]\.img";
				$sim1 = `cp $temp1 "$full_subdirectory1/$a_other"`;
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]\.hdr";
				$sim1 = `cp $temp1 "$full_subdirectory1/$a_other"`;
			}
			else{
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]";
				$temp2 = "$full_subdirectory1/$a_other/$short_atlas_label[$k]\.img";
				$params1 = "$ATLAS_LABEL_FILENAME_FORMAT[$k] $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]";
				$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
				if($ANALYZE_Y_FLIPPING_TRUE==1){
					$sim1 = `$IMG_flip $temp2 $temp2 2`;
				}
			}
		}		
	}

	if($ATLAS_GRAYS_GIVEN > 0){
		for($k=0; $k<$ATLAS_GRAYS_GIVEN; $k++) {      $j=$k+1;	
			if($ATLAS_GRAYS_FILENAME_FORMAT[$k] == 0){
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]\.img";
				$sim1 = `cp $temp1 "$full_subdirectory1/$a_other"`;
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]\.hdr";
				$sim1 = `cp $temp1 "$full_subdirectory1/$a_other"`;
			}
			else{
				$temp1 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]";
				$temp2 = "$full_subdirectory1/$a_other/$short_atlas_grays[$k]\.img";
				$params1 = "$ATLAS_GRAYS_FILENAME_FORMAT[$k] $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]";
				$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
				if($ANALYZE_Y_FLIPPING_TRUE==1){
					$sim1 = `$IMG_flip $temp2 $temp2 2`;
				}
			}
		}		
	}

}




sub formatchange_channel_data{

if($DO_SUBJECT_SKULLSTRIP_TRUE == 1 || $DO_SUBJECT_SKULLSTRIP_TRUE == 2){
	if($SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0] == 0){
		$temp1 = "$full_subdirectory0/$short_subject_skullstrip[0]\.img";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
		$temp1 = "$full_subdirectory0/$short_subject_skullstrip[0]\.hdr";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
	}
	elsif($SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]<4 && $SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]>0){
		$temp1 = "$full_subdirectory0/$short_subject_skullstrip[0]";
		$temp2 = "$full_subdirectory1/$short_subject_skullstrip[0]\.img";
		$params1 = "$SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0] $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){ 
			$sim1 = `$IMG_flip $temp2 $temp2 2`; 
		}
	}
}
if($DO_AIR_TRUE == 1){
	if($SUBJECT_AIR_FILENAME_FORMAT[0] == 0){
		$temp1 = "$full_subdirectory0/$short_subject_air[0]\.img";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
		$temp1 = "$full_subdirectory0/$short_subject_air[0]\.hdr";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
	}
	elsif($SUBJECT_AIR_FILENAME_FORMAT[0]<4 && $SUBJECT_AIR_FILENAME_FORMAT[0]>0){
		$temp1 = "$full_subdirectory0/$short_subject_air[0]";
		$temp2 = "$full_subdirectory1/$short_subject_air[0]\.img";
		$params1 = "$SUBJECT_AIR_FILENAME_FORMAT[0] $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){
			$sim1 = `$IMG_flip $temp2 $temp2 2`;
		}
	}

	if($ATLAS_AIR_FILENAME_FORMAT[0] == 0){
		$temp1 = "$full_subdirectory0/$short_atlas_air[0]\.img";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
		$temp1 = "$full_subdirectory0/$short_atlas_air[0]\.hdr";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
	}
	elsif($ATLAS_AIR_FILENAME_FORMAT[0]<4 && $ATLAS_AIR_FILENAME_FORMAT[0]>0){
		$temp1 = "$full_subdirectory0/$short_atlas_air[0]";
		$temp2 = "$full_subdirectory1/$short_atlas_air[0]\.img";
		$params1 = "$ATLAS_AIR_FILENAME_FORMAT[0] $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){
			$sim1 = `$IMG_flip $temp2 $temp2 2`;
		}
	}

}




for($i=0; $i<$CHANNEL_NO; $i++) {
	if($ATLAS_CHANNEL_FILENAME_FORMAT[$i] == 0){
		$temp1 = "$full_subdirectory0/$short_atlas_channel[$i]\.img";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
		$temp1 = "$full_subdirectory0/$short_atlas_channel[$i]\.hdr";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
	}
	elsif($ATLAS_CHANNEL_FILENAME_FORMAT[$i]<4 && $ATLAS_CHANNEL_FILENAME_FORMAT[$i]>0){
		$temp1 = "$full_subdirectory0/$short_atlas_channel[$i]";
		$temp2 = "$full_subdirectory1/$short_atlas_channel[$i]\.img";
		$params1 = "$ATLAS_CHANNEL_FILENAME_FORMAT[$i] $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2] $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){ 
			$sim1 = `$IMG_flip $temp2 $temp2 2`; 
		}
	}

	if($SUBJECT_CHANNEL_FILENAME_FORMAT[$i] == 0){
		$temp1 = "$full_subdirectory0/$short_subject_channel[$i]\.img";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
		$temp1 = "$full_subdirectory0/$short_subject_channel[$i]\.hdr";
		$sim1 = `cp $temp1 "$full_subdirectory1/"`;
	}
	elsif($SUBJECT_CHANNEL_FILENAME_FORMAT[$i]<4 && $SUBJECT_CHANNEL_FILENAME_FORMAT[$i]>0){
		$temp1 = "$full_subdirectory0/$short_subject_channel[$i]";
		$temp2 = "$full_subdirectory1/$short_subject_channel[$i]\.img";
		$params1 = "$SUBJECT_CHANNEL_FILENAME_FORMAT[$i] $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2] $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]";
		$sim1 = `$IMG_change_raw2analyze $temp1 $params1 $temp2`;
		if($ANALYZE_Y_FLIPPING_TRUE==1){ 
			$sim1 = `$IMG_flip $temp2 $temp2 2`; 
		}
	}
}

}

sub copy_other_data_1{

if($SUBJECT_TENSOR_GIVEN == 1){
	$temp3 = $short_subject_tensor;
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_tensor = "subject_tensor";	}	
	$temp1 = "$subject_tensor_path/$temp3";
	$temp2 = "$full_subdirectory0/$s_tensor/$short_subject_tensor";	
	$sim1 = `cp $temp1 $temp2`;
}
	
if($SUBJECT_LABEL_GIVEN > 0){
	for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {      
		$j=$k+1;	
		$temp3 = $short_subject_label[$k];
		if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_label[$k] = "subject_label_file_$j";	}	
		if($SUBJECT_LABEL_FILENAME_FORMAT[$k]==0){
			$temp1 = "$subject_label_path[$k]/$temp3\.img";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_label[$k]\.img";			
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$subject_label_path[$k]/$temp3\.hdr";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_label[$k]\.hdr";			
			$sim1 = `cp $temp1 $temp2`;
		}
		else{
			$temp1 = "$subject_label_path[$k]/$temp3";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_label[$k]";			
			$sim1 = `cp $temp1 $temp2`;
		}
	}
}

if($SUBJECT_GRAYS_GIVEN > 0){
	for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {      
		$j=$k+1;	
		$temp3 = $short_subject_grays[$k];
		if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_grays[$k] = "subject_grayscale_file_$j";	}
		if($SUBJECT_GRAYS_FILENAME_FORMAT[$k]==0){
			$temp1 = "$subject_grays_path[$k]/$temp3\.img";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]\.img";			
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$subject_grays_path[$k]/$temp3\.hdr";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]\.hdr";			
			$sim1 = `cp $temp1 $temp2`;
		}
		else{
			$temp1 = "$subject_grays_path[$k]/$temp3";
			$temp2 = "$full_subdirectory0/$s_other/$short_subject_grays[$k]";			
			$sim1 = `cp $temp1 $temp2`;
		}
	}
}

if($ATLAS_TENSOR_GIVEN == 1){
	$temp3 = $short_atlas_tensor;
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_atlas_tensor = "atlas_tensor";	}	
	$temp1 = "$atlas_tensor_path/$temp3";
	$temp2 = "$full_subdirectory0/$a_tensor/$short_atlas_tensor";	
	$sim1 = `cp $temp1 $temp2`;
}

if($ATLAS_LABEL_GIVEN > 0){
	for($k=0; $k<$ATLAS_LABEL_GIVEN; $k++) {      
		$j=$k+1;	
		$temp3 = $short_atlas_label[$k];
		if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_atlas_label[$k] = "atlas_label_file_$j";	}
		if($ATLAS_LABEL_FILENAME_FORMAT[$k]==0){
			$temp1 = "$atlas_label_path[$k]/$temp3\.img";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]\.img";			
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$atlas_label_path[$k]/$temp3\.hdr";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]\.hdr";			
			$sim1 = `cp $temp1 $temp2`;
		}
		else{
			$temp1 = "$atlas_label_path[$k]/$temp3";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_label[$k]";			
			$sim1 = `cp $temp1 $temp2`;
		}
	}
}

if($ATLAS_GRAYS_GIVEN > 0){
	for($k=0; $k<$ATLAS_GRAYS_GIVEN; $k++) {      
		$j = $k+1;	
		$temp3 = $short_atlas_grays[$k];
		if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_atlas_grays[$k] = "atlas_grayscale_file_$j";		}
		if($ATLAS_GRAYS_FILENAME_FORMAT[$k]==0){
			$temp1 = "$atlas_grays_path[$k]/$temp3\.img";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]\.img";			
			$sim1 = `cp $temp1 $temp2`;
			$temp1 = "$atlas_grays_path[$k]/$temp3\.hdr";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]\.hdr";			
			$sim1 = `cp $temp1 $temp2`;
		}
		else{
			$temp1 = "$atlas_grays_path[$k]/$temp3";
			$temp2 = "$full_subdirectory0/$a_other/$short_atlas_grays[$k]";			
			$sim1 = `cp $temp1 $temp2`;
		}
	}
}

}



sub copy_channel_data_1{

if($DO_SUBJECT_SKULLSTRIP_TRUE == 1 || $DO_SUBJECT_SKULLSTRIP_TRUE == 2){
	$temp3 = $short_subject_skullstrip[0];
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_skullstrip[0] = "subject_skull_file";	}
	if($SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0] == 0){
		$temp1 = "$subject_skullstrip_path[0]/$temp3\.img";			
		$temp2 = "$full_subdirectory0/$short_subject_skullstrip[0]\.img";        	
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$subject_skullstrip_path[0]/$temp3\.hdr";
		$temp2 = "$full_subdirectory0/$short_subject_skullstrip[0]\.hdr";
		$sim1 = `cp $temp1 $temp2`;
	}
	elsif($SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]<4 && $SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]>0){
		$temp1 = "$subject_skullstrip_path[0]/$temp3";
		$temp2 = "$full_subdirectory0/$short_subject_skullstrip[0]";
		$sim1 = `cp $temp1 $temp2`;
	}
}
if($DO_AIR_TRUE == 1){
	$temp3 = $short_subject_air[0];
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_air[0] = "subject_air_file";	}
	if($SUBJECT_AIR_FILENAME_FORMAT[0] == 0){
		$temp1 = "$subject_air_path[0]/$temp3\.img";
		$temp2 = "$full_subdirectory0/$short_subject_air[0]\.img";				
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$subject_air_path[0]/$temp3\.hdr";
		$temp2 = "$full_subdirectory0/$short_subject_air[0]\.hdr";				
		$sim1 = `cp $temp1 $temp2`;
	}
	elsif($SUBJECT_AIR_FILENAME_FORMAT[0]<4 && $SUBJECT_AIR_FILENAME_FORMAT[0]>0){
		$temp1 = "$subject_air_path[0]/$temp3";
		$temp2 = "$full_subdirectory0/$short_subject_air[0]";				
		$sim1 = `cp $temp1 $temp2`;
	}
	$temp3 = $short_atlas_air[0];
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_atlas_air[0] = "atlas_air_file";	}
	if($ATLAS_AIR_FILENAME_FORMAT[0] == 0){
		$temp1 = "$atlas_air_path[0]/$temp3\.img";
		$temp2 = "$full_subdirectory0/$short_atlas_air[0]\.img";				
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$atlas_air_path[0]/$temp3\.hdr";
		$temp2 = "$full_subdirectory0/$short_atlas_air[0]\.hdr";				
		$sim1 = `cp $temp1 $temp2`;
	}
	elsif($ATLAS_AIR_FILENAME_FORMAT[0]<4 && $ATLAS_AIR_FILENAME_FORMAT[0]>0){
		$temp1 = "$atlas_air_path[0]/$temp3";
		$temp2 = "$full_subdirectory0/$short_atlas_air[0]";				
		$sim1 = `cp $temp1 $temp2`;
	}
}


for($i=0; $i<$CHANNEL_NO; $i++) {
	$j = $i+1;
	$temp3 = $short_atlas_channel[$i];
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_atlas_channel[$i] = "atlas_lddmm_file_$j";	}
	if($ATLAS_CHANNEL_FILENAME_FORMAT[$i] == 0){
		$temp1 = "$atlas_channel_path[$i]/$temp3\.img";
		$temp2 = "$full_subdirectory0/$short_atlas_channel[$i]\.img";			
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$atlas_channel_path[$i]/$temp3\.hdr";
		$temp2 = "$full_subdirectory0/$short_atlas_channel[$i]\.hdr";			
		$sim1 = `cp $temp1 $temp2`;
	}
	elsif($ATLAS_CHANNEL_FILENAME_FORMAT[$i] < 4 && $ATLAS_CHANNEL_FILENAME_FORMAT[$i] >0){
		$temp1 = "$atlas_channel_path[$i]/$temp3";
		$temp2 = "$full_subdirectory0/$short_atlas_channel[$i]";		
		$sim1 = `cp $temp1 $temp2`;
	}
	$temp3 = $short_subject_channel[$i];
	if($USE_ORIGINAL_FNAMES_TRUE != 1) {	$short_subject_channel[$i] = "subject_lddmm_file_$j";	}
	if($SUBJECT_CHANNEL_FILENAME_FORMAT[$i] == 0){
		$temp1 = "$subject_channel_path[$i]/$temp3\.img";
		$temp2 = "$full_subdirectory0/$short_subject_channel[$i]\.img";		
		$sim1 = `cp $temp1 $temp2`;
		$temp1 = "$subject_channel_path[$i]/$temp3\.hdr";
		$temp2 = "$full_subdirectory0/$short_subject_channel[$i]\.hdr";		
		$sim1 = `cp $temp1 $temp2`;
	}
	elsif($SUBJECT_CHANNEL_FILENAME_FORMAT[$i] < 4 && $SUBJECT_CHANNEL_FILENAME_FORMAT[$i] > 0){
		$temp1 = "$subject_channel_path[$i]/$temp3";
		$temp2 = "$full_subdirectory0/$short_subject_channel[$i]";		
		$sim1 = `cp $temp1 $temp2`;
	}
}

	if($SUBJECT_TENSOR_GIVEN == 1){
	}
	if($SUBJECT_LABEL_GIVEN == 1){
	}
	if($SUBJECT_GRAYS_GIVEN == 1){
	}
	if($ATLAS_TENSOR_GIVEN == 1){
	}
	if($ATLAS_LABEL_GIVEN == 1){
	}
	if($ATLAS_GRAYS_GIVEN == 1){
	}

}




sub remove_paths_from_filenames{
print "\n";


if($DO_SUBJECT_SKULLSTRIP_TRUE == 1 || $DO_SUBJECT_SKULLSTRIP_TRUE == 2){
        $temp1 = $SUBJECT_SKULLSTRIP_FILENAME[0] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

        if($SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0] == 0){
                $temp2       =~ s/.img//;
                $short_subject_skullstrip[0] = $temp2 ;
                $temp3 = "$short_subject_skullstrip[0]\.img";
                $temp1 =~ s/\/$temp3//;
                $subject_skullstrip_path[0] = $temp1;
        }
        else{
                $short_subject_skullstrip[0] = $temp2 ;
                $temp3 = $short_subject_skullstrip[0];
                $temp1 =~ s/\/$temp3//;
                $subject_skullstrip_path[0] = $temp1;
        }
#	$short_subject_mask[0] = "$short_subject_skullstrip[0]\_mask";

print "subject_skullstrip_path :\t $subject_skullstrip_path[0]  \n";
print "short_subject_skullstrip:\t $short_subject_skullstrip[0] \n";

}


if($DO_AIR_TRUE == 1){
        $temp1 = $SUBJECT_AIR_FILENAME[0] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

        if($SUBJECT_AIR_FILENAME_FORMAT[0] == 0){
                $temp2       =~ s/.img//;
                $short_subject_air[0] = $temp2 ;
                $temp3 = "$short_subject_air[0]\.img";
                $temp1 =~ s/\/$temp3//;
                $subject_air_path[0] = $temp1;
        }
        else{
                $short_subject_air[0] = $temp2 ;
                $temp3 = $short_subject_air[0];
                $temp1 =~ s/\/$temp3//;
                $subject_air_path[0] = $temp1;
        }

        $temp1 = $ATLAS_AIR_FILENAME[0] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

        if($ATLAS_AIR_FILENAME_FORMAT[0] == 0){
                $temp2       =~ s/.img//;
                $short_atlas_air[0] = $temp2 ;
                $temp3 = "$short_atlas_air[0]\.img";
                $temp1 =~ s/\/$temp3//;
                $atlas_air_path[0] = $temp1;
        }
        else{
                $short_atlas_air[0] = $temp2 ;
                $temp3 = $short_atlas_air[0];
                $temp1 =~ s/\/$temp3//;
                $atlas_air_path[0] = $temp1;
        }
print "subject_air_path        :\t $subject_air_path[0]  \n";
print "short_subject_air       :\t $short_subject_air[0] \n";
print "atlas_air_path          :\t $atlas_air_path[0]  \n";
print "short_atlas_air         :\t $short_atlas_air[0] \n\n";
}



for($i=0; $i<$CHANNEL_NO; $i++) {
        $temp1 = $SUBJECT_CHANNEL_FILENAME[$i];
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

	if($SUBJECT_CHANNEL_FILENAME_FORMAT[$i] == 0){
        	$temp2       =~ s/.img//;
	        $short_subject_channel[$i] = $temp2 ;
		$temp3 = "$short_subject_channel[$i]\.img";
	        $temp1 =~ s/\/$temp3//;
	       	$subject_channel_path[$i] = $temp1;
	}
	elsif($SUBJECT_CHANNEL_FILENAME_FORMAT[$i]>0 && $SUBJECT_CHANNEL_FILENAME_FORMAT[$i]<4){
        	$short_subject_channel[$i] = $temp2 ;
		$temp3 = $short_subject_channel[$i];
        	$temp1 =~ s/\/$temp3//;
	        $subject_channel_path[$i] = $temp1;
	}

        $temp1 = $ATLAS_CHANNEL_FILENAME[$i];
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

	if($ATLAS_CHANNEL_FILENAME_FORMAT[$i] == 0){
        	$temp2       =~ s/.img//;
	        $short_atlas_channel[$i] = $temp2 ;
		$temp3 = "$short_atlas_channel[$i]\.img";
	        $temp1 =~ s/\/$temp3//;
        	$atlas_channel_path[$i] = $temp1;
	}
	elsif($ATLAS_CHANNEL_FILENAME_FORMAT[$i]>0 && $ATLAS_CHANNEL_FILENAME_FORMAT[$i]<4){
        	$short_atlas_channel[$i] = $temp2 ;
		$temp3 = $short_atlas_channel[$i];
	       	$temp1 =~ s/\/$temp3//;
	        $atlas_channel_path[$i] = $temp1;
	}

$j=$i+1;
print "subject_channel_path  $j :\t $subject_channel_path[$i] \n";
print "short_subject_channel $j :\t $short_subject_channel[$i] \n";
print "atlas_channel_path    $j :\t $atlas_channel_path[$i] \n";
print "short_atlas_channel   $j :\t $short_atlas_channel[$i] \n\n";

}






if($SUBJECT_TENSOR_GIVEN == 1){
        $temp1 = $SUBJECT_TENSOR_FILENAME ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;
#        $temp2       =~ s/.d$//;

        $short_subject_tensor = $temp2 ;
#        $temp3 = "$short_subject_tensor\.d";
        $temp3 = "$short_subject_tensor";
        $temp1 =~ s/\/$temp3//;
        $subject_tensor_path = $temp1;
print "subject_tensor_path     :\t $subject_tensor_path  \n";
print "short_subject_tensor    :\t $short_subject_tensor \n\n";
}
if($ATLAS_TENSOR_GIVEN == 1){
        $temp1 = $ATLAS_TENSOR_FILENAME ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;
#        $temp2       =~ s/.d$//;
        $short_atlas_tensor = $temp2 ;
#        $temp3 = "$short_atlas_tensor\.d";
        $temp3 = "$short_atlas_tensor";
        $temp1 =~ s/\/$temp3//;
        $atlas_tensor_path = $temp1;
print "atlas_tensor_path       :\t $atlas_tensor_path  \n";
print "short_atlas_tensor      :\t $short_atlas_tensor \n\n";
}

if($SUBJECT_LABEL_GIVEN > 0){
for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) {	$j=$k+1;

        $temp1 = $SUBJECT_LABEL_FILENAME[$k] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

        if($SUBJECT_LABEL_FILENAME_FORMAT[$k] == 0){
                $temp2       =~ s/.img//;
                $short_subject_label[$k] = $temp2 ;
                $temp3 = "$short_subject_label[$k]\.img";
                $temp1 =~ s/\/$temp3//;
                $subject_label_path[$k] = $temp1;
        }
        else{
                $short_subject_label[$k] = $temp2 ;
                $temp3 = $short_subject_label[$k];
                $temp1 =~ s/\/$temp3//;
                $subject_label_path[$k] = $temp1;
        }

print "subject_label_path-$j    :\t $subject_label_path[$k]  \n";
print "short_subject_label-$j   :\t $short_subject_label[$k] \n";
}
print "\n";
}

if($ATLAS_LABEL_GIVEN > 0){
for($k=0; $k<$ATLAS_LABEL_GIVEN; $k++) {	$j=$k+1;
        $temp1 = $ATLAS_LABEL_FILENAME[$k] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

	if($ATLAS_LABEL_FILENAME_FORMAT[$k] == 0){
        	$temp2       =~ s/.img//;
	        $short_atlas_label[$k] = $temp2 ;
		$temp3 = "$short_atlas_label[$k]\.img";
	        $temp1 =~ s/\/$temp3//;
        	$atlas_label_path[$k] = $temp1;
	}
	else{
        	$short_atlas_label[$k] = $temp2 ;
		$temp3 = $short_atlas_label[$k];
        	$temp1 =~ s/\/$temp3//;
	        $atlas_label_path[$k] = $temp1;
	}

print "atlas_label_path-$j      :\t $atlas_label_path[$k]  \n";
print "short_atlas_label-$j     :\t $short_atlas_label[$k] \n";
}
print "\n";
}

if($SUBJECT_GRAYS_GIVEN > 0){
for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {	$j=$k+1;
        $temp1 = $SUBJECT_GRAYS_FILENAME[$k] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

        if($SUBJECT_GRAYS_FILENAME_FORMAT[$k] == 0){
                $temp2       =~ s/.img//;
                $short_subject_grays[$k] = $temp2 ;
                $temp3 = "$short_subject_grays[$k]\.img";
                $temp1 =~ s/\/$temp3//;
                $subject_grays_path[$k] = $temp1;
        }
        else{
                $short_subject_grays[$k] = $temp2 ;
                $temp3 = $short_subject_grays[$k];
                $temp1 =~ s/\/$temp3//;
                $subject_grays_path[$k] = $temp1;
        }

print "subject_grays_path-$j    :\t $subject_grays_path[$k]  \n";
print "short_subject_grays-$j   :\t $short_subject_grays[$k] \n";
}
print "\n";
}

if($ATLAS_GRAYS_GIVEN > 0){
for($k=0; $k<$ATLAS_GRAYS_GIVEN; $k++) {	$j=$k+1;
        $temp1 = $ATLAS_GRAYS_FILENAME[$k] ;
        $temp2 = $temp1;
        chomp $temp2;
        $temp2 =~ /^.+\/(.+)/;
        $temp2 = $1;

	if($ATLAS_GRAYS_FILENAME_FORMAT[$k] == 0){
        	$temp2       =~ s/.img//;
	        $short_atlas_grays[$k] = $temp2 ;
		$temp3 = "$short_atlas_grays[$k]\.img";
	        $temp1 =~ s/\/$temp3//;
        	$atlas_grays_path[$k] = $temp1;
	}
	else{
        	$short_atlas_grays[$k] = $temp2 ;
		$temp3 = $short_atlas_grays[$k];
        	$temp1 =~ s/\/$temp3//;
	        $atlas_grays_path[$k] = $temp1;
	}

print "atlas_grays_path-$j      :\t $atlas_grays_path[$k]  \n";
print "short_atlas_grays-$j     :\t $short_atlas_grays[$k] \n";
}
print "\n";
}


}





sub create_main_subdirectories{

		$temp1 = "0_origdata";		$subdirectory0 = $temp1;        $full_subdirectory0  = "$output_path\/$temp1";
        $temp1 = "1_formatchange";	$subdirectory1 = $temp1;        $full_subdirectory1  = "$output_path\/$temp1";
        $temp1 = "2_masked";		$subdirectory2 = $temp1;        $full_subdirectory2  = "$output_path\/$temp1";
        $temp1 = "3_resampled";		$subdirectory3 = $temp1;        $full_subdirectory3  = "$output_path\/$temp1";
        $temp1 = "4_air";			$subdirectory4 = $temp1;        $full_subdirectory4  = "$output_path\/$temp1";
        $temp1 = "5_histmatch";		$subdirectory5 = $temp1;        $full_subdirectory5  = "$output_path\/$temp1";
        $temp1 = "6_lddmm";			$subdirectory6 = $temp1;		$full_subdirectory6  = "$output_path\/$temp1";


        $sim1 = `mkdir "$full_subdirectory0"`;
        $sim1 = `mkdir "$full_subdirectory1"`;
        $sim1 = `mkdir "$full_subdirectory2"`;
        $sim1 = `mkdir "$full_subdirectory3"`;
        $sim1 = `mkdir "$full_subdirectory4"`;
        $sim1 = `mkdir "$full_subdirectory5"`;
        $sim1 = `mkdir "$full_subdirectory6"`;
if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
        $temp1 = "6_lddmm_temp";	$subdirectory66 = $temp1;	$full_subdirectory66 = "$output_path\/$temp1";
        $sim1 = `mkdir "$full_subdirectory66"`;
	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
		$temp1 = "$full_subdirectory66\/iterno_$kkk";
	        $sim1 = `mkdir "$temp1"`;
	}
}

	$lddmminputs = "lddmminputs";
        $temp1 = "$full_subdirectory5\/$lddmminputs";		
	$sim1 = `mkdir "$temp1"`;

	$lddmmtxt = "txt";
        $temp1 = "$full_subdirectory6\/txt";		
	$sim1 = `mkdir "$temp1"`;



}


sub create_other_subdirectories{
	$s_tensor = "s_tensor";
	$s_other  = "s_other";
	$a_tensor = "a_tensor";
	$a_other  = "a_other";


if($SUBJECT_TENSOR_GIVEN == 1){
	$sim1  = `mkdir "$subdirectory0\/$s_tensor"`;
	$sim1  = `mkdir "$subdirectory1\/$s_tensor"`;
	$sim1  = `mkdir "$subdirectory2\/$s_tensor"`;
	$sim1  = `mkdir "$subdirectory3\/$s_tensor"`;
	$sim1  = `mkdir "$subdirectory4\/$s_tensor"`;
#	$sim1  = `mkdir "$subdirectory5\/$s_tensor"`;
	$sim1  = `mkdir "$subdirectory6\/$s_tensor"`;
	if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
	       	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
                $temp1 = "$full_subdirectory66\/iterno_$kkk\/$s_tensor";
                $sim1 = `mkdir "$temp1"`;
        	}
	}
}


if($SUBJECT_GRAYS_GIVEN > 0  || $SUBJECT_LABEL_GIVEN > 0){
	$sim1  = `mkdir "$subdirectory0\/$s_other"`;
	$sim1  = `mkdir "$subdirectory1\/$s_other"`;
	$sim1  = `mkdir "$subdirectory2\/$s_other"`;
	$sim1  = `mkdir "$subdirectory3\/$s_other"`;
	$sim1  = `mkdir "$subdirectory4\/$s_other"`;
#	$sim1  = `mkdir "$subdirectory5\/$s_other"`;
	$sim1  = `mkdir "$subdirectory6\/$s_other"`;
	if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
	       	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
                $temp1 = "$full_subdirectory66\/iterno_$kkk\/$s_other";
                $sim1 = `mkdir "$temp1"`;
        	}
	}
}

if($ATLAS_TENSOR_GIVEN == 1){
	$sim1  = `mkdir "$subdirectory0\/$a_tensor"`;
	$sim1  = `mkdir "$subdirectory1\/$a_tensor"`;
	$sim1  = `mkdir "$subdirectory2\/$a_tensor"`;
	$sim1  = `mkdir "$subdirectory3\/$a_tensor"`;
	$sim1  = `mkdir "$subdirectory4\/$a_tensor"`;
#	$sim1  = `mkdir "$subdirectory5\/$a_tensor"`;
#	$sim1  = `mkdir "$subdirectory6\/$a_tensor"`;
	if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
	       	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
                $temp1 = "$full_subdirectory66\/iterno_$kkk\/$a_tensor";
                $sim1 = `mkdir "$temp1"`;
        	}
	}
}

if($ATLAS_GRAYS_GIVEN == 1 || $ATLAS_LABEL_GIVEN == 1){
	$sim1  = `mkdir "$subdirectory0\/$a_other"`;
	$sim1  = `mkdir "$subdirectory1\/$a_other"`;
	$sim1  = `mkdir "$subdirectory2\/$a_other"`;
	$sim1  = `mkdir "$subdirectory3\/$a_other"`;
	$sim1  = `mkdir "$subdirectory4\/$a_other"`;
#	$sim1  = `mkdir "$subdirectory5\/$a_other"`;
#	$sim1  = `mkdir "$subdirectory6\/$a_other"`;
	if($LDDMM_OUTPUT_LEVEL==2 && $lddmm_cascading_iteration_number>1){
	       	for($kkk=1; $kkk<$lddmm_cascading_iteration_number; $kkk++) {
                $temp1 = "$full_subdirectory66\/iterno_$kkk\/$a_other";
                $sim1 = `mkdir "$temp1"`;
        	}
	}
}


}


sub read_parameter_file_format{
	my($INPUT_PARAM_FILE)    = $_[0];
	print "INPUT PARAMETER FILE              : $INPUT_PARAM_FILE\n";
	open(DAT, $INPUT_PARAM_FILE) || die("Could not open param file!");        @params1=<DAT>;        close(DAT);
#print "CONTENTS OF PARAMETER FILE        : \n";
#print "*********************************************************************************************\n";
#print "*********************************************************************************************\n";
#print "*********************************************************************************************\n";
# 	for($j=0; $j<=$#params1; $j++) {
#		print "$params1[$j]";
#	}
#print "*********************************************************************************************\n";
#print "*********************************************************************************************\n";
#print "*********************************************************************************************\n\n";
	$search_string = "PARAMETER_FILE_FORMAT";	 
	#my $index1 = find_stringindex_instringarray($search_string,\@params1);	$i=$index1+1;
	$temp = $params1[$i];   $i=$i+1;		chomp $temp;    @temp1 = split(' ',$temp);
	$PARAMETER_FILE_FORMAT = $temp1[0];	
	print "PARAMETER FILE FORMAT                             : $PARAMETER_FILE_FORMAT\n";	
	if($PARAMETER_FILE_FORMAT<1 || $PARAMETER_FILE_FORMAT>1){
		print "ERROR: Subject file format can be 1 or 1 \n";
		print "...exiting\n\n";
		exit;
	}
}


sub check_print_parameters1{


#checking if any of the subject air or lddmm data is in analyze format
$subjectformat_analyze_true=0;
if($DO_AIR_TRUE==1 && $subjectformat_analyze_true==0){
	if($SUBJECT_AIR_FILENAME_FORMAT[0]==0){
		$SUBJECT_SIZERES_FILENAME = $SUBJECT_AIR_FILENAME[0]; 
		$subjectformat_analyze_true=1;
	}
}
if($subjectformat_analyze_true==0){
	for($k=0; $k<$CHANNEL_NO; $k++) {	
		if($SUBJECT_CHANNEL_FILENAME_FORMAT[$k]==0){
			$SUBJECT_SIZERES_FILENAME = $SUBJECT_CHANNEL_FILENAME[$k]; 
			$subjectformat_analyze_true=1;
			last;
		}
	}
}


if($subjectformat_analyze_true==0 && $SUBJECT_SIZERES_GIVEN==0){
	print "ERROR: Subject size resolution was not entered and no subject data (for AIR or LDDMM) has analyze format\n";
	print "...exiting\n\n";
	exit;
}
if($subjectformat_analyze_true==1 && $SUBJECT_SIZERES_GIVEN==1){
	print "WARNING: Subject size resolution was entered but it will not be used\n";
	print "WARNING: One of the atlas analyze data will be used to read size and resolution\n\n";
}

#checking if any of the atlas air or lddmm data is in analyze format
$atlasformat_analyze_true=0;
if($DO_AIR_TRUE==1 && $atlasformat_analyze_true==0){
	if($ATLAS_AIR_FILENAME_FORMAT[0]==0){
		$ATLAS_SIZERES_FILENAME = $ATLAS_AIR_FILENAME[0]; 
		$atlasformat_analyze_true=1;
	}
}
if($atlasformat_analyze_true==0){
	for($k=0; $k<$CHANNEL_NO; $k++) {	
		if($ATLAS_CHANNEL_FILENAME_FORMAT[$k]==0){
			$ATLAS_SIZERES_FILENAME = $ATLAS_CHANNEL_FILENAME[$k]; 
			$atlasformat_analyze_true=1;
			last;
		}
	}
}
if($atlasformat_analyze_true==0 && $ATLAS_SIZERES_GIVEN==0){
	print "ERROR: Atlas size resolution was not entered and no atlas data (for AIR or LDDMM) has analyze format\n";
	print "...exiting\n\n";
	exit;
}
if($atlasformat_analyze_true==1 && $ATLAS_SIZERES_GIVEN==1){
	print "WARNING: Atlas size resolution was entered but it will not be used\n";
	print "WARNING: One of the subject analyze data will be used to read size and resolution\n\n";

}
               

#creating output directory if necessary	
if($subjectformat_analyze_true==1 || $atlasformat_analyze_true==1){	
	$sim1  = `mkdir $OUTPUT_FOLDER`;	
}

if($subjectformat_analyze_true==1){
	$temp1 = "$SUBJECT_SIZERES_FILENAME";
	$temp2 = "$OUTPUT_FOLDER/subject.imgsizeres";
        $sim1 = `$IMG_saveimgsize_resolution $temp1 $temp2`;
        open(DAT, $temp2) || die("Could not open directory file!");        @params1=<DAT>;        close(DAT);
        $i=0;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $INPUT_SUBJECT_SIZE[$jj] = "$temp1[$jj]";        }
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $INPUT_SUBJECT_RES[$jj] = "$temp1[$jj]";        }
}
if($atlasformat_analyze_true==1){
	$temp1 = "$ATLAS_SIZERES_FILENAME";
	$temp2 = "$OUTPUT_FOLDER/atlas.imgsizeres";
        $sim1 = `$IMG_saveimgsize_resolution $temp1 $temp2`;
        open(DAT, $temp2) || die("Could not open directory file!");        @params1=<DAT>;        close(DAT);
        $i=0;
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $INPUT_ATLAS_SIZE[$jj] = "$temp1[$jj]";        }
        $temp = $params1[$i];   $i=$i+1;        chomp $temp;    @temp1 = split(' ',$temp);
        for($jj=0; $jj<3; $jj++) {      $INPUT_ATLAS_RES[$jj] = "$temp1[$jj]";        }
}


#if($atlasformat_analyze_true==1){print "$ATLAS_SIZERES_FILENAME\n";}



#checking if tensor trace is used for any lddmm channel 
#if($DO_LDDMM_TRUE==1){
	$tensortrace_4subject_lddmmch1_true=0;
	if($SUBJECT_CHANNEL_FILENAME_FORMAT[0]==4 && $SUBJECT_TENSOR_GIVEN==1){
		$tensortrace_4subject_lddmmch1_true=1;
	}
	elsif($SUBJECT_CHANNEL_FILENAME_FORMAT[0]==4 && $SUBJECT_TENSOR_GIVEN==0){
	print "ERROR: No subject tensor is given\n";
	print "A different file should be entered for subject channel-1 in lddmm\n";
	print "...exiting\n\n";
	exit;	
	}

	$tensortrace_4atlas_lddmmch1_true=0;
	if($ATLAS_CHANNEL_FILENAME_FORMAT[0]==4 && $ATLAS_TENSOR_GIVEN==1){
		$tensortrace_4atlas_lddmmch1_true=1;
	}
	elsif($ATLAS_CHANNEL_FILENAME_FORMAT[0]==4 && $ATLAS_TENSOR_GIVEN==0){
	print "ERROR: No atlas tensor is given\n";
	print "A different file should be entered for atlas channel-1 in lddmm\n";
	print "...exiting\n\n";
	exit;	
	}
#}


$subjectformat_analyze_true;
$SUBJECT_SIZERES_FILENAME;

$atlasformat_analyze_true;
$ATLAS_SIZERES_FILENAME;


$tensortrace_4subject_lddmmch1_true;
$tensortrace_4atlas_lddmmch1_true;




print "PARAMETER FILE FORMAT                             : $PARAMETER_FILE_FORMAT\n";
print "OUTPUT FOLDER                                     : $OUTPUT_FOLDER\n";


if($DO_SUBJECT_SKULLSTRIP_TRUE>0)	{	
print "SKULLSTRIP SUBJECT ?                              : (YES) $DO_SUBJECT_SKULLSTRIP_TRUE \n";	
	if($DO_SUBJECT_SKULLSTRIP_TRUE==1)	{	
	print "\tW5 param                                  : $SKULLSTRIPPING_W5_PARAM\n";
        print "\tfilename                                  : $SUBJECT_SKULLSTRIP_FILENAME[0]\n";
        print "\tfile format                               : $SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]\n";
	}
	elsif($DO_SUBJECT_SKULLSTRIP_TRUE==2)	{
	print "\tThe following mask file was entered\n";	
        print "\tfilename                                  : $SUBJECT_SKULLSTRIP_FILENAME[0]\n";
        print "\tfile format                               : $SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0]\n";
	}
	elsif($DO_SUBJECT_SKULLSTRIP_TRUE==3)	{
	print "\tSubject channel-1 in lddmm will be used for skull stripping\n";	
	}	
}
else			{	
print "SKULLSTRIP SUBJECT ?                              : (NO) $DO_SUBJECT_SKULLSTRIP_TRUE \n";	
}


if($DO_AIR_TRUE==1)	{	
print "AIR REGISTRATION ?                                : (YES) $DO_AIR_TRUE \n";	
        print "\tsubject AIR filename                      : $SUBJECT_AIR_FILENAME[0]\n";
        print "\tsubject AIR file format                   : $SUBJECT_AIR_FILENAME_FORMAT[0]\n";
        print "\tatlas AIR filename                        : $ATLAS_AIR_FILENAME[0]\n";
        print "\tatlas AIR file format                     : $ATLAS_AIR_FILENAME_FORMAT[0]\n";
}
elsif($DO_AIR_TRUE==2)	{	
print "AIR REGISTRATION ?                                : (YES) $DO_AIR_TRUE \n";	
	print "\tSubject channel-1 in lddmm will be used for air registration\n";	
}
else			{	
print "AIR REGISTRATION ?                                : (NO) $DO_AIR_TRUE \n";	
}

#if($DO_LDDMM_TRUE==1)	{	
#print "LDDMM REGISTRATION ?                              : (YES) $DO_LDDMM_TRUE \n";	
print "LDDMM PARAMETERS                                  :\n";	

	if($LDDMM_OUTPUT_LEVEL ==1){
	print "\tLDDMM OUTPUT LEVEL                        : $LDDMM_OUTPUT_LEVEL (Only final Hmap/Kimap)\n";
	}
	elsif($LDDMM_OUTPUT_LEVEL ==2){
	print "\tLDDMM OUTPUT LEVEL                        : $LDDMM_OUTPUT_LEVEL (Also Intermediate Hmap/Kimap)\n";
	}

	print "\tlddmm_cascading_iteration_type            : $lddmm_cascading_iteration_type\n";
	print "\tlddmm_cascading_iteration_number          : $lddmm_cascading_iteration_number\n";
	for($k=0; $k<$lddmm_cascading_iteration_number; $k++) {		$j = $k+1;
       	print "\talpha for lddmm iteration $j               : $lddmm_alphalist[$k]\n";
	}
	for($k=0; $k<$lddmm_cascading_iteration_number; $k++) {		$j = $k+1;
       	print "\ttimestep for lddmm iteration $j            : $lddmm_timesteplist[$k]\n";
	}
print "CHANNEL NUMBER                                    : $CHANNEL_NO\n";
	for($k=0; $k<$CHANNEL_NO; $k++) {			        $j = $k+1;
		if($k==0 && $SUBJECT_CHANNEL_FILENAME_FORMAT[$k]==4){
		print "\tTensor trace will be calculated and used in lddmm as subject channel $j\n";
		}
		else{
        	print "\tchannel $j subject filename                : $SUBJECT_CHANNEL_FILENAME[$k]\n";
	        print "\tchannel $j subject file format             : $SUBJECT_CHANNEL_FILENAME_FORMAT[$k]\n";
		}
		if($k==0 && $ATLAS_CHANNEL_FILENAME_FORMAT[$k]==4){
		print "\tTensor trace will be calculated and used in lddmm as atlas channel $j\n";
		}
		else{
	        print "\tchannel $j atlas filename                  : $ATLAS_CHANNEL_FILENAME[$k]\n";
        	print "\tchannel $j atlas file format               : $ATLAS_CHANNEL_FILENAME_FORMAT[$k]\n";
		}
	        print "\tchannel $j sigma                           : $lddmm_sigma[$k]\n";
        	print "\tchannel $j histogram matching              : $lddmm_histmatch_true[$k]\n";
	}
#}
#else			{	
#print "LDDMM REGISTRATION ?                              : (NO) $DO_LDDMM_TRUE \n";	
#}



#if($SUBJECT_SIZERES_GIVEN==1){}
#if($ATLAS_SIZERES_GIVEN==1){}

print "SUBJECT SIZE AND RESOLUTION                       :";
if($subjectformat_analyze_true==1)	{                print "It was read from $SUBJECT_SIZERES_FILENAME\n";}
else				  				{                print "It was read from parameter file\n";} 	
print "\tsize                                      : $INPUT_SUBJECT_SIZE[0] $INPUT_SUBJECT_SIZE[1] $INPUT_SUBJECT_SIZE[2]\n";
print "\tresolution                                : $INPUT_SUBJECT_RES[0] $INPUT_SUBJECT_RES[1] $INPUT_SUBJECT_RES[2]\n";

print "ATLAS SIZE AND RESOLUTION                         :";
if($atlasformat_analyze_true==1)	{                  print "It was read from $ATLAS_SIZERES_FILENAME\n";}
else								{                  print "It was read from parameter file\n";} 	
print "\tsize                                      : $INPUT_ATLAS_SIZE[0] $INPUT_ATLAS_SIZE[1] $INPUT_ATLAS_SIZE[2]\n";
print "\tresolution                                : $INPUT_ATLAS_RES[0] $INPUT_ATLAS_RES[1] $INPUT_ATLAS_RES[2]\n";


if($ANALYZE_Y_FLIPPING_TRUE==1){
print "ANALYZE IMAGES Y-FLIPPED  ?                       : (YES) $ANALYZE_Y_FLIPPING_TRUE \n";
}
else{
print "ANALYZE IMAGES Y-FLIPPED  ?                       : (NO) $ANALYZE_Y_FLIPPING_TRUE \n";
$ANALYZE_Y_FLIPPING_TRUE = 0;
}




if($SUBJECT_TENSOR_GIVEN == 1){
print "SUBJECT TENSOR DATA TO BE TRANSFORMED ?           : (YES) $SUBJECT_TENSOR_GIVEN \n";
	print "\tsubject tensor filename                   : $SUBJECT_TENSOR_FILENAME\n";
	print "\tsubject tensor format                     : $SUBJECT_TENSOR_FILENAME_FORMAT\n";
	if($SUBJECT_TENSOR_OUTPUT_LEVEL==1){
	print "\tsubject tensor output level               : $SUBJECT_TENSOR_OUTPUT_LEVEL (Only deformed tensor data)\n";
	}
	elsif($SUBJECT_TENSOR_OUTPUT_LEVEL==2){
	print "\tsubject tensor output level               : $SUBJECT_TENSOR_OUTPUT_LEVEL (Also other files from tensor data)\n";
	}
}
else{
print "SUBJECT TENSOR DATA TO BE TRANSFORMED ?           : (NO) $SUBJECT_TENSOR_GIVEN \n";
}

	
if($SUBJECT_GRAYS_GIVEN > 0 ){
print "SUBJECT GRAYSCALE DATA TO BE TRANSFORMED ?        : (YES) $SUBJECT_GRAYS_GIVEN \n";
	for($k=0; $k<$SUBJECT_GRAYS_GIVEN; $k++) {                               $j = $k+1;
	print "\tsubject grayscale filename                : $SUBJECT_GRAYS_FILENAME[$k]\n";
	print "\tsubject grayscale format                  : $SUBJECT_GRAYS_FILENAME_FORMAT[$k]\n";
	}
}
else{
print "SUBJECT GRAYSCALE DATA TO BE TRANSFORMED ?        : (NO) $SUBJECT_GRAYS_GIVEN \n";
}

if($SUBJECT_LABEL_GIVEN > 0){
print "SUBJECT LABEL DATA TO BE TRANSFORMED ?            : (YES) $SUBJECT_LABEL_GIVEN \n";
	for($k=0; $k<$SUBJECT_LABEL_GIVEN; $k++) { 				$j = $k+1;
	print "\tsubject label filename                    : $SUBJECT_LABEL_FILENAME[$k]\n";
	print "\tsubject label format                      : $SUBJECT_LABEL_FILENAME_FORMAT[$k]\n";
	}
}
else{
print "SUBJECT LABEL DATA TO BE TRANSFORMED ?            : (NO) $SUBJECT_LABEL_GIVEN \n";
}





if($ATLAS_TENSOR_GIVEN == 1){
print "ATLAS TENSOR DATA TO BE TRANSFORMED ?             : (YES) $ATLAS_TENSOR_GIVEN \n";
	print "\tatlas tensor filename                     : $ATLAS_TENSOR_FILENAME\n";
	print "\tatlas tensor format                       : $ATLAS_TENSOR_FILENAME_FORMAT\n";
	if($ATLAS_TENSOR_OUTPUT_LEVEL==1){
	print "\tatlas tensor output level                 : $ATLAS_TENSOR_OUTPUT_LEVEL (Only deformed tensor data)\n";
	}
	elsif($ATLAS_TENSOR_OUTPUT_LEVEL==2){
	print "\tatlas tensor output level                 : $ATLAS_TENSOR_OUTPUT_LEVEL (Also other files from tensor data)\n";
	}
}
else{
print "ATLAS TENSOR DATA TO BE TRANSFORMED ?             : (NO) $ATLAS_TENSOR_GIVEN \n";
}


if($ATLAS_GRAYS_GIVEN > 0){
print "ATLAS GRAYSCALE DATA TO BE TRANSFORMED ?          : (YES) $ATLAS_GRAYS_GIVEN \n";
	for($k=0; $k<$ATLAS_GRAYS_GIVEN; $k++) { 			$j = $k+1;
	print "\tatlas grayscale filename                  : $ATLAS_GRAYS_FILENAME[$k]\n";
	print "\tatlas grayscale format                    : $ATLAS_GRAYS_FILENAME_FORMAT[$k]\n";
	}
}
else{
print "ATLAS GRAYSCALE DATA TO BE TRANSFORMED ?          : (NO) $ATLAS_GRAYS_GIVEN \n";
}

if($ATLAS_LABEL_GIVEN > 0){
print "ATLAS LABEL DATA TO BE TRANSFORMED ?              : (YES) $ATLAS_LABEL_GIVEN \n";
	for($k=0; $k<$ATLAS_LABEL_GIVEN; $k++) { 			$j = $k+1;
	print "\tatlas label filename                      : $ATLAS_LABEL_FILENAME[$k]\n";
	print "\tatlas label format                        : $ATLAS_LABEL_FILENAME_FORMAT[$k]\n";
	}
}
else{
print "ATLAS LABEL DATA TO BE TRANSFORMED ?              : (NO) $ATLAS_LABEL_GIVEN \n";
}

print "USER NAME                                         : $USERNAME \n";
print "USER EMAIL                                        : $USEREMAIL \n";
print "\n\n";

#if($HISTMATCH_OUTPUT_LEVEL ==1){
#print "SAVE HISTOGRAM MATCHED DATA                      : (YES) $HISTMATCH_OUTPUT_LEVEL \n";
#}
#elsif($HISTMATCH_OUTPUT_LEVEL ==2){
#print "SAVE HISTOGRAM MATCHED DATA                      : (NO) $HISTMATCH_OUTPUT_LEVEL  \n";
#}


}






sub initialize_parameters{

        $PARAMETER_FILE_FORMAT 		= 1;
	$OUTPUT_FOLDER			= "output_folder";

        $DO_SUBJECT_SKULLSTRIP_TRUE 	= 1;
	$SUBJECT_SKULLSTRIP_FILENAME[0] = "subject_skullstrip.img";
	$SUBJECT_SKULLSTRIP_FILENAME_FORMAT[0] = 0;
	$SKULLSTRIPPING_W5_PARAM 	= 0;

        $DO_AIR_TRUE 			= 1;
	$SUBJECT_AIR_FILENAME[0] 	= "subject_airfile.img";
	$SUBJECT_AIR_FILENAME_FORMAT[0] = 0;
	$ATLAS_AIR_FILENAME[0] 		= "atlas_airfile.img";
	$ATLAS_AIR_FILENAME_FORMAT[0]	= 0;


#        $DO_LDDMM_TRUE 				= 1;
        $LDDMM_OUTPUT_LEVEL 			= 1;
	$lddmm_cascading_iteration_type		= 1;
	$lddmm_cascading_iteration_number	= 3;
	$lddmm_alphalist[0]=0.01;   $lddmm_alphalist[1]=0.005;  $lddmm_alphalist[2]=0.002;
	$lddmm_timesteplist[0]=10;  $lddmm_timesteplist[1]=10;  $lddmm_timesteplist[2]=10;

	$CHANNEL_NO				= 2;			
	$SUBJECT_CHANNEL_FILENAME[0] 		= "subject_channel_1.img";
	$SUBJECT_CHANNEL_FILENAME[1] 		= "subject_channel_2.img";
	$SUBJECT_CHANNEL_FILENAME_FORMAT[0] 	= 0;
	$SUBJECT_CHANNEL_FILENAME_FORMAT[1] 	= 0;
	$ATLAS_CHANNEL_FILENAME[0] 		= "atlas_channel_1.img";
	$ATLAS_CHANNEL_FILENAME[1] 		= "atlas_channel_2.img";
	$ATLAS_CHANNEL_FILENAME_FORMAT[0] 	= 0;
	$ATLAS_CHANNEL_FILENAME_FORMAT[1] 	= 0;
	$lddmm_histmatch_true[0]		= 1;
	$lddmm_histmatch_true[1]		= 1;
	$lddmm_sigma[0]			        = 1;
	$lddmm_sigma[1]			        = 1;



	$SUBJECT_SIZERES_GIVEN	= 1;
	$INPUT_SUBJECT_SIZE[0]=200; $INPUT_SUBJECT_SIZE[1]=220; $INPUT_SUBJECT_SIZE[2]=180;
	$INPUT_SUBJECT_RES[0]=1;    $INPUT_SUBJECT_RES[1]=1;	$INPUT_SUBJECT_RES[2]=1;

	$ATLAS_SIZERES_GIVEN	= 1;
	$INPUT_ATLAS_SIZE[0]=181; $INPUT_ATLAS_SIZE[1]=217; $INPUT_ATLAS_SIZE[2]=182;
	$INPUT_ATLAS_RES[0]=1;    $INPUT_ATLAS_RES[1]=1;    $INPUT_ATLAS_RES[2]=1;

#        $HISTMATCH_OUTPUT_LEVEL 		= 1;

	$SUBJECT_TENSOR_GIVEN	          	= 1;
	$SUBJECT_TENSOR_FILENAME	  	= "subject_tensor.d";
	$SUBJECT_TENSOR_FILENAME_FORMAT		= 1;
	$SUBJECT_TENSOR_OUTPUT_LEVEL		= 1;

	$SUBJECT_GRAYS_GIVEN    	  	= 2;
	$SUBJECT_GRAYS_FILENAME[0] 	  	= "subject_grayscale1.img";
	$SUBJECT_GRAYS_FILENAME_FORMAT[0] 	= 0;
	$SUBJECT_GRAYS_FILENAME[1] 	  	= "subject_grayscale2.img";
	$SUBJECT_GRAYS_FILENAME_FORMAT[1] 	= 0;

	$SUBJECT_LABEL_GIVEN    		= 2;
	$SUBJECT_LABEL_FILENAME[0]		= "subject_label1.img";
	$SUBJECT_LABEL_FILENAME_FORMAT[0] 	= 0;
	$SUBJECT_LABEL_FILENAME[1]		= "subject_label2.img";
	$SUBJECT_LABEL_FILENAME_FORMAT[1] 	= 0;


	$ATLAS_TENSOR_GIVEN    			= 1;
	$ATLAS_TENSOR_FILENAME			= "atlas_tensor.d";
	$ATLAS_TENSOR_FILENAME_FORMAT		= 1;
	$ATLAS_TENSOR_OUTPUT_LEVEL 		= 1;
	
	$ATLAS_GRAYS_GIVEN    			= 2;
	$ATLAS_GRAYS_FILENAME[0] 		= "atlas_grayscale1.img";
	$ATLAS_GRAYS_FILENAME_FORMAT[0]		= 0;
	$ATLAS_GRAYS_FILENAME[1] 		= "atlas_grayscale2.img";
	$ATLAS_GRAYS_FILENAME_FORMAT[1]		= 0;

	$ATLAS_LABEL_GIVEN			= 2;
	$ATLAS_LABEL_FILENAME[0] 		= "atlas_label1.img";
	$ATLAS_LABEL_FILENAME_FORMAT[0] 	= 0;
	$ATLAS_LABEL_FILENAME[1] 		= "atlas_label2.img";
	$ATLAS_LABEL_FILENAME_FORMAT[1] 	= 0;

	$ANALYZE_Y_FLIPPING_TRUE		= 1;

	$USERNAME  = "can";
	$USEREMAIL = "cceritog@hotmail.com";
	
	$USE_ORIGINAL_FNAMES_TRUE = 1;	
}



sub copy_data{

if($SUBJECT_TENSOR_GIVEN == 1){
}
else{
}

if($SUBJECT_GRAYS_GIVEN == 1){
}
else{
}

if($SUBJECT_LABEL_GIVEN == 1){
}
else{
}

if($ATLAS_TENSOR_GIVEN == 1){
}
else{
}

if($ATLAS_GRAYS_GIVEN == 1){
}
else{
}

if($ATLAS_LABEL_GIVEN == 1){
}
else{
}




}
