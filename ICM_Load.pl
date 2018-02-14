#!/usr/bin/env perl
#use Cwd qw(abs_path);

# Define I/O && initialize #
$info = "\nICM_Load.pl opens and rename all files within a given folder into ICM. It will need the full directory path. \n\t(IE: ./ICM_Load.pl /home/server/ICM_FOLDER/ [new_name])";

$input = "\nUsage\:  ICM_Load.pl [Your/.ob/Files/Folder] [new-name]\n (take away the [] when using this)

\t[Your/.ob/Files/Folder]\t\tPath to the .ob files\n\t[new-name]\t\tNew names due to ICM rename request
";
# Set default values that can be overwritten #
$directory = $ENV{'PWD'};
$icm_home = "~/icm-3.7-2b/";
$rname = "New-Name";

# Get flags #
if((@ARGV))
{
  if($#ARGV<3)
  {
    $help = 1;
    if($#ARGV=2)
    {
      print "\nInvalid Usage, please give the name of the project to rename to."
    }
    else
    {
      print "\nInvalid Usage, Please follow all usage rules.\n";
    }
  }
  else 
  {  
   for ($i=0; $i<=$#ARGV; $i++) 
   {
     $flag = $ARGV[$i];
     chomp $flag;
     if($flag eq "-h")
     {
       $help = 1;
       last;
     }
     else
     {
       switch ($i)
       {
         case 0
         {
           $directory=$ARGV[$i];
         }
         case 1
         {
           $rname = $ARGV[$i]
         }
         else
         {
           $help = 1;
           last;
         }
       }       
     }
   }
 }
}
else
{
  print "$input\n"; 
  exit();
}

# If user type the -h flag or put to many arguements, activate this help menu
if($help==1)
{
  print "$info";
  print "$input\n"; 
  exit();
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

# Reading the files in the directory and putting the files name into array DIR #
opendir(DIR,$directory);
my @files = readdir(DIR);
closedir(DIR);

# This section is used to set up the working directory for loadICM.icm to be made #
chdir $directory;

# Create ICM script #
open(ICM,'>',"loadICM.icm") || die "Please give me output filename $!"; #adjust the ICMscript 
#print ICM "#!$icm_home"."icm64 -g /home/server/icm-3.7-2b/_startup \n";

# This print portion is used to Hack ICM into loading its Library -Aingty Eung #
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

$newNameCount = 0;
for($i=0; $i<=$#files; $i++)
{
  chomp $files[$i];
  if($files[$i] eq "." || $files[$i] eq "..")
  {
    next;
  }
 else
 {
    $newNameCount++;
    print ICM "openFile '$directory$files[$i]'\n";
    print ICM "rename a_ Name(Name(\"$rname$newNameCount\" simple),object)\n";
 }

}
print ICM "quit\n";
close(ICM)||die $!;
# Ending creating ICM script #

# Running the command to load in files
system("$icm_home"."icm64 -g loadICM.icm && rm loadICM.icm"); 
# End running the command
###################################################################################################################################################################################
