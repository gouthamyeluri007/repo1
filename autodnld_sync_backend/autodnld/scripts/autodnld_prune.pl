# see main() for comments

# the script generate_new_release.pl will compile this for NT, dos2unix it for UNIX etc

# use strict
use IO::File;

my $verbose_prune;    # set based on scalar(grep(/^\-verbose_prune$/i, @ARGV ) );

use vars ( qw
           (
            $slash
            $com_spec
             %hIniFile
             %hCrntEnv
             $ship_server_password
             ));


# Table of Contents
# =================
# print_help
# ZapCduOnNt
# ZapCduOnUnix
# ZapFlavorCdu
# prune_cmo_data    <<< ENTRY


#------------------------------- print_help
# prints a help message to the user. If a 1 is passed to it, it prints an error, else it just
# provides information.
sub print_help
{
    print "

-------- Help screen for autodnld_prune --------

This is a program to delete out-of-date files from an Intex database.

This program requires command line arguments.  It is normally run as part of the autodnld cycle.

Required arguments:
  -dir {cdu base directory} e.g. c:\\intex\\cmo_cdu

  -cdu_depth; purge if more cdu's than this; typical value is 3 or 12
              If no value is given, a default of 3 is used.

  -os {operating system): unix/nt/win98

Optional arguments:
  -depth_report (OPTIONAL): report; how many cdu's you actually have for each deal.

  -deficit_report (OPTIONAL): report; deals, if any, with less than \"depth\" cdu's.
                              (This may be a new deal)

  -batch (DEBUG ONLY): don't actually delete any files, but write delete commands to a batch file.
                       Sample batch file: autodnld_prune.bat or autodnld_prune.csh.

  -help: show this screen and exit

Examples:
  (Windows): autodnld_prune -dir c:\\intex\\cmo_cdu -cdu_depth 3 -os nt

  (UNIX): perl autodnld_prune.pl -dir /home/intex/cmo_cdu -cdu_depth 3 -os unix\n";

    return 0;

} # print_help


#------------------------------- parse_args
# Parse command line args (ignore verbose arg, if any)
sub parse_args
{
   my(
       $pszOs,             # -os
       $p_working_dir,     # -dir
       $p_cdu_depth,
       $p_do_batch,        # -batch             0 or 1
       $pszDepthReport,    # -depth_report      value or undef
       $pszDeficitReport,  # -deficit_report    value or undef
       $paArg              # @ARGV
       ) = @_;

   my($ix, $szArg );

   # must have args
   if(!@$paArg)
   {
      print "Command line arguments are required\n";
       print_help();
       exit(1);
   }

   # init value
   $$p_do_batch = 0;

   for ($ix = 0; $ix < scalar(@$paArg); $ix++ )
   {
      $szArg = @$paArg[$ix];

      if (lc($szArg) eq "-depth_report")
      {
         $ix++;
         $$pszDepthReport = $$paArg[$ix];
         next;
      }

      if (lc($szArg) eq "-deficit_report")
      {
         $ix++;
         $$pszDeficitReport = $$paArg[$ix];
         next;
      }

      if (lc($szArg) eq "-cdu_depth")
      {
         $ix++;
         $$p_cdu_depth = $$paArg[$ix];
         next;
      }

      if (lc($szArg) eq "-dir")
      {
         $ix++;
         $$p_working_dir = $$paArg[$ix];
         next;
      }

      if(lc($szArg) eq "-os")   # unix/nt/win98
      {
         $ix++;
         $$pszOs = lc($$paArg[$ix]);
         next;
      }

      if(lc($szArg) eq "-batch")
      {
          $$p_do_batch = 1;
          print "Batch mode enabled\n";
          next;
      }

      if(lc($szArg) eq "-verbose")  # picked up elsewhere
      {
          next;
      }

      if((lc($szArg) eq "-help") || (lc($szArg) eq "/?"))
      {
          print_help();
          exit(0);
      }

      # got this far; bad keyword
      print "Invalid command line argument: $szArg\n";
      print_help();
      exit(1);
   }

} # parse_args


# ------------------------- OptionalReports
sub OptionalReports
{
   my (
       $iCduDepth,
       $szDepthReport,
       $szDeficitReport,
       $phRoot
       ) = @_;

   my ( $szKey, $szValue );

   # emit optional reports
   if (defined($szDepthReport))
   {
      open(OUTPUTFILE, ">$szDepthReport");
      print OUTPUTFILE "# First column is deal; second column is number of cdu's for deal\n";
      print "Depth report: $szDepthReport\n";
   }

   if ( defined ( $szDeficitReport ))
   {
      open(DEFICIENTCDUFILE, ">$szDeficitReport");
      print DEFICIENTCDUFILE "# First column is deal; second column is number of cdu's short of purge depth\n";
      print "Deficit report: $szDeficitReport\n";
   }

   foreach $szKey ( sort ( keys ( %$phRoot)))
   {
      $szValue = $$phRoot{$szKey};

      if ( defined ( $szDepthReport ))
      {
         print OUTPUTFILE substr($szKey."                       ", 0, 20).$szValue."\n";
      }

      if( defined($szDeficitReport) && $szValue < $iCduDepth)
      {
         print DEFICIENTCDUFILE substr($szKey."                       ", 0, 20).$szValue."\n";
      }
   }

   if (defined($szDepthReport))
   {
      close(OUTPUTFILE);
   }

   if ( defined ( $szDeficitReport ))
   {
      close(DEFICIENTCDUFILE);
   }

} # OptionalReports


# ------------------ ZapCduOnNt
# get a list etc
sub ZapCduOnNt
{
my (
      $szCmoCduPath,
      $iCduDepth,
      $iDoBatch,
      $szDepthReport,
      $szDeficitReport,
      $iUpperYyyyMm,        # need a upper anchor on yyyymm; sometimes Intex ships into the future, but start here anyway
      $paSummaryLine,       # fill in lines: file count per subdir
      ) = @_;

my %hRoot = ();
my $very_verbose = 0;

print "current yyyymm value for pruning=$iUpperYyyyMm\n" if ( $verbose_prune );  # global
print "cdu depth that we will retain=$iCduDepth\n" if ( $verbose_prune );
my ( $iFileSize, @aLine, $szLine, @aYymm, @aYyyymm, $szYymm );
my ( $szSize, $szRoot, $szFile, $szSubdir );
my ( $icByteSaved, $icFileZapped );
my ( $szKey, $szValue, $szCmd );

# get a list of all the yymm subdirs under cmo_cdu
$szCmd = "$com_spec dir $szCmoCduPath";    # unix/nt/win95/win98
@aLine = `$szCmd`;
@aYymm = ();

foreach $szLine ( @aLine )   # e.g. "11/12/98  11:01a        <DIR>          9711"
    {
    chomp($szLine);

    #                  1st   2nd   3rd
    #if ( $szLine =~ /^\S+\s+\S+\s+<DIR>\s+(\d\d\d\d)$/ )

    if ( $szLine =~ /\s+<DIR>\s+(\d\d\d\d)$/ )
        {
        push ( @aYymm, $1 );
        }
    }

# now build a paralled list in yyyymm format; also, apply upper limit
# subdirs are not y2k compliant; pivot at 1980
@aYyyymm = ();

foreach $szLine ( @aYymm )
    {
    my ($szYyyyMm) = ( substr($szLine,0,2) > 80 ) ? 190000 + $szLine : 200000 + $szLine;

    if ( $szYyyyMm <= $iUpperYyyyMm )
        {
        push ( @aYyyymm, $szYyyyMm );
        }
    else
        {
        print "NOTE: ignored subdir for $szYyyyMm; value is too high\n";
        }
    }

# reverse sort and change back to yy format; we want to scan the latest subdir first
@aYyyymm = reverse(sort(@aYyyymm));

@aYymm = ();

foreach $szLine ( @aYyyymm )
    {
    push ( @aYymm, substr($szLine,2));
    }

print "Here is a list of all the subdirs that we will scan:
--------
" . join(" ", @aYymm ) . "
--------\n" if ( $verbose_prune );

# get ready to scan
if($iDoBatch)
    {
    print BATFILE "REM excess cdu files:\n";
    }

$icByteSaved = 0;
$icFileZapped = 0;

# iterate for every directory ... scan newest first
# keep a running total of each cdu using a hash; if exceed total, zap the file
my @aRmdir = ();

foreach $szYymm (@aYymm)
    {
    $szSubdir = $szCmoCduPath . $slash . $szYymm;

    if ( $verbose_prune )
        {
        print "\n\n============= scan subdir=$szSubdir to count the CDU's\n" ;
        }
    else
        {
        print "Scanning dir=$szSubdir\n";
        }

    my $subdir_file_cnt = 0;
    my $total_bytes = 0;

    $szCmd = "$com_spec dir $szSubdir";
    print "Get a dir listing...\n" if ( $verbose_prune );
    my $start_time = time();
    @aLine = `$szCmd`;
    print "Dir listing is complete; elapsed time in seconds=" . (time() - $start_time) . "; process the listing\n" if ( $verbose_prune );
    print "Process the listing...\n" if ( $verbose_prune );

    foreach $szLine ( @aLine )  # e.g. "11/12/97  12:38p                 1,102 fnmsg197.cdu"
        {
        chomp($szLine);

        # if a cdu file
        #                  1st   2nd   3rd
        #if ( lc($szLine) =~ /^\S+\s+\S+\s+(\S+)\s+(\S+)\.cdu$/ )

        if ( lc($szLine) =~ /\s+(\S+)\s+(\S+)\.cdu$/ )
            {
            $subdir_file_cnt++;
            $szSize = $1;
            $szRoot = $2;
            $szSize =~ s/,//g;
            $total_bytes += $szSize;
            my $old_count = $hRoot{$szRoot};
            $old_count = 0 if ( !defined($old_count ));
            print "root=$szRoot  old_count=$hRoot{$szRoot}\n" if ( $very_verbose );

            if ( ++$hRoot{$szRoot} > $iCduDepth)
                {
                # zap file
                $szFile = "$szSubdir\\$szRoot.cdu";
                $icByteSaved += $szSize;
                $icFileZapped++;

                if($iDoBatch)
                    {
                    print "  write to batch file: del $szFile\n";
                    print BATFILE "del $szFile\n";
                    }
                else
                    {
                    if ( $szFile =~ /\"/ )
                       {
                       $szFile =~ s/\"//g ;
                       }
                    print "  zap $szFile\n";
                    unlink($szFile);
                    }	       	

                }               # too many

            }                   # is a cdu

        }                       # file

    print "Processing is complete for this subdir; files=$subdir_file_cnt; bytes=$total_bytes; files tracked=" . scalar(keys(%hRoot)) . " items\n" if ( $verbose_prune );

    # keep a one line summary for each cdu subdir that we can display when the program is done
    push ( @$paSummaryLine, "subdir=$szYymm; file_count=$subdir_file_cnt; total_bytes=$total_bytes" ) if ( $verbose_prune );  # -verbose switch
    push ( @aRmdir, $szSubdir ) if ( $subdir_file_cnt == 0 );

    if ( $very_verbose )
        {
        print "Press enter key to move on > ";
        <STDIN>;
        }

    } # subdir


################## all done scanning thru subdir

# remove any emtpy subdirs
if ( scalar(@aRmdir))
    {
    print "\n--- Remove cmo_cdu subdirs that no longer contain data\n";

    foreach my $subdir ( @aRmdir )
        {
        my $szCmd = "$com_spec rmdir $subdir";
        print "...cmd=$szCmd\n";
        system ( $szCmd );
        }
}

# emit optional reports
OptionalReports
    (
     $iCduDepth,
     $szDepthReport,
     $szDeficitReport,
     \%hRoot
     );

print "Done checking for excess cdu files\n";
print "Number of cdu removed=$icFileZapped; bytes saved=$icByteSaved\n";

} # ZapCduOnNt


# ------------------ ZapCduOnUnix
# this code also works for NT, but using dir listings is faster for NT

sub ZapCduOnUnix
{
   my (
         $szCmoCduPath,   # user passed this in
         $iCduDepth,
         $iDoBatch,
         $szDepthReport,
         $szDeficitReport,
         $iUpperYyyyMm,
         $paSummaryLine,       # fill in lines: file count per subdir ... soon
         ) = @_;

   my ( $iFileSize, @aLine, $szLine, @aYymm, @aYyyymm, $szYymm );
   my ( $szSize, $szRoot, $szFile, $szSubdir );
   my ( $icByteSaved, $icFileZapped );
   my ( $szKey, $szValue, $szEntry );

   # get a list of yymm subdirs under cmo_cdu
   @aYymm = ();
   opendir ( DIR, $szCmoCduPath );

   while ( defined ( $szRoot = readdir(DIR)))
   {
      if ( $szRoot =~ /^\d\d\d\d$/ )
      {
         push ( @aYymm, $szRoot );
      }
   }

   closedir(DIR);

   # now convert to yyyy format; also, apply upper limit
   # subdirs are not y2k compliant; pivot at 1980
   @aYyyymm = ();

   foreach $szLine ( @aYymm )
   {
      my ($szYyyyMm) = ( substr($szLine,0,2) > 80 ) ? 190000 + $szLine : 200000 + $szLine;

      if ( $szYyyyMm <= $iUpperYyyyMm )
      {
         push ( @aYyyymm, $szYyyyMm );
      }
      else
      {
         print "NOTE: ignored subdir for $szYyyyMm\n";
      }
   }

   # reverse sort and change back to yy format; we want to scan the latest subdir first
   @aYyyymm = reverse(sort(@aYyyymm));

   @aYymm = ();

   foreach $szLine ( @aYyyymm )
   {
      push ( @aYymm, substr($szLine,2));
   }


   # get ready to scan
   if($iDoBatch)
   {
      print BATFILE "# excess cdu files:\n";
   }

   $icByteSaved = 0;
   $icFileZapped = 0;

   # iterate for every directory ... scan newest first
   # keep a running total of each cdu using a hash; if exceed total, zap the file
   foreach $szYymm (@aYymm)
   {
      $szSubdir = $szCmoCduPath . $slash . $szYymm;
      print "Scanning dir=$szSubdir\n";
      opendir ( DIR, $szSubdir );

      while ( defined ( $szEntry = readdir(DIR)))
      {
         if ( $szEntry !~ /^(\S+)\.cdu$/ )
         {
            next;
         }

         $szRoot = $1;

         if ( ++$::hRoot{$szRoot} <= $iCduDepth)
         {
            next;
         }

         # got this far; zap file
         $szFile = $szSubdir . $slash . "$szRoot.cdu";
         $icByteSaved += (stat($szFile))[7];
         $icFileZapped++;

         if($iDoBatch)
         {
            print "  write to batch file: rm $szFile\n";
            print BATFILE "rm $szFile\n";
         }
         else
         {
            print "  zap $szFile\n";
            unlink($szFile);
         }	       	

      } # file

      closedir(DIR);

   } # subdir

   # emit optional reports
   OptionalReports
       (
       $iCduDepth,
       $szDepthReport,
       $szDeficitReport,
        \%::hRoot
        );

   print "Done checking for excess cdu files\n";
   print "Number of cdu removed=$icFileZapped; bytes saved=$icByteSaved\n";

} # ZapCduOnUnix


# ------------------ ZapFlavorCdu
# example: if non-flash exists, zap the flash

sub ZapFlavorCdu
{
my (
       $szCmoCduPath,
       $iDoBatch,
       $flavor,    # e.g. "flash"
       $szRefFlavor,    # if defined, may have zap=flash/partial, ref=flash
                        # default value: $szCmoCduPath . $slash .                             $szYymm . $slash. $szRoot;
    $max_day,
       $szDelCmd,   # del or rm
      $paSummaryLine,       # fill in lines: file count per subdir
       ) = @_;

my ( $iFileSize, @aLine, $szLine, @aYymm, @aYyyymm, $szYymm );
my ( $szSize, $szRoot, $szFile );
my ( $icByteSaved, $icFileZapped, $szCmd );

# get a list of yymm subdirs under cmo_cdu flavor
print "\n---- Checking for excess $flavor files\n";
@aYymm = ();
opendir ( DIR, "$szCmoCduPath$slash$flavor" );

while ( defined ( $szRoot = readdir(DIR)))
    {
    if ( $szRoot =~ /^\d\d\d\d$/ )
        {
        push ( @aYymm, $szRoot );
        }
    }

closedir(DIR);

if($iDoBatch)
    {
    print BATFILE "REM excess $flavor files:\n";
    }

# scan each flavored directory
# for each flavored cdu found found, look for the non-flavored; if found, zap it
$icByteSaved = 0;
$icFileZapped = 0;

foreach $szYymm (@aYymm)
    {
    my $szSubdir = "$szCmoCduPath$slash$flavor$slash$szYymm";  # e.g. $szYymm=0202, subdir=y:\\cmo_cdu\\flash\\0202
    my $ref_subdir;

    if ( defined($szRefFlavor))
        {
        $ref_subdir = "$szCmoCduPath$slash$szRefFlavor$slash$szYymm";
        }
    else
        {
        $ref_subdir = "$szCmoCduPath$slash$szYymm";
        }

    my @aTime = localtime();
    my $stamp = sprintf ( "%02d:%02d:%02d", $aTime[2], $aTime[1], $aTime[0] );

    if ( $verbose_prune )
        {
        print "=========== scanning dir=$szSubdir for unnecessary $flavor cdu files ($stamp)\n";
        }
    else
        {
        print "Scanning dir=$szSubdir for unnecessary $flavor cdu files; ($stamp)\n";
        }

##    if ( $szSubdir eq "y:\\cmo_cdu\\partial\\9912" )
##        {
##        my $foobar = 1;
##        }

    opendir ( DIR, $szSubdir );
    my $subdir_file_cnt = 0;

    # scan subdir e.g. subdir=y:\\cmo_cdu\\flash\\0202...
    while ( defined ( $szRoot = readdir(DIR)))
        {
        if ( $szRoot !~ /\.cdu$/i )
            {
            next;
            }

        $subdir_file_cnt++;
        my $pathed_file = "$szSubdir$slash$szRoot";

        # check age
        my @aStat = stat ( $pathed_file );
        my $szAgePossDel = $aStat[9] ;
        my $days = sprintf ( "%.1f", (time() - $aStat[9]) / ( 60 * 60 * 24 ) );

        if ( $days > $max_day )
            {
            $icByteSaved += $aStat[7];
            $icFileZapped++;
            print "  Erase file=$pathed_file; age_in_days=$days; max=$max_day\n";

            if($iDoBatch)
                {
                print "  write to batch file: $szDelCmd $szSubdir$slash$szRoot\n";
                print BATFILE "$szDelCmd $szSubdir$slash$szRoot\n";
                }
            else
                {
                if ( $pathed_file =~ /\"/ )
                   {
                   $pathed_file  =~ s/\"//g ;
                   }
                print "  Erase file=$pathed_file\n";
                unlink ( $pathed_file );
                }

            next;
            }

        # check ref copy; if there, zap file
        @aStat = stat("$ref_subdir$slash$szRoot");

        if ( scalar(@aStat) > 0 )
            {
            my $szAgeKeep = $aStat[9] ;
            if ( $szAgePossDel < $szAgeKeep  )
                {
                if ( defined (  $hIniFile{'skip_flash_prune'}  ) )
                   {
                    if ( uc($hIniFile{'skip_flash_prune'}) eq "Y" )
                       {
                       #print "Will not erase file=$pathed_file because skip_flash_purge=y\n" ;
                       next ;
                       }
                   }

                $icByteSaved += $aStat[7];
                $icFileZapped++;

                if($iDoBatch)
                    {
                    print "  write to batch file: $szDelCmd $szSubdir$slash$szRoot\n";
                    print BATFILE "$szDelCmd $szSubdir$slash$szRoot\n";
                    }
                else
                    {
                    if ( $pathed_file =~ /\"/ )
                       {
                       $pathed_file  =~ s/\"//g ;
                       }
                    print "  Erase file=$pathed_file\n";
                    unlink ( $pathed_file );
                    }
                }
            else
                {
                print "\nFile $szSubdir$slash$szRoot Not older than $ref_subdir$slash$szRoot" if ( $verbose_prune ) ;
                }
            } # if cdu file
        } # each file

    if ( $subdir_file_cnt == 0 )
        {
        print "remove empty subdir=$szSubdir\n";
        rmdir ( $szSubdir );
        }

    push ( @$paSummaryLine, "subdir=$szSubdir; file_count=$subdir_file_cnt" ) if ( $verbose_prune );  # -verbose switch

    } # each subdir

print "Done checking for excess $flavor files\n";
print "Number of $flavor cdu removed=$icFileZapped; bytes saved=$icByteSaved\n";

} # ZapFlavorCdu


# ------------------------ prune_cmo_data  <<< ENTRY
sub prune_cmo_data
{
# This Perl script prunes an Intex database (compiled for Windows into an exe)
# The number of CDU files to be kept is specified via a command line parameter
# Also, flash and partial CDU files are removed if the non-flavored cdu is available

# args
# ===
# -os  ... unix/nt/win95/win98
# -cdu_depth ... ususally 3 or so
# -dir   ... cmo_cdu dir e.g. c:\\intex\\cmo_cdu
# -batch  ... debug only

my($iStartTime) = time();

my $szCmoCduPath = $hIniFile{'tgt_cdu_dir'};
$szCmoCduPath =~ s/\\\"$/\"/ ;
$szCmoCduPath =~ s/[\\\/]$// ;
if ( $szCmoCduPath =~ / / && $szCmoCduPath !~ /^\"/ )
    {
    $szCmoCduPath = "\"".$szCmoCduPath."\"" ;
    }

if (!defined $hIniFile{'cdu_purge_depth'} || $hIniFile{'cdu_purge_depth'}==0)
{
	AppendLog("Not prune because either cdu_purge_depth is zero or not defined");
	return;
}
	
my $iCduDepth = $hIniFile{'cdu_purge_depth'};

AppendLog("Start to prune CDU to depth of ".$iCduDepth);

my $iDoBatch = scalar(grep(/^\-prune_batch$/i, @ARGV ) ) ? 1 : 0;

# depth report? ... may be undef
my $szDepthReport;

if ( scalar(grep(/^\-prune_depth_report/i, @ARGV ) ) )
     {
     my @aMatch = grep(/^\-prune_depth_report/i, @ARGV );
     my $line = $aMatch[0];
     my $ix = index($line,"=");

     if ( $ix > 0 )
         {
         $szDepthReport = substr($line,$ix);
         }
     }

my $szDeficitReport;

if ( scalar(grep(/^\-prune_deficit_report/i, @ARGV ) ) )
     {
     my @aMatch = grep(/^\-prune_deficit_report/i, @ARGV );
     my $line = $aMatch[0];
     my $ix = index($line,"=");

     if ( $ix > 0 )
         {
         $szDeficitReport = substr($line,$ix);
         }
     }

# verbose is a global
$verbose_prune = scalar(grep(/^\-prune_verbose$/i, @ARGV ) );
print "Verbose option has been enabled\n" if ( $verbose_prune );

# batch file has hardcoded name
my $szBatFile = ( $hIniFile{'operating_system'} eq "unix" ) ?  "autodnld_prune.csh" : "autodnld_prune.bat";

# may have batch file output for debug
if($iDoBatch)
{
   open(BATFILE, ">$szBatFile"); # open our batch file we are going to output
}

# need a upper limit on subdir yyyymm; sometimes Intex ships into the future
# e.g. date is 04/2000, but 05/2000 files are shipped; still start purging at 04/2000
my ( @aTime ) = localtime(time());
my($iUpperYyyyMm) = sprintf ( "%4d%02d", $aTime[5]+1900, $aTime[4]+1 );


################## zap old cdu's


print "\n---- Checking for excess cdu files; this may take a while\n";
my @aSummaryLine = ();

if ( $hIniFile{'operating_system'} ne "unix" )     # unix/nt/win95/win98
{
   ZapCduOnNt
       (
         $szCmoCduPath,
         $iCduDepth,
         $iDoBatch,
         $szDepthReport,
         $szDeficitReport,
         $iUpperYyyyMm,    # need a upper anchor on yyyymm; sometimes Intex ships into the future, but start here anyway
         \@aSummaryLine,   # if verbose because -verbose arg, will fill in lines
         );
}
else
{
   ZapCduOnUnix
       (
         $szCmoCduPath,   # user passed this in
         $iCduDepth,
         $iDoBatch,
         $szDepthReport,
         $szDeficitReport,
         $iUpperYyyyMm,      # need a upper anchor on yyyymm; sometimes Intex ships into the future, but start here anyway
         \@aSummaryLine,   # if verbose because -verbose arg, will fill in lines ... soon ...
         );
}

AppendLog("End of pruning regular CDUs");


############ zap flash etc



# figure out where flash and/or partial files are
my @aFlavor = ( "flash,,90", "partial,,90" );

if ( $hIniFile{'operating_system'} ne "unix" )     # unix/nt/win95/win98
{
   push ( @aFlavor, "flash\\partial,,90" );
   push ( @aFlavor, "flash\\partial,partial,90" );
}
else
{
   push ( @aFlavor, "flash/partial,,90" );    # subdir to look in, ref subdir, age in days before delete
   push ( @aFlavor, "flash/partial,partial,90" );    # subdir to look in, ref subdir, age in days before delete
}

foreach my $szFlavor (@aFlavor)
{
   my ( @aToken ) = split(",",$szFlavor);
   push ( @aSummaryLine, "========== $aToken[0]" ) if ( $verbose_prune );;

   ZapFlavorCdu
       (
        $szCmoCduPath,   # cmo_cdu path
        $iDoBatch,
        $aToken[0],    # add to cmo_cdu path e.g. flash
        $aToken[1],   # ref subdir; may be undef; this is OK
        $aToken[2],   #age in days before delete
        ($hIniFile{'operating_system'} ne "unix") ? "del" : "rm",
        \@aSummaryLine,  # only add lines to this if verbose
        );
}




##########  coda


if($iDoBatch)
{
   close(BATFILE); # close the batch file
   print "Delete commands, if any, are in file $szBatFile\n";
}

# if zapping on NT and if verbose turned on, may have summary lines; if so, show them
print "\nSummary for each subdir:\n--------------------\n" . join("\n", @aSummaryLine) . "\n------------------\n" if ( scalar ( @aSummaryLine ));
my $sTimeSpend=(time() - $iStartTime)/60;
AppendLog("Finish pruning in $sTimeSpend minutes");

} # prune_cmo_data

1;
