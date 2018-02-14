#!/usr/bin/env perl

$fileinfo = "\nICM_PDB.pl created on 01-25-18\n";

# Define I/O && initialize #
$info = "\nICM_PDB.pl opens all files within a given folder into ICM and produces PDB files. It will need the full directory path. \n\t(IE: ./ICM_PDB.pl -d /home/server/OBfiles_Folder/)";
$input = "\nUsage\:  ICM_PDB.pl  Path/To/ObjectFiles\n\t* Path can be from current directory";

# Set default values that can be overwritten #
$directory = $ENV{'PWD'};
$icm_home = "/home/server/icm-3.7-2b";
$icmInhibit = "BcheTemplate.icb";

# Get flags #
if((@ARGV)) 
{
  if($#ARGV<1)
  {
   print "\nInvalid Usage, Please try again\n";
   $help = 1;
  }
  else 
  {  
   for ($i=0; $i<=$#ARGV; $i++) 
   {
     $flag = $ARGV[$i];
     chomp $flag;
     if($flag eq "-d"){ $i++; $directory=$ARGV[$i]; next; }
     if($flag eq "-h"){ $help = 1; }
   }
 }
}
else
{
  print "$input\n"; exit();
}

if($help==1)
{
  print "$fileinfo";
  print "$info";
  print "$input\n"; exit();
}

# Validing user's directory #
if(-e $directory)
{
  chomp $directory;
  if((substr $directory, -1) ne "/")
  {
    $directory = $directory."/";
  }
}
elsif (-e $ENV{'PWD'}.$directory)
{
  $directory = $ENV{'PWD'}."/".$directory;
  chomp $directory;
  if((substr $directory, -1) ne "/")
  {
    $directory = $directory."/";
  }
}
else
{
 print "\nThe directory:$directory does not exist!!!\n\n";
 exit;
}

#chdir $icm_home;

# Checking if Server's project file exist
if(-e $icm_home.$icmInhibit)
{
  # This section is used to set up the working directory for loadICM.icm to be made #
  chdir $directory;
  system("cp $icm_home"."$icmInhibit $directory"."BChEInhibit.icb");
  $icmInhibit = "BChEInhibit.icb";
  if (-e $icmInhibit)
  {
    print "success";
    $icm_home = "~/icm-3.7-2b/";
  }
  else
  {
    exit;
  }
  
}
else
{
  print "\nThe file: $icmInhibit does not exist in $icm_home!!! Please contact your system Admin.\n\n";
  exit;
}

# Reading the files in the directory and putting the files name into array DIR #
opendir(DIR,$directory);
#my @files = readdir(DIR);
my @obFiles;
$obFilesCount = 0;
while ( my $file = readdir(DIR) )
{
  # Ignoring all the non files in the directory, IE: "." & ".."
  next unless ( -f "$directory/$file" );

  # Finding files with .ob extension
  next unless ( $file =~ /\.ob$/ );
  $obFiles[$obFilesCount] = $file;
  $obFilesCount++;
}
closedir(DIR);

########################################### Create ICM script ###########################################
open(ICM,'>',"pdbICM.icm") || die "Please give me output filename $!"; #adjust the ICMscript 

# This print portion is used to Hack ICM into loading its Library -Aingty Eung :) #
print ICM "l_commands = no \n";
print ICM "l_info=no \n";
print ICM "if((Version()~\"*WIN*\" & Version() !~ \"*WINCONSOLE*\" ) | Version()~\"*MacOSX-IL*\") set directory s_projectsDir \n";
print ICM "read table s_icmhome + \"WEBLINK.tab\" system \n";
print ICM "set property WEBLINK show delete edit off \n";
print ICM "set property WEBAUTOLINK show delete edit off \n";
print ICM "set property DATABASE show delete edit off \n";
print ICM "print \"Startup> Loading libraries..\" \n";
print ICM "read libraries \n";
print ICM "read libraries mute \n";
print ICM "l_info=yes \n";
print ICM "call _aliases \n";
print ICM "call _macro \n";
print ICM "loadResources \n";
print ICM "call _bioinfo test \n";
print ICM "call _rebel test \n";
print ICM "call _ligedit test \n";
print ICM "call _docking test \n";
print ICM "l_info=yes \n";
print ICM "if (l_info) printf \"\\n\" \n";
print ICM "if (Index(Version(),\"NoGraphics\")==0 & !Exist(gui)) then \n";
print ICM "  print \" Hint> Run program with -g switch to start graphical user interface\" \n";
print ICM "endif \n";
print ICM "movie_init \n";
print ICM "print \"...ICM startup file executed...\" \n";
print ICM "l_info=yes \n";
print ICM "l_commands=yes \n";
# End of Hacked Print section #

$obFilesCount = 0;
print ICM "openFile '$directory$icmInhibit' 0 yes no no no ' append'\n";
for($i=0; $i<=$#obFiles; $i++)
{
  chomp $obFiles[$i];
  
  # $tempFile is now the file name without the extension, IE: dock2.ob ---> dock2
  $tempFile = substr $obFiles[$i], 0, length($obFiles[$i])-3;
  
  $obFilesCount++;
  print ICM "openFile '$directory$obFiles[$i]' 0 yes no no no ' append'\n";
  print ICM "move a_ a_1P0I_HumanBChE_ICM.\n";
  print ICM "write pdb a_1P0I_HumanBChE_ICM. '$directory$tempFile.ent'\n";
  print ICM "delete a_1P0I_HumanBChE_ICM.m\n";
}
print ICM "quit\n";
close(ICM)||die $!;
########################################### End of ICM script ###########################################

# Running the command to load in files
system("$icm_home"."icm64 -g pdbICM.icm"); 
system("rm pdbICM.icm && rename 's/\.ent/\.pdb/' *.ent && rm -f "."$icmInhibit");
# End running the command
#########################################################################################################