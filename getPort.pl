#!/usr/bin/perl -w
use Switch;
#(1) Header of Script
#----------------------------------
#Author :  Nguyen Hung Quan
#Website:  http://nguyenquanicd.blogspot.com/
#Function: List all input, output and inout of a module
#Note: Do NOT support RTL file with comment block /* */
#Reversion and History:
# v0.0 - Create firstly
#----------------------------------

#----------------------------------
#(2) Create the log file
#----------------------------------
my $myLog = "logGetPort.log";
system "/usr/bin/rm -f logGetPort.log";
open (LOGFILE, ">$myLog") or die because $!;
#----------------------------------
#(3) Get the current script name
#----------------------------------
my $myScript   = $0;
$myScript =~ s/\.\///;
#----------------------------------
#(4) Check input arguments
#----------------------------------
my $argNum  = @ARGV;
if ($argNum == 0) {
  printLog (LOGFILE, "[ERROR] Missing options - please fill your options\n");
  system "./$myScript -help";
  exit;
}
#----------------------------------
#(5) Common information
#----------------------------------
#Account name
my $wName = getlogin();
#Generation time
my $wTime = localtime();
#Working directory
my $wDir  = $ENV{PWD};
#----------------------------------
#(6) File header of output
#----------------------------------
my $headerFile;
$headerFile .= "#----------------------------------\n";
$headerFile .= "#Author              : $wName\n";
$headerFile .= "#Date                : $wTime\n";
$headerFile .= "#Working directory   : $wDir\n";
$headerFile .= "#Number of arguments : $argNum\n";
$headerFile .= "#Submitted command   : $myScript @ARGV\n";
$headerFile .= "#----------------------------------\n";
printLog (LOGFILE, $headerFile);
#----------------------------------
#(7) Global variables
#----------------------------------
my $rmComment = 0;
my $mode = "file";
my $myRtl;
my $myDir;
my $outLine;
my $outFile = "outputFile.txt";
#----------------------------------
#(8) Scan arguments and assign the setting values
#----------------------------------
#Note: Must have "use Switch" when using switch
while ($argNum != 0) {
  my $arg = shift(@ARGV); #Get an argument
  switch($arg) {
    #Get RTL file
    case "-f" {
      $myRtl = shift(@ARGV);
    }
    #Get RTL directory
    case "-d" {
      $myDir = shift(@ARGV);
      $mode = "dir";
    }
    #Set option "remove comment"
    case "-rc" {
      $rmComment = 1;
    }
    case "-help" {
      printLog (LOGFILE, "#----------------------------------\n");
      printLog (LOGFILE, "Format: $myScript <option 0> <value 0> ... <option N> <value N>\n");
      printLog (LOGFILE, "  Option:\n");
      printLog (LOGFILE, "  -f    : Declare an RTL file (only .sv or .v).\n          Example \"-f test.v\"\n");
      printLog (LOGFILE, "  -d    : Declare an RTL directory which contains RTL files (only .sv or .v).\n          Example \"-d working/rtlIn\"\n");
      printLog (LOGFILE, "  -rc   : Remove comments. Default is \"no-remove\".\n          Example \"-rc\"\n");
      printLog (LOGFILE, "  -help : Show all options.\n");
      printLog (LOGFILE, "#----------------------------------\n");
      exit;
    }
    else {
      printLog (LOGFILE, "[ERROR]Do NOT support the option: $arg\n");
      system "./$myScript -help";
      exit;
    }
  }
  $argNum  = @ARGV; #Update number of arguments
}

#----------------------------------
#(9) Main functions
#----------------------------------
if ($mode eq "dir") {
  printLog(LOGFILE, "--- START reading RTL directory: $myDir\n");
  #Get all file names and store to an array
  opendir (DIR, $myDir) or die because $!;
  my @fileList = readdir(DIR);
  closedir (DIR);
  #Scan all RTL files
  my $fileCount = 0;
  foreach $myRtl (@fileList) {
    if (($myRtl =~ /.sv$/) || ($myRtl =~ /.v$/)) {
      $fileCount++;
      #Return a unused signal array
      printLog(LOGFILE, "+ RTL file $fileCount    : $myRtl\n");
      $myRtl = "$myDir/$myRtl";
      $lineOut .= "$fileCount) $myRtl\n";
      $lineOut .= getPort($myRtl, $rmComment);
      $lineOut .= "\n";
    }
    printLog (LOGFILE, "\n");
  }
  printLog(LOGFILE, "--- END reading RTL directory: $myDir\n\n");
}
else {
  printLog(LOGFILE, "--- START reading RTL file: $myRtl\n");
  $lineOut .= "  $myRtl\n";
  $lineOut = getPort($myRtl, $rmComment);
  printLog(LOGFILE, "--- END reading RTL file: $myRtl\n\n");
}

open (OFILE, ">$outFile") or die because $!;
print OFILE $lineOut;
close(OFILE);

#----------------------------------
#(10) Close the log file - always put at END of Main function
#----------------------------------
close (LOGFILE);
#----------------------------------
#(11) Subrountines
#----------------------------------
#
#Print to a log file
#
sub printLog {
  my $fileHandle = shift;
  my $msg        = shift;
  #
  print "$msg";
  print $fileHandle $msg;
} #printLog
#
#Read a RTL file and return a unused signal array
#
sub getPort {
  my $fileIn = shift;
  my $opIn   = shift;
  my $portIn;
  my $portOut;
  my $portInout;
  my $portList;
  #
  open (RTL, $fileIn) or die because $!;
  foreach my $line (<RTL>) {
    chomp($line);
    #Pre-operate
    $line =~ s/^\s+//; #Remove START spaces
    $line =~ s/\s+/ /g; #Replace tab or many spaces to one space
    $line =~ s/\s+$//; #Remove END space
    #Post-operate
    if ($line !~ /^\/\//) { #Do NOT care the comment line
      #Remove comment at END of a line
      if (($opIn == 1) && ($line =~ /\/\//)) {
        my @wordArray = split(/\/\//, $line);
        $line = $wordArray[0];
      }
      #
      if ($line =~ /^input /) { 
        $portIn .= "$line\n";
      }
      elsif ($line =~ /^output /) {
        $portOut .= "$line\n";
      }
      elsif ($line =~ /^inout /)  {
        $portInout .= "$line\n";
      }
    }
  }
  close (RTL);
  #
  if (defined($portIn)) {
    $portList = "$portIn";
  }
  if (defined($portOut)) {
    $portList .= "$portOut";
  }
  if (defined($portInout)) {
    $portList .= "$portInout";
  }
  #
  $portList; #This is the returned value
} #getPort

1;
