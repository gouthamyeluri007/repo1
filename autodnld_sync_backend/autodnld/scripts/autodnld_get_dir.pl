# h:/fips/scripts/autodnld/autodnld_get_dir.pl

# use strict

use vars ( qw (
               $slash
               %hIniFile
               %hCrntEnv
               $ship_server_password
               ));


# GetRemoteDir   <<< ENTRY
# VerifyRemoteDir

# ------------------------- GetRemoteDir
# get remote dir; see worker routines for explanation of parameters
sub GetRemoteDir
{
my (
    $subdir,
    $paRemoteDirArray,   # fill in data lines
    $paErr,              # if have errors, push lines here
    $bFilesNotNeeded,
    ) = @_;

my $func = "GetRemoteDir";

if ( $subdir =~ /\w\/$/ )
    {
    $subdir .= ".";
    AppendLog ( " $func: fixed path by adding dot; new val=$subdir" );
    }
elsif ( $subdir =~ /\w$/ )
    {
    $subdir .= "/.";
    AppendLog ( " $func: fixed path by adding slash dot; new val=$subdir" );
    }

DownloadDIRViaHTTP($subdir, $paRemoteDirArray, $paErr,$bFilesNotNeeded );
return;

} # GetRemoteDir

1;
