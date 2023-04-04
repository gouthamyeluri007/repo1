#! /usr/local/bin/perl  ... may have to uncomment this for UNIX
# see main() for comments

# we recommend that you "use strict"
# However, it is commented out in this script as shipped, since some customers don't have the strict module available to them.
# use strict
push ( @INC, "." );

# if you don't have IO::File, comment out the "use IO::File" and comment out the call to flush() in the code
use IO::File;
# commented for unix scripts # # commented for unix scripts # use Win32::AdminMisc ;    # cline44
use Cwd;
use IO::Socket::SSL;
use Socket;
use Net::SSLeay;

# ------- hCmoState
# cmo state data ... we hash it into %hCmoState e.g. $hCmoState{'cmo_cdu_dir'}
# For example, when we are in GetAllCmoWrapper(), and have decided a flavor e.g. "flash", we can set val for "cmo_cdi_dir"
# keys for hCmoState:
#   cmo_flavor         "cmodata" (magic value), or "flash" etc
#   distrib_word     distrib or distribution ... set this very early when we do a dir of /user on ship server
#   distrib_dir      e.g. "distrib" or "distrib/flash" ... this value varies as we download main vs flash CMO data
#   cmo_cdi_dir      local cmo_cdi dir e.g. "d:\\intex\\cmo_cdi" (ususally the same for flash, may be different for "abs_auto")
#                    NOTE: flash shipments have "flash" imbedded in their pathing
#   cmo_cdu_dir      local cmo_cdu dir e.g. "d:\\intex\\cmo_cdi" (ususally the same for flash, may be different for "abs_auto")
#                    NOTE: flash shipments have "flash" imbedded in their pathing
#   flavored_log_dir      local log dir; depends on CMO flavor e.g. "d:\\autodnld\\log"; cmotrack.log goes here; eot files go here
#   tracking_file    e.g. c:\\autodnld\\log\\CMOTrack.log ... never in the flavored log dir, always in the main log dir


# -------- hCmo
#    remote_dir   e.g. "/$hIniFile{'user'}/$hCmoState{'distrib_dir'}/last3/." ... may have "flash" etc
#    local_eot_file e.g. 4.eot
#    descr e.g. "old shipment (4 back)"
#    path_segment ... ( "last4", "last3", "last2", "last", "" )
#    shipment_stamp ... from eot file e.g. "Tue..."
#    short_pull_path e.g. distribution/last4 or distribution/flash/last4; always has forward slashes
#    long_pull_path e.g. /ppm/distribution/last4 or /ppm/distribution/flash/last4; always has forward slashes

use vars ( qw ( %hCmoState ));  # required modules may need this var
%hCmoState = ();
use vars ( qw ( %hErrorMeaning @aHttpProxyKeywords ));
%hErrorMeaning=(
   1000 =>"Decode Error.",
   1001 =>"Username error. ",
   1002 =>"Invalid http password.",
   1003 =>"File list empty.",
   1004 =>"No file list uploaded.",
   1005 =>"File missing.",
   1006 =>"Unrecognized file name in the list.",
   1007 =>"You set usehttp=http or https in autodnld.ini file, please contact Intex shipping to set this up",
   1008 =>"Stale log in, more than 30 days lapsed from last attempt",
   1009 =>"Post list exceed 60 M limit.",
   1010 =>"Can't create https socket. More information can be found at https://www.intex.com/main/autodnld/faq#httpdownload",
   1011 =>"Downloadgetfile, source file name/dir not given, return from intex server",
   1012 =>"Intex Server Error. Please retry",
   1013 =>"Intex Server Error.",
   1014 =>"Intex Server Error. Please retry",
   1015 =>"User password error.",
   1016 =>"User request error.",
   2005 =>"File missing.",   #replace 1005
   2006 =>"http connection dropped. Last file being partially downloaded",
   2010 =>"timeout while waiting for header stream from http",
   2011 =>"timeout while waiting for File_ID from htttp",
   2012 =>"timeout while waiting for file size to be downloaded in http stream",
   2013 =>"leftover chunk or file size becomes negative, in last chunk decoding",
   2014 =>"other kinds of timeout during http download",
   2015 =>"Http chunk unexpectly ended",
   2017 =>"http connection dropped. Last file being partially downloaded",
   2101 =>"can\'t write file to local directory",
   9999 =>"reserved",
  );
@aHttpProxyKeywords = ( 'HTTPS_PROXY', 'HTTPS_PROXY_USERNAME', 'HTTPS_PROXY_PASSWORD','HTTPS_CERT_FILE','HTTPS_KEY_FILE','HTTPS_CA_FILE','HTTPS_CA_PATH','HTTPS_CA_DIR','HTTPS_VERSION','HTTPS_VERIFY_MODE' );


# ---------- hCrntEnv: via inf file, computations etc
# 'email_retries'} = 3;
# 'cmodata_keyword'}  "cmodata";
use vars ( qw ( %hCrntEnv ));  # required modules may need this var
%hCrntEnv = ();


# ----------- hPoolBondState
# see FigureOutPoolBondHash(): must set $hPoolBondState{'pool_or_bond'} before calling it
use vars ( qw ( %hPoolBondState ));  # required modules may need this var
%hPoolBondState = ();

# ---------------- hIniFile ... from ini file
# 'operating_system'    unix/nt/win95/win98
use vars ( qw ( %hIniFile %hIniFileOrig ));  # required modules may need this var
%hIniFile = ();
%hIniFileOrig = ();


# required modules may need this misc var
# FYI: com_spec: "nt" ? "cmd.exe /c" : "command /c";
use vars ( qw (
               $slash
               $is_unix
               $com_spec
               $ship_server_password
               ));

# next value is modified by generate_new_release.pl
use vars ( qw ( $this_script_is_compiled ));  # required modules may need this var
$this_script_is_compiled = 0;

# the script generate_new_release.pl will modify the next two values; we just edit in fairly recent values
use vars ( qw ( $release_version $release_date ));  # required modules share these var
$release_version = "5.26u";
$release_date = "2022-12-02";

# magic id for email
my $magic_email_id_for_testing = 'test_email';

# list of possible ini file values (for all OS)
use vars ( qw ( @aAllPossibleIniKey @aPossibleIntexServers ) );

@aPossibleIntexServers = qw ( ship.intex.com ship.intexmirror.com ) ;

@aAllPossibleIniKey = qw
    (
     autodnld_home
     bond_data_months_back
     bond_data_purge
     cdu_check_n_months_back
     cdu_purge_depth
     connection
     copy_flash_cdu
     dbstatus_addl_cmd
     dbstatus_check
     dbstatus_check_signature
     dbstatus_check_time
     dbstatus_filter_error
     deal_remit_data_months_back
     deal_rmtd_data_days_back
     disable_ip_check
     disk_space_cmd
     disk_space_pattern
     distrib_subdir
     email_to
     file_download_retry_count
     file_uncompress_retry_count
     file_uncompress_retry_sleep
     file_uncompress_retry_max_errors
     get_remit_diff_files
     get_deal_remit_diff_files
     get_tranche_remit_diff_files
     get_id
     https
     http_session_header
     id_tgt_cdi_dir
     id_tgt_cdu_dir
     ip_script
     ip_arguments
     ignore_size_check
     ignore_dbstatus_return
     kill_autodnld
     log_file_max_length
     mail_bin
     mail_exe
     mail_exe_option
     mail_from
     mail_sender
     mail_server
     minimal_email
     mkdir_retry_cnt
     new_servers
     no_chdir_code_250
     no_ls_dash_l
     operating_system
     password
     pool_data_months_back
     pool_data_skip_geo
     pool_data_purge
     post_download_command
     ps_command
     remit_data_months_back
     replicate_cmd
     remit_data_prune
     rmtd_data_days_back
     save_serialized_group_shiplist
     save_serialized_zip_files
     http_save_ind_zip_path
     save_dbstatus_error_files
     send_histdata_email
     shipment_backup_path
     skip_update_exe
     skip_file_in_use_process
     skip_flash_prune
     suppress_log
     suppress_utc_check
     temp_download_subdir
     tgt_cdi_dir
     tgt_cdu_dir
     tgt_perfdata_dir
     tgt_remitdata_dir
     tgt_histdata_dir
     tgt_rmtddata_dir
     tgt_deal_remit_data_dir
     tgt_tranche_remit_data_dir
     tranche_remit_data_months_back
     tranche_remit_diff_data_days_back
     try_alternate_server
     upload_dbstatus
     redownload_count
     user
     unix_unzip_cmd
     win_unzip_cmd
     unix_safe_unzip
     win_safe_unzip
     win_https_wininet
     unix_safe_swap_file_cmd
     win_safe_swap_file_cmd
     verbose
     );

use vars ( qw ( @aDAYSPERMONTH ) );

@aDAYSPERMONTH = ( 31, 28, 31,
                      30, 31, 30,
                      31, 31, 30,
                      31, 30, 31 );



########################################################################################################
######################################## utilities #####################################################
########################################################################################################


sub LogThis
{
my ( $sType, $iLevel ) = @_;


if ( $sType eq 'http' )
    {
    if ( defined( $hIniFile{httpdump} ) && $hIniFile{httpdump} > 0 )
        {
        return 1;
        }
    }
elsif ( $sType eq 'flash' )
    {
    if ( defined( $hCrntEnv{verbose} ) && $hCrntEnv{verbose} > 0 )
        {
        return 1;
        }
    }
else   ## all others: gen, dnld, mail
    {
    if ( defined( $hIniFile{suppress_log} ) &&  $hIniFile{suppress_log} =~ /^n$/i )
        {
        return 1;
        }
    }

return 0;

}

# -------------------------------- TrytoKillAutodnld
sub TrytoKillAutodnld
{
##will use pstools to kill autodnld.  pslist and pskill.
my $szCmd = "pslist" ;
my @aListBack = `$szCmd` ;
my ( $bAutodnldRunning, $bNotRecognized ) ;
my ( $iMaxElapsedTime, $iPidToKill ) ;
$iMaxElapsedTime  = 0 ;
$bAutodnldRunning = 1 ;

AppendLog ( "TrytoKillAutodnld(): start" );

foreach my $szOneListBack ( @aListBack )
   {
   if ( $szOneListBack =~ /not recognized/i )
      {
      $bNotRecognized = 1 ;
      }
   if ( $szOneListBack =~ /^ *autodnld/i )
      {
      my @aListCompnents = split ( / +/, $szOneListBack) ;
      my $iPid   = $aListCompnents[1] ;
      my $iPTime = $aListCompnents[8] ;
      $iPTime =~ s/[\:\.]//g ;
      $iPTime =~ s/^0+//g ;
      $bAutodnldRunning ++ ;
      AppendLog ( "TrytoKillAutodnld(): found autodnld process $bAutodnldRunning ID\#=$iPid elapsed time = ".$aListCompnents[8] );
      if ( $iPTime > $iMaxElapsedTime )
         {
         $iMaxElapsedTime = $iPTime  ;
         $iPidToKill      = $iPid    ;
         }

      }
   }

if ( $bNotRecognized )
   {
   return ( "System did not recognize command \"pslist\" please install pstools to use kill_autodnld" ) ;
   }
AppendLog ( "TrytoKillAutodnld(): done going through pslist oldest autodnld (out of $bAutodnldRunning autodnld processes) is Time=$iMaxElapsedTime ID\#=$iPidToKill" );

if ( $bAutodnldRunning > 2 )
   {
   my ( $bKilledOk ) ;
   my $szCmd = "pskill $iPidToKill" ;
   my @aListBack = `$szCmd` ;
   foreach my $szOneListBack ( @aListBack )
      {
      if ( $szOneListBack =~ /Process autodnld killed/i )
         {
         $bKilledOk = 1 ;
         }
      }
   if ( ! $bKilledOk )
      {
      my $szCmd = "pslist" ;
      my @aListBack = `$szCmd` ;
      my ( $bAutodnldStillRunning, $bNotRecognized ) ;

      foreach my $szOneListBack ( @aListBack )
         {
         if ( $szOneListBack =~ /^ *autodnld +$iPidToKill /i )
            {
            $bAutodnldStillRunning = 1 ;
            }
         }
      if ( $bAutodnldStillRunning )
         {
         return ( "After trying to kill the other autodnld running, it is still running" ) ;
         }
      }
   }

}

# -------------------------------- OpenSocket

sub OpenSocket {
    # use Devel::StackTrace; print Devel::StackTrace->new( max_arg_length => 200 )->as_string();
    my ($sHost, $iPort) = @_;

    my %hParams = (SSL_verify_mode => SSL_VERIFY_PEER);

    $hParams{SSL_ca_file}   = $ENV{HTTPS_CA_FILE}   if ( $ENV{HTTPS_CA_FILE}  );
    $hParams{SSL_ca_path}   = $ENV{HTTPS_CA_PATH}   if ( $ENV{HTTPS_CA_PATH}  );
    if ( ! $hParams{SSL_ca_path} )
        {
        $hParams{SSL_ca_path}   = $ENV{HTTPS_CA_DIR}   if ( $ENV{HTTPS_CA_DIR}  );
        }
    $hParams{SSL_cert_file} = $ENV{HTTPS_CERT_FILE} if ( $ENV{HTTPS_CERT_FILE});
    $hParams{SSL_key_file}  = $ENV{HTTPS_KEY_FILE}  if ( $ENV{HTTPS_KEY_FILE} );
    $hParams{SSL_version}   = $ENV{HTTPS_VERSION}   if ( $ENV{HTTPS_VERSION}  );
    $hParams{SSL_verify_mode}   = SSL_VERIFY_PEER   if ( $ENV{HTTPS_VERIFY_MODE} && $ENV{HTTPS_VERIFY_MODE} =~ m/peer/i );
    $hParams{SSL_verify_mode}   = SSL_VERIFY_NONE   if ( $ENV{HTTPS_VERIFY_MODE} && $ENV{HTTPS_VERIFY_MODE} =~ m/none/i );



    if (defined($ENV{HTTPS_PROXY}) && $ENV{HTTPS_PROXY} =~ m/^\s*(\S+?):(\d+)\s*$/) {
        my ($sProxyHost, $iProxyPort) = ($1, $2);

        my $CRLF = "\x0d\x0a";
        my $dest_ip     = gethostbyname($sProxyHost);
        my $host_params = sockaddr_in($iProxyPort, $dest_ip);
        socket(my $socket, &PF_INET(), &SOCK_STREAM(), 0) or die "socket: $!";
        connect($socket, $host_params)                    or die "connect: $!";
        my $old_select = select($socket); $| = 1; select($old_select);

        my $sProxyUsername = ( defined( $ENV{HTTPS_PROXY_USERNAME} ) ? $ENV{HTTPS_PROXY_USERNAME} : '' );
        my $sProxyPassword = ( defined( $ENV{HTTPS_PROXY_PASSWORD} ) ? $ENV{HTTPS_PROXY_PASSWORD} : '' );
        my $sProxyAuth = $sProxyUsername ? $CRLF . 'Proxy-authorization: Basic ' . MIME::Base64::encode("$sProxyUsername:$sProxyPassword", '') : '';
        print $socket "CONNECT $sHost:$iPort HTTP/1.0$sProxyAuth$CRLF$CRLF";
        my $line = <$socket>;

        # upgrade the TCP socket to TLS
        $socket = IO::Socket::SSL->start_SSL($socket,
                                  # hostname is needed for SNI and certificate validation
                                  SSL_hostname => $sHost,
                                  %hParams
        ) or die $SSL_ERROR;

        return $socket;
    } else {
        return IO::Socket::SSL->new(PeerHost => $sHost, PeerPort => $iPort, %hParams);
    }
}

# -------------------------------- stamp_as_yyyymmdd_hhmm
sub stamp_as_yyyymmdd_hhmm
{
my @aTime = localtime();
return sprintf ( "%04d%02d%02d_%02d%02d", $aTime[5] + 1900, $aTime[4] + 1, $aTime[3],   $aTime[2], $aTime[1] );  # #yyyymmdd_hhmm
}


# ---------------- AppendEmailLog
# append info to summary log file (raw output: no stamp, no crlf)

sub AppendEmailLog
{
my($szInfo) = @_;

if (  open ( LOGOUT, ">>$hCrntEnv{'email_log_file'}" ) == 1 )
    {
    print LOGOUT $szInfo;
    close ( LOGOUT );
    }

} # AppendEmailLog


# ---------------- AppendLog
# append info to log file; may also print to screen
# If we see password, change it to xxx.xxx

sub AppendLog
{
my(
   $szInfo,    # info
   $iPrint,    # may be undef; print-to-screen flag
   $paErrorLog,
   ) = @_;
$|=1;
# we also may call this when running -config and stuff is not set up
return if ( !defined ( $hCrntEnv{'log_file'} ) || !defined ( $hCrntEnv{'error_log_file'} ) );

my ( $szStamp );

if ( !defined($iPrint) || $iPrint eq "" )
    {
    $iPrint = 0;
    }
if ( $szInfo eq "SKIP" )
   {
   }
else
   {
   # may have password ... should be wierd string ... mask it
   if ( defined ( $ship_server_password ) && $ship_server_password ne '' )  # global
       {
       $szInfo =~s/$ship_server_password/xxx\.xxx/g if ( $ship_server_password ne '' );
       }

   if( $iPrint)
       {
       print("$szInfo\n");
       }

   if (  open ( LOGOUT, ">>$hCrntEnv{'log_file'}" ) == 1 )
       {
       # for UNIX, show process ID; clients often run multiple autodnld w/o realizing it
       if($is_unix)
           {
           $szStamp = substr(scalar(localtime(time())),4,15) . " ($$)";   # e.g. "06:30: 123"
           }
       else
           {
           $szStamp = substr(scalar(localtime(time())),4,15);   # e.g. "06:30"
           }

       print LOGOUT "$szStamp $szInfo\n";
       close ( LOGOUT );
       }
   else
       {
       print "ERROR: cannot open logfile=$hCrntEnv{'log_file'}\n";
       }
   }

if ( defined ( $paErrorLog ) && defined $hCrntEnv{'error_log_file'} )
    {
    if (  open ( ERRORLOG, ">$hCrntEnv{'error_log_file'}" ) == 1 )
        {
        # for UNIX, show process ID; clients often run multiple autodnld w/o realizing it
        if($is_unix)
            {
            $szStamp = substr(scalar(localtime(time())),4,15) . " ($$)";   # e.g. "06:30: 123"
            }
        else
            {
            $szStamp = substr(scalar(localtime(time())),4,15);   # e.g. "06:30"
            }

        print ERRORLOG "Error Received: $szStamp\n\n";
        foreach my $szOneErrorLogLine ( @$paErrorLog )
            {
            if ( defined ( $ship_server_password ) )
                {
                $szOneErrorLogLine  =~ s/$ship_server_password/xxx\.xxx/g ;
                }
            print ERRORLOG "$szOneErrorLogLine\n";
            }
        close ( ERRORLOG );
        }
    else
        {
        print "ERROR: cannot open logfile=$hCrntEnv{'error_log_file'}\n";
        }
    }

} # AppendLog


# -------------------------- AppendHashInfoToLogFile

# sample output:

##  09:58
##  Contents of hIniFile hash:
##    autodnld_home=d:\autodnld_qa
##    bond_data_months_back=2

# don't depend on Dumper module
sub AppendHashInfoToLogFile
{
my (
    $szLabel,
    $phState,
    $bIgnoreEmpty,
    ) = @_;

my $out = "\n$szLabel:\n";

foreach my $key ( sort( keys ( %$phState )))
    {
    if ( $bIgnoreEmpty )
        {
        next if ( ( $$phState{$key} eq '0' || $$phState{$key} eq '' ) && $key =~ /^get/ );
        }

    $out .= "  $key=";
    my $val = $phState->{$key};

    if ( ref($val) eq "HASH" )
        {
        $out .= "HASH";
        }
    elsif ( ref($val) eq "ARRAY" )
        {
        $out .= join(",",@$val);
        }
    else
        {
        $out .= "$val";
        }

    $out .= "\n";
    }

AppendLog ($out );

} # AppendHashInfoToLogFile


# -------------- copy_file
# no error checking yet
sub copy_file
{
my (
    $src,
    $dst,
    ) = @_;

my $cmd;

if($is_unix)
    {
    $cmd = "cp -p \"$src\" \"$dst\"";
    }
else
    {
    $cmd = "$com_spec copy /Y \"$src\" \"$dst\"";   # global
    }

my @aLine = `$cmd`;
if (($?!=0)||(!-e $dst)){
   AppendLog("Command $cmd returned with error".join(" ",@aLine));
   return 0;
}
return 1;
} # copy_file


# ------------------ CopyFlashCdu
# example: if non-flash exists, and has newer timestamp, move them to non-flash directory

sub CopyFlashCdu
{

        my $sMainDir = $hIniFile{'tgt_cdu_dir'};
        my @aFlashPair=("",$slash."partial");
        foreach my $sDir (@aFlashPair)
        {
                my  $szCmoCduPath=$sMainDir.$sDir;
                my $szCmoCduFlashPath=$hIniFile{'tgt_cdu_dir'}.$slash."flash".$sDir;
                if (!-d $szCmoCduFlashPath)
                {
                        AppendLog("$szCmoCduFlashPath doesn't exist");
                        next;
                }
                AppendLog("CopyFlashCDU(): read $szCmoCduFlashPath");
                my ( @aYymm,  $szYymm ,$szRoot);

                @aYymm = ();
                opendir ( DIR, $szCmoCduFlashPath );

                while ( defined ( $szRoot = readdir(DIR)))
                        {
                        if ( $szRoot =~ /^\d\d\d\d$/ )
                        {
                                push ( @aYymm, $szRoot );
                        }
                        elsif (-f $szCmoCduFlashPath.$slash.$szRoot)
                        {
                                #sometimes, idx file is sent to flash
                                FlashFileCompare($szCmoCduFlashPath.$slash.$szRoot,$szCmoCduPath.$slash.$szRoot,$szCmoCduPath.$slash.$szRoot);
                        }
                }

                closedir(DIR);


                foreach $szYymm (@aYymm)
                {
                        my $szSubdir = $szCmoCduFlashPath.$slash.$szYymm;  # e.g. $szYymm=0202, subdir=y:\\cmo_cdu\\flash\\0202
                        my $ref_subdir =$szCmoCduPath.$slash.$szYymm;
                        my $ref_subdir2=$sMainDir.$slash.$szYymm;
                        my $sDirFileCnt=0;
                        opendir ( DIR, $szSubdir );

                        # scan subdir e.g. subdir=y:\\cmo_cdu\\flash\\0202...
                        while ( defined ( $szRoot = readdir(DIR)))
                                {
                                        $sDirFileCnt++;
                                        next if ( $szRoot !~ /\.cdu$/i );
                                        FlashFileCompare($szSubdir.$slash.$szRoot,$ref_subdir.$slash.$szRoot,$ref_subdir2.$slash.$szRoot);
                                }
                        closedir(DIR);
                        if ($sDirFileCnt==2)
                        {
                                rmdir($szSubdir)|| AppendLog(" rm $szSubdir got error: ".$!);
                        }
                }
        }
        AppendLog("End of CopyFlashCdu()");
        return 1;
} # CopyFlashCdu

####FlashFileCompare#####
###If flash is newer than non flash file, copy it over
###If non flash file is newer, remove flash copy
sub FlashFileCompare
{
        my ($sFlashFile,$sNonFlashFile,$sAltNonFlashFile)=@_;
        my @aFlashStat = stat ( $sFlashFile );
        my $bNonFlashExists;
        my $bAltNonFlashExists;
        my @aNonFlashStat;
        my @aAltNonFlashStat;
        if (-f $sNonFlashFile)
        {
                $bNonFlashExists = 1;
                @aNonFlashStat = stat($sNonFlashFile) ;
        }
        if ($sAltNonFlashFile ne $sNonFlashFile && -f $sAltNonFlashFile)
        {
                $bAltNonFlashExists = 1;
                @aAltNonFlashStat = stat($sAltNonFlashFile) ;
        }
        if (! $bNonFlashExists ||$aFlashStat[9]>$aNonFlashStat[9] )
        {
                AppendLog("Copy $sFlashFile timestamp:".localtime($aFlashStat[9])." to $sNonFlashFile") if ( LogThis('flash') > 0 );
                AppendLog("Original $sNonFlashFile timestamp:".localtime($aNonFlashStat[9])) if ( LogThis('flash') > 0 && @aNonFlashStat);
                copy_file($sFlashFile,$sNonFlashFile);
        }
        elsif ($aFlashStat[9]<$aNonFlashStat[9])
        {
                AppendLog("Delete $sFlashFile timestamp:".localtime($aFlashStat[9]).",size:".$aFlashStat[7]." because $sNonFlashFile timestamp:".localtime($aNonFlashStat[9]).",size:".$aNonFlashStat[7]) if ( LogThis('flash') > 0 );
                unlink($sFlashFile) || AppendLog("Delete $sFlashFile got error:".$!);
        }
        elsif ($bAltNonFlashExists && $aFlashStat[9]<$aAltNonFlashStat[9])
        {
                AppendLog("Delete $sFlashFile timestamp:".localtime($aFlashStat[9]).",size:".$aFlashStat[7]." because $sAltNonFlashFile timestamp:".localtime($aNonFlashStat[9]).",size:".$aAltNonFlashStat[7]) if ( LogThis('flash') > 0 );
                unlink($sFlashFile) || AppendLog("Delete $sFlashFile got error:".$!);
        }
        return;

}#end of FlashFileCompare

# --------------- dump_ref_for_debug
# mkdir() as needed
sub dump_ref_for_debug
{
my (
    $fn,   # "$log_subdir\\table.as.hash.txt";
    $ph,
    ) = @_;

# quick return if shipping version
return;  # z_z

# mkdir if needed
my ($path_ix ) = rindex ( $fn, "\\" );
my ( $subdir ) = substr( $fn,0,$path_ix);
system ( "cmd.exe /c mkdir $subdir" ) if ( ! ( -d $subdir ));

# dump hash
my ( $fh ) = new IO::File ">$fn";
## print $fh Dumper ( $ph );  # z_z
$fh->close();

} # dump_ref_for_debug



# ---------------------------- PossiblyShrinkAllLogFiles
# max of NNNN lines; when you hit it, back to nnnn lines

#   if limit of 3000 lines, about 300K max
#   if limit of 6000 lines, about 600K max

sub PossiblyShrinkAllLogFiles
{
my ( $szCmd, $szLogFile, $cnt, @aLine );
my ( $max_cnt, $rollback_cnt )  ;


my ( @aLogFilesToShrink ) = ( $hCrntEnv{'log_file'}, $hCrntEnv{'sum_log_file'}, $hCrntEnv{'email_log_file'}, $hCrntEnv{'successful_log_file'}  ) ;
if ( defined ( $hIniFile{'temp_download_subdir'}  ) && ! $is_unix && $hIniFile{'skip_file_in_use_process'} ne 'Y' )
   {
   my ( $szPreviouslyCopiedInUse ) = $hIniFile{'temp_download_subdir'}  ; #. "Previously_copied.txt"
   $szPreviouslyCopiedInUse .= $slash if ( $szPreviouslyCopiedInUse !~ /[\\\/]$/ ) ;  #. "Previously_copied.txt"
   $szPreviouslyCopiedInUse .=  "in_use". $slash ."Previously_copied.txt"      ;
   push @aLogFilesToShrink, $szPreviouslyCopiedInUse  ;
   }

if ( defined ( $hIniFile{'get_id'}  ) )
   {
   my $szIdTrackFile = "$hCrntEnv{'tgt_log_dir'}$slash" . "ID_CMOTrack.log";
   FixSlashes(\$szIdTrackFile,"native");
   push @aLogFilesToShrink, $szIdTrackFile if ( -e $szIdTrackFile ) ;
   }

foreach $szLogFile ( @aLogFilesToShrink )
    {
    if ( $szLogFile =~ /successful_download/ )
       {
       $max_cnt       = 100 ;
       $rollback_cnt  = 50  ;
       }
    elsif ( $szLogFile =~ /ID_CMOTrack|shiplist_done/i )
       {
       $max_cnt       = 10000 ;
       $rollback_cnt  = 9000  ;
       }
    elsif ( defined ( $hIniFile{'log_file_max_length'} ) && $hIniFile{'log_file_max_length'} =~  /^\d+$/ )
       {
       $max_cnt       = $hIniFile{'log_file_max_length'}       ;
       $rollback_cnt  = $hIniFile{'log_file_max_length'} - 500 ;
       }
    else
       {
       $max_cnt       = 6000;   # was 3000
       $rollback_cnt  = 5500;   # was 2500;
       }
    next if ( ! -e $szLogFile ) ;
    next if ( ! ( open ( LOG, $szLogFile )));
    @aLine = <LOG>;
    close(LOG);
    $cnt = scalar(@aLine);

    if ( $cnt > $max_cnt )
        {
        AppendLog ( "PossiblyShrinkAllLogFiles: shrink log file=$szLogFile from $cnt to $rollback_cnt", );
        @aLine = @aLine[($cnt - $rollback_cnt)..($cnt-1)];
        unlink ( $szLogFile );
        open ( LOG, ">$szLogFile" );
        print LOG join("",@aLine);
        close(LOG);
        }
    }

} # PossiblyShrinkAllLogFiles


# --------------- quote_if_has_spaces
# if has spaces, quote it
sub quote_if_has_spaces
{
my ( $p_token ) = @_;

$$p_token = "\"$$p_token\"" if ( $$p_token =~ / /);     # quote it as needed

} # quote_if_has_spaces

# --------------- months_diff
#       Returns positive integer for number of months different between two YYYYMMs
sub months_diff
{
my( $szDate1, $szDate2 ) = @_ ;
my ( $Years, $Months );
$Years  = substr($szDate1,0,4) - substr($szDate2,0,4);
$Months = substr($szDate1,4,2) - substr($szDate2,4,2);
return abs($Years*12 + $Months);

} # months_diff

# -------------------------- FixSlashes
# force to unix style (forward slash) or nt style (backslash) (if "native", use global $is_unix)
sub FixSlashes
{
my (
    $refPath,    # fix user's path
    $szFlavor    # native/unix/nt ... (if "native", use global $is_unix)
    ) = @_;

die "FixSlashes: must pass string ref. as arg" if ( ref($refPath) ne 'SCALAR' );

if ( $szFlavor eq "native" )
    {
    if($is_unix)
        {
        $$refPath =~ s/\\/\//g;   # back to forward slash
        }
    else
        {
        $$refPath =~ s/\//\\/g;   # forward to back slash
        }

    return $$refPath;
    }

if ( $szFlavor eq "unix" )
    {
    $$refPath =~ s/\\/\//g;   # back to forward slash
    return $$refPath;
    }

if ( $szFlavor eq "nt" )
    {
    $$refPath =~ s/\//\\/g;   # forward to back slash
    return $$refPath;
    }

die "FixSlashes(): illegal arg to FixSlashes()=$szFlavor";

} # FixSlashes


# -------------------------- UnixSlashes
# force to unix style (forward slash)
# caller should call like this: UnixSlashes ( \$szPath )
sub UnixSlashes
{
    my ( $refPath ) = @_;

    $$refPath =~ s/\\/\//g;   # back to forward slash

} # UnixSlashes


# ----------------- MkdirAsReq
# make subdir if cannot see it; retry NN times

# we need to know:
#    $hIniFile{'operating_system'}

# called by:
#   DiskSpaceAvailable
#   UncompressFile
#   MakeLocalSubdirPerCmoStateHash
#   etc, etc

# return "" if all is OK; else, return error message

sub MkdirAsReq
{
my(
   $szPath,  # e.g:
                 #   c:\\intex\\cmo_cdu\\mbspools\\1997\\mbscusip.inf.Z
                 #   /home/intex/cmo_cdu/mbspools/1997/mbscusip.inf.Z
   $iHasFile,   # optional arg: if defined: 0=path only  1=file included; default value is 0 (path only)
   ) = @_;

my ( $szPathSoFar, @aToken, $szToken, $iMax, $szSubdir, $ix );
my $func_name = "MkdirAsReq";

$iHasFile = 0 if ( !defined($iHasFile));

# nt/2000/xp ...
if ( $hIniFile{'operating_system'} eq "nt" )  # unix/nt/win95/win98
    {
    # figure out subdir
    if ( $iHasFile )
        {
        $ix = rindex($szPath,"\\");
        $szSubdir = substr($szPath,0,$ix);
        }
    else
        {
        $szSubdir = $szPath;
        }

    # if already have subdir, done
    return "" if ( -d $szSubdir );   # no error

    # got this far, will retry on making subdir; but first figure out retry_cnt
    my $retry_cnt = 1;  # default value
    my $dir_debug = 0;       # if have error, may do a "cmd /c dir" command and put output in autodnld.log to help debug
    my $net_use_debug = 0;   # if have error, may do a "net use" command and put output in autodnld.log to help debug
    my $map_debug = 0;   # if have error, may do a "map" command and put output in autodnld.log to help debug

    if ( defined($hIniFile{'mkdir_retry_cnt'} ) )  # if in ini file .. .can use trailing debug letters: d,n,m
         {
         $retry_cnt = $hIniFile{'mkdir_retry_cnt'};
         $dir_debug =     1 if ($retry_cnt =~ /d/);   # if have error, may do a "cmd /c dir" command and put output in autodnld.log to help debug
         $net_use_debug = 1 if ($retry_cnt =~ /n/);   # if have error, may do a "net use" command and put output in autodnld.log to help debug
         $map_debug =     1 if ($retry_cnt =~ /m/);   # if have error, may do a "map" command and put output in autodnld.log to help debug
         $retry_cnt =~ /^(\d+)/;  # chop any trailing letters
         $retry_cnt = $1;
         AppendLog ( "$func_name(): retry_cnt set to $retry_cnt per ini file: mkdir_retry_cnt=$retry_cnt",) if ( LogThis( 'gen' ) > 0 );
         }

    if ( $retry_cnt < 2 )
         {
         $retry_cnt = 1;
         AppendLog ( "$func_name(): retry_cnt raised to min. value of 2", ) if ( LogThis( 'gen' ) > 0 );
         }

    # got this far, retry on making subdir
    my $quoted_subdir = $szSubdir;
    quote_if_has_spaces(\$quoted_subdir);

    for ( my $try = 1; ; $try++ )
        {
        my $msg;
        my $szCmd = "$com_spec mkdir $quoted_subdir";   # $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c"
        AppendLog ( "$func_name(): try to mkdir: cmd=$szCmd") if ( LogThis( 'gen' ) > 0 );
        system ( $szCmd);

        if ( -d $szSubdir )
            {
            AppendLog ( "$func_name(): mkdir was successful" ) if ( LogThis( 'gen' ) > 0 );
            return "";
            }

        if ( ! -d $szSubdir && $try >= $retry_cnt)
            {
            $msg = "Cannot see subdir=$szSubdir
(Already tried to create it)
We retried $retry_cnt times";

            AppendLog ( "$func_name(): return error msg: $msg" ) if ( LogThis( 'gen' ) > 0 );
            return $msg;
            }

        # ok, we will try again, but first: may have dir debug
        $msg = "WARNING: could not see nor create subdir=$szSubdir; will wait and then try again";
        print "$msg\n";

        # may have dir debug
        if ( $dir_debug && !$is_unix )
            {
            my $cmd = "$com_spec dir $szSubdir";  # com_spec: "nt" ? "cmd.exe /c" : "command /c";
            my @aLine = `$cmd`;
            my ( @aCustomerLog ) = ( "Making local directories on the system", "Autodnld was unsuccessful trying to make directory: $szSubdir", "To test for an internal error try to make that directory", "If successfull please forward autodnld.log file to Intex", "Ran Debug = $cmd here are the results:" ) ;
            push ( @aCustomerLog, @aLine ) ;
            AppendLog ( "$func_name: run debug cmd=$cmd, here are the results
================================
" . join("",@aLine) . "
================================","", \@aCustomerLog ) if ( LogThis( 'gen' ) > 0 );
            }

        # may have "net use" debug
        if ( $net_use_debug && !$is_unix )
            {
            my $cmd = "net.exe use";
            my @aLine = `$cmd`;
            my ( @aCustomerLog ) = ( "Making local directories on the system", "Autodnld was unsuccessful trying to make directory: $szSubdir", "To test for an internal error try to make that directory", "If successfull please forward autodnld.log file to Intex", "Ran Debug = $cmd here are the results:" ) ;
            push ( @aCustomerLog, @aLine ) ;
            AppendLog ( "$func_name: run debug cmd=$cmd, here are the results
================================
" . join("",@aLine) . "
================================", "",  \@aCustomerLog ) if ( LogThis( 'gen' ) > 0 );
            }

        # may have "map" debug
        if ( $map_debug && !$is_unix )
            {
            my $cmd = "map";
            my @aLine = `$cmd`;
            my ( @aCustomerLog ) = ( "Making local directories on the system", "Autodnld was unsuccessful trying to make directory: $szSubdir", "To test for an internal error try to make that directory", "If successfull please forward autodnld.log file to Intex", "Ran Debug = $cmd here are the results:" ) ;
            push ( @aCustomerLog, @aLine ) ;
            AppendLog ( "$func_name: run debug cmd=$cmd, here are the results
================================
" . join("",@aLine) . "
================================", "",  \@aCustomerLog ) if ( LogThis( 'gen' ) > 0 );
            }

        # ok, sleep then retry again
        AppendLog ( "$func_name(): $msg" ) if ( LogThis( 'gen' ) > 0 );
        sleep(2);
        }
    }

# got this far; must be win95/98/unix
if ( $hIniFile{'operating_system'} ne "unix" )  # unix/nt/win95/win98
    {
    @aToken = split ( /\\/, substr($szPath,3 ) );   # e.g. intex,cmo_cdu...
    }
else
    {
    @aToken = split ( /\//, substr($szPath,1 ) );   # e.g. intex,cmo_cdu...
    }

# start with this, keep adding delim plus token
if ( $hIniFile{'operating_system'} ne "unix" )
    {
    $szPathSoFar = substr($szPath,0,2);    # e.g. "d:"
    }
else
    {
    $szPathSoFar = "/";
    }

$iMax = $iHasFile ? scalar(@aToken)-1 : scalar(@aToken);    # if has file also, skip last token: this is file name

for ( $ix = 0; $ix < $iMax; $ix++ )
    {
    $szToken = $aToken[$ix];
    $szPathSoFar .= "$slash$szToken";

    if ( ! ( -d $szPathSoFar ) )
        {
        if ( mkdir ( $szPathSoFar, 0777 ) != 1 )
            {
            return "Cannot see subdir=$szPathSoFar, and cannot create it either";
            }
        }

    } # tokens...

return "";  # no error

} # MkdirAsReq


# --------------- push_error_if_bad_exe
# check exe (first token in command); if cannot find it, push error and return non-zero
sub push_error_if_bad_exe
{
my (
    $cmd,
    $paErr,
    ) = @_;

my ( $exe, $rest ) = split( /\s+/,$cmd );

if ( !defined( $exe ))
    {
    push ( @$paErr, "Cannot find exe in this command: $cmd" );
    return 1;
    }

if ( $is_unix )
    {
    return 0 if ( -l $exe  ||  -X $exe );
    push ( @$paErr, "Cannot find the following program which autodnld needs to run: $exe" );
    push ( @$paErr, "We recommend that you create a symbolic link to this program in the autodnld/scripts subdir" );
    push ( @$paErr, "Typical command: ln -s /usr/local/bin/gzip gzip" );
    return 1;
    }
else
    {
    return 0 if ( -e $exe );
    push ( @$paErr, "Cannot find the following program (which autodnld needs to run): $exe" );
    return 1;
    }

# got this far; error
push ( @$paErr, "Cannot find the following exe which autodnld needs to run: $exe" );
push ( @$paErr, "NOTE: under UNIX, you need a symbolic link to the exe in the autodnld/scripts subdir") if ( $is_unix );
return 1;

} # push_error_if_bad_exe


# -------------------- ZapSerializedFile
# only called for
#   shipinfo.*
#   cmo_cdi.*
#   cmo_cdu.*

# if .Z file, also try to zap file w/o the .Z

sub ZapSerializedFile
{
my ( $szFile, $bUpdateSuccessFile ) = @_;

# have special option to not do this
if ( $bUpdateSuccessFile == 1 && $szFile =~ /cmo_cd.*\d\d/)  ## serialized
   {
   my $szTempFile = $szFile ;
   $szTempFile =~ s/^.*(cmo[^\\\/]+)$/$1/ ;

   my $szSuccessfulDownloadListFile =  $hCrntEnv{'successful_log_file'} ;
   open ( SUCCESS, ">>$szSuccessfulDownloadListFile" ) ;
   print SUCCESS "$szTempFile\n" ;
   close SUCCESS ;
   }

return if ( defined ( $hIniFile{'save_serialized_zip_files'} ) && !($hCmoState{'usehttp'}=~ /HTTP/i) );
return if (defined ( $hIniFile{'save_serialized_zip_files'} )&&($hCmoState{'usehttp'}=~ /HTTP/i)&&($szFile=~/shipinfo\.\d+\.zip$/i));

if ( -e $szFile )
    {
    AppendLog ( "ZapSerializedFile: file=$szFile" ) if ( LogThis( 'gen' ) > 0 );
    unlink ( $szFile );
    }

if ( $szFile =~ /^(.+)\.Z$/ )

    {
    my $fn = $1;

    if ( -e $fn )
        {
        AppendLog ( "ZapSerializedFile: secondary file=$fn") if ( LogThis( 'gen' ) > 0 );
        unlink ( $fn );
        }
    }

return 0;

} # ZapSerializedFile


# -------------------------- DiskSpaceAvailable
# figure how much disk room in a subdir
# return # of bytes, 0 if error (also return traceback message(s) in case we have problem)

sub DiskSpaceAvailable
{
my (
    $subdir_to_check,     # check space in this subdir
    $paTraceBack,  # put list of traceback strings here for caller to possibly email if error
    ) = @_;

my( $szDir, @aDir, $szDirLine, $iBytesAvailable, $ii );
my( $szResult, $szLine, @aLine, $ix, $szCmd );

@$paTraceBack = () if defined ( $paTraceBack );

# just in case ... have pooldata only and no cmo_cdu path yet
my ( $szErr ) = MkdirAsReq ( $subdir_to_check );

if ( $szErr ne "" )
    {
    push ( @$paTraceBack, $szErr );
    return 0;
    }




# user defined magic word: UNLIMITED (put this in autodnld.ini: "disk_space_cmd=UNLIMITED") ...........................
if( $hIniFile{disk_space_cmd}  &&   $hIniFile{disk_space_cmd} eq 'UNLIMITED' )
    {
    push ( @$paTraceBack, "Using custom script=$hIniFile{'disk_space_cmd'}" )  if defined ( $paTraceBack );
    $iBytesAvailable = 1_000_000_000_000;
    return $iBytesAvailable;
    }



####################### user defined ######################

# if user script
#    use disk_space_cmd directive in .ini file e.g. "disk_space_cmd=d:\autodnld\scripts\diskspace.pl"
#    use $subdir_to_check in user script
#    set the value $iBytesAvailable in user script
#    sample script: see diskspaceN.pl in source subdir

if(defined($hIniFile{'disk_space_cmd'})  &&  length($hIniFile{'disk_space_cmd'}))
    {
    push ( @$paTraceBack, "Using custom script=$hIniFile{'disk_space_cmd'}" )  if defined ( $paTraceBack );

    # read in script
    if(!(open(EVAL,$hIniFile{'disk_space_cmd'})))
        {
        my ( @aCustomerLog ) = ( "Using user script to get disk space avbailable, and had an error", "Please check if the script: $hIniFile{'disk_space_cmd'} is available" ) ;
        AppendLog("ERROR: Unable to open disk space script=$hIniFile{'disk_space_cmd'}", 1, \@aCustomerLog );
        return 0;
        }

    @aLine = <EVAL>;
    close(EVAL);

    # eval each line
    # note: subdir var used to be called $szSubdir
    my $szSubdir = $subdir_to_check;

    foreach $szLine ( @aLine )
        {
        if ( $szLine ne "" )
            {
            push ( @$paTraceBack, "eval() line=$szLine")  if defined ( $paTraceBack );
            eval($szLine);
            }
        }

    return $iBytesAvailable;
    }


####################################### unix ##########################################


if($is_unix)
    {
    push ( @$paTraceBack, "Operating system is UNIX" )  if defined ( $paTraceBack );

    # run the df command
    $szCmd = "df $subdir_to_check";
    push ( @$paTraceBack, "cmd=$szCmd" )  if defined ( $paTraceBack );
    @aLine = `$szCmd`;
    $ix = 0;

    foreach $szLine ( @aLine )
        {
        $szLine =~ s/[\n\r]//g; # chomp() not reliable on Solaris
        $aLine[$ix] = $szLine;
        $ix++;
        }

    if (defined ( $paTraceBack ))
        {
        push ( @$paTraceBack, "Result of disk space command:
command=$szCmd
lines:
------------
" . join("",@aLine) . "\n------------\n" )  ;
        }

    # try for linux type listing ... 1k-blocks is the magic word
    # warning: the lines may wrap and we may get more than two lines
    # thus we put all the tokens on the same line, and go one token back from nn%
    # ---------------------------------
    # "Filesystem           1k-blocks      Used Available Use% Mounted on"
    # "dev/hdb6                80004     44712     31161  59% /home
    # ---------------------------------
    my @aToken = ();

    foreach my $line ( @aLine )   # glue together
        {
        my @aTemp = split(/\s+/,$line);
        push ( @aToken, @aTemp );
        }

    if ( scalar(grep(/^1k\-blocks$/i,@aToken))  ||  scalar(grep(/^kbytes$/i,@aToken)))  # if have magic word...
        {
        for ( my $ii = 0; $ii < scalar(@aToken); $ii++ )  # walk list...
            {
            if ( $aToken[$ii] =~ /^\d+\%/ )    # if nn%
                {
                my $val = $aToken[$ii-1];     # one back

                if ( defined($val) && $val =~ /^\d+$/ )  # if pure digits
                    {
                    AppendLog ( "DiskSpaceAvailable(): we found value of " . $val . " within linux style listing, block size is 1024" );
                    return $val * 1024;
                    }
                } # token ok
            } # each token
        } # found 1k-blocks

    # try for Solaris style listing
    # we want the token just before "blocks" on the first line
    # always 512 byte blocks ??
    # ---------------------------------
    # "/export/home       (/dev/md/dsk/d27   ): 4512106 blocks 12243245 files"
    # ---------------------------------
    @aToken = split(/[\s:]+/,$aLine[0]);
    $ii = 0;

    foreach my $szToken (@aToken)
        {
        if($szToken =~ /blocks/)
            {
            my $val = $aToken[$ii - 1];

            if ( $val =~ /^\d+$/ )
                {
                AppendLog ( "DiskSpaceAvailable(): we found value of " . $aToken[$ii - 1] . " just before \"blocks\" ... use this times 512" );
                return $val * 512;
                }
            }

        $ii++;
        }

    # if got this far, cannot parse the disk-free listing
    return 0;
    }



####################################### win98/winnt ##############################################3
# windows nt/98 # use dir command in command shell
# typical command unders win98: command /c dir c:\intex\autodnld\log
# typical output line: "                          4,399,329,280 bytes free"

push ( @$paTraceBack, "Operating system is $hIniFile{'operating_system'}" )  if defined ( $paTraceBack );
my $quoted_subdir = $subdir_to_check;
quote_if_has_spaces ( \$quoted_subdir );
$szCmd = "$com_spec dir $quoted_subdir";   # $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c"

# commented for unix scripts # #my ( @aBack  )  = Win32::AdminMisc::GetDriveSpace (  $quoted_subdir ) ;     # cline44
# commented for unix scripts # #my ( $szDiskSpace ) =  $aBack[1] ;                                          # cline44

# commented for unix scripts # #if ( $szDiskSpace > 10 )                                                                       # cline44
# commented for unix scripts # #   {                                                                                           # cline44
# commented for unix scripts # #   AppendLog ( "DiskSpaceAvailable(): we found value of $szDiskSpace from GetDriveSpace()" );  # cline44
# commented for unix scripts # #   return $szDiskSpace ;                                                                       # cline44
# commented for unix scripts # #   }                                                                                           # cline44

push ( @$paTraceBack, "cmd=$szCmd" )  if defined ( $paTraceBack );
@aDir = `$szCmd`;
push ( @$paTraceBack, "Result of dir cmd=" . join("",@aDir))  if defined ( $paTraceBack );
push ( @$paTraceBack, "We will search for pattern=\"bytes free\" in output")  if defined ( $paTraceBack );

foreach $szDirLine (@aDir)
    {
    $szDirLine =~ s/[\n\r]//g;  # chomp() not reliable on Solaris

    if ( defined ( $hIniFile{'disk_space_pattern'} ) )
        {
        my $szBytesFreePattern = $hIniFile{'disk_space_pattern'} ;
        if($szDirLine =~ /([\d\.,]+) $szBytesFreePattern/i )   ## hardcoded: for French
            {
            my $szTempDirLine = $1 ;
            $szDirLine = $szTempDirLine if ( $szTempDirLine ne "" ) ;
            $szDirLine =~ s/\D//g;  # zap all the non digits

            return $szDirLine;
            }

        }
    else
        {
        if($szDirLine =~ /(\S+) bytes free\w*$|(\S+) octets libres\w*$|(\S+) bytes frei\w*$/i )   ## hardcoded: for French
            {
            my $szTempDirLine = $1 ;
            $szDirLine = $szTempDirLine if ( $szTempDirLine ne "" ) ;
            $szDirLine =~ s/\D//g;  # zap all the non digits

            return $szDirLine;
            }

        # may have "NNN,NNN,NNN bytes"
        # e.g. typical win98 output:
    ###             38 file(s)     47,863,832 bytes
    ###             94 dir(s)       16,477.89 MB free

        if($szDirLine =~ /([\d\.,]+) MB free/)
            {
            $szDirLine = $1;        # e.g. NNN,NNN,NNN.NN
            $szDirLine =~ s/,//g;   # zap commas
            return int($szDirLine * 1000000); # return # of bytes
            }
        }
    }

    # got this far; error
    return 0;

} # DiskSpaceAvailable


########################################################################################################
######################## read ini file #################################################################
########################################################################################################

# -------------------------------------------- GetParameter
# get cdi or cdu subdir; possibly under flash, for example
sub GetParameter
{
    my( $szKey ) = $_[0];
    my( $szDir ) = $_[1];
    my( $szCompositeKey );
    my( $szTemp ) = "";

    if($szDir eq $hCrntEnv{'cmodata_keyword'} || length($szDir) == 0)
    {
        $szCompositeKey = $szKey;
    }
    else
    {
        $szCompositeKey = "\[$szDir\]$szKey";
    }
    #This seems to be necessary to avoid the "uninitialized variable" complaint when the key doesn't exist.
    if(defined($hIniFile{$szCompositeKey}))
    {
        $szTemp = $hIniFile{$szCompositeKey};
    }
    return $szTemp;

} # GetParameter



# -------------------------------------------- ReadIniFile

# read ini file into global "%hIniFile"; if multiple tgt_cdu_dir, split off the extra subdirs; no checking for missing values yet
# NOTE: inf file has NOT been read yet; it is read much later on; we do various computations when we read the inf file
# caller will next call CheckAndDeriveIniInfo() if we return w/o error

# do not use AppendLog() yet

# if we have paragraphs at the bottom of the ini file, they are a little irregular to encode
# sample lines:
## -----------------------------
## [flash]=y
## tgt_cdi_dir=c:\intex\cmo_cdi
## tgt_cdu_dir=c:\intex\cmo_cdu
## -----------------------------

# sample single value hash key
##  email_to

# sample paragraph hash keys:
##   [flash]y [flash]tgt_cdi_dir [flash]tgt_cdu_dir)

# if error return non-zero # caller will write to console and abort autodnld program; NOTE: there is NO log file yet
##  cannot read .ini file:
## bad password

sub ReadIniFile
{
my( $szFile ) = $_[0];

my ( $szLine, @aParamLine, $szKey, $szVal );
my ( $szParaKey );  # if have value, we are processing a paragraph key e.g. [flash]

if ( !open ( IN, $szFile ) )
    {
    print "ERROR: could not open file=$szFile (NOTE: you must run autodnld program from the scripts subdir)\n";
    return(1);
    }

$szParaKey = "";  # will fill in if have para section

while ( defined($szLine = <IN>) )
    {
    $szLine =~ s/[\n\r]//g;
    $szLine =~ s/^\s*//;        # left trim
    $szLine =~ s/\s*$//;        # right trim

    # skip comments and empty lines
    if ( $szLine eq "" || substr($szLine,0,1) eq "#" )
        {
        next;
        }

    # paragraph key? ... once we encounter this, all keys from here down get a para key prefix
    if ( $szLine =~ /^\[(\S+)\]=(\S+)$/ ) # token in angle brackets; equal sign; token
        {
        $szParaKey = $1;
        $szKey = "[$szParaKey]";
        $szVal = uc($2);        # u.c. it just in case
        $hIniFile{$szKey} = $szVal;
        next;
        }

    # split at equal sign w/ optional whitespace after equal sign, only do the first equal sign. See http_session_header
    @aParamLine = split(/=\s*/,$szLine,2);
    $szKey = $aParamLine[0];

    if (defined($aParamLine[1]))
        {
        $szVal = $aParamLine[1];
        }
    else
        {
        $szVal = "";
        }

    # if we are in para section, add that to key
    if ( $szParaKey ne "" )
        {
        $szKey = "[$szParaKey]$szKey";
        }

    # save the name/value
    if ( uc ( $szKey ) eq "USER" && $szVal =~ /[A-Z]/ )
        {
        $szVal = lc ( $szVal ) ;
        }

    if ( uc ( $szKey ) eq "EMAIL_TO" && $szVal =~ / / )
        {
        $szVal =~ s/ //g ;
        }

    $hIniFile{$szKey} = $szVal;

    }                      # foreach line

# unencrypt password; now it is defined for the first time; place in global
my $err = '';
$ship_server_password = UnEncrypt($hIniFile{'password'}, \$err);  # global

if ( $err ne '' )
    {
    print "ERROR: $err\n";
    return(1);
    }

# multiple tgt_cdi_dir? ... if so, split off the extra subdirs
if ( $hIniFile{'tgt_cdi_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_cdi_dir'} );
    $hIniFile{'tgt_cdi_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_cdi_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): We have extra CDI subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_cdi_dirs'}}) );
    }

# multiple tgt_cdu_dir? ... if so, split off the extra subdirs
if ( $hIniFile{'tgt_cdu_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_cdu_dir'} );
    $hIniFile{'tgt_cdu_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_cdu_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): We have extra CDU subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_cdu_dirs'}}));

    # NOTE: wait until ReadInfFile() to do the following: from the extra-cdu subdir, make extra-int-rate subdir
    }

# multiple tgt_perfdata_dir? ... if so, split off the extra subdirs
if ( defined($hIniFile{'tgt_perfdata_dir'})  &&  $hIniFile{'tgt_perfdata_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_perfdata_dir'} );
    $hIniFile{'tgt_perfdata_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_perfdata_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): have extra performance data subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_perfdata_dirs'}}));
    }

# multiple tgt_remitdata_dir? ... if so, split off the extra subdirs
if ( defined($hIniFile{'tgt_remitdata_dir'})  &&  $hIniFile{'tgt_remitdata_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_remitdata_dir'} );
    $hIniFile{'tgt_remitdata_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_remitdata_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): we have extra remittance data subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_remitdata_dirs'}}));
    }
# multiple tgt_histdata_dir? ... if so, split off the extra subdirs
if ( defined($hIniFile{'tgt_histdata_dir'})  &&  $hIniFile{'tgt_histdata_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_histdata_dir'} );
    $hIniFile{'tgt_histdata_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_histdata_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): we have extra hist data subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_histdata_dirs'}}));
    }
# multiple tgt_remitdata_dir? ... if so, split off the extra subdirs
if ( defined($hIniFile{'tgt_rmtddata_dir'})  &&  $hIniFile{'tgt_rmtddata_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_rmtddata_dir'} );
    $hIniFile{'tgt_rmtddata_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_rmtddata_dirs'} = [@aPath];
##    AppendLog ("ReadIniFile(): we have extra remittance data subdir(s) to replicate data to: " . join(",",@{$hIniFile{'extra_remitdata_dirs'}}));
    }
# multiple tgt_remitdata_dir? ... if so, split off the extra subdirs
if ( defined($hIniFile{'tgt_deal_remit_data_dir'})  &&  $hIniFile{'tgt_deal_remit_data_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_deal_remit_data_dir'} );
    $hIniFile{'tgt_deal_remit_data_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_deal_remit_data_dirs'} = [@aPath];
    }

if ( defined($hIniFile{'tgt_tranche_remit_data_dir'})  &&  $hIniFile{'tgt_tranche_remit_data_dir'} =~ /,/ )
    {
    my @aPath = split(/ *, */,$hIniFile{'tgt_tranche_remit_data_dir'} );
    $hIniFile{'tgt_tranche_remit_data_dir'} = $aPath[0];
    splice ( @aPath,0,1);
    $hIniFile{'extra_tranche_remit_data_dirs'} = [@aPath];
    }
if ( defined ( $hIniFile{'http_session_header'} ) && $hIniFile{'http_session_header'} ne "" )
   {
   $hIniFile{'try_alternate_server'} = "N" ;
   #session header could have encoded string need to strip the password part first

   #$hIniFile{http_session_header}="HTTPS_PROXY=${sServerIPPort}|HTTPS_PROXY_USERNAME=${sProxyUserName}|HTTPS_PROXY_PASSWORD=ENCODE\"${s{ProxyPwd}\"";
   my @aLine = split(/\|/,$hIniFile{'http_session_header'});

   foreach my $szLine ( @aLine )
       {
       my ( $sKey, $sVal ) = split(/=/,$szLine,2);
       if ( grep( /^$sKey$/i, @aHttpProxyKeywords ) )
           {

            if (($sKey=~/HTTPS_PROXY_PASSWORD/i)&&($hIniFile{'http_session_header'}=~/\|HTTPS_PROXY_PASSWORD=ENCODE"(\S+)"/)) {
               #encoded password has to grab from original string, in case split token showed up in the password string
               $sVal=password_decoding($1);
               $ENV{uc($sKey)} = $sVal;
            }
            elsif ($sKey eq 'HTTPS_PROXY_PASSWORD' && $sVal eq "ENCODE\"\"") {
                  $ENV{uc($sKey)} = "";
               }
            else {
               $ENV{uc($sKey)} = $sVal;
            }
       }
       }
   ### SAMPLE HTTP HEADER
   # http_session_header=HTTPS_PROXY=http://proxy_server:port|HTTPS_PROXY_USERNAME=PROXY_USERNAME|HTTPS_PROXY_PASSWORD=PROXY_PASSWORD
   # proxy support
   }
if ( defined( $hIniFile{'unix_unzip_cmd'} ) && $hIniFile{'unix_unzip_cmd'} !~ /^\s*$/ )
   {
   if ( $hIniFile{'unix_unzip_cmd'} !~ /\%FILE\%/ )
       {
       AppendLog ("ReadIniFile(): WARNING: We have a custom unix_unzip_cmd that does not make reference to the parameter \%FILE\% (".$hIniFile{'unix_unzip_cmd'}."), so ignoring this parameter.  Please see the Autodnld manual for proper usage" );
       delete($hIniFile{'unix_unzip_cmd'});
       }
   if ( $hIniFile{'unix_unzip_cmd'} !~ /\%DESTDIR\%/ )
       {
       AppendLog ("ReadIniFile(): WARNING: We have a custom unix_unzip_cmd that does not make reference to the parameter \%DESTDIR\% (".$hIniFile{'unix_unzip_cmd'}."), so ignoring this parameter.  Please see the Autodnld manual for proper usage" );
       delete($hIniFile{'unix_unzip_cmd'});
       }
   }
if ( defined( $hIniFile{'win_unzip_cmd'} ) && $hIniFile{'win_unzip_cmd'} !~ /^\s*$/ )
   {
   if ( $hIniFile{'win_unzip_cmd'} !~ /\%FILE\%/ )
       {
       AppendLog ("ReadIniFile(): WARNING: We have a custom win_unzip_cmd that does not make reference to the parameter \%FILE\% (".$hIniFile{'win_unzip_cmd'}."), so ignoring this parameter.  Please see the Autodnld manual for proper usage" );
       delete($hIniFile{'win_unzip_cmd'});
       }
   if ( $hIniFile{'win_unzip_cmd'} !~ /\%DESTDIR\%/ )
       {
       AppendLog ("ReadIniFile(): WARNING: We have a custom win_unzip_cmd that does not make reference to the parameter \%DESTDIR\% (".$hIniFile{'win_unzip_cmd'}."), so ignoring this parameter.  Please see the Autodnld manual for proper usage" );
       delete($hIniFile{'win_unzip_cmd'});
       }
   }

%hIniFileOrig = %hIniFile;


$hIniFile{'suppress_log'}='y' if ( ! defined( $hIniFile{'suppress_log'} ) );

return 0;

} # ReadIniFile



# -------------------------------------------- read_name_val_file
# read a file in format name=value
# return hash ref or undef
sub read_name_val_file
{
my( $szFile ) = $_[0];

return if ( ! -e $szFile );  # return undef
return if ( open ( IN, $szFile ) != 1 );
my $phVal = {};

while ( defined( my $line = <IN>) )
    {
    $line =~ s/[\n\r]//g;
    $line =~ s/^\s*//;        # left trim
    $line =~ s/\s*$//;        # right trim
    next if ( $line eq "" || substr($line,0,1) eq "#" );   # skip comments and empty lines

    # split at equal sign (possible spaces after equal sign)
    my ( $name, $val )  = split(/=\s*/,$line);
    $phVal->{$name} = $val if ( defined($name)  &&  defined($val) );
    }

return $phVal;

} # read_name_val_file


# -------------------------------------------- write_name_val_file
# write a file in format name=value

sub write_name_val_file
{
my(
   $szFile,
   $phVal,
   $p_err,  # may set error
   ) = @_;

AppendLog ( "save name/val data to file=$szFile" );

if ( open ( OUT, ">$szFile" ) )
    {
    print OUT "# this file written by $0 on " . scalar(localtime()) . "\n";

    foreach my $key ( sort ( keys ( %$phVal )))
        {
        print OUT "$key=$phVal->{$key}\n";
        }

    close(OUT);
    }

} # write_name_val_file


# ------------- CheckAndDeriveIniInfo  (WARNING: similar code in autodnld_install.ini)
# Have just read ini file; have computed $slash; have found value for tgt_log_dir; have computed and started log files:
# ... now we can do this: check for missing ini values; fill in default values if missing; derive a few %hCrntEnv keys also
# return non zero if error
sub CheckAndDeriveIniInfo
{
my ( $szKey, @aLine );

# load list of expected keys
my @aKey = ();
push ( @aKey, 'autodnld_home' );
#push ( @aKey, 'cdu_purge_depth' ); #Chris request 20140115, cdu_purge_depth no longer a required, but still default =0
push ( @aKey, 'operating_system' );
push ( @aKey, 'password' );
push ( @aKey, 'tgt_cdi_dir' );
push ( @aKey, 'tgt_cdu_dir' );
push ( @aKey, 'user' );

#if ( $hIniFile{'operating_system'} eq "unix" && defined ($hIniFile{'email_to'}) &&  $hIniFile{'email_to'} ne '' )
#    {
#    push ( @aKey, 'mail_bin' );
#    }

# NOTE: 'mail_server' is not required, since 'email_to' may be blank

# walk list of required keys
foreach $szKey (@aKey )
    {
    if ( !defined ( $hIniFile{$szKey} ) )
        {
        print "ERROR: a value is missing from your autodnld.ini file.\n";
        print "Missing value=$szKey\n";
        print "Please run autodnld_install to edit and correct the .ini file\n";
        return(1);
        }
    }

# the following feature is experimental
#  You can use the same script for NT and win95/98
#  To do this, you specify Windows NT plus either 95 or 98 as your OS e.g. "nt;win95" or "nt;win98"
#  This means editing the autodnld.ini file directly.
#  You must have the Win32::GetOSVersion() entry point in your Perl build to use this feature
if ( $hIniFile{'operating_system'} =~ /nt;(win\d\d)/ )
{
   my ( $winDD ) = $1;
   my ( $id ) = (Win32::GetOSVersion())[4];
   $hIniFile{'operating_system'} = ($id == 2) ? "nt" : $winDD;
}
elsif ( $hIniFile{'operating_system'} =~ /nt;(win\d\d\d\d)/ )
{
   my ( $winDD ) = $1;
   my ( $id ) = (Win32::GetOSVersion())[4];
   $hIniFile{'operating_system'} = ($id == 2) ? "nt" : $winDD;
}
elsif ( $hIniFile{'operating_system'} =~ /xp/ )
{
   $hIniFile{'operating_system'} = "nt" ;
   $com_spec = "cmd.exe /c" ;
}

### just to make things more robust, deal with change in paths: new='autodnld_home'  old='tgt_log_dir'
### this will help user if they just replaced the exe w/o running autodnld_install again
##if ( !defined ( $hIniFile{'autodnld_home'} ) && defined ( $hIniFile{'tgt_log_dir'} ) )
##    {
##    my ( $ix ) = rindex ( $hIniFile{'tgt_log_dir'}, $slash );
##    $hIniFile{'autodnld_home'} = substr ( $hIniFile{'tgt_log_dir'}, 0, $ix-1 );
##    }

# add more later: do keys have values? ... OK if some are empty
if( !length($hIniFile{'password'}))
    {
    print "ERROR: no password in ini file, please run autodnld_install to edit it in\n";
    return 1;
    }

# many keys are optional; if user did not specify them, fill in default
$hIniFile{'bond_data_months_back'} = 2    if ( !defined( $hIniFile{'bond_data_months_back'}));
$hIniFile{'cdu_check_n_months_back'} = 2 if ( !defined ( $hIniFile{'cdu_check_n_months_back'} ) );
$hIniFile{'connection'} = "ship.intex.com" if ( !defined( $hIniFile{'connection'}));
$hIniFile{'cdu_purge_depth'}=0 if (!defined ($hIniFile{'cdu_purge_depth'}));

# 'dbstatus_check' ... only used one place in code ... just check it at that spot
# 'disk_space_cmd' ... check for defined() and then use value in code as needed

$hIniFile{'minimal_email'} = 'N' if ( !defined($hIniFile{'minimal_email'}));

if ( !defined($hIniFile{'mail_sender'} ))
    {
    # NT: use %ENV
    if ($hIniFile{'operating_system'} eq 'nt')
        {
        $hIniFile{'mail_sender'} = $ENV{'COMPUTERNAME'};
        }
    # unix: try to use "uname -n"
    elsif ($hIniFile{'operating_system'} eq 'unix')
        {
        my ( $ss ) = `uname -n`;
        $ss =~ s/[\n\r]//g if ( defined ( $ss ) );
        $hIniFile{'mail_sender'} = ( defined($ss) && $ss ne "" ) ? $ss : $ENV{'COMPUTERNAME'};
        }
    # for win95,98 use ???
    else
        {
        $hIniFile{'mail_sender'} = 'autodnld';
        }
    }

$hIniFile{'pool_data_months_back'} = 2    if ( !defined( $hIniFile{'pool_data_months_back'}));

# check for spaces in 'temp_download_subdir'
##  bad temp subdir: c:/Documents and Settings/finance/Local Settings/Temp
if ( defined ( $hIniFile{'temp_download_subdir'} )  &&  $hIniFile{'temp_download_subdir'} =~ / / )
{
    my ( @aCustomerLog ) = ( "While reading ini file found a bad value for \"temp_download_subdir\"", "There are spaces in the value: \"$hIniFile{'temp_download_subdir'}\"", "Please re-enter a directory in autodnld.ini without a space in it",  ) ;
    if ( !$is_unix )
        {
        push ( @aCustomerLog, "We recommend a value like c:\\temp or d:\\temp") ;
        print "We recommend a value like c:\\temp or d:\\temp\n";
        }
    AppendLog  ("CheckAndDeriveIniInfo(): ERROR: found spaces in value for \"temp_download_subdir\"", "", \@aCustomerLog );
    print "ERROR: there are spaces in the value for \"temp_download_subdir\" in autodnld.ini
This is where autodnld places temporary files (and then erases them later on)\n";

    return 1;
}

# set $hIniFile{'remit_data_months_back'} to default value if not defined
if ( !defined($hIniFile{'remit_data_months_back'}) )
{
    $hIniFile{'remit_data_months_back'} = 2;
    AppendLog ( "set \"remit_data_months_back\" to default value of 2 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

# set $hIniFile{'deal_remit_data_months_back'} to default value if not defined
if ( !defined($hIniFile{'deal_remit_data_months_back'}) )
{
    $hIniFile{'deal_remit_data_months_back'} = 2;
    AppendLog ( "set \"deal_remit_data_months_back\" to default value of 2 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

# set $hIniFile{'tranche_remit_data_months_back'} to default value if not defined
if ( !defined($hIniFile{'tranche_remit_data_months_back'}) )
{
    $hIniFile{'tranche_remit_data_months_back'} = 2;
    AppendLog ( "set \"tranche_remit_data_months_back\" to default value of 2 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

if ( !defined($hIniFile{'rmtd_data_days_back'}) )
{
    $hIniFile{'rmtd_data_days_back'} = 7 ;
    AppendLog ( "set \"rmtd_data_days_back\" to default value of 7 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

if ( !defined($hIniFile{'tranche_remit_diff_data_days_back'}) )
{
    $hIniFile{'tranche_remit_diff_data_days_back'} = 7 ;
    AppendLog ( "set \"tranche_remit_diff_data_days_back\" to default value of 7 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

if ( !defined($hIniFile{'deal_remit_diff_data_days_back'}) )
{
    $hIniFile{'deal_remit_diff_data_days_back'} = 7 ;
    AppendLog ( "set \"deal_remit_diff_data_days_back\" to default value of 7 since not defined in .ini file" ) if ( LogThis('gen') > 0 );
}

return 0;

} # CheckAndDeriveIniInfo

# ---------------------------------- ComposeAndSendMailWorker

# Send file contents; subject is an arg also.

# Only called by: ComposeAndSendEmail()

# NOTE: when running autodnld.pl/autodnld.exe under NT: use blat.exe
#    text.file
#    -t (to)        supplied on command line
#    -s (subject)   supplied on command line
#    -server        machine that is running SMTP service; from ini file; key=mail_server

#    -f             sender ... must be acceptable to SMTP daemon; from ini file; key=mail_sender

#    -i             sender as appears on email ... not necessarily known to SMTP daemon
#                   In other words, this will appear in the "from" field when you receive the email
#                   The contents of this field is hardcoded.

# return non zero if error

sub ComposeAndSendMailWorker
{
my(
   $szEmailFile,   # file that contains email to be sent
   $szSubject,
   $test_mode_flag,  # if set, we are running in test mode; be verbose
   ) = @_;

AppendLog ( "ComposeAndSendMailWorker: start()
  subject=$szSubject" ) if ( LogThis('mail') > 0 );

# read in msg
open ( EMAIL, $szEmailFile );
my @aEmailLine = <EMAIL>;
close ( EMAIL );

# add msg in log file
AppendLog ( "EMAIL: " . join("EMAIL: ",@aEmailLine) );

my @aLine;

if ( $is_unix )
    {
    @aLine = `cat $szEmailFile`;
    }
else
    {
    @aLine = `type $szEmailFile`;
    }

AppendEmailLog ( "\n\n======== Subject: $szSubject (sent at " . scalar(localtime()) . ") ========
" . join("",@aLine) . "
");

# If there are no addresses to send to, done
if(length($hIniFile{'email_to'}) == 0)
    {
       AppendLog ( "No email sent, since no email recipients specified in ini file (key=email_to)" );
       return(0);
    }

# got this far; we will actuall send email (have already logged the message)
FixSlashes ( \$szEmailFile, "native" );

################# got this far; use NT mail for windows, or sendMail for unix

# try NN times (1 if in test mode, otherwise, 3 times)
# decide on from: 'From:' address, not necessarily known to the SMTP server
my ( $mail_from ) = $hIniFile{'mail_from'};
$mail_from = 'Intex_auto_download' if ( !defined($mail_from));

for( my $count = 0; $count < $hCrntEnv{'email_retries'}; $count++)
{

   my $szMailExe;
   if(defined($hIniFile{'mail_exe'}))
    {
      $szMailExe = $hIniFile{'mail_exe'};
      if ( $szMailExe !~ /[\\\/]/ )
         {
            $szMailExe = $hIniFile{'autodnld_home'} . $slash . "scripts\\" . $szMailExe;
         }
    }
    else
    {
     if ($is_unix)
      {
      $szMailExe="perl ".$hIniFile{'autodnld_home'} . $slash . "scripts".$slash."sendEmail";
      }
     else
      {
      $szMailExe = $hIniFile{'autodnld_home'} . $slash . "scripts\\blat.exe";
      }
    }

    my $szCmd = $szMailExe ;
    if( $szCmd =~ /%FROM%/ || $szCmd =~ /%TO%/ || $szCmd =~ /%SUBJECT%/ || $szCmd =~ /%FILE%/ )
      {
        $szCmd =~ s/%FROM%/$mail_from/;
        $szCmd =~ s/%TO%/$hIniFile{'email_to'}/;
        $szCmd =~ s/%SUBJECT%/"$szSubject"/;
        $szCmd =~ s/%FILE%/$szEmailFile/;

        AppendLog("ComposeAndSendMailWorker(): found custom mail command flags.");
      }
    else
      {
        if ($szCmd =~ /sendEmail/)
          {
            $szCmd .=" -o message-file=$szEmailFile -u \"$szSubject\"  -s $hIniFile{'mail_server'}";
            $szCmd .= " -t $hIniFile{'email_to'}";
            $szCmd .= " -f $hIniFile{'mail_sender'}"; # "Sender": NT very rarely SMTP cares who this is, Linux sendMail require this
          }
        else
          {
            #default to use blat, and blat options
            $szCmd=$hIniFile{'autodnld_home'} . $slash . "scripts\\blat.exe" ;
            $szCmd .= " $szEmailFile";
            $szCmd .= " -t $hIniFile{'email_to'}";
            $szCmd .= " -s \"$szSubject\"";
            $szCmd .= " -server $hIniFile{'mail_server'}"; #  machine that is running SMTP service
            $szCmd .= " -f $hIniFile{'mail_sender'}"; # "Sender": very rarely SMTP cares who this is
            $szCmd .= " -i \"$mail_from\""; # "From"
          }
        $szCmd .= " ".$hIniFile{'mail_exe_option'} if (defined $hIniFile{'mail_exe_option'}); #to use TLS, use -o tls=yes
      }

    AppendLog ( "  cmd=$szCmd" );
    print "\nHere is the command we are about to run to send mail:\n-----------------------------------\n$szCmd\n----------------------------\n" if ( $test_mode_flag );
    @aLine = `$szCmd`;

    if($? == 0 )
        {
        return 0;
        }

    # log error once only
    AppendLog ( "ComposeAndSendMailWorker(): error sending mail
szCmd=$szCmd
lines:
" . join("",@aLine) . "
" ) if ( $count == 0 );

    AppendLog ( "  email command failed, will retry in 3 seconds ($hCrntEnv{'email_retries'} tries maximum)...", 1 ); # 1=console
    sleep(3);

}

print "ERROR sending email\n";
AppendLog ( "ComposeAndSendMailWorker(): ERROR sending email");

} # ComposeAndSendMailWorker


# -------------------------------------- ComposeAndSendEmail
# Send email, possibly adding
#   prefix: autodnld version number etc
#   suffix: technical info
#   suffix: contact info.
#   tech traceback

sub ComposeAndSendEmail
{
my (
    $id,        # used to exclude email by id ... magic id: $magic_email_id_for_testing (global): 'test_email';
     $szSubject,  # email subject
     $paMsg,      # msg to email; no EOL on lines; we will add them
     $paTechMsg,   # optional:  tech addendum
     ) = @_;

my ( $szMsg, @aExtra );

AppendLog ( "ComposeAndSendEmail(): started with subject=$szSubject" );

my $email_fn = "$hCrntEnv{'tgt_log_dir'}$slash"."email.txt";    # c:\\intex\\autodnld\\log\\email.txt"
AppendLog ( "ComposeAndSendEmail(): make local file: $email_fn" ) if ( LogThis('email') > 0 );
my $email_tmp_fn = "$hCrntEnv{'tgt_log_dir'}$slash"."email.tmp.txt";    # c:\\intex\\autodnld\\log\\email.tmp.txt"
open ( EMAIL,">$email_tmp_fn");

foreach $szMsg ( @$paMsg )
    {
    print EMAIL "$szMsg\n";
    }

# add info: how to contact Intex
print EMAIL "\nHow to contact INTEX
Send email to autodnld_help\@intex.com and attach files autodnld.log and cmotrack.log (both are in the autodnld\\log subdir)to your email.\n\n";

# possibly add tech notes
if ( defined($paTechMsg) && scalar(@$paTechMsg) )
    {
    print EMAIL "\n---- Technical notes\n";

    foreach $szMsg ( @$paTechMsg )
        {
        print EMAIL "$szMsg\n";
        }
    }

# add system information
print EMAIL "\n\t---- System information ----
\tYou are running Intex autodnld version $release_version*
\tThis email was sent at " . scalar(localtime()) . "\n";

# nt only; show machine name (not in win95 env)
print EMAIL "\tAutodnld is running on machine=$ENV{'COMPUTERNAME'}\n" if ($hIniFile{'operating_system'} eq "nt");

# misc info...
print EMAIL "\tYou are using the Intex shipment server $hIniFile{'connection'}
\tYour user name on the shipment server is $hIniFile{'user'}
\tYou are unpacking Intex data to cdi subdir=$hIniFile{'tgt_cdi_dir'}\n";
print EMAIL "\tCdu subdir=$hIniFile{'tgt_cdu_dir'}\n";

print EMAIL "\tAfter download, cdu files are purged to a depth of $hIniFile{'cdu_purge_depth'}\n" if ( $hIniFile{'cdu_purge_depth'} > 0 );

close ( EMAIL );

# run thru the email message: if find password, xlat it
my $tmp_fh = new IO::File $email_tmp_fn;
my $fh = new IO::File ">$email_fn";

while (defined ( my $line = <$tmp_fh> ) )
    {
    $line =~s/$ship_server_password/xxx\.xxx/g if ( $ship_server_password ne '' );  # global
    print $fh $line;
    }
$tmp_fh->close();
$fh->close();
unlink ( $email_tmp_fn);

# send it off
my $test_mode_flag = ($id eq $magic_email_id_for_testing)  ? 1 : 0;
ComposeAndSendMailWorker($email_fn,$szSubject, $test_mode_flag);

} # ComposeAndSendEmail

# ----------------------------- AddLineToTrackingFile
# keep at NN lines; remove blank lines
# Called for cmotrack.log, pooltrak.log etc

# return non "" if error

sub AddLineToTrackingFile
{
    my (
        $szTrackingFile,        # fully pathed file
        $szEot,                 # line to add
        $bCmo                   # CMO Shipment
        ) = @_;

    my ( @aLine, @aTemp, $iOverRun, $szLine, $iMaxLine );

    $iMaxLine = 200;  # may have multiple flavors, dup lines etc
    AppendLog ( "AddLineToTrackingFile: file=$szTrackingFile  line=$szEot  limit=$iMaxLine", 0 );

    # read contents of tracking file, if any
    if ( ! ( -e $szTrackingFile ) )
    {
        @aLine = ();
    }
    else
    {
        if ( open ( IN, $szTrackingFile ) != 1 )
        {
            return ("Unable to read tracking file=$szTrackingFile");
        }

        @aLine = <IN>;
        close(IN);
    }

    # remove empty lines, if any; typical line="Tue Sep 14 17:27:33 EDT 1999" (OR) "199909100917"
    # NOTE: we want to have \n at the end of each line
    @aTemp=();

    foreach $szLine ( @aLine )
    {
       $szLine =~ s/[\n\r]//g;

        if ( $szLine ne "" )
        {
            push ( @aTemp, "$szLine\n" );   # careful; lines need \n on end
        }
    }

    @aLine = @aTemp;

    # if tracking file is too long, chop it
    $iOverRun = scalar(@aLine) - ($iMaxLine-1);          # we will soon add one, so $iMaxLine is our desired size

    if ( $iOverRun > 0 )
    {
        splice ( @aLine,0,$iOverRun );
    }

    # add the new line, and done
    my $szTodayYYYYMMDD_HHMM = stamp_as_yyyymmdd_hhmm ( ) ;
    my $szNewLineToAdd = $szEot ;
    $szNewLineToAdd = $szEot . " | run on $szTodayYYYYMMDD_HHMM" if ( 1 || $szTrackingFile =~ /cmotrack.log/i ) ;

    push ( @aLine, "$szNewLineToAdd\n" );

    if ( open ( OUT, ">$szTrackingFile") != 1 )
    {
        return ("Unable to write back to tracking file=$szTrackingFile");
    }

    print OUT @aLine;
    close(OUT);

    if (defined($hIniFile{'shipment_backup_path'}))
       {
       BackupShipment($hCmoState{'flavored_log_dir'}.$slash."shiplist.txt", $szTodayYYYYMMDD_HHMM ) if ( $bCmo );
       }

    if(defined($hIniFile{'post_download_command'}))
    {
      my $post_download_command = $hIniFile{'post_download_command'};
      AppendLog("AddLineToTrackingFile: Found post download command '$post_download_command'", 1);
      AppendLog("AddLineToTrackingFile: Starting to run post download command. NOTE: autodnld is paused while running command.", 1);
      my @aLines = `$post_download_command`;
      AppendLog("AddLineToTrackingFile: Finished running post download command. The output was:\n".join("\n", @aLines), 1);
    }

    return "";

} # AddLineToTrackingFile

# ----------------- BackupShipment
# read shiplist file and copy each file shipped from the destination folder to a backup area organized by date/time of the download

sub BackupShipment
{
   my ($sShipList, $sSubdir )=@_;

   AppendLog("BackupShpiment: Backing up shipment started for ".$hIniFile{'shipment_backup_path'}, 1);
   my $sDstDir = $hIniFile{'shipment_backup_path'}.$slash.$sSubdir.$slash;
   my ( $szErr ) = MkdirAsReq ( $sDstDir ) ;
   if ( $szErr )
      {
      AppendLog("BackupShpiment: Failed, could not create backup dir $sDstDir", 1);
      return;
      }

   if ( ! open( SHIPLIST, $sShipList ) )
      {
      AppendLog("BackupShpiment: Failed, could not read shiplist file ($sShipList)", 1);
      return;
      }

   my @aLines = <SHIPLIST>;
   close(SHIPLIST);
   chomp(@aLines);
   foreach my $sLine ( @aLines )
      {
      my ( $s1, $sFile, $iSize ) = split( /\|/, $sLine );
      my $sSrcFile = "";
      if ( $sFile =~ /^cmo_cd(\w)(.*)/ )
         {
         if ( $1 eq 'i' )
             {
             $sSrcFile = $hIniFile{'tgt_cdi_dir'}.$2;
             }
         else
             {
             $sSrcFile = $hIniFile{'tgt_cdu_dir'}.$2;
             }
         }
      FixSlashes(\$sSrcFile, 'native');
      my $sDstFile = $sDstDir.$sFile;
      FixSlashes(\$sDstFile, 'native');
      my ( $szErr ) = MkdirAsReq ( $sDstFile, 1 ) ;
      if ( $szErr )
         {
         AppendLog("BackupShpiment: Failed, could not create backup dir for $sDstDir", 1);
         return;
         }

      if ( ! copy_file( $sSrcFile, $sDstFile ) )
         {
         AppendLog("BackupShpiment: Failed, could not copy file from $sSrcFile to $sDstFile", 1);
         return;
         }
      }

    AppendLog("BackupShipment: Backing finished for ".$hIniFile{'shipment_backup_path'}, 1);
    return;

} # BackupShipment



# ----------------- ReadInfFile
# read .inf file (never read more than once): figure out data types that customer gets; add settings to $hCrntEnv
# file is located in home dir on ship server
# if we do read the inf file, figure out default tgt subdir for perfdata etc if not specified

# sample stack trace when we call this
##  . = main::ReadInfFile() called from file `h:\fips\scripts\autodnld\autodnld.pl' line 5820
##  . = main::TryToDownloadAllDataTypes() called from file `h:\fips\scripts\autodnld\autodnld.pl' line 6468

# set in hCrntEnv:
##    gets_cmo_data,   # set to 1/0
##    gets_pool_data,   # set to 1/0
##    gets_pool_data_archive,   # set to 1/0
##    gets_bond_data,   # set to 1/0
##    gets_perf_data,  # set to '' or comma delim list
##    gets_remit_data,  # set to '' or comma delim list

# sample file:
##   cmo=1
##   perfdata=abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,cmbs,wl
##   pooldata=1

# sample file:
##   cmo=1
##   perfdata=abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,cmbs,wl
##   pooldata=1
##   remitdata=ab_au,ab_cc,ab_eq,ab_fp,ab_he,ab_mh,ab_rv,cmbs,wl
# added input value as a test flag, return value, 0 for success, 1 for error, used for autodnld https test only. starting 5.02
sub ReadInfFile
{
   my ($sTestFlag,)=@_;
# only read the file once
return 2 if ( defined ( $hCrntEnv{'gets_cmo_data'} ) && ! defined $sTestFlag); # to differentiate the return 1, inf not downloaded, 0 success, used for autodnld -t

# set default values
$hCrntEnv{'gets_cmo_data'} = 0;    # set to 0/1
$hCrntEnv{'gets_pool_data'} = 0;   # set to 0/1
$hCrntEnv{'gets_pool_data_archive'} = 0;   # set to 0/1
$hCrntEnv{'gets_bond_data'} = 0;   # set to 0/1
$hCrntEnv{'gets_perf_data'} = '';  # set to '' or comma delim list
$hCrntEnv{'gets_remit_data'} = '';  # set to '' or comma delim list
$hCrntEnv{'gets_hist_data'} = '';  # set to '' or comma delim list

$hCrntEnv{verbose} = defined( $hIniFile{suppress_log} ) && $hIniFile{suppress_log} =~ /n/i ? 1 : 0;

# get the inf file to decide what data types the customer gets
my ( $remote ) = "/$hIniFile{'user'}/$hIniFile{'user'}.inf";   # remote file is in customer home subdir
my ( $local ) = "$hCrntEnv{'tgt_log_dir'}/$hIniFile{'user'}.inf";  # local file will be in log subdir
FixSlashes ( \$local, "native" );
my ( $check_for_existence ) = 1;

DownloadFile
    (
     $remote,
     $local,
     $check_for_existence,  # 1 means check for existence only, not for size
     );

# if no inf, assume cmo data only ... should never happen
my ( @aLine ) = ();

if ( ! ( -e $local ))
    {
    my ( @aCustomerLog ) = ( "Could not download file file=$remote", "This is a file on the Intex server which describes which date you should get", "It is unusual to not be able to download this", "Please check your connection to the server" ) ;
    AppendLog ( "ERROR: could not download file=$remote, will assume cmo data only.","", \@aCustomerLog );
    $hCrntEnv{'gets_cmo_data'} = 1;
    # below return 1 indicates that the inf file was not downloaded correctly, instead of inf file not set up correctly from intex, used for autodnld -t test
    return 1;  # default values of cmo only were set earlier
    }

# read data
open ( INF_FILE, $local );
@aLine = <INF_FILE>;
close ( INF_FILE);
unlink ( $local );

my ( $szJunk, $szIpAddresses, $szSubNetMask, @aIpAddresses, @aSubNetMasks) ;
foreach my $szOneLine ( @aLine )
    {
    if ( $szOneLine =~ /IPaddress=/i  )
       {
       ( $szJunk, $szIpAddresses ) = split ( /\=/, $szOneLine )  if ( $szOneLine =~ /IPaddress=/i  ) ;
       $szIpAddresses  =~ s/\s//g ;
       @aIpAddresses = split ( /\,/,  $szIpAddresses ) ;
       }
    if ( $szOneLine =~ /SubnetMask=/i  )
       {
       ( $szJunk, $szSubNetMask  ) = split ( /\=/, $szOneLine )  if ( $szOneLine =~ /SubnetMask=/i ) ;
       $szSubNetMask   =~ s/\s//g ;
       @aSubNetMasks = split ( /\,/,  $szSubNetMask  ) ;
       }
     if ( $szOneLine =~ /use_http=([0-9\.a-z]+)/i  )
       {
        $hCmoState{'connection'}=$hIniFile{'connection'};
        $hCmoState{'usehttp'}="http";
       }
      if ($szOneLine =~ /download_dir=([0-9a-z\\\/]+)/i ) {
         $hCmoState{'distrib_word'}=$1; #take the path from here
      }
      if ($szOneLine=~ /key=(\S+)/i) {
         $hCmoState{'httpkey'}=$1;
      }
      if ($szOneLine=~ /iddata=1/) {
         #we set get_id
         $hIniFile{'get_id'}='y' if (!defined $hIniFile{'get_id'});
      }
    }
return 0 if (defined $sTestFlag); #should be enough for test purpose

if(($hIniFile{'usehttp'} =~ /http/i)&&(!defined ($hCmoState{'usehttp'})))
   {
   AppendLog("Error 1007: You set usehttp=".$hIniFile{'usehttp'}." in autodnld.ini file, please contact Intex to set this up");
   print "\nError 1007: You set usehttp=".$hIniFile{'usehttp'}." in autodnld.ini file, please contact Intex to set this up.\n";
   exit(1);
   }
### make valid_ips.log file
if ( scalar ( @aIpAddresses ) != scalar ( @aSubNetMasks ) )
    {
    AppendLog ( "Problem getting list of ip addresses and subnet masks from intex.  Number of each are not equal.  Number of ip addresses is ". scalar ( @aIpAddresses ). ". Number of Subnet masks is " . scalar ( @aSubNetMasks )  );
    AppendLog ( "Dump of data... IP Addresses:\n" . join ( "\n", @aIpAddresses ) ."\nSubnet Masks:\n" . join ( "\n", @aSubNetMasks  ) );
    print "\nProblem getting ip addresses and subnet mask.  Numbers are not equal.  Number of ip addresses is ". scalar ( @aIpAddresses ). ". Number of Subnet masks is " . scalar ( @aSubNetMasks ) ;
    print "\nDump of data... IP Addresses:\n" . join ( "\n", @aIpAddresses ) ."\nSubnet Masks:\n" . join ( "\n", @aSubNetMasks  ) ;
    }
elsif ( scalar ( @aIpAddresses ) > 0 )
    {
    open ( IP_FILE, ">$hCrntEnv{'tgt_log_dir'}$slash"."valid_ips.log" ) ;
    my ( $iCountThroughIp ) ;
    for ( $iCountThroughIp = 0 ; $iCountThroughIp <  scalar ( @aIpAddresses ) ; $iCountThroughIp ++ )
        {
        print IP_FILE $aIpAddresses[$iCountThroughIp]."|". $aSubNetMasks[$iCountThroughIp] . "\n";
        }
    close IP_FILE ;
    }


# tell user if special command line switches
my @aMatch = grep ( /_inf_/, @ARGV );
AppendLog ( "NOTE: we have command line switches to suppress data downloads: " . join(",",@aMatch), 1 ) if ( scalar(@aMatch));

# parse file info
$hCrntEnv{'gets_cmo_data'} = 1 if  ( scalar(grep(/^cmo=1/,     @aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_cmo$/i,      @ARGV ) == 0 ) );
$hCrntEnv{'gets_pool_data'} = 1 if ( scalar(grep(/^pooldata=1/,@aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_pooldata$/i, @ARGV ) == 0 ) );
$hCrntEnv{'gets_pool_data_archive'} = 1 if ( scalar(grep(/^pooldata_archive=1/,@aLine)) > 0  &&  scalar(grep( /^\-get_pooldata_archive$/i, @ARGV ) > 0 ) ); ## Only do this with special command line arg
$hCrntEnv{'gets_bond_data'} = 1 if ( scalar(grep(/^bonddata=1/,@aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_bonddata$/i, @ARGV ) == 0 ) );

# gets perfdata?
@aMatch = grep(/^perfdata/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_perfdata$/i, @ARGV ) == 0 ) )
    {
    my $perf = substr($aMatch[0],9);
    $perf =~ s/[\n\r]//g;
    $hCrntEnv{'gets_perf_data'} = $perf;

    # if 'tgt_perfdata_dir' missing, figure out a default
    my ( $flavor ) = 'perf';
    my ( $key  ) = "tgt_$flavor" . "data_dir";   # 'tgt_perfdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my ( $val ) = substr($cdu_path,0,$ix) . $slash . $flavor . "data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );
        }
    }

# gets remitdata?
@aMatch = grep(/^remitdata/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_remitdata$/i, @ARGV ) == 0 ) )
    {
    my $remit = substr($aMatch[0],10);
    $remit =~ s/[\n\r]//g;
    $hCrntEnv{'gets_remit_data'} = $remit;

    # if tgt_remitdata_dir missing, figure out a default
    my ( $flavor ) = 'remit';
    my ( $key  ) = "tgt_$flavor" . "data_dir";  # 'tgt_remitdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ReadInfFile: ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my $val = substr($cdu_path,0,$ix) . $slash . $flavor . "data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );

        }
    }

# gets deal_remit_data?
@aMatch = grep(/^deal_remit_data/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_deal_remit_data$/i, @ARGV ) == 0 ) )
    {
    my $remit = substr($aMatch[0],16);
    $remit =~ s/[\n\r]//g;
    $hCrntEnv{'gets_deal_remit_data'} = $remit;

    # if tgt_remitdata_dir missing, figure out a default
    my ( $flavor ) = 'deal_remit';
    my ( $key  ) = "tgt_$flavor" . "_data_dir";  # 'tgt_remitdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ReadInfFile: ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my $val = substr($cdu_path,0,$ix) . $slash . $flavor . "_data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );

        }
    }


# gets tranche_remit_data?
@aMatch = grep(/^tranche_remit_data|^tranche_remitdata/,@aLine);
if ( scalar(grep( /^\-suppress_inf_tranche_remit_diff_data$/i, @ARGV ) > 0 ) )
   {
   $hIniFile{'get_tranche_remit_diff_files'}  = "N" ;
   }
if ( scalar(grep( /^\-suppress_inf_deal_remit_diff_data$/i, @ARGV ) >  0 ) )
   {
   $hIniFile{'get_deal_remit_diff_files'}  = "N" ;
   }
if ( scalar(grep( /^\-suppress_inf_remit_diff_data$/i, @ARGV ) >  0 ) )
   {
   $hIniFile{'get_remit_diff_files'}  = "N" ;
   }

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_tranche_remit_data$/i, @ARGV ) == 0 ) )
    {
    my $remit = substr($aMatch[0],19);
    $remit =~ s/[\n\r]//g;
    $hCrntEnv{'gets_tranche_remit_data'} = $remit;

    # if tgt_remitdata_dir missing, figure out a default
    my ( $flavor ) = 'tranche_remit';
    my ( $key  ) = "tgt_$flavor" . "_data_dir";  # 'tgt_remitdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ReadInfFile: ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my $val = substr($cdu_path,0,$ix) . $slash . $flavor . "_data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );

        }
    }


# gets histdata?
@aMatch = grep(/^histdata/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_histdata$/i, @ARGV ) == 0 ) )
    {
    my $hist = substr($aMatch[0],9);
    $hist =~ s/[\n\r]//g;
    $hCrntEnv{'gets_hist_data'} = $hist;

    # if tgt_remitdata_dir missing, figure out a default
    my ( $flavor ) = 'hist';
    my ( $key  ) = "tgt_$flavor" . "data_dir";  # 'tgt_histdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $val = $cdu_path ;
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );

        }
    }

# gets custom_remitdata?
@aMatch = grep(/^custom_remitdata/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_remitdata$|^\-suppress_inf_custom_remitdata$/i, @ARGV ) == 0 ) )
    {
    my $remit = substr($aMatch[0],17);
    $remit =~ s/[\n\r]//g;
    $hCrntEnv{'gets_remit_data'} = $remit;
    $hCrntEnv{'gets_custom_remit_data'} = 1 ;

    # if tgt_remitdata_dir missing, figure out a default
    my ( $flavor ) = 'remit';
    my ( $key  ) = "tgt_$flavor" . "data_dir";  # 'tgt_remitdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ReadInfFile: ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my $val = substr($cdu_path,0,$ix) . $slash . $flavor . "data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );

        }
    }

# gets custom_perfdata?
@aMatch = grep(/^custom_perfdata/,@aLine);

if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_perfdata$|^\-suppress_inf_custom_perfdata$/i, @ARGV ) == 0 ) )
    {
    my $perf = substr($aMatch[0],16);
    $perf =~ s/[\n\r]//g;
    $hCrntEnv{'gets_perf_data'} = $perf;
    $hCrntEnv{'gets_custom_perf_data'} = 1 ;

    # if 'tgt_perfdata_dir' missing, figure out a default
    my ( $flavor ) = 'perf';
    my ( $key  ) = "tgt_$flavor" . "data_dir";   # 'tgt_perfdata_dir'

    if ( !defined ( $hIniFile{$key} ) )
        {
        my $cdu_path = $hIniFile{'tgt_cdu_dir'};
        my $ix = rindex($cdu_path, $slash);

        if ( $ix < 0 )
            {
            print "ERROR: could not parse slash out of path=$cdu_path\n";  # NOTE: no log file yet
            exit(1);
            }

        my ( $val ) = substr($cdu_path,0,$ix) . $slash . $flavor . "data";
        $hIniFile{$key} = $val;
        AppendLog ( "ReadInfFile: set $key=$val, since not specified in ini file" );
        }
    }


# dump hCrntEnv hash to log
AppendHashInfoToLogFile ( "ReadInfFile(): contents of hCrntEnv hash after reading the .inf file ($remote):", \%hCrntEnv, 1 );

} # ReadInfFile


#---------------------- chdir_before_uncompress
# NOTE: we only have 3 chdir() in all of autodnld
#    driven by command line switch on startup
#    chdir_before_uncompress()
#    chdir_after_uncompress()

# return error string or '' if no error (also, push msg onto list)
sub chdir_before_uncompress
{
my (
    $dest_subdir,
    $paErrMsg,     # push any error lines on this list
    ) = @_;

my $func = "chdir_before_uncompress";
my ( $msg );

AppendLog ( "chdir_before_uncompress(): subdir=$dest_subdir" )if ( LogThis( 'gen' ) > 0 );

# error if trying to chdir to UNC
if ( $dest_subdir =~ /\\\\/ )
    {
    $msg = "$func(): You cannot chdir to a UNC path ($dest_subdir)";
    push ( @$paErrMsg, $msg );
    return $msg;
    }

if ( !chdir( $dest_subdir ))
    {
    $msg = "$func(): unable to chdir to subdir=$dest_subdir";
    push ( @$paErrMsg, $msg );
    return $msg;
    }

return "";

}  # chdir_before_uncompress


#---------------------- chdir_after_uncompress
# NOTE: we only have 3 chdir() in all of autodnld
#    driven by command line switch on startup
#    chdir_before_uncompress()
#    chdir_after_uncompress()

# return error string or '' if no error (also, push msg onto list)
sub chdir_after_uncompress
{
my (
    $paErrMsg,     # push any error lines on this list
    ) = @_;

my $func = "chdir_after_uncompress";
my ( $msg );
my $dest_subdir = $hIniFile{'autodnld_home'} . $slash . "scripts";
AppendLog ( "chdir_after_uncompress(): subdir=$dest_subdir" ) if ( LogThis( 'gen' ) > 0 );

if ( !chdir( $dest_subdir ))
    {
    $msg = "$func(): unable to chdir to subdir=$dest_subdir";
    push ( @$paErrMsg, $msg );
    return $msg;
    }

return "";

}  # chdir_after_uncompress


# --------------------- uncompress_run_exe
# we have figured out command line for uncompress; run it (capture output), capture ret. code
# if errors, push them onto error list
# also, if using stderr, add to list
# return non zero if error, and push errors onto list

sub uncompress_run_exe
{
my (
    $cmd,           # command to run
    $paErrMsg,      # push errors here
    $szStderrFile,  # may be undef ... file that will capture stderr ... not used for UNIX
    ) = @_;

# run decompress or unzip; quick return if error
# if we are uncompressing cmo_cdi.zip/cmo_cdu.zip, the caller put us in the cmo_cdi or cmo_cdu subdir
# If a chdir() is needed, the caller has already done it for us
AppendLog ( "uncompress_run_exe(); start
  cmd=$cmd" )if ( LogThis( 'gen' ) > 0 );

## ---- debug only
## print "\nabout to decompress file
## cmd=$cmd
## press return key to proceed > ";
## <STDIN>;
## print "\n";

# capture stdout ... has lines like this:    Inflating: d:/temp/autodnld/cmo_cdu/0203/bms97001.cdu
# NOTE: errors go to stderr, not stdout
my(@aLine) = `$cmd`;
my($iRet) = $?;

## ---- debug only
## print "\ndone w/ decompress
## press return key to proceed > ";  # gary
## <STDIN>;
## print "\n";

if($iRet)
    {
    print "ERROR uncompressing file\n";
    my ( @aCustomerLog ) = ( "When uncompressing file a non-zero error code was returned from the program:",@aLine, "return code=$iRet\n  cmd=$cmd", "Please try running the cmd locally and see if you can diagnose the problem" ) ;
    AppendLog ( "uncompress_run_exe(): non-zero error code returned from program\n Error:".join(" ",@aLine)."return code=$iRet\n  cmd=$cmd","", \@aCustomerLog );
    push ( @$paErrMsg," ERROR: had error return code from decompress program; cmd=$cmd; EC=$iRet" );

    # if we had error, may want to see stderr; else, just look at stdout
    if ( defined($szStderrFile)  &&  -e $szStderrFile )
        {
        push ( @$paErrMsg,"--- start: stderr lines from cmd=$cmd" );
        my($szLine) = `type $szStderrFile`;
        push ( @$paErrMsg, split(/[\n\r]+/,$szLine));
        push ( @$paErrMsg, "--- end lines" );
        }

    return 1;
    }

AppendLog ( "uncompress_run_exe(); done and all is OK", 0 )if ( LogThis( 'gen' ) > 0 );
return 0;

} # uncompress_run_exe


# ---------------------------- uncompress_zip_under_win
# unzip; pkzip32 takes a path arg; we never chdir(); OK to have UNC for dest_subdir (if you have temp_subdir defined)

# sample pkzip32 command lines:
#   pkzip32 -ext foo c:\temp
#   pkzip32 -ext foo \\webget\d_drive\temp

# return non zero if error (and push errors onto list)
sub uncompress_zip_under_win
{
my (
    $compressed_file,     # file to uncompress
    $paErrMsg,       # error traceback
                     # caller may chose to display this or whatever
                     # if error, push onto this list and return 1
    $dest_subdir,    # may be UNC
    $tmp_dest_subdir, # if 'win_safe_unzip' is set to 'y'
    ) = @_;

quote_if_has_spaces ( \$compressed_file );

# NOTE: pkzip default for -directories is "relative" pathing

# figure out file to redirect stderr to
my($std_err_file) = $hCrntEnv{'tgt_log_dir'} . $slash . "pkzip32_stderr.txt";    # d:\temp\autodnld\log\pkzip32_stderr.txt
unlink ( $std_err_file );
my($cmd) = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."pkzip32.exe";
$cmd .= " -extract -nofix -over=all -directories $compressed_file";

# optionally add dest subdir arg
if ( defined( $tmp_dest_subdir ) )
    {
    quote_if_has_spaces ( \$tmp_dest_subdir);
    $cmd .= " $tmp_dest_subdir";
    }
elsif ( defined($dest_subdir))
    {
    quote_if_has_spaces ( \$dest_subdir);
    $cmd .= " $dest_subdir";
    }


if ( defined($hIniFile{'win_unzip_cmd'}) && $hIniFile{'win_unzip_cmd'} !~ /^\s*$/ )
    {
    $cmd = $hIniFile{'win_unzip_cmd'};
    $cmd =~ s/\%FILE\%/$compressed_file/;
    if ( defined( $tmp_dest_subdir ) )
        {
        $cmd =~ s/\%DESTDIR\%/$tmp_dest_subdir/;
        }
    elsif ( defined($dest_subdir))
        {
        $cmd =~ s/\%DESTDIR\%/$dest_subdir/;
        }
    }

# capture stderr
$cmd .= " 2> $std_err_file";

# check that exe is there
return 1 if ( push_error_if_bad_exe ( $cmd, $paErrMsg ) );

# call worker to run command that we assembled, push any errors on list etc
# wil also add contents of stderr to error list
my ( $ret ) = uncompress_run_exe
    (
     $cmd,                # cmd to run
     $paErrMsg,          # will fill this in if error
     $std_err_file,      # we DO have a stderr file
     );

# if we had error, but if all errors are "can't create", ignore the error
if ( $ret && -e $std_err_file )
    {
    my ( @aLine ) = `$com_spec type $std_err_file`;      # $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c"
    chomp(@aLine);
    my ( @aMatch ) = grep ( /can\'t create/i, @aLine );
    if ( $hIniFile{'temp_download_subdir'} ne "" && $hIniFile{'skip_file_in_use_process'} ne 'Y'&& scalar ( @aMatch ) < 20 )
        {
        my @aMsg =
            (
             "You have some file(s) in your database that were in use when trying to update.",
             "These files were saved in your temp_download_subdir.",
             "Below you will find FILE1 ===> FILE2.",
             "",
             "To become up to date, you can run autodnld with the command line option \"-in_use\"\n(i.e. open a command window change to the autodnld\/scripts directory and type \"autodnld -in_use\"",
             "Autodnld will also try to copy these files, before exiting, and each time it is run until it is successful.",
             "Or for each line below copy FILE1 to FILE2 when FILE2 is not in use anymore.",
             "To make it easier to copy, each line is followed by a command that if run in a DOS prompt will copy the files.",
             "========================  Begin List of Files In Use =======================================================",
              );
        #my @aAllMsgFiles ;
        foreach my $szOneLine ( @aLine )
             {
             if ( $szOneLine =~  /can't create\: (.*[\\\/])([^\\\/]+)$/  )
                 {
                 my $szOneFileToCopyToTemp = $2 ;
                 my $szOrigDestinToCopy    = $1.$2 ;
                 $szOrigDestinToCopy =~ s/[\\\/]/$slash/g ;
                 my $szFileBack = FileInUseSaveToTemp ( $compressed_file, $hIniFile{'temp_download_subdir'}, $szOneFileToCopyToTemp ) ;

                 my $szCmdToRun = "copy $szFileBack $szOrigDestinToCopy" ;
                 push @::aFilesInUse, $szCmdToRun ;

                 push ( @aMsg, "$szFileBack ===> $szOrigDestinToCopy" ) ;
                 push ( @aMsg, "COMMAND TO RUN:\"copy $szFileBack $szOrigDestinToCopy\"\n" ) ;
                 }
             }
         my ( $bErrorMakeFile ) = MakeFileInUseMarkerFile ( ) ;
         if ( $bErrorMakeFile )
            {
            push ( @aMsg, "========================  End List of Files In Use =======================================================\n\n" ) ;
            ComposeAndSendEmail( 'e__', "ERROR: File(s) in use, please follow instuctions in email.", \@aMsg ) ;
            AppendLog ( "uncompress_zip_under_win(): We had unpack errors from files in use files were saved in temp directory.  Email was sent and detail can be found in $hCrntEnv{'error_log_file'}", "", \@aMsg ) ;
            print "\n\nERROR was from decompressing and some files were in use.  Please see email (or email.log) for details.\n" ;
            }
         }

    if ( scalar(@aLine)  &&  scalar(@aLine) == scalar(@aMatch) )
         {
         $ret = 0;

         AppendLog ( "uncompress_zip_under_win(): We had unpack errors from files in use; we will ignore these errors for now
------------------------------------------------------
" . join("\n",@aLine) . "
------------------------------------------------------");

             print "\nNOTE: We had " . scalar(@aMatch) . " unpack error(s) from files in use; we will ignore these errors for now
------------------------------------------------------
" . join("\n",@aLine) . "
------------------------------------------------------\n";
         }
    }
if ( $tmp_dest_subdir )
    {
    ### Need to move file from tmp_dest_subdir to dest_subdir
    my $sRealFile = "";
    if ( $compressed_file =~ /cmo_cd\w(\-.*)\.zip/ )
        {
        $sRealFile = $1;
        $sRealFile =~ s/\-/$slash/g;
        }
    else
        {
        push ( @$paErrMsg, "WARNING: unexpecrted file name is tmp dest subdir $compressed_file in $tmp_dest_subdir" );
        return 1;
        }


    my $sTmpFullFile = $tmp_dest_subdir.$sRealFile;
    my $sFullFile    = $dest_subdir.$sRealFile;
    if ( ! -e $sTmpFullFile )
        {
        push ( @$paErrMsg, "WARNING: unzipped file $sTmpFullFile in $tmp_dest_subdir does not exist" );
        return 1;
        }

    my ( $szErr ) = MkdirAsReq ( $sFullFile, 1 ) ;

    if ( $szErr ne "" )
        {
        push ( @$paErrMsg, $szErr );
        return 1;
        }

    if ( $hIniFile{win_safe_swap_file_cmd}  )
        {
        my $sCmd = $hIniFile{win_safe_swap_file_cmd};
        $sCmd =~ s/%SRC_FILE%/$sTmpFullFile/;
        $sCmd =~ s/%DST_FILE%/$sFullFile/;

        AppendLog ( "uncompress_zip_under_win(); win_safe_unzip win_safe_swap_file_cmd command start cmd=$sCmd" )if ( LogThis( 'gen' ) > 0 );

        my @aRes = `$sCmd`;
        if ( $? > 0 )
            {
            push ( @$paErrMsg, "WARNING: win_safe_swap_file_cmd command failed: $sCmd\nError return is $?\nError output is: ".join( "\n", @aRes ) );
            return 1;
            }
        }
    else
        {
        my $sCmd = "$com_spec move /Y \"$sTmpFullFile\" \"$sFullFile\"";

        AppendLog ( "uncompress_zip_under_win(); win_safe_unzip move command start cmd=$sCmd" )if ( LogThis( 'gen' ) > 0 );

        my @aRes = `$sCmd`;
        if ( $? > 0 )
            {
            push ( @$paErrMsg, "WARNING: windows move command failed: $sCmd\nError return is $?\nError output is: ".join( "\n", @aRes ) );
            return 1;
            }
        }
    }

return $ret;

} # uncompress_zip_under_win


# ----------------------- uncompress_zip_under_unix
# need to chdir() because we don't know how to make the unzip program redirect files to another path
# return non zero if error (and push errors onto list)
sub uncompress_zip_under_unix
# caller has already chdir() to dest subdir
{
my (
    $compressed_file,     # file to uncompress
    $paErrMsg,       # error traceback
                     # caller may chose to display this or whatever
                     # if error, push onto this list and return 1
    $dest_subdir,
    $tmp_dest_subdir, # if 'unix_safe_unzip' is set to 'y'
    ) = @_;

# put together command line
my ( $cmd)  = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."unzip";
$cmd .= " -d " . ( defined( $tmp_dest_subdir ) ? $tmp_dest_subdir : $dest_subdir ) ." -o $compressed_file";
if ( defined($hIniFile{'unix_unzip_cmd'}) && $hIniFile{'unix_unzip_cmd'} !~ /^\s*$/ )
    {
    $cmd = $hIniFile{'unix_unzip_cmd'};
    $cmd =~ s/\%FILE\%/$compressed_file/;
    if ( defined( $tmp_dest_subdir ) )
        {
        $cmd =~ s/\%DESTDIR\%/$tmp_dest_subdir/;
        }
    elsif ( defined($dest_subdir))
        {
        $cmd =~ s/\%DESTDIR\%/$dest_subdir/;
        }
    }

return 1 if ( push_error_if_bad_exe ( $cmd, $paErrMsg ));

# call worker to run command that we assembled, push any errors on list etc
my $ret = uncompress_run_exe    # 1=error
    (
     $cmd,
     $paErrMsg,
     );

if ( $tmp_dest_subdir )
    {
    ### Need to move file from tmp_dest_subdir to dest_subdir
    my $sRealFile = "";
    if ( $compressed_file =~ /cmo_cd\w(\-.*)\.zip/ )
        {
        $sRealFile = $1;
        $sRealFile =~ s/\-/$slash/g;
        }
    else
        {
        push ( @$paErrMsg, "WARNING: unexpecrted file name is tmp dest subdir $compressed_file in $tmp_dest_subdir" );
        return 1;
        }


    my $sTmpFullFile = $tmp_dest_subdir.$sRealFile;
    my $sFullFile    = $dest_subdir.$sRealFile;
    if ( ! -e $sTmpFullFile )
        {
        push ( @$paErrMsg, "WARNING: unzipped file $sTmpFullFile in $tmp_dest_subdir does not exist" );
        return 1;
        }

    my ( $szErr ) = MkdirAsReq ( $sFullFile, 1 ) ;

    if ( $szErr ne "" )
        {
        push ( @$paErrMsg, $szErr );
        return 1;
        }

    if ( $hIniFile{unix_safe_swap_file_cmd}  )
        {
        my $sCmd = $hIniFile{unix_safe_swap_file_cmd};
        $sCmd =~ s/%SRC_FILE%/$sTmpFullFile/;
        $sCmd =~ s/%DST_FILE%/$sFullFile/;

        AppendLog ( "uncompress_zip_under_unix(); unix_safe_unzip unix_safe_swap_file_cmd command start
  cmd=$sCmd" ) if ( LogThis( 'gen' ) > 0 );

        my @aRes = `$sCmd`;
        if ( $? > 0 )
            {
            push ( @$paErrMsg, "WARNING: unix_safe_swap_file_cmd command failed: $sCmd\nError return is $?\nError output is: ".join( "\n", @aRes ) );
            return 1;
            }
        }
    else
        {
        my $sCmd = "mv '$sTmpFullFile' '$sFullFile'";

        AppendLog ( "uncompress_zip_under_unix(); unix_safe_unzip move command start
  cmd=$sCmd" )if ( LogThis( 'gen' ) > 0 );

        my @aRes = `$sCmd`;
        if ( $? > 0 )
            {
            push ( @$paErrMsg, "WARNING: unix mv command failed: $sCmd\nError return is $?\nError output is: ".join( "\n", @aRes ) );
            return 1;
            }
        }
    }

return $ret;

} # uncompress_zip_under_unix

# ------------------------ uncompress_non_tar_Z (plain .Z)
# any OS; do not need to chdir
# return 1 if error, and push errors onto list

sub uncompress_non_tar_Z
{
my (
    $compressed_file,     # pathed file to uncompress e.g. "d:\temp\autodnld\cmo_cdu\mbspools\fhlmc.hdr.Z"
    $paErrMsg,       # error traceback
                     # caller may chose to display this or whatever
                     # if error, push onto this list and return 1
    $dest_subdir,
    ) = @_;

quote_if_has_spaces(\$compressed_file);

# want root e.g. "d:\\temp\\info.txt.Z" --> info.txt
my($ix) = rindex ( $compressed_file, $slash );
my($root) = ($ix > 0) ? substr($compressed_file,$ix+1) : $compressed_file;
$root = substr($root, 0, length($root)-2 );  # chop off .Z

# gzip switches: -c=console output -d=decompress  -f=force overwrite
my ( $dst_fn ) = "$dest_subdir$slash$root";
quote_if_has_spaces(\$dst_fn );
my ( $gzip_cmd ) = $is_unix ? 'gzip' : 'gzip.exe';
my ( $cmd ) = $hIniFile{'autodnld_home'} . $slash . "scripts$slash$gzip_cmd -cdf $compressed_file > $dst_fn";
return 1 if ( push_error_if_bad_exe ( $cmd, $paErrMsg ));

# call worker to run command that we assembled, push any errors on list etc
# Example: d:\autodnld_qa\scripts\gzip.exe -cdf d:\autodnld\temp\fhlmc.hsp.Z > d:\autodnld_qa\cmo_cdu\mbspools\fhlmc.hsp
# If you hold dst file open for read, gzip.exe will still update the file
my ( $ret ) = uncompress_run_exe   # 1=error
    ( $cmd,
      $paErrMsg,
      );

unlink ( $compressed_file ) if ($ret==0);  # since we uncompressed with redirection to stdout
return $ret;

} # uncompress_non_tar_Z


# --------------------------- UncompressFile
# Uncompress and/or unpack one or more files
# If unix, we need to chdir() to dest subdir

# NOTE: If we are using gzip/tar under NT, we invoke the exe in the scripts path
#       The dll is in the same path, and the exe is smart enough to look there to load the DLL

# Called for:
#   shipinfo file
#   cmo_cdi.*
#   cmo_cdu.*
#   .Z file (pooldata, bonddata, perfdata, remitdata)

# use worker sub:
#     uncompress_zip_under_win()
#     uncompress_zip_under_unix()
#     uncompress_non_tar_Z ... for all OS

# and all of the worker sub use:
#     uncompress_run_exe()

# return non zero if error (and caller should display the error msg list we return)

sub UncompressFile
{
my (
    $compressed_file,     # pathed file to uncompress

    $paErrMsg,       # error traceback
                        # caller may chose to display this or whatever
                        # if error, push onto this list and return 1

    $dest_subdir,    # subdir to unpack to
                     # we will try to use path argument w/ unpack command rather than chdir() if possible
    $tmp_dest_subdir
       ) = @_;

print "Decompressing file $compressed_file...\n";

AppendLog( "UncompressFile(): start
  file=$compressed_file
  dest_subdir=$dest_subdir
".( defined( $tmp_dest_subdir ) ? "tmp_dest_subdir=$tmp_dest_subdir\n" : "" )
)if ( LogThis( 'gen' ) > 0 );

# just in case, make the dst subdir
if ( ! ( -d $dest_subdir ))
    {
    my ( $szErr ) = MkdirAsReq ( $dest_subdir ) ;

    if ( $szErr ne "" )
        {
        push ( @$paErrMsg, $szErr );
        return 1;
        }
    }

if ( $tmp_dest_subdir )
    {
    if ( ! ( -d $tmp_dest_subdir ))
        {
        my ( $szErr ) = MkdirAsReq ( $tmp_dest_subdir ) ;

        if ( $szErr ne "" )
            {
            push ( @$paErrMsg, $szErr );
            return 1;
            }
        }
    }

# if zip file and Windows ...
if($compressed_file =~ /\.zip$/i && $is_unix == 0 )
    {
    return uncompress_zip_under_win
        (
         $compressed_file,     # file to uncompress
         $paErrMsg,       # error traceback
                          # caller may chose to display this or whatever
                          # if error, push onto this list and return 1
         $dest_subdir,    # subdir to unpack to
         $tmp_dest_subdir, # If have 'win_safe_unzip' set to 'y'
         );
    }
# else if zip and UNIX
elsif ( $compressed_file =~ /\.zip$/i && $is_unix == 1)
    {
    return uncompress_zip_under_unix
        (
         $compressed_file,     # file to uncompress
         $paErrMsg,       # error traceback
                          # caller may chose to display this or whatever
                          # if error, push onto this list and return 1
         $dest_subdir,    # subdir to unpack to
         $tmp_dest_subdir, # If have 'unix_safe_unzip' set to 'y'
         );
    }
# else if plain .Z (all OS) ... chdir not needed
elsif ( $compressed_file =~ /\.Z$/i )
    {
    return uncompress_non_tar_Z
        (
         $compressed_file,     # file to uncompress
         $paErrMsg,       # error traceback
                          # caller may chose to display this or whatever
                          # if error, push onto this list and return 1
         $dest_subdir,    # subdir to unpack to
         );
    }
else
    {
    push ( @$paErrMsg, "ERROR: don't know how to unpack file=$compressed_file" );
    return 1;
    }

} # UncompressFile


# -------------------------------- DownloadAndDecompressZFile
# used for .Z files
# for all OS, can uncompress a Z file with a path arg
# We will use the temp_download_subdir if defined

# return () or error msg list

sub DownloadAndDecompressZFile
{
my (
    $remote_file,        # file to get
                             # always start with slash plus user name
                             # examples:
                             #      /xmaspool/distribution/eot.txt
                             #      /xmaspool/../pooldata/shipping/199902280934
                             #      /xmaspool/../public/xxx.xx
                             # can have jumbled slashes ... we will fix them

    $local_file,         # local file name (destination name) e.g. c:/intex/perfdata/abag/abaghist.txt (no Z)
                             # can have jumbled slashes ... we will fix them

    $final_size,   # final size when decompressed

    $compressed_size,  # may be undef

    ) = @_;
my ( $szCheckSizeVal ) ;

if ( defined ( $compressed_size ) )
   {
   if ( $compressed_size > 1 )
      {
      $szCheckSizeVal = $compressed_size ;
      }
   else
      {
      $szCheckSizeVal = 1 ;
      }
   }
else
   {
   $szCheckSizeVal = 1 ;
   }

AppendLog ( "DownloadAndDecompressZFile(): start
  remote file=$remote_file
  local file=$local_file
  final size=$final_size
" . ( defined($compressed_size) ? "  compressed size=$compressed_size" : "" ) );

my ( @aMsg ) ;
my ( @aTraceBack );
FixSlashes( \$local_file,"native");

# need path and file
my ( $ix ) = rindex($local_file, $slash );
my ( $file ) = substr($local_file, $ix+1);  # e.g. abaghist.txt
my ( $path ) = substr($local_file, 0, $ix );

# if have temp subdir, check disk space in that subdir
# example
##  81678369 May 25 05:22 bdc0105.dat.Z                             >>>>>>>>> 81 meg
##  file=cmo_cdu\bonds\bdc0105.dat|size=534850822|utc=990781062     >>>>>>>>> 534 meg
if ( defined ( $hIniFile{'temp_download_subdir'} ) )
    {
    my ( $space ) = DiskSpaceAvailable
        (
        $hIniFile{'temp_download_subdir'},     # check space in this subdir
        \@aTraceBack,  # put list of traceback strings here for caller to possibly email if error
         );

    my ( $size_to_check ) = defined($compressed_size) ? $compressed_size : $final_size;

    if ( $space < $size_to_check )
        {
        @aMsg = (
                 "Not enough disk room to download compressed file to the temp subdir",
                 "Temp subdir=$hIniFile{'temp_download_subdir'}",
                 "We checked for this much room: $size_to_check; actual room: $space",
                 "",
                 "Debug information from DiskSpaceAvailable():",
                 @aTraceBack,
                 );

        return @aMsg;
        }
    else
        {
        AppendLog ( "Have enough disk room
  Final file (after decompressing)=$local_file
  We checked the disk room in the temp download subdir=$hIniFile{'temp_download_subdir'}
  We checked for this: $size_to_check; actual room=$space" );
        }
    }

# if not using temp subdir, check disk space in final subdir
if ( !defined ( $hIniFile{'temp_download_subdir'} ) )
    {
    my ( $space ) = DiskSpaceAvailable
        (
        $path,     # check space in this subdir
        \@aTraceBack,  # put list of traceback strings here for caller to possibly email if error
         );

    my ( $size_to_check ) = defined($compressed_size) ? ( $compressed_size + $final_size) : ( $final_size * 2 );

    if ( $space < $size_to_check )
        {
        @aMsg = (
                 "Not enough disk room to download file",
                 "Final file=$local_file",
                 "We checked the disk room in the final download subdir=$path",
                 "We need room for both the compressed file and the final file",
                 "Room needed=$size_to_check; actual room=$space",
                 "",
                 "Debug information from DiskSpaceAvailable():",
                 @aTraceBack,
                 );

        return @aMsg;
        }
    else
        {
        AppendLog ( "Have enough disk room:
  Final file=$local_file
  We need room for both the compressed file and the final file
  We checked the disk room in the final download subdir=$path
  Room needed=$size_to_check; actual room=$space" );
        }
    }

# if have temp subdir, pull .Z file to that subdir; check disk room; uncompress to the local subdir
if ( defined ( $hIniFile{'temp_download_subdir'} ) )
     {
     my ( $temp_file ) = "";

     @aMsg = DownloadFile
         (
          $remote_file,
          "$hIniFile{'temp_download_subdir'}$slash$file.Z",
          $szCheckSizeVal,                      # 1=file must exist after downloading, but size not important
          0,                      # flag: check for disk room
##          \$temp_file,            # special instructions: download to temp file subdir; leave it there; pass the name back
          {p_raw_dst_fn => \$temp_file},            # special instructions: download to temp file subdir; leave it there; pass the name back
          );

     return @aMsg if ( scalar(@aMsg) );

     my ( $space ) = DiskSpaceAvailable
         (
          $hIniFile{'temp_download_subdir'},     # check space in this subdir
          \@aTraceBack,  # put list of traceback strings here for caller to possibly email if error
          );

     if ( $space < $final_size )
         {
         @aMsg = (
                  "Not enough disk room to download file",
                  "Final file=$local_file",
                  "We checked the disk room in subdir=$path",
                  "Room needed=$final_size; actual room=$space",
                  "",
                  "Debug information from DiskSpaceAvailable():",
                  @aTraceBack,
                  );

         return @aMsg;
         }
     else
         {
         AppendLog ( "Have enough disk room
  Final file=$local_file
  We checked the disk room in path=$path
  Room needed=$final_size; actual room=$space" );
         }

     # ok, we have checked for disk room, uncompress the file
     my ( $ret ) = UncompressFile
         (
          $temp_file,     # pathed file to uncompress
          \@aMsg,       # error traceback
                        # caller may chose to display this or whatever
                        # if error, push onto this list and return 1
          $path,    # subdir to unpack to
                     # we will try to use path argument w/ unpack command
          );

     return @aMsg if ( $ret );
     return ();
     }
else   # not using temp subdir
     {
     @aMsg = DownloadFile
         (
          $remote_file,
          "$local_file.Z",
          $szCheckSizeVal, # 1=file must exist after downloading, but size not important
          );

     return @aMsg if ( scalar(@aMsg) );

     # NOTE: already check for 2X disk room earlier on

     my ( $ret ) = UncompressFile
         (
          "$local_file.Z",     # pathed file to uncompress
          \@aMsg,       # error traceback
                        # caller may chose to display this or whatever
                        # if error, push onto this list and return 1
          $path,    # subdir to unpack to
                     # we will try to use path argument w/ unpack command
          );
     return @aMsg if ( $ret );
     return ();
     }

} # DownloadAndDecompressZFile


# -------------------------- FileInUseSaveToTemp
# If tried to decompress and the file was in use will decompress to temp subdir.
#

#                     FileInUseSaveToTemp ( $compressed_file, $hIniFile{'temp_download_subdir'}, szOneFileToCopyToTemp ) ;

sub FileInUseSaveToTemp
{
my ( $szCompressedFile, $szDestinationSubdir,  $szFileToDecompress ) = @_ ;
my ( $szFileInZipFile, $paErrMsg, $bFoundInZip ) ;

$szDestinationSubdir .= $slash."in_use" ;

my ( $func_name    ) = "FileInUseSaveToTemp" ;
my ( $std_err_file ) = $hCrntEnv{'tgt_log_dir'} . $slash . "pkzip32_stderr.txt";    # d:\temp\autodnld\log\pkzip32_stderr.txt

AppendLog ( "$func_name(): File: $szFileToDecompress in use during decompress will decompress to $szDestinationSubdir" );
my ( $cmd ) = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."pkzip32.exe" ;
$cmd .= " -view=brief $szCompressedFile" ;
my ( @aLine ) = `$cmd` ;
chomp ( @aLine ) ;
my ( $iTodayYYYYMMDD ) = stamp_as_yyyymmdd_hhmm ( ) ;
#$iTodayYYYYMMDD = substr ( $iTodayYYYYMMDD, 0, 8 ) ;

foreach my $szOneLine ( @aLine )
    {
    if ( $szOneLine =~ / ([^ ]*$szFileToDecompress)\s*$/ )
       {
       $szFileInZipFile = $1 ;
       $szFileInZipFile =~ s/[\\\/]/$slash/g ;
       AppendLog ( "$func_name(): File: $szFileToDecompress found in $szCompressedFile as $szFileInZipFile" );
       AppendLog ( "$func_name(): File: $szFileToDecompress will be saved as $szDestinationSubdir".$slash.$szFileInZipFile );
       $bFoundInZip  = 1 ;
       last ;
       }
    }
if ( $bFoundInZip )
    {
    $cmd  = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."pkzip32.exe" ;
    $cmd .= " -extract -nofix -over=all -directories $szCompressedFile $szFileInZipFile $szDestinationSubdir" ;
    my ( $ret ) = uncompress_run_exe
        (
         $cmd,                # cmd to run
         $paErrMsg,          # will fill this in if error
         $std_err_file,      # we DO have a stderr file
         );
    my $szDestinationFile = $szDestinationSubdir ."\\" . $szFileInZipFile ;
    $szDestinationFile =~ s/[\\\/]/$slash/g ;
    if ( $ret && -e $std_err_file )
        {
        if ( ! -e $szDestinationFile )
           {
           AppendLog ( "WARNING: $func_name(): File: $szFileToDecompress not archived to $szDestinationFile.  Will continue" );
           }
        }
    return ( $szDestinationFile ) ;
    }
else
    { ##....
    }

} # FileInUseSaveToTemp


############################
#  CheckForInUseFiles
#
#
#
sub CheckForInUseFiles
{
my ( $szInUseDir ) = $hIniFile{'temp_download_subdir'}  ;
my ( $szFunction ) = "CheckForInUseFiles" ;
$szInUseDir .= $slash if ( $szInUseDir !~ /[\\\/]$/ ) ;
$szInUseDir .= "in_use" . $slash ;
my ( $iRightNowYYYYMMDD_HHMM ) = stamp_as_yyyymmdd_hhmm ( ) ;
my ( $bNoneFound ) = 1  ;

if ( ! -d $szInUseDir )
    {
    AppendLog ( "$szFunction (): In_use dir ($szInUseDir) not found... assume no in_use files to be copied." );
    return 1, undef, $bNoneFound  ;
    }

if ( $hIniFile{'skip_file_in_use_process'} eq 'Y')
    {
    AppendLog ( "$szFunction (): skip_file_in_use_process=Y found... will exit this fn without checking." );
    return 1, undef, $bNoneFound  ;
    }

if ( ! opendir ( INUSE, $szInUseDir ))
    {
    #AppendLog ( "ERROR: Could not get dir listing of $szInUseDir to check for files to copy", 1 );
    AppendLog ( "ERROR: CheckForInUseFiles(): could net get a dir listing of $szInUseDir" );
    return 1, undef, $bNoneFound  ;
    }

my ( @aFile ) = readdir(INUSE);
closedir(INUSE);

my @aDoneCopies ;
my ( @aStillToDo, @aStillToDoCmd ) ;
foreach my $szInUseFile ( @aFile )
   {
   my $szFullFile = $szInUseDir.$szInUseFile ;
   next if ( $szInUseFile !~ /^\d\d\d\d\d\d\d\d_\d+\.txt/i ) ;
   AppendLog ( "$szFunction (): found in_use file $szInUseFile" );
   $bNoneFound = "" ;
   next if ( open ( INUSE_FILE, $szFullFile ) != 1 ) ;
   my @aInUseData = <INUSE_FILE> ;
   close INUSE_FILE ;
   unlink ( $szFullFile ) ;

   #rename ( $szFullFile, $iRightNowYYYYMMDD_HHMM.".old" ) ;

   foreach my $szInUseDataLine ( @aInUseData )
      {
      $szInUseDataLine =~ s/\n|\s+$//g ;
      next if ( $szInUseDataLine !~  /copy/i ) ;
      my ( $szInUseCmd,   $szInUseOrigFile, $szInUseDestFile ) = split ( / +/, $szInUseDataLine ) ;
      my ( $szCmdOnly, $szFileToCopyInfo, $szFileDestInfo ) = split ( /\|/, $szInUseDataLine ) ;

      $szInUseDestFile =~  s/^([^\|]+)\|.*$/$1/ ;

      AppendLog ( "$szFunction (): Temp file: $szInUseOrigFile Dest File:$szInUseDestFile" );

      my ( $szSizeToCopy, $szTimeToCopy ) = split ( /\:/, $szFileToCopyInfo ) ;
      my ( $szSizeDest,   $szTimeDest   ) = split ( /\:/, $szFileDestInfo ) ;

      my $iUtcOrig = (stat($szInUseOrigFile))[9];
      my $iUtcDest = (stat($szInUseDestFile))[9];

      my $iSizeOrigNow = (stat($szInUseOrigFile))[7];
      my $iSizeDestNow = (stat($szInUseDestFile))[7];

      if ( $iUtcDest > $iUtcOrig )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, time dest > time of temp file Dest: $iUtcDest > Temp: $iUtcOrig" ) ;
         AppendLog ( "$szFunction (): Was not copied, time Dest: $iUtcDest > Temp: $iUtcOrig" );
         next ;
         }
      elsif ( ! -e $szInUseOrigFile  )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, file: $szInUseOrigFile does not exist anymore" ) ;
         AppendLog ( "$szFunction (): Was not copied, file: $szInUseOrigFile does not exist anymore" );
         next ;
         }
      elsif ( ! -e $szInUseDestFile  )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, file: $szInUseDestFile does not exist anymore" ) ;
         AppendLog ( "$szFunction (): Was not copied, file: $szInUseDestFile does not exist anymore" );
         next ;
         }
      elsif ( $iSizeOrigNow != $szSizeToCopy )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, size of file $szInUseOrigFile  ($iSizeOrigNow bytes) not the same as it was when marker file was created ($szSizeToCopy bytes)" ) ;
         AppendLog ( "$szFunction (): Was not copied, size of file $szInUseOrigFile  ($iSizeOrigNow bytes) not the same as it was when marker file was created ($szSizeToCopy bytes)" );
         next ;
         }
      elsif (  $iSizeDestNow != $szSizeDest )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, size of file $szInUseDestFile  ($iSizeDestNow bytes) not the same as it was when marker file was created ($szSizeDest bytes)" ) ;
         AppendLog ( "$szFunction (): Was not copied, size of file $szInUseDestFile  ($iSizeDestNow bytes) not the same as it was when marker file was created ($szSizeDest bytes)" );
         next ;
         }
      elsif ( $szTimeToCopy != $iUtcOrig )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, time of file $szInUseOrigFile  ($iUtcOrig bytes) not the same as it was when marker file was created ($szTimeToCopy bytes)" ) ;
         AppendLog ( "$szFunction (): Was not copied, time of file $szInUseOrigFile ($iUtcOrig bytes) not the same as it was when marker file was created ($szTimeToCopy bytes)" );
         next ;
         }
      elsif ( $szTimeDest != $iUtcDest )
         {
         push ( @aDoneCopies,  $szInUseDataLine ."|Was not copied, time of file $szInUseDestFile  ($iUtcDest bytes) not the same as it was when marker file was created ($szTimeDest bytes)" ) ;
         AppendLog ( "$szFunction (): Was not copied, time of file $szInUseDestFile  ($iUtcDest bytes) not the same as it was when marker file was created ($szTimeDest bytes)" );
         next ;
         }
      else
         {
         my $bSystem = system ( "$com_spec $szCmdOnly" ) ;
         AppendLog ( "$szFunction (): Doing $szCmdOnly " );
         my $iUtcAfter = (stat($szInUseDestFile))[9];
         my $iSizeAfter = (stat($szInUseDestFile))[7];
         if (  $bSystem )
            {
             AppendLog ( "$szFunction (): ERROR: Doing $szCmdOnly: $bSystem" );
            #print "\n\nERROR!!!! doing:\n$com_spec $szCmdOnly";
            push ( @aStillToDo, $szInUseDataLine ) ;
            push ( @aStillToDoCmd, $szCmdOnly  ) ;
            }
         elsif (  $iUtcAfter != $iUtcOrig  )
            {
            AppendLog ( "$szFunction (): ERROR: Doing $szCmdOnly: After copy, the time of the file ($iUtcAfter)does not equal the expected time $iUtcOrig." );
            #print "\n\nERROR!!!! doing:\n$com_spec $szCmdOnly";
            push ( @aStillToDo, $szInUseDataLine ) ;
            push ( @aStillToDoCmd, $szCmdOnly  ) ;
            }
         else
            {
            AppendLog ( "$szFunction (): Cmd  $szCmdOnly processed succesfully...deleting $szInUseOrigFile" );
            push ( @aDoneCopies,  $szInUseDataLine ) ;
            unlink ( $szInUseOrigFile ) ;
            }
         }
      }
   }

if ( scalar ( @aStillToDo ) > 0 )
   {
   my $szNewInUseFile = $szInUseDir."$iRightNowYYYYMMDD_HHMM".".txt" ;
   AppendLog ( "$szFunction (): File $szNewInUseFile created with list of leftover in_use files" );
   if ( open ( STILL_DO, ">$szNewInUseFile" ) )
      {
      foreach my $szOneLineToDo ( @aStillToDo )
          {
          print STILL_DO "$szOneLineToDo\n" ;
          }
      close STILL_DO ;
      }
   else
      {
      ## some error
      }
   }

if ( scalar ( @aDoneCopies ) > 0  )
   {
   if ( open ( IN_USE_DONE, ">>".$szInUseDir."Previously_copied.txt" ) )
      {
      foreach my $szOneLineDone ( @aDoneCopies )
          {
          print IN_USE_DONE "\n$iRightNowYYYYMMDD_HHMM ==== $szOneLineDone" ;
          }
      close IN_USE_DONE ;
      }
   else
      {
      ## some error
      }
   }
return ( undef, \@aStillToDoCmd, $bNoneFound ) ;

} # end CheckForInUseFiles


# -------------------------- MakeFileInUseMarkerFile
#
#
#

sub MakeFileInUseMarkerFile
{
my $iDateNow = stamp_as_yyyymmdd_hhmm ( ) ;
my ( @aOldInUseFiles, @aOldInUseLines ) ;

my ( $szInUseDir ) = $hIniFile{'temp_download_subdir'}  ;
$szInUseDir .= $slash if ( $szInUseDir !~ /[\\\/]$/ ) ;
$szInUseDir .= "in_use" . $slash ;
my ( $iRightNowYYYYMMDD_HHMM ) = stamp_as_yyyymmdd_hhmm ( ) ;

if ( ! -d $szInUseDir )
    {
    MkdirAsReq ( $szInUseDir );
    }
else
    {
    if ( ! opendir ( INUSE, $szInUseDir ))
        {
        #AppendLog ( "ERROR: Could not get dir listing of $szInUseDir to check for files to copy", 1 );
        AppendLog ( "ERROR: MakeFileInUseMarkerFile(): could net get a dir listing of $szInUseDir" );
        return 1 ;
        }

    my ( @aFile ) = readdir(INUSE);
    closedir(INUSE);

    foreach my $szInUseFile ( @aFile )
       {
       my $szFullFile = $szInUseDir.$szInUseFile ;
       next if ( $szInUseFile !~ /^\d\d\d\d\d\d\d\d_\d+\.txt/i ) ;
       AppendLog ( "MakeFileInUseMarkerFile(): found in_use file $szInUseFile" );

       next if ( open ( INUSE_FILE, $szFullFile ) != 1 ) ;
       my @aInUseData = <INUSE_FILE> ;
       close INUSE_FILE ;
       unlink ( $szFullFile ) ;

       foreach my $szOneLine ( @aInUseData )
          {
          next if ( $szOneLine !~ /copy/i ) ;
          $szOneLine =~ s/[\n\r]//g ;
          my ( $szJunkIgnore, $szOneFile, $szAfterJunk ) = split ( / +/, $szOneLine ) ;

          my ( $ix ) = rindex($szOneFile, "\\" );
          $szOneFile = substr($szOneFile,$ix+1);
          #$szOneFile =~ s/[\\\/]([^\\\/]+$)/$1/ ;

          push @aOldInUseFiles, $szOneFile ;
          push @aOldInUseLines, $szOneLine ;
          }
   }

    }
my $szInUseMarkerFile  = $hIniFile{'temp_download_subdir'} . $slash . "in_use" . $slash . $iDateNow . ".txt" ;
my $szInUseLineToOutput ;

my ( %hNewFilesIn ) ;
if ( open ( INUSE_MARK, ">$szInUseMarkerFile" ) )
   {
   #print INUSE_MARK join ( "\n", @aOldInUseLines ) ."\n" if ( scalar ( @aOldInUseLines ) > 0 ) ;
   foreach my $szOneInUseLine ( @::aFilesInUse  )
        {
        $szInUseLineToOutput = $szOneInUseLine ;
        my ( $szCopyCmd, $szFileToCopy, $szDestFile ) = split ( / +/, $szInUseLineToOutput ) ;
        my ( $szFileToCopyFnOnly ) = $szFileToCopy ;

         my ( $ix ) = rindex ( $szFileToCopyFnOnly, "\\" );
         $szFileToCopyFnOnly = substr ( $szFileToCopyFnOnly, $ix+1);

        $hNewFilesIn{uc($szFileToCopyFnOnly)} = 1 ;

        my $szSizeToCopy = ( stat( $szFileToCopy ) ) [7];
        my $szTimeToCopy = ( stat( $szFileToCopy ) ) [9];

        my $szSizeDest = ( stat( $szDestFile     ) ) [7];
        my $szTimeDest = ( stat( $szDestFile     ) ) [9];

        $szInUseLineToOutput .= "|"."$szSizeToCopy:$szTimeToCopy"."|"."$szSizeDest:$szTimeDest" ; ;

        print INUSE_MARK $szInUseLineToOutput ."\n" ;
        }
   if ( scalar ( @aOldInUseLines ) > 0 )
        {
        my ( $iCountFiles ) = 0 ;
        for ( $iCountFiles = 0 ; $iCountFiles <  scalar ( @aOldInUseLines ) ; $iCountFiles ++ )
            {
            my ( $szOneFileToCheck, $szOneLineToCheck ) ;
            $szOneFileToCheck =  $aOldInUseFiles[$iCountFiles] ;
            $szOneLineToCheck =  $aOldInUseLines[$iCountFiles] ;
            next if ( defined ( $hNewFilesIn{uc($szOneFileToCheck)} ) ) ;
            print INUSE_MARK  $szOneLineToCheck ."\n" ;
            }
        }

   close INUSE_MARK ;
   }
else
   {
   AppendLog ( "MakeFileInUseMarkerFile(): error trying to make in_use marker file. We were not able to create $szInUseMarkerFile" );
   return 1 ;
   }

return "" ;

} # MakeFileInUseMarkerFile
 # end MakeFileInUseMarkerFile





# -------------------------- UnEncrypt
# unecrypt the password; have old and new algorithm
# return clear text
sub UnEncrypt
{
my (
    $szEncryptedString,
    $p_err,
    ) = @_;

# new method? (if so, take the last 6 char and reverse them; typically the pw is: 'aknmzn' . reverse($plain);
if ( length($szEncryptedString) < 20 )
    {
    my $clear = reverse(substr($szEncryptedString,6)) ;

    if ( length($clear) < 5 )
        {
        $$p_err = "Password is too short";
        return;
        }

    return $clear;
    }

# got this far: must be old method
my ( $string );
my( $len );

$szEncryptedString =~ tr/TQICKBRWNFOXJUMPSVEHLAZYDG0123456789tqickbrwnfoxjumpsvehlazydg/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/;

if ( length ($szEncryptedString) < 66 )
    {
    $$p_err = "Bad password (len LT 66)";
    return;
    }

$len = substr($szEncryptedString, 65, 2);
$len = $len - 11;
$string = substr($szEncryptedString,60 - $len,$len);
return $string;

} # UnEncrypt


# -------------------------------------- monitor_ship_server_status
# we only want to email every 4 hours if Intex server is offline
sub monitor_ship_server_status
{
my (
    $err_cnt,   # 0=no errors ie. have connectivity
    $p_status,   # will return one of these phrases: up/down (may be user problem, not Intex problem)
    $p_just_changed,  # will return 1/0
    $p_down_for_nn_hours,  # will return 1/0
    ) = @_;

# This is our marker file; if exists, in server-down state etc
# First line is when we first went down; we add lines every NN hours
my $szHadConnectErrorFile = "$hCrntEnv{'tgt_log_dir'}$slash"."had.connect.error.txt";

# down to up?
if ( -e $szHadConnectErrorFile  &&  $err_cnt == 0 )
    {
    AppendLog ( "monitor_ship_server_status(): down to up" );
    unlink($szHadConnectErrorFile);
    $$p_status = 'up';
    $$p_just_changed = 1;
    $$p_down_for_nn_hours = 0;
    return;
    }

# up to down?
if ( ! -e $szHadConnectErrorFile  &&  $err_cnt != 0 )
    {
    AppendLog ( "monitor_ship_server_status(): up to down; create marker file=$szHadConnectErrorFile" );
    if ( open ( OUT, ">$szHadConnectErrorFile" ) )
        {
        print OUT scalar(localtime(time())) . "
Intex server is off-line\n";
        close(OUT);
        }

    $$p_status = 'down';
    $$p_just_changed = 1;
    $$p_down_for_nn_hours = 0;
    return;
    }

# up and still up?
if ( ! -e $szHadConnectErrorFile  &&  $err_cnt == 0 )
    {
    AppendLog ( "monitor_ship_server_status(): up and still up" );
    $$p_status = 'up';
    $$p_just_changed = 0;
    $$p_down_for_nn_hours = 0;
    return;
    }

my $iSec = time() - (stat($szHadConnectErrorFile))[9];

# down and still down but not for that long
if ( -e $szHadConnectErrorFile  &&  $err_cnt != 0  &&  $iSec < 3600 * 4 )
    {
    AppendLog ( "monitor_ship_server_status(): down and still down but not for that long" );
    $$p_status = 'down';
    $$p_just_changed = 0;
    $$p_down_for_nn_hours = 0;
    return;
    }

# got this far; must be down and still down and time GT NN hours; append to marker file etc
AppendLog ( "monitor_ship_server_status(): down and still down and time GT NN hours; append to marker file=$szHadConnectErrorFile" );
open ( OUT, ">>$szHadConnectErrorFile" );
print OUT "Intex server is still off-line; email user; time=" . scalar(localtime()) . "\n";
close ( OUT );

$$p_status = 'down';
$$p_just_changed = 0;
$$p_down_for_nn_hours = 1;

} #  monitor_ship_server_status


# ------------------- CheckAccessToIntexServer
# Check access to remote ship server
# Also, figure out whether cmo subdir is distrib or distribution
# NOTE: if server goes down, only email every 4 hours, not every time we run autodnld
# We call this subroutine before we check cmo data, pool data etc

# callers:
#   autodnld in test mode
#   TryToDownloadAllDataTypes()
#   CreateFakeTrackingFiles()
#   etc, etc

# If errors, email user to that effect
# Return list of error lines, or empty array

sub CheckAccessToIntexServer
{
my (
    $p_status,   # may be undef, or will return one of these phrases: up/down
    $p_just_changed,  # may be undef, or will return 1/0
    $p_down_for_nn_hours,  # may be undef, or will return 1/0
    $bDontCheckAlternate
    ) = @_;
my $szFunction = "CheckAccessToIntexServer" ;
my ( $bStillErrorReport,  $bFoundSuccesfulServer, $szOldConnection ) ;

## my( @aRemoteDir, $szDir, $szMsg, $szLine, $szName, @aToken );
## my ( $iSec );

AppendLog ( "$szFunction(): start" ) if ( LogThis( 'gen' ) > 0 );

print "Checking access ... please wait\n";

# try to get a dir listing
# WARNING: we cannot always detect errors for HTTP format
my @aRemoteDirErr = ();
my @aRemoteDir = ();

GetRemoteDir
        (
         "/" . $hIniFile{'user'} . "/.",                # e.g. "/tiny_tar/."
         \@aRemoteDir,      # return dir listing
         \@aRemoteDirErr      # possible err msg
         );

# we only want to email every 4 hours if Intex server is offline
monitor_ship_server_status
    (
     scalar(@aRemoteDirErr),   # 0=no errors ie. have connectivity
    $p_status,

    $p_just_changed,  # will return 1/0
    $p_down_for_nn_hours,  # will return 1/0
     );
# ok, have dealt with state machine for ship server down; now can return if error
if ( scalar(@aRemoteDirErr) )
    {
    $bStillErrorReport = 1 ;
    }

if ( scalar ( @aRemoteDirErr ) > 0  && uc( $hIniFile{'try_alternate_server'} ) ne "N" && ! $bDontCheckAlternate )
    {
    AppendLog ( "$szFunction (): Had an error accessing ship server.  Will try other servers." );

    if ( -e $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "available_servers.txt" )
       {
       @aPossibleIntexServers = ( ) ;
       if ( open ( AVAIL, $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "available_servers.txt" ) )
          {
          my @aAvailLines = <AVAIL> ;
          foreach my $szOneAvailServer ( @aAvailLines  )
              {
              $szOneAvailServer =~ s/\s// ;
              push ( @aPossibleIntexServers, $szOneAvailServer ) ;
              }
          }
       AppendLog ( "$szFunction (): Found file ". $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "available_servers.txt" );
       AppendLog ( "$szFunction (): will only use the servers in that file: ". join ( ", ", @aPossibleIntexServers )  );
       }

    if ( defined  ( $hIniFile{'new_servers'} ) )
       {
       my @aNewServers = split ( /\,/, $hIniFile{'new_servers'} ) ;
       AppendLog ( "$szFunction (): Found ini entry for \"new_servers\".  will add the following servers to the list of servers to check: ". join ( ", ", @aNewServers ) ) ;
       push @aPossibleIntexServers, @aNewServers ;
       }

    $szOldConnection = $hIniFile{'connection'} ;
    AppendLog ( "$szFunction (): Starting testing other servers.  List to try: ". join ( ", ", @aPossibleIntexServers )  );
    foreach my $szOneServer ( @aPossibleIntexServers )
       {
       next if ( uc($szOneServer) eq uc ( $szOldConnection )  ) ;
       AppendLog ( "$szFunction (): Start server=$szOneServer" );
       $hIniFile{'connection'} = $szOneServer ;

       my ( @aErr, @aRemoteDirReturn ) ;
       GetRemoteDir
               (
                "/" . $hIniFile{'user'} . "/.",                # e.g. "/tiny_tar/."
                \@aRemoteDirReturn,      # return dir listing
                \@aErr      # possible err msg
                );

#      my @aErr = DownloadFile
#          (
#           $szRemoteFile,
#           $szLocalFile,
#           1,                  # 0=no error check for existence after we try to download
#           );
       if ( scalar ( @aErr ) == 0 )
          {
          print "\nServer: $szOldConnection had an error.  The alternate server: $szOneServer connected fine. Will use that server." ;
          AppendLog ( "$szFunction (): Server=$szOneServer did not have an error, will use that server." );
          $hIniFile{'connection'} = $szOneServer ;
          @aRemoteDir  = @aRemoteDirReturn ;
          $bFoundSuccesfulServer = 1 ;
          $bStillErrorReport = "" ;
          last ;
          }
       else
          {
          AppendLog ( "$szFunction (): Server=$szOneServer had an error.\nDirListings returned:\n" . join ( "\n", @aRemoteDirReturn ) ."\nErrors Returned:\n" . join ( "\n", @aErr )  );
          }
       }
    if ( ! $bFoundSuccesfulServer )
       {
       $bStillErrorReport = 1 ;
       AppendLog ( "$szFunction (): Checked all the servers, and did not find a succesful one.  Set server back to $szOldConnection  and will try to continue." );
       $hIniFile{'connection'} = $szOldConnection  ;
       }
    }

if ( scalar(@aRemoteDirErr) && $bStillErrorReport )
    {
    my @aMsg =
              (
               "$szFunction(): We were checking access to the Intex Shipment server",
               "To help determine the cause of this error, please try to open a command line window and run \"autodnld -t\" to determine whether you can connect to Intex Shipment servers using https(port443).",
               "If the test succeeds, please contact autodnld_help\@intex.com and attach log\\autodnld.log and a screen capture of your test in the email",
               "Here is command Autodnld uses and some debugging information from GetRemoteDir():",
               "---------------------------------------",
               @aRemoteDirErr,
               "---------------------------------------",
               );

    AppendLog ( "$szFunction(): returned these error lines\n" . join("\n",@aMsg) );
    return @aMsg;
    }

# got this far; no errors with dir listing
print "We were able to get a dir listing\n";
AppendLog ( "$szFunction(): we have dir listing, look for distrib*" );

# OK, have listing of home dir, look for distrib or distribution (but not both), and set global
# NT server typical lines:
#   "----------   1 owner    group           34659 Nov  1 19:48 cmo_cdi.zip"
#   "d---------   1 owner    group               0 Aug  7  1998 distribution"
# (NOTE: we have nt server set for unix style dirs)
# FYI: for both NT and UNIX, name is token[8]
$hCmoState{'distrib_word'} = "";

foreach my $szLine ( @aRemoteDir )
    {
    my @aToken = split(/\s+/,$szLine);
    my $szName = $aToken[8];       # cmo_cdi.zip
    $szName=$aToken[1];

    if ( $szName =~ /^distrib$|^distribution$/ )
        {
        # if have multiple distrib subdir, error
        if ( $hCmoState{'distrib_word'} ne "" )
            {
            my @aMsg =
                (
                 "$szFunction(): we were checking access to the Intex shipment server",
                 "We were able to get a dir listing from the server",
                 "However, there were more than one subdir that matches the pattern distrib*",
                 "",
                 );

           my ( @aCustomerLog ) = ( "When checking access to the server ran into an error. Here is the error message:" ) ;
           push ( @aCustomerLog, @aMsg) ;
            AppendLog ( "$szFunction(): returned these error lines\n" . join("\n",@aMsg), "", \@aCustomerLog );
            return @aMsg;
            }

        $hCmoState{'distrib_word'} = $szName;
        if ( defined ( $hIniFile{'distrib_subdir'} ) )
           {
           $hCmoState{'distrib_word'} .= "\/" . $hIniFile{'distrib_subdir'}  ;
           }
        }
    }

# done scanning dir listing, if no distrib* subdir found...
if ( $hCmoState{'distrib_word'} eq "" )
    {
    my @aMsg =
        (
         "$szFunction(): we were checking access to the Intex shipment server",
         "We were able to get a dir listing from the server",
         "However, there were no subdirs that matched the pattern distrib*",
         "",
         );

    my ( @aCustomerLog ) = ( "When checking access to the server ran into an error. Here is the error message:" ) ;
    push ( @aCustomerLog, @aMsg) ;
    AppendLog ( "$szFunction(): returned these error lines\n" . join("\n",@aMsg),"", \@aCustomerLog );
    return @aMsg;
    }
print "Read INF file\n";
ReadInfFile();
# got this far; no error
print "Access is OK\n";
AppendLog ( "$szFunction(): all is OK" );
return ();

} # CheckAccessToIntexServer


# -------------------------- CheckIPAddresses
#
#
sub CheckIPAddresses
{
my ( @aIpAddresses, $szMsgToReturn, $bErrorBack ) ;

my $func = "CheckIpAddress" ;

my $szHttpDumpExe  = $hIniFile{'autodnld_home'} . $slash . "scripts" . $slash . "httpdump.exe" ;
#my $szHttpDumpArgs = "-h www.intex.com -o scripts\\ip.pl" ;
my $szHttpDumpArgs = "-h ww1.intex.com -o scripts\\ip.pl" ;    ## works at intex and outside.

if ( defined ( $hIniFile{'ip_script'} ) )
   {
   if ( $hIniFile{'ip_script'} =~ /[a-z]/i && -e $hIniFile{'ip_script'} )
      {
      $szHttpDumpExe = $hIniFile{'ip_script'} ;
      }
   elsif ( $hIniFile{'ip_script'} =~ /[a-z]/i && ! -e $hIniFile{'ip_script'} )
      {
      $szMsgToReturn .=  "\nIp script in ini file ". $hIniFile{'ip_script'}. " does not exist" ;
      AppendLog ( "$func(): Ip script in ini file ". $hIniFile{'ip_script'}. " does not exist", 0 );
      $bErrorBack = 1 ;
      return ( $bErrorBack, $szMsgToReturn ) ;
      }
   }
if ( defined ( $hIniFile{'ip_arguments'} ) )
   {
   if ( $hIniFile{'ip_arguments'} =~ /[a-z]/i )
      {
      $szHttpDumpArgs = $hIniFile{'ip_arguments'} ;
      }
   }

my ( $szLocalIpAddressFile ) = $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "Valid_ips.log" ;

AppendLog ( "$func(): start", 0 );

if ( open ( VALID, $szLocalIpAddressFile ) )
   {
   @aIpAddresses = <VALID> ;
   close VALID ;
   }
else
   {
   $szMsgToReturn .=  "\nCould not open $szLocalIpAddressFile. This file is created during a successful shipment process." ;
   AppendLog ( "$func(): Could not open $szLocalIpAddressFile", 0 );
   $bErrorBack = 1 ;
   return ( $bErrorBack, $szMsgToReturn ) ;
   }


my ( $szHttpDumpCmd ) = "$szHttpDumpExe $szHttpDumpArgs" ;
print "\nrunning: $szHttpDumpCmd\n" ;
my @aResultsCmd = `$szHttpDumpCmd` ;

my ( $szThisIpAddress, $szMatchedIpAddress )  ;
foreach my $szOneLineCmd ( @aResultsCmd )
    {
    if ( $szOneLineCmd =~ /(\d+\.\d+\.\d+\.\d+)/ )
        {
        $szThisIpAddress = $1  ;
        $szOneLineCmd =~ s/\s//g ;
        my ( @aElementsOfThisIpAddress ) = split ( /\./, $szThisIpAddress ) ;
        $szMsgToReturn .=  "\nThis computer's IP address is $szThisIpAddress" ;
        foreach my $szOneValidIp ( @aIpAddresses )
           {
           $szOneValidIp =~ s/\s//g ;
           my ( $szIpAddress, $szSubNet ) = split ( /\|/, $szOneValidIp ) ;
           my ( @aElementsOfThisValidIp ) = split ( /\./, $szIpAddress ) ;
           #$szSubNet =~ s/^.*\=//g ;
           my ( @aElementsOfThisValidSubNetIp ) = split ( /\./, $szSubNet ) ;
           my ( $bNotMatched ) ;
           for  ( my $iTempCount = 0 ; $iTempCount < scalar ( @aElementsOfThisValidIp ) ; $iTempCount ++ )
               {
               my ( $szThisIpAddressElement            ) = $aElementsOfThisIpAddress[$iTempCount] ;
               my ( $szThisValidIpAddressElement       ) = $aElementsOfThisValidIp[$iTempCount] ;
               my ( $szThisValidIpAddressSubNetElement ) = $aElementsOfThisValidSubNetIp[$iTempCount] ;
               if ( $szThisValidIpAddressElement eq $szThisIpAddressElement || ( $szThisValidIpAddressElement =~ /^0+$/ && $szThisValidIpAddressSubNetElement =~ /^0+$/ && $iTempCount  > 1 ) )
                  {
                  }
               else
                  {
                  $bNotMatched  = 1 ;
                  }
               }

           if ( ! $bNotMatched  )
              {
              $szMatchedIpAddress  = $szOneLineCmd ;
              $bErrorBack = 0 ;
              $szMsgToReturn .=   "\nIP address $szThisIpAddress is in the last list of valid ip addresses, so it should be valid.\nValid IP: $szOneValidIp " ;
              AppendLog ( "$func(): IP address $szThisIpAddress is in the last list of valid ip addresses, so it should be valid.\nValid IP: $szOneValidIp ", 0 );
              last ;
              }
           }
        }
    else
        {
        next ;
        }
    last if (  $szMatchedIpAddress  =~ /\d/ ) ;
    }
if ( $szThisIpAddress   eq "" )
    {
    $szMsgToReturn .=   "\nNot able to determine this computer's IP address. Make sure you have internet access from this pc.\nValid IP addresses are: \n" . join ( "", @aIpAddresses ) ;
    AppendLog ( "$func(): Not able to determine this computer's IP address. Make sure you have internet access from this pc.\nValid IP addresses are: \n" . join ( "", @aIpAddresses ) , 0 );
    $bErrorBack = 1 ;
    }
elsif ( $szMatchedIpAddress  eq "" )
    {
    $szMsgToReturn .=  "\nNot able to match this computer's IP address $szThisIpAddress to a valid ip address.\nValid addresses are: \n" . join ( "\n", @aIpAddresses ) ;
    AppendLog ( "$func(): Not able to match this computer's IP address $szThisIpAddress to a valid ip address.\nValid addresses are: \n" . join ( "\n", @aIpAddresses ), 0 );
    $bErrorBack = 2 ;  ## message will be different in this case to say that the ip address is bad.
    }
$szMsgToReturn .=  "\nFile listing valid IP addresses is $szLocalIpAddressFile" ;

return ( $bErrorBack, $szMsgToReturn ) ;

} # end CheckIPAddresses

# -------------------------- DownloadShipInfoAndCheckDiskSpace
# Check disk room by getting and reading shipinfo file, and then looking for that much room
# Only called from one place
# We are doing one shipment e.g. last2 for one flavor e.g. flash (globals have useful info)
# We set file-retry to 2 ... default is 0; acceptable range is 0..2; worker may force retries lower based on ini file setting
# Return "" if OK; else, return error message

sub DownloadShipInfoAndCheckDiskSpace
{
my (
    $phCmo,
    ) = @_;

my( @aFile );
my(@aThisDir);

my($szLine, $iByteNeeded, $iFree);
my ( $ix, @aTraceBack );
my ( $szRemoteFile, $szLocalFile, @aUncmpMsg );
my ( @aLocalFile );

my $func = "DownloadShipInfoAndCheckDiskSpace";
AppendLog ( "$func(): start", 0 );

# get free disk space; error if cannot (we need a minimum even before pulling shipinfo file)
$iFree = DiskSpaceAvailable ( $hIniFile{'tgt_cdu_dir'}, \@aTraceBack );

# if had disk space error, dump log
if ( $iFree == 0  )
    {
    AppendLog ( "--------- out of room: traceback from disk space routine:");

    foreach $szLine (@aTraceBack )
        {
        AppendLog ( $szLine );
        }

    my ( @aCustomerLog ) = ( "Had a disk space error in $hIniFile{'tgt_cdu_dir'}", "--------- out of room: traceback from disk space routine:",) ;
    push ( @aCustomerLog, @aTraceBack ) ;
    push ( @aCustomerLog, "----------- end traceback" ) ;
    AppendLog ( "----------- end traceback", "", \@aCustomerLog);
    }

# figure out file names
$szRemoteFile = "$phCmo->{'long_pull_path'}/$phCmo->{'compressed_info_file'}";    # always forward slash
$szLocalFile = "$hCmoState{'flavored_log_dir'}/$phCmo->{'compressed_info_file'}";
FixSlashes(\$szLocalFile,"native");

# need NN megs minimum for ship info file; else error; this is an arbitrary number
if ( $iFree < 100000000 )
    {
    AppendLog ( "ERROR: need 100 megs room for ship info file." );
    AppendLog ( "--------- start traceback from DiskSpaceAvailable()");

    foreach $szLine (@aTraceBack )
        {
        AppendLog ( $szLine );
        }

    my ( @aCustomerLog ) = ( "Had a disk space error in $hIniFile{'tgt_cdu_dir'}", "--------- out of room: traceback from disk space routine:",) ;
    push ( @aCustomerLog, @aTraceBack ) ;
    push ( @aCustomerLog, "----------- end traceback" ) ;
    AppendLog ( "----------- end traceback", "", \@aCustomerLog);

    return "Not enough disk room to download file=$szRemoteFile; we require 1 megabyte minimum";
    }

# download the shipinfo file; DownloadFile() returns array of techie error messages if error
print "Downloading the shipinfo file...\n";

my @aDownloadFileErr = DownloadFile
    (
     $szRemoteFile,
     $szLocalFile,
     1,                    # 1=file must exist after downloading, but size not important
     {retry_cnt => 2},  # default is 0; acceptable range is 0..2; worker may force retries lower based on ini file setting
     );

if ( scalar ( @aDownloadFileErr ) )
    {
    my ( $msg ) = "$func: could not download file=$szRemoteFile
function: $func
Traceback: the function DownloadFile() returned error lines:
" . join("\n",@aDownloadFileErr);

    return ($msg);
    }

# zap any existing sif files (NOTE: name of sif file is not necessarily that of the user
opendir ( LOGDIR, $hCmoState{'flavored_log_dir'} );

while ( my $dir_file = readdir(LOGDIR))
    {
    if ( $dir_file =~ /\.sif$/i )
        {
        unlink ("$hCmoState{'flavored_log_dir'}$slash$dir_file" )  ;
        AppendLog ( "$func(): zap existing sif file=$dir_file" ) if ( LogThis( 'gen' ) > 0 );
        }
    }

closedir(LOGDIR);

# uncompress the shipinfo file (we will zap it soon)
AppendLog ( "$func(): uncompress the shipinfo file" );
@aUncmpMsg = ();

if( UncompressFile
    (
     $szLocalFile,  # has path
     \@aUncmpMsg,
     $hCmoState{'flavored_log_dir'},   # dest subdir
     ) )
    {
    my ( $msg ) = "Could not unpack shipinfo file=$szLocalFile\nTRACEBACK from UncompressFile():\n" . join("\n", @aUncmpMsg );
    my ( @aCustomerLog ) = ( "Could not unpack shipinfo file=$szLocalFile\nTRACEBACK from uncompressing:\n" . join("\n", @aUncmpMsg ) ) ;
    AppendLog ( $msg, "" , \@aCustomerLog );
    return ($msg);
    }
#cmostat.qa file doesn't come with the http download, so copy it from log directory
#do we do dbstatus check for intraday? if we do, we need some code here. Pei

my $cmostat_qa_fn = "$hCmoState{'cmo_cdu_dir'}$slash" . "cmostat.qa";
my $cmostat_qa_log= "$hCmoState{'flavored_log_dir'}$slash" . "cmostat.qa";
AppendLog("Copy cmostat.qa from $cmostat_qa_log to $cmostat_qa_fn");
copy_file($cmostat_qa_log,$cmostat_qa_fn);
# now can zap the shipinfo file: may be serialized and will start to pile up in the log subdir
ZapSerializedFile ( $szLocalFile );    # if .Z file, also try to zap file w/o the Z

# inhale the first .sif file we can find (earlier we erased any .sif files in the log subdir)
# (inhale .sif into globals; we like .sif info for emails)
# zap any existing sif files (NOTE: name of sif file is not necessarily that of the user
@::aSIFFile = ();
my $sif_fn;
opendir ( LOGDIR, $hCmoState{'flavored_log_dir'} );

while ( my $dir_file = readdir(LOGDIR))
    {
    if ( $dir_file =~ /\.sif$/i )
        {
        $sif_fn =  "$hCmoState{'flavored_log_dir'}$slash$dir_file";
        AppendLog ( "$func(): read .sif file: fn=$sif_fn" ) if ( LogThis( 'gen' ) > 0 );
        open( SIF, $sif_fn );
        @::aSIFFile = <SIF>;
        close(SIF);

        # zap .sif and .pac file .. .want to keep the log subdir clean
      #  unlink ( $sif_fn );
      #  my $pac_fn = $sif_fn;
      #  $pac_fn =~ s/\.sif/\.pac/i;
      #  unlink ( $pac_fn );

        last;
        }
    }

closedir(LOGDIR);

# if cannot read sif file...
if ( scalar(@::aSIFFile) == 0 )
    {
    my ( $msg ) = "Could not read the SIF file
  We just finished uncompressing the shipinfo file, which should contain the SIF file
  Remote shipinfo file=$szRemoteFile
  Local shipinfo file=$szLocalFile
  Directory where we looked for a .sif file: $hCmoState{'flavored_log_dir'}
  We must have the SIF file; it has information about the disk space we will need for this shipment";
    AppendLog ( "$func(): return the following error string:
    $msg" );
    return ($msg);
    }

# find meg. needed in siff file; also, clean off crlf
$iByteNeeded = "";
$ix = 0;

foreach $szLine (@::aSIFFile)
    {
    $szLine =~ s/[\n\r]//g;
    $::aSIFFile[$ix] = $szLine;
    AppendLog ( "$func(): another line from SIF file: $szLine", 0 ) if ( LogThis( 'gen' ) > 0 );

    if($szLine =~ /^Total megabytes in shipment: (\S+)/)
        {
        $iByteNeeded = $1 * 1048576; #  ... binary version
        }

    $ix++;
    }

    if ( $iByteNeeded eq "" )
    {
       my ( $msg ) = "Could not parse megabytes in shipment out of .sif file (located in $hCmoState{'flavored_log_dir'})";
       AppendLog ( "$func(): Return the following error string:
$msg" );
       return ($msg);
    }

    AppendLog ( "$func(): Disk room needed per SIF file=$iByteNeeded bytes; free space in subdir $hIniFile{'tgt_cdu_dir'}=$iFree bytes" );

    if (( $iFree < $iByteNeeded )&&($hIniFile{disk_space_cmd} ne 'UNLIMITED'))
    {
       my ( $msg ) = "Not enough disk room
  bytes needed: $iByteNeeded (based on SIF file from shipinfo file ...we use uncompresed value)
  subdir: $hIniFile{'tgt_cdu_dir'}";
       AppendLog ( "$func(): Return the following error string:
$msg" );
       return ($msg);
    }

    # we may be using a temp download area; if so, check disk room there also
    if ( !defined ( $hIniFile{'temp_download_subdir'}))
    {
       return "";  # no error
    }

   ############# got this far; check temp area
   ################## xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx if zip, can use compressed size xxxxxxxxxxxxxxxxxxxxxxx
   # now we use uncompressed size ... this is tougher than necessary xxxxxxxxxxxxxxxxxxx

    # get free disk space for temp area; error if cannot
    $iFree = DiskSpaceAvailable ( $hIniFile{'temp_download_subdir'}, \@aTraceBack );

    # if had disk space error, dump log
    if ( $iFree == 0 )
        {
        AppendLog ( "$func(): --------- start traceback from disk space routine:");

        foreach $szLine (@aTraceBack )
        {
            AppendLog ( $szLine );
        }

        my ( @aCustomerLog ) = ( "Had a disk space error in $hIniFile{'tgt_cdu_dir'}", "--------- out of room: traceback from disk space routine:",) ;
        push ( @aCustomerLog, @aTraceBack ) ;
        AppendLog ( "----------- end traceback", "", \@aCustomerLog );
    }

    AppendLog ( "$func(): Disk room needed per SIF file=$iByteNeeded bytes; free space in subdir $hIniFile{'temp_download_subdir'}=$iFree bytes" );

    if (( $iFree < $iByteNeeded )&& ($hIniFile{disk_space_cmd} ne 'UNLIMITED'))
    {
       my ( $msg ) = "Not enough disk room
  bytes needed: $iByteNeeded (based on SIF file from shipinfo file ...we use uncompresed value)
  subdir: $hIniFile{'temp_download_subdir'}
  free space=$iFree bytes";
       AppendLog ( "$func(): Return the following error string:
$msg" );
       return ($msg);
    }

    return ""; # no error

} # DownloadShipInfoAndCheckDiskSpace

################DownloadFileViaHTTP: single file download or directory listing############
# used for inf file, eot file, shipinfo file, update_exe download
# return @p_err
sub DownloadFileViaHTTP {
   my ($sSrcLocation,$sDstLocation)=@_;

   my $func="DownloadFileViaHTTP";
   my $sPipedFileLocation=$sSrcLocation."|".$sDstLocation; #pipe it to be the same style as other http downloaded files
   my ($sErr,$sDownloadedFileName)=HTTPGET($sPipedFileLocation,'getfile');
   return $sErr if($sErr);
   my $sFileDownloadFH=IO::File->new($sDownloadedFileName)||return("$func:Can't open file $sDownloadedFileName to read. The final file name is $sDstLocation");
   AppendLog("$func: decode $sDownloadedFileName and write to $sDstLocation");
   my ($httpError,$pDoneList,$sFileLeftOver)=chunk_decoding($sFileDownloadFH,$sDstLocation);#keep track the file downloaded

   $sFileDownloadFH->close();
   return "$func: Decoding returned EC:".$httpError." ".$hErrorMeaning{$httpError} if ($httpError);
   return "$func: some leftover:".$sFileLeftOver." bytes not being decoded for file $sDstLocation" if ($sFileLeftOver>0);
   return ;
}# endo fo DownloadFileViaHTTP


sub DownloadDIRViaHTTP {
   my ($sSrcLocation,$paRemoteDirArray,$paErr,$bFilesNotNeeded)=@_;

   my $func="DownloadDIRViaHTTP";
   my ($sErr,$sDownloadedFileName)=HTTPGET($sSrcLocation,'getdir');

   if($sErr){
      push(@$paErr,$sErr);
      return;
   }
   my $sFileDownload=IO::File->new($sDownloadedFileName);
   if (!defined $sFileDownload){
      push(@$paErr,"$func:Can't open file $sDownloadedFileName to read. The remote directory looking for is $sSrcLocation");
      return;
   }
   my $sDirBegin;
   while (<$sFileDownload>) {
      last if ($_=~/^End of dir list$/);
      if ($_=~/^dir list:$/)
         {
           $sDirBegin=1;
           next;
      }
      if ($_=~/Error:(\d{4})/) {
         my $sECCode=$1;
         my $sErrMSG="$func:returned EC".$sECCode.":".$hErrorMeaning{$sECCode}.". Remote Dir:".$sSrcLocation;
         AppendLog($sErrMSG);
         #$bFilesNotNeeded is a flag used for dbstatus=1, id =2 cases. that may not be counted as errors.
         push(@$paErr,$sErrMSG) if (!defined $bFilesNotNeeded);
         $sFileDownload->close();
         return;
      }
      next if (!defined($sDirBegin));
      chomp($_); #added a new line at the server side
      next if ($_=~/^\.{1,2}$/); # skip . or ..
      push(@$paRemoteDirArray,$_);
   }
   $sFileDownload->close();
   AppendLog("$func:remote dir $sSrcLocation yield empty") if (scalar(@$paRemoteDirArray)==0);
   AppendLog("$func: Saw filesNotNeeded=$bFilesNotNeeded set for either dbstatus(1)or ID(2) directory") if (scalar(@$paRemoteDirArray)==0 && defined $bFilesNotNeeded);
   return;
}# end of DownloadFileViaHTTP

#-------------------------DropMessageViaHTTP
# Drop a test or config message so Intex is aware that current configuration
# We log errors, but not scare clients.
sub DropMessageViaHTTP {
   my ($sMsg)=@_;
   #We drop a message to Intex, log  error but no more.
   my $func="DropMessageViaHTTP():";
   my ($sErr,$sDownloadedFileName)=HTTPGET($sMsg,'sendmessage');
   if($sErr){
      AppendLog("$func: HTTPGET returned error:".$sErr.". Ignore now") if ( LogThis('gen') > 0 );
      return;
   }
   my $sFileDownloadFH = IO::File->new($sDownloadedFileName);
   if (!defined $sFileDownloadFH ){
      AppendLog("$func:Can't open file $sDownloadedFileName to read.Ignore now")  if ( LogThis('gen') > 0 );
      return;
   }
   my $sECCode;
   while (<$sFileDownloadFH>) {
      chomp($_) if ( $is_unix ); #Linux may append a carriage return behind
      if ($_=~/Error:(\d{2})\r?$/) {
         $sECCode=$1;
         if ($sECCode==10) {
            AppendLog("$func: Got success message from server") if ( LogThis('gen') > 0 );
         }
         else {
            AppendLog("$func: warning got message from server EC".$sECCode) if ( LogThis('gen') > 0 );
         }
         last;

      }
   }
   $sFileDownloadFH->close();
   AppendLog("$func: warning no expected code returned from server.") if (!defined $sECCode && LogThis('gen') > 0 );
   return;
}

sub HTTPGET_IO_SOCKET_SSL {
    my ($phRequest, $iHttpVerbose) = @_;

    my $szHost = $phRequest->{sHost};
    my $port   = $phRequest->{iPort};

    my $func="HTTPGET_IO_SOCKET_SSL";

    my $sock = eval{OpenSocket($szHost, $port)};

    return("$func:EC1010:".$@."\n$hErrorMeaning{1010}.")if ( $@ || ! $sock );

    if ( $iHttpVerbose > 0 ) {

        my $out='';
        $out .="SSL connection through Proxy:".$hIniFile{'http_session_header'}."\n" if defined ( $hIniFile{'http_session_header'});
        $out .= "WEB SITE       : $szHost:$port\n";
        $out .= "CIPHER         : ".$sock->get_cipher."\n";
        my $cert = $sock->get_peer_certificate;

        $out .= "CERT SUBJECT   : ".$cert->subject_name."\n";
        $out .= "CERTIFIED BY   : ".$cert->issuer_name."\n";
        #$out .= "CERT NOT BEFORE: ".$cert->not_before."\n";
        #$out .= "CERT NOT AFTER : ".$cert->not_after."\n";
        AppendLog($out);
    }

    $sock->print( $phRequest->{'sMethod'} . ' ' . $phRequest->{'sPath'} . ' ' . $phRequest->{'sHttpVersion'} ."\r\n");
    $sock->print(join('', map {"$_->[0]: $_->[1]\r\n"} @{$phRequest->{'paHeaders'}}));
    $sock->print( "\r\n");
    $sock->print($phRequest->{sBody});

    my $sTempBinFile = $phRequest->{'sOutputFn'};
    my $sTempFH=IO::File->new(">$sTempBinFile")||return("$func: Can't write $sTempBinFile. Please make sure autodnld has write access to this directory");
    my $szBuf='';
    while (my $szTotalByte=$sock->read($szBuf,8192,length($szBuf))) {
        $sTempFH->syswrite($szBuf);
        $szBuf='';
        AppendLog("Received $szTotalByte Bytes") if ( $iHttpVerbose > 0 );
    }
    close($sock);

    AppendLog("Finished writing to file:".$sTempBinFile) if ( $iHttpVerbose > 0 );

    $sTempFH->close();
    return ('',$sTempBinFile);
}

#$sGetCommand=uploadstatus and $sUpLoadFile name is defined, it is an upload.
sub HTTPGET {
   my ($sSrcLocation,$sGetCommand,$sUpLoadFile)=@_;
   #using http to get files
   my $func="DownloadViaHTTP";
   return ("$func: $sGetCommand but file $sUpLoadFile not existing or 0 size.") if (($sGetCommand eq 'uploadstatus')&&((!defined $sUpLoadFile)||(!-e $sUpLoadFile)||((stat($sUpLoadFile))[7]==0)));
   my $szHost=$hIniFile{'connection'}; #we provided a http connection server name
   # always use connection server defined in ini file, may need change once in prod mode
   my $sUser=$hIniFile{'user'};
   my $sKey=$ship_server_password;
   my $port="443";

   my $sMultiPartBoundary = '-----------------------------7db4012306c8';
   my $sock;
   my $iHttpVerbose = LogThis('http') || 0;

   my $sTimeout = $hIniFile{'sslreadtime'} if (defined($hIniFile{'sslreadtime'}));

   my $sUploadFileHeader;
   my $sBodyHeader = '';

   if ($sGetCommand eq 'uploadstatus')
       {
       $sUploadFileHeader = "--$sMultiPartBoundary\r\n"
         . "Content-Disposition: form-data; name=\"report\"; filename=\"report.txt\"\r\n"
         . "Content-Type: text/plain\r\n"
         . "\r\n";
       $sBodyHeader .="\r\n";
       AppendLog("$func: UploadFile=$sUpLoadFile, host=$szHost" );
       }
   elsif ( $sGetCommand eq 'getdir' )
       {
       AppendLog("$func: GetDir=$sSrcLocation, host=$szHost" );
       }
   elsif ( $sGetCommand eq 'sendmessage' )
       {
       AppendLog("$func: SendMessage=$sSrcLocation, host=$szHost" ) if ( LogThis('gen') > 0 ) ;
       }
   else
       {
       AppendLog("$func: GetFile=$sSrcLocation, host=$szHost" );
       }

   $sBodyHeader .="--$sMultiPartBoundary\r\n"
            ."Content-Disposition: form-data; name=\"username\"\r\n"
            ."\r\n$sUser\r\n"
            . "--$sMultiPartBoundary\r\n"
            ."Content-Disposition: form-data; name=\"keycode\"\r\n"
            ."\r\n$sKey\r\n"
            . "--$sMultiPartBoundary\r\n"
            ."Content-Disposition: form-data; name=\"srcdir\"\r\n"
            ."\r\n".$sSrcLocation."\r\n"
            . "--$sMultiPartBoundary\r\n"
            . "Content-Disposition: form-data; name=\"action\"\r\n"
            . "\r\n".$sGetCommand."\r\n"
            . "--$sMultiPartBoundary--\r\n";

   my $iContentLength = length($sBodyHeader);
   $iContentLength +=length($sUploadFileHeader)+(stat($sUpLoadFile))[7] if ($sGetCommand eq "uploadstatus");
   AppendLog( "Content length=$iContentLength\n") if( $iHttpVerbose > 0 );
   if ($iContentLength>60*1024*1024) {
      AppendLog( "$func: Content length=$iContentLength, including $sUpLoadFile size of ".(stat($sUpLoadFile))[7]."\n");
      AppendLog("$func: Your upload returned Error Code:1009 ".$hErrorMeaning{1009});
      return ( "$func: Your upload returned Error Code:1009 ".$hErrorMeaning{1009});
   }
   $|=1;
   #$sock->print( "Accept: application/x-ms-application, image/jpeg, application/xaml+xml, image/gif, image/pjpeg, application/x-ms-xbap, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*\r\n");
   #$sock->print( "Referer: http://$szHost/shiptest.html\r\n");
   my $sBody = '';
   if ($sGetCommand eq "uploadstatus") {
       $sBody .= $sUploadFileHeader;
       AppendLog("$func: Start to uploaddbstatus file: $sUpLoadFile upload time:".time());
       my $oListFh = IO::File->new($sUpLoadFile);
       binmode($oListFh);
       local $/ = undef;
       $sBody .= <$oListFh>;
       $oListFh->close();
       AppendLog("$func: end uploaddbstatus file: $sUpLoadFile end time:".time());
   }
   $sBody .= $sBodyHeader;

   if ($iContentLength != length($sBody)) {
       #return ( "$func: Your download returned Error Code:1009 ".$hErrorMeaning{1009});
       #TODO
       die("Content length mismatch.  $iContentLength != ".length($sBody));
   }

   AppendLog("Post request for file $sSrcLocation upload time:".time().", start to save data stream") if ( $iHttpVerbose > 0 );

   AppendLog("$func:Build Input:") if ( $iHttpVerbose > 0 );

   my @aHeaders = (
          ["Accept-Language", "en-us"],
          ["Content-Type", "multipart/form-data; boundary=$sMultiPartBoundary"],
          ["Accept-Encoding", "gzip, deflate"],
          ["Host", "$szHost"],
          ["Content-Length", "$iContentLength"],
          ["Connection", "Keep-Alive"],
          ["Pragma", "no-cache"],
   );

   my %hRequest = (
       sMethod      => 'POST',
       sPath        => '/ship',
       sHttpVersion => 'HTTP/1.1',
       sHost        => $szHost,
       iPort        => $port,
       sOutputFn    => $hIniFile{'temp_download_subdir'} . $slash."tempBuf.bin",
       paHeaders    => \@aHeaders,
       sBody        => $sBody,
   );

   unlink($hIniFile{'temp_download_subdir'} . $slash."tempBuf.bin");
   my $bUseWininet = 0;
   if ($hIniFile{'win_https_wininet'}) {
       if ($^O =~ m/win32/i) {
           $bUseWininet = 1;
       }
       else {
           AppendLog("$func:Ignoring request to use wininet in config, because OS=$^O");
       }
   }

   my ($sErrorMessage, $sFn);
   if ($bUseWininet) {
       require "autodnld_wininet.pl";
       ($sErrorMessage, $sFn) = MakeRequestViaWininetAndWrapError(\%hRequest, $iHttpVerbose);
   }
   else {
       ($sErrorMessage, $sFn) = HTTPGET_IO_SOCKET_SSL(\%hRequest, $iHttpVerbose);
   }

   return ($sErrorMessage, $sFn);
}# End of HTTPGET

#####password_encoding######
#return encoded or decoded string
#input string
# use MIME::Base64, will croak if input string contains charaters with code above 255
# step: encode(one line) +reverse+tranlation of cap-noncap
# return: result string
sub password_encoding {
   my ($szString)=@_;
   use MIME::Base64();
   my $sTemp=reverse($szString);
   $sTemp=MIME::Base64::encode($sTemp,"");
   $sTemp=~tr/[a-zA-Z]/[A-Za-z]/;
   return $sTemp;
}

sub password_decoding{
   my ($szString)=@_;
   use MIME::Base64();
   my $sTemp=$szString;
   $sTemp=~tr/[a-zA-Z]/[A-Za-z]/;
   $sTemp=MIME::Base64::decode($sTemp);
   return reverse($sTemp);
}

################HTTPConnect: Generate header and download stream, save to a temp binary file############
# return ($Err_msg,$sTempBinFile)
sub HTTPConnect_IO_SOCKET_SSL {
    my ($phRequest, $iHttpVerbose) = @_;

    my $szHost = $phRequest->{sHost};
    my $port   = $phRequest->{iPort};


    my $func="HTTPConnect_IO_SOCKET_SSL";

    my $sock = eval{OpenSocket($szHost, $port)};

   return("$func:EC1010:".$@."\n$hErrorMeaning{1010}.")if ( $@ || ! $sock );

   if ( $iHttpVerbose > 0 ) {

       my $out='';
       $out .="SSL connection through Proxy:".$hIniFile{'http_session_header'}."\n" if defined ( $hIniFile{'http_session_header'});
       $out .= "WEB SITE       : $szHost:$port\n";
       $out .= "CIPHER         : ".$sock->get_cipher."\n";
       my $cert = $sock->get_peer_certificate;

       $out .= "CERT SUBJECT   : ".$cert->subject_name."\n";
       $out .= "CERTIFIED BY   : ".$cert->issuer_name."\n";
       #$out .= "CERT NOT BEFORE: ".$cert->not_before."\n";
       #$out .= "CERT NOT AFTER : ".$cert->not_after."\n";

       AppendLog($out);
   }

   # AppendLog( "Content length=$iContentLength\n") if ( $iHttpVerbose > 0 );
   $|=1;
   $sock->print( $phRequest->{'sMethod'} . ' ' . $phRequest->{'sPath'} . ' ' . $phRequest->{'sHttpVersion'} ."\r\n");
   #$sock->print( "Accept: application/x-ms-application, image/jpeg, application/xaml+xml, image/gif, image/pjpeg, application/x-ms-xbap, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*\r\n");
   #$sock->print( "Referer: http://$szHost/shiptest.html\r\n");
   $sock->print(join('', map {"$_->[0]: $_->[1]\r\n"} @{$phRequest->{'paHeaders'}}));
   $sock->print( "\r\n");
   $sock->print($phRequest->{sBody});

   my $sTempBinFile = $phRequest->{'sOutputFn'};
   my $sTempFH=IO::File->new(">$sTempBinFile")||return("$func: Can't write $sTempBinFile. Please make sure autodnld has write access to this directory");
   my $szBuf='';
   while (my $szTotalByte=$sock->read($szBuf,8192,length($szBuf))) {
       $sTempFH->syswrite($szBuf);
       $szBuf='';
      AppendLog("Received $szTotalByte Bytes") if ( $iHttpVerbose > 0 );
   }
   close($sock);

   AppendLog("Finished writing to file:".$sTempBinFile) if ( $iHttpVerbose > 0 );

   $sTempFH->close();
   return ('',$sTempBinFile);
}

sub HTTPConnect {
   my ($sFileList,$sTestFlag)=@_; #TestFlag=0 is production, =1 is connection test

   #using http to get files
   my $func="HTTPConnect";
   my $szHost=$hIniFile{'connection'}; #we provided a http connection server name
   my $sUser=$hIniFile{'user'};
   my $sKey=$hCmoState{'httpkey'};
   $sKey="ri6a38uaui6ts7nj8j14no3u" if ($sTestFlag==1);
   my $port="443";

   my $iHttpVerbose = LogThis('http') || 0;

   my $sMultiPartBoundary = '-----------------------------7db4012306c8';

   AppendLog("$func: List=$sFileList, host=$szHost, port=$port") if ( LogThis( 'gen' ) > 0 );

   AppendLog("$func:Build Input:") if ( $iHttpVerbose > 0 );
   my $sBodyHeader = "--$sMultiPartBoundary\r\n"
     . "Content-Disposition: form-data; name=\"list\"; filename=\"list.txt\"\r\n"
     . "Content-Type: text/plain\r\n"
     . "\r\n";
   my $sBodyFooter = "\r\n"
            . "--$sMultiPartBoundary\r\n"
            ."Content-Disposition: form-data; name=\"username\"\r\n"
            ."\r\n$sUser\r\n"
            . "--$sMultiPartBoundary\r\n"
            ."Content-Disposition: form-data; name=\"keycode\"\r\n"
            ."\r\n$sKey\r\n"
            . "--$sMultiPartBoundary\r\n"
            . "Content-Disposition: form-data; name=\"action\"\r\n"
            . "\r\n"
            . "downloadfiles\r\n"
            . "--$sMultiPartBoundary--\r\n";

   my $iContentLength = length($sBodyHeader)+length($sBodyFooter)+(stat($sFileList))[7];
   if ($iContentLength>60*1024*1024) {
      AppendLog( "$func: Content length=$iContentLength, including $sFileList size of ".(stat($sFileList))[7]."\n");
      AppendLog("$func: Your download returned Error Code:1009 ".$hErrorMeaning{1009});
      return ( "$func: Your download returned Error Code:1009 ".$hErrorMeaning{1009});
   }

   my $sBody = $sBodyHeader;
   {
       local $/ = undef;
       my $oListFh = IO::File->new($sFileList);
       binmode($oListFh);
       $sBody .= <$oListFh>;
   }
   $sBody .= $sBodyFooter;
   if ($iContentLength != length($sBody)) {
       #return ( "$func: Your download returned Error Code:1009 ".$hErrorMeaning{1009});
       #TODO
       die("Content length mismatch.  $iContentLength != ".length($sBody));
   }

   my @aHeaders = (
          ["Accept-Language", "en-us"],
          ["Content-Type", "multipart/form-data; boundary=$sMultiPartBoundary"],
          ["Accept-Encoding", "gzip, deflate"],
          ["Host", "$szHost"],
          ["Content-Length", "$iContentLength"],
          ["Connection", "Keep-Alive"],
          ["Pragma", "no-cache"],
   );

   my %hRequest = (
       sMethod      => 'POST',
       sPath        => '/ship',
       sHttpVersion => 'HTTP/1.1',
       sHost        => $szHost,
       iPort        => $port,
       sOutputFn    => $hIniFile{'temp_download_subdir'} . $slash."tempBuf.bin",
       paHeaders    => \@aHeaders,
       sBody        => $sBody,
   );

   unlink($hIniFile{'temp_download_subdir'} . $slash."tempBuf.bin");
   my $bUseWininet = 0;
   if ($hIniFile{'win_https_wininet'}) {
       if ($^O =~ m/win32/i) {
           $bUseWininet = 1;
       }
       else {
           AppendLog("$func:Ignoring request to use wininet in config, because OS=$^O");
       }
   }

   my ($sErrorMessage, $sFn);
   if ($bUseWininet) {
       require "autodnld_wininet.pl";
       ($sErrorMessage, $sFn) = MakeRequestViaWininetAndWrapError(\%hRequest, $iHttpVerbose);
   }
   else {
       ($sErrorMessage, $sFn) = HTTPConnect_IO_SOCKET_SSL(\%hRequest, $iHttpVerbose);
   }

   return ($sErrorMessage, $sFn);
} # End of HTTPConnect



################HTTPDownloadSet###############

sub HTTPDownLoadSet {
   my ($phCmo,)=@_; #if phCmo->{test} is defined, it is connection test
   my $func = "HTTPDownLoadSet";

   my $szShipListfile=$hCmoState{'flavored_log_dir'}.$slash."shiplist.txt"; #potential issues with the slashes.
   my $szShipListDone=$hCmoState{'flavored_log_dir'}.$slash."shiplistDone.txt"; #Donelist for intraday purpose
   my ($szShipListDoneLastReg,$szShipListFailedLastReg,$szShipListFailedLastRegRetry);
   if ($hCmoState{'cmo_flavor'}!~/intraday/i) #for regular shipment, we may have a crash file list pointers. which uses the timestamp.
      {
      #$szShipListDoneLastReg only keep track the files being normally successfully downloaded, not any files from $szShipListFailedLastReg when autodnld restarts
      #in this case, we don't mess up the sequence
      $szShipListDoneLastReg=$hCmoState{'flavored_log_dir'}.$slash."shiplistDone_".$phCmo->{"ShipTimeStamp"}.".txt";
      $szShipListFailedLastReg=$hCmoState{'flavored_log_dir'}.$slash."shiplistFailed_".$phCmo->{"ShipTimeStamp"}.".txt";
      $szShipListFailedLastRegRetry=$hCmoState{'flavored_log_dir'}.$slash."shiplistFailed_".$phCmo->{"ShipTimeStamp"}."_retry.txt";
      FixSlashes(\$szShipListDoneLastReg, "native");
      FixSlashes(\$szShipListFailedLastReg, "native");
      FixSlashes(\$szShipListFailedLastRegRetry, "native");
      #$szShipListFailedLastRegRetry will be used to add to working list, $szShipListFailedLastReg will be refreshed to keep track newly failed files.
      unlink($szShipListFailedLastRegRetry) if (-e $szShipListFailedLastRegRetry);
      if (-e $szShipListFailedLastReg)
         {
         rename($szShipListFailedLastReg,$szShipListFailedLastRegRetry);
         if((-e $szShipListFailedLastReg)||(!-e $szShipListFailedLastRegRetry))
            {
            AppendLog("Error: $func failed to rename $szShipListFailedLastReg to $szShipListFailedLastRegRetry");
            return("Error: $func failed to rename $szShipListFailedLastReg to $szShipListFailedLastReg");
            };

         }
      }
   FixSlashes(\$szShipListfile, "native");
   FixSlashes(\$szShipListDone, "native");

   my $szSaveIndZipPath = "";
   if ( $hIniFile{http_save_ind_zip_path} )
      {
      my $sSavePath = $hIniFile{http_save_ind_zip_path}.$slash.$phCmo->{"ShipTimeStamp"};
      $szSaveIndZipPath = FixSlashes( \$sSavePath, "native" );
      MkdirAsReq( $szSaveIndZipPath );
      }

   return("$func can't find ship list file: $szShipListfile") if (!-e $szShipListfile);
   return ("$func find ship list file= $szShipListfile size =0") if ((stat($szShipListfile))[7]==0);
   #sometimes shiplist is too big, we split it up based on shiplist file size <=30M or total one time download size <2GB, which
   #ever comes first
   my ($szErrMsg,$pSplittedList)=splitshiplist($szShipListfile,$szShipListDoneLastReg,$szShipListFailedLastRegRetry);
   if ( $szErrMsg ne "" )
      {
      #If any error during split list process, will use the original list as a fail proof.
      AppendLog( "$func(): warning:Error happened in".$szErrMsg."\nWill use the whole list file $szShipListfile instead." );
      push(@$pSplittedList,$szShipListfile);
      }


   #check whether we have a leftover from 2005 file missing error last time, do this in splitshiplist above
   #push(@$pSplittedList,$szShipListFailedLastRegRetry) if ((defined $szShipListFailedLastRegRetry)&&(-e $szShipListFailedLastRegRetry));
   my @aErrTrace;
   foreach my $sShortlistFullPath(@$pSplittedList)
      {
      #the split list has the fullpatch in it.
#      my $sShortlistFullPath=$hCmoState{'flavored_log_dir'}.$slash.$szShortlist;
      return("$func can't find splitted ship list file: $sShortlistFullPath") if (!-e $sShortlistFullPath);
      my $szRetry=0;
      my $sMaxRetry=3;
      my $szErrMsg;
      #loop this retry 3 times or files to be downloaded are empty
      while (($szRetry<=$sMaxRetry)&&(-e $sShortlistFullPath)&& ((stat($sShortlistFullPath))[7]>0))
         {
         my $phDone;
         $szRetry++;
         AppendLog ( "$func: start with retry count=$szRetry for list: $sShortlistFullPath" );
         #using http to get files


         my ($Err_msg,$sTempBinFile)=HTTPConnect($sShortlistFullPath,0);
         if($Err_msg ne '' && $szRetry == $sMaxRetry)
            {
            if($szRetry == $sMaxRetry)
               {
               return $func.":".$Err_msg if ($Err_msg ne '');
               }
            else
               {
               next;
               }
            }
         if ( ! -e $sTempBinFile )
             {
             AppendLog("No error reported, but no content downloaded to $sTempBinFile (try $szRetry)");
             next;
             }

         AppendLog("Open $sTempBinFile to decode") if ( LogThis('gen') > 0 );
         my $sTempFH=IO::File->new("$sTempBinFile")||return("$func: failed to open $sTempBinFile to read. Please check the access of file $sTempBinFile. Try to assign the temp folder to a local directory and run autodnld again.");

         my ($httpError,$pDoneList,$sFileLeftOver)=chunk_decoding($sTempFH);#keep track the file downloaded
         $sTempFH->close();
         if ($httpError==9999)
            {
            AppendLog("You requested a debug dump saved as file:".$hCmoState{'flavored_log_dir'}.$slash."sock_tmp.bin");
            return ( "$func: You requested a debug dump saved as file:".$hCmoState{'flavored_log_dir'}.$slash."sock_tmp.bin\n Please send this to Intex");
            }

         if ($httpError>0)
            {
            if($httpError<2000)
               {
               #severe log in error, return now
               AppendLog("Your download returned Error Code:$httpError ".$hErrorMeaning{$httpError}." while working on $sShortlistFullPath");
               return ( "$func: Your download returned Error Code:$httpError ".$hErrorMeaning{$httpError}." while working on $sShortlistFullPath");
               }
            elsif ($httpError=~/^201\d/)
               {
               AppendLog("http connection was dropped. we have some leftover from last file: ".$sFileLeftOver) if ($sFileLeftOver!=0);
               #http download time out error. We will pop the last file to be redownloaded, will check wether exhaused last retry at end of loop
               my $sCorruptedFile=pop(@$pDoneList);
               AppendLog("Your download returned Error Code:$httpError ".$hErrorMeaning{$httpError}.".  This likely happened during $sCorruptedFile download. We will ignore and retry later");
               }
            else
               {
               my $sErr="$func: Your download returned Error Code:$httpError ".$hErrorMeaning{$httpError};
               AppendLog ( $sErr." Download continued...");
               push(@aErrTrace,$sErr);
               }
            }
         if((!defined($pDoneList))||(scalar(@$pDoneList)==0))
            {
            #something is wrong here, no file being downloaded. one possibility is the list file size is too large. Another is the file doesn't exit
            # on server, but should return an error code 2005. If not EC 2005 Try again, log this
            # Because the server will stop sending files if encounter 2005 error. so the file missed on server will almost always being captured here.
            if (($httpError == 2005)&&($hCmoState{'cmo_flavor'}!~/intraday/i))
               {
               AppendLog("Error: http download got nothing due to EC$httpError seen earlier. Pop the top list from $sShortlistFullPath into $szShipListFailedLastReg for future download.");
               my $ErrMsg=TopFileList($sShortlistFullPath,$szShipListFailedLastReg,1);
               if ($ErrMsg ne '')
                  {
                  AppendLog("Error:$func had error where running TopFileList, input arg:$sShortlistFullPath,$szShipListFailedLastReg, Error: $ErrMsg");
                  return("$func:TopFileList from $sShortlistFullPath to $szShipListFailedLastReg had error: $ErrMsg");
                  }
               $szRetry--; #reset retry count
               }
            else
               {
               AppendLog("Error: http download got nothing. will retry. Shiplist file:".$sShortlistFullPath." size: ".(stat($sShortlistFullPath))[7]);
               }
            next;

            }

         my $iUncompMaxErrors = 30;
         my $iUncompMaxTries  = 2;
         my $iUncompSleep     = 1;

         if ( defined( $hIniFile{file_uncompress_retry_count} ) && $hIniFile{file_uncompress_retry_count} =~ /^\d+$/ )
             {
             $iUncompMaxTries = $hIniFile{file_uncompress_retry_count} + 1;
             }
         if ( defined( $hIniFile{file_uncompress_retry_sleep} ) && $hIniFile{file_uncompress_retry_sleep} =~ /^\d+$/ )
             {
             $iUncompSleep = $hIniFile{file_uncompress_retry_sleep};
             }
         if ( defined( $hIniFile{file_uncompress_retry_max_errors} ) && $hIniFile{file_uncompress_retry_max_errors} =~ /^\d+$/ )
             {
             $iUncompMaxErrors = $hIniFile{file_uncompress_retry_max_errors};
             }

         my $iUncompErrors = 0;
         AppendLog ( "$func: start uncompressing downloaded files" );

         foreach my $szOneDone(@$pDoneList)
            {
            if ( $iUncompErrors == $iUncompMaxErrors )
                {
                $iUncompMaxTries = 1;
                AppendLog ("Exceeded max uncompress errors ($iUncompMaxErrors), so we are no longer re-trying the uncompress if it fails");
                }
            if($szOneDone =~ /(cmo_cd[u|i])-(\S+)\.zip/i)
               {
               my $szLocalDir=$hCmoState{$1.'_dir'};
               my $szTmpLocalDir;
               my $szLocalFile = $hIniFile{'temp_download_subdir'} . $slash.$szOneDone;
               FixSlashes(\$szLocalDir,"native");
               if ( ( $hIniFile{unix_safe_unzip} eq 'y' && $is_unix ) || ( $hIniFile{win_safe_unzip} eq 'y' && ! $is_unix ) )
                  {
                  $szTmpLocalDir = $szLocalDir.$slash.'tmp';
                  FixSlashes(\$szTmpLocalDir,"native");
                  }

               my (@aErrMsg,$sUncompressError) ;
               my $iUncompFinalRet = 0;
               for ( my $iUncompTry = 1; $iUncompTry <= $iUncompMaxTries; $iUncompTry++ )
                  {
                  sleep($iUncompSleep) if ( $iUncompTry > 1 );
                  my $iUncompRet = UncompressFile(
                                                  $szLocalFile,
                                                  \@aErrMsg,
                                                  $szLocalDir ,
                                                  $szTmpLocalDir,
                                                );
                  if ( ! $iUncompRet )
                     {
                     $iUncompFinalRet = 0;
                     #add the file to be done list, for intraday only
                     if ($hCmoState{'cmo_flavor'}=~/intraday/i){
                             open ( SHIPDONE, ">>$szShipListDone" ) ;
                             print SHIPDONE "$szOneDone\n" ;
                             close(SHIPDONE);
                     }
                     $phDone->{$szOneDone}=1;
                     # zap the compressed cdi file (may be serialized and they pile up fast).
                     if ( $szSaveIndZipPath )
                        {
                        my $szSavedFile = $szOneDone;
                        $szSavedFile =~ s/^[abcdef\d]{32}-\w+-|^CUST-[abcdef\d]{32}-\w+-//;
                        copy_file( $szLocalFile, $szSaveIndZipPath.$slash.$szSavedFile );
                        }

                     ZapSerializedFile ( $szLocalFile ) ; # if .Z file, also try to zap file w/o the Z
                     last;
                     }
                  $iUncompFinalRet = 1;
                  if ($sFileLeftOver!=0)
                     {
                     last;
                     }
                  else
                     {
                     AppendLog ("There were errors when decompressing (try $iUncompTry) file=$szLocalFile (ret(destination file in use or error writing to the destination?).\n--- Traceback:".join("\n",@aErrMsg));
                     if ($hCmoState{'cmo_flavor'}=~/intraday/i && $iUncompTry == 1 )
                        {
                        open ( SHIPDONE, ">>$szShipListDone" ) ;
                        print SHIPDONE "$szOneDone\n" ;
                        close(SHIPDONE);
                        }
                     $phDone->{$szOneDone}=1;

                     }
                  }
               if ($sFileLeftOver!=0 && $iUncompFinalRet > 0 )
                  {
                  AppendLog ("EC2017: http download dropped while downloading file=$szLocalFile. Please try again");
                  ZapSerializedFile ( $szLocalFile ) if ($szRetry < $sMaxRetry); # if .Z file, also try to zap file w/o the Z
                  }
               elsif( $iUncompFinalRet > 0 )
                  {
                  $iUncompErrors++;
                  }
               }
            else
               {
               return ( "$func: problem, could not determine if file is cdi or cdu:$szOneDone " );
               }

            }
         # we keep a pointer for last file downloaded. Since retries could happen, last file being successfully downloaded may not be the last file in the
         # list. CompareAndRemoveMem should know which file is still in the pending list.
         # we do that for a normal sequential list, not for the last failed downloaded list
         # We only keep track last file successfully downloaded for non intraday and not working in the FailedLastRegRetry list to keep the pointer
         # always forward.
         if (($hCmoState{'cmo_flavor'}=~/intraday/i)||((defined $szShipListFailedLastRegRetry)&&($sShortlistFullPath eq $szShipListFailedLastRegRetry)))
            {
            $szErrMsg=CompareAndRemoveMem($sShortlistFullPath,$phDone);
            }
         else
            {
            $szErrMsg=CompareAndRemoveMem($sShortlistFullPath,$phDone,$szShipListDoneLastReg);
            }
         if ( $szErrMsg ne "" )
            {
            return ( "$func(): CompareAndRemoveMem had error---".$szErrMsg."---please check read/write access of the files" );
            }
         }
      #if 3 retires exhausted, still some files not downloaded, we save the error to a list to be picked for next time and plow ahead
      if ((-e $sShortlistFullPath)&& ((stat($sShortlistFullPath))[7]>0))
         {
         #for file missing error, it should not come here since it should be topped out into $szShipListFailedLastReg
         # earlier in scalar(@$pDoneList)==0. Any other unfinished list shoule come here.
         my $ErrMsg="$func exhausted $sMaxRetry retires, but still some files not being able downloaded. File list is saved in $sShortlistFullPath\n";
         $ErrMsg .="Some additional error trace:".join("\n",@aErrTrace) if (scalar(@aErrTrace));
         return($ErrMsg);
         }
      unlink($sShortlistFullPath) if (-e $sShortlistFullPath);
      }
   if ((defined $szShipListFailedLastReg)&&(-e $szShipListFailedLastReg))
      {
      #need alarm clients on this because we captured $szShipListFailedLastReg for this new shipment and pending
      my $ErrMsg="$func finished the shiplist, but some files not able to be downloaded and skipped. File list is saved in $szShipListFailedLastReg\n";
      $ErrMsg .="Additional error trace:".join("\n",@aErrTrace) if (scalar(@aErrTrace));
      return($ErrMsg);
      }
   return();
}# end of HTTPDownLoadSet

# -------------------------- HaveEotInTrackingFile
# we have line from eot.txt; is it in our tracking file?
# if cmo_flavor=flash, will have "[flash]" in front of each line

# NOTE: we have a flavored log subdir e.g. log/flash, which we used for eot files etc, but we do NOT
#       use the flavored log path for cmo tracking info (this is historic)

# return non zero if match

sub HaveEotInTrackingFile
{
my (
        $szEotLine,
        $szMode,      # cmo/pool/bond (assume cmo if undefined)
        ) = @_;   # line = contents of eot.txt file

my ( $szLine, $szFile, $szPrefix, $szTrackingFile );

if ( !defined($szMode) )
    {
       $szMode = "cmo";
    }

AppendLog ( "HaveEotInTrackingFile(): start; line=$szEotLine mode=$szMode" );

if ( $szMode eq "cmo" )
    {
       AppendLog ( "flavor=$hCmoState{'cmo_flavor'}" );
    }

# figure out prefix; if cmo and flash, have "[flash]" in front of each line
if ( $szMode eq "cmo" && $hCmoState{'cmo_flavor'} ne "cmodata" )
    {
        $szPrefix = "[$hCmoState{'cmo_flavor'}]";
    }
else
    {
       $szPrefix = "";
    }

# figure out name of tracking file
# NOTE: for cmo, we always use the non-flavored log dir for the cmotrack.log file ... never a flavored log dir
if ( $szMode eq "cmo" )
    {
       $szTrackingFile = $hCmoState{'tracking_file'};
    }
elsif ( $szMode eq "id" )
    {
       $szTrackingFile = $hCmoState{'id_tracking_file'} ;
    }
elsif ( $szMode eq "hist" )
    {
       $szTrackingFile = $hCmoState{'hist_tracking_file'} ;
    }
else
    {
       $szTrackingFile = "$hCrntEnv{'tgt_log_dir'}$slash" . $hPoolBondState{'pool_or_bond'} . "trak.log";  # e.g c:\\autodnld\\log\\pooltrak.log
    }

# if no tracking file, return "no match"
if ( ! ( -e $szTrackingFile ) )
    {
    my ( @aCustomerLog ) = ( "Could not find file=$szTrackingFile", "Please check if file exists", "If it exists, try re-running autodnld and check for errors" ) ;
        AppendLog ( "HaveEotInTrackingFile: no tracking file at all; no match; file=$szTrackingFile", 0, \@aCustomerLog );
        return 0;
    }

# open file, else error
if ( open ( EOTFILE, $szTrackingFile ) != 1 )
    {
    my ( @aCustomerLog ) = ( "Could not open file=$szTrackingFile" ) ;
        AppendLog ( "HaveEotInTrackingFile: could not open tracking file; no match; file=$szTrackingFile", 0, \@aCustomerLog );
        return 0;
    }

# scan file, looking for a match
while ( defined($szLine = <EOTFILE>) )
    {
        $szLine =~ s/[\n\r]//g;
        $szLine =~ s/ *\|.*$// ; ## have date of download in it

        if ( $szLine =~ /^#/ )    # for debug, can have comment lines; skip them
            {
                next;
            }

        if ( $szLine eq "$szPrefix$szEotLine" )   # may have prefix e.g. [flash]
        {
            AppendLog ( "HaveEotInTrackingFile: found match in $szTrackingFile; line=$szLine" );
            close ( EOTFILE );
            return 1;
        }
    }

    close(EOTFILE);
    AppendLog ( "HaveEotInTrackingFile: no match found in $szTrackingFile" );
    return 0;

} # HaveEotInTrackingFile


# ------------------------------ possibly_filter_out_dbstatus__lines
# NOTE: there is an option in .ini file to filter out errors e.g. "dbstatus_ignore_file=cmo_cdu\brokersp.inf" ...
# line in dbstatus.rpt file: "cmo_cdi\mbs_fhl.cdi                 |MISSING  | 09/13/05 17:10            Missing   "
sub possibly_filter_out_dbstatus__lines
{
  my ($rpt_fn, $txt_fn) = @_;

  my $func = "possibly_filter_out_dbstatus__lines";
  my $lst = $hIniFile{'dbstatus_ignore_file'};
  return if ( !defined($lst) || $lst eq '' );

  my @aMatch = map {quotemeta($_)} split(/,/, $lst);
  AppendLog ( "$func(): filter in use: $lst" );
  print "FYI: dbstatus_ignore_file filter in use: $lst\n";

  #make copy
  my $orig_stamp = (stat($rpt_fn))[9];
  my $bak_fn = "$rpt_fn.before.filtering";
  copy_file($rpt_fn, $bak_fn);

  # xfer file line by line
  my $in_fh = new IO::File "$bak_fn";
  my $out_fh = new IO::File ">$rpt_fn";

  my %hIgnoreCounts = (remove_file_cnt => 0, err_file_cnt => 0);

  while ( defined ( my $line = <$in_fh> ) )
  {
    my $skip = 0;
    chomp($line);

    foreach my $match ( @aMatch )
    {
      if ( $line =~ /^$match/ )
      {
        $skip=1;
        AppendLog ( "$func(): filter out this line: $line" );

        my @aRow = split(/\|/, $line);
        my $sError = $aRow[1];
        $sError =~ s/\s+//g;
        print "Error Type: $sError\n";

        if($sError =~ /REMOVE/)
        {
          $hIgnoreCounts{remove_file_cnt}++;
        }
        else
        {
          $hIgnoreCounts{err_file_cnt}++;

        }
      }
    }

    next if ( $skip );
    print $out_fh $line."\n";
  }

  $in_fh->close();
  $out_fh->close();

  # dbstatus.rpt has been filtered; set utime back to orig value
  utime ( $orig_stamp, $orig_stamp, $rpt_fn );


  #Modify dbstatus.txt to reduce error/remove count by removed errors.
  AppendLog("$func(): Removed $hIgnoreCounts{err_file_cnt} errors and $hIgnoreCounts{remove_file_cnt} remove file lines from dbstatus.rpt");
  $orig_stamp = (stat($txt_fn))[9];
  $bak_fn = "$txt_fn.before.filtering";
  copy_file($txt_fn, $bak_fn);
  $in_fh = new IO::File "$bak_fn";
  $out_fh = new IO::File ">$txt_fn";

  while ( defined ( my $line = <$in_fh> ) )
  {
    chomp($line);

    foreach my $sErrLine ('err_file_cnt', 'remove_file_cnt')
    {
      if ( $line =~ /^$sErrLine=(\d+)/  )
      {
        my $iOrigCnt = $1;
        my $iIgnoreCnt = $hIgnoreCounts{$sErrLine};
        my $iNewCnt = $iOrigCnt - $iIgnoreCnt;
        AppendLog ( "$func(): modify err_file_cnt from $iOrigCnt to $iNewCnt");
        $line =~ s/^err_file_cnt=(\d+)/err_file_cnt=$iNewCnt/;
      }
    }

    print $out_fh $line."\n";
  }

  utime ( $orig_stamp, $orig_stamp, $txt_fn );


} # possibly_filter_out_dbstatus__lines


# ------------------------------- RunDbStatusForCmo
# Possibly run dbstatus.exe using qa file: cmostat.qa (caller deleted it earlier on)
# Every time we finish downloading current shipment for one "flavor" e.g. flash, we call this routine
# If runs it OK, will email user to that effect

# called by
#   TestDbStatus
#   GetAllCMOForOneFlavor

# Return array of error messages, if any

sub RunDbStatusForCmo
{
my ( $bSkipUpload, $szCmoStatFileIn, $szOutputDbstatFile ) = @_ ;   ## be careful with the second input. it also signals not to email or post dbstatus files.
my $func = "RunDbStatusForCmo";
AppendLog ( "$func(): start" );
my @aErrMsg = ();
my ( $bDoPostFile ) ;


$bDoPostFile = 1 if ( defined($hIniFile{"upload_dbstatus"}) && uc( $hIniFile{"upload_dbstatus"} ) eq "Y" );
$bDoPostFile = 0 if ( $bSkipUpload ) ;

# check config file... may have no dbstatus check
return () if ( defined($hIniFile{"dbstatus_check"}) && $hIniFile{"dbstatus_check"} eq "none" );

# error if executable does not exist
my $szExe = ( $is_unix == 1 ) ? $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."dbstatus" : $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."dbstatus.exe";

if(!( -e $szExe ) )
    {
    my ( @aCustomerLog ) = ( "Cannot find dbstatus exe; fn: $szExe so cannot run database-integrity check", "Please make sure it exists in the script directory.", "If not you can download from the website https://www.intex.com/main/autodnld/download" ) ;
    AppendLog ( "ERROR: $func: cannot find dbstatus exe; fn: $szExe", "", \@aCustomerLog );
    push ( @aErrMsg, "Could not find dbstatus executable: file: $szExe" );
    push ( @aErrMsg, "Because of this error, we cannot run a database-integrity check (the download of CMO data has finished)" );
    return @aErrMsg;
    }
else  # put exe size in log file
    {
    AppendLog ( "$func: found dbstatus exe ok: fn: $szExe; size in bytes: " . (stat($szExe))[7] );
    }

# error if cannot see qa file (cmostat.qa)
my $cmostat_qa_fn = "$hCmoState{'cmo_cdu_dir'}$slash" . "cmostat.qa";    # e.g. c:\\intex\\cmo_cdu\\
if ( $szCmoStatFileIn ne "" )
   {
   $cmostat_qa_fn = $szCmoStatFileIn ;  ## jeff
   }

if(!( -e $cmostat_qa_fn ) )  # cmo_cdu\\cmostat.qa
    {
    my ( @aCustomerLog ) = ( "Cannot find file: $cmostat_qa_fn so cannot run database-integrity check" ) ;
    AppendLog ( "ERROR: $func: cannot find file: $cmostat_qa_fn", , "", \@aCustomerLog );
    push ( @aErrMsg, "Could not find dbstatus file; file=$cmostat_qa_fn" );
    push ( @aErrMsg, "This means that the download of CMO data has finished, but we cannot run a file-missing check" );
    return @aErrMsg;
    }
else
    {
    AppendLog ( "$func: found qa file OK: fn: $cmostat_qa_fn" );
    }

# make a backup copy of the QA file in the log subdir, in case we have both cmodata and flash, for example; useful for debug
{
    my $src = $cmostat_qa_fn;  # cmo_cdu\\cmostat.qa
    my $dst = "$hCrntEnv{'tgt_log_dir'}$slash" . 'cmostat.' . $hCmoState{'cmo_flavor'} . ".qa.";
    AppendLog ( "$func: make backup copy of cmostat.qa
  src=$src
  dst=$dst" );

    copy_file
    (
     $src,
     $dst,
     );
}

# put dbstatus command line together (NOTE: if flash, will put dbstatus.txt and dbstatus.rpt in log/flash subdir)
my $szCmd = $szExe;

# NOTE: if customer has data at root e.g. "e:\", need arg like this: "e:\."
my $cmo_cdi = $hCmoState{'cmo_cdi_dir'};
$cmo_cdi .= "." if ( $cmo_cdi =~ /\\$/ );
$szCmd .= " -cdi_path \"$cmo_cdi\"";

# NOTE: if customer has data at root e.g. "e:\", need arg like this: "e:\."
my $cmo_cdu = $hCmoState{'cmo_cdu_dir'};
$cmo_cdu .= "." if ( $cmo_cdu =~ /\\$/ );
$szCmd .= " -cdu_path \"$cmo_cdu\"";

# months back is normally 2, but can override it via the ini file
$szCmd .= " -check_n_months_back $hIniFile{'cdu_check_n_months_back'}";
$szCmd .= " -rpt_path \"$hCmoState{'flavored_log_dir'}\"";   # might be /log, might be /log/cms
$szCmd .= " -check_ver 0";

if ( $szCmoStatFileIn ne "" )
   {
   my $szCmoStatFileInPath ;
   my $szCmoStatFileInName ;
   if ( $szCmoStatFileIn =~ /^(.*[\\\/])([^\\\/]+)$/ )
       {
       $szCmoStatFileInPath = $1 ;
       $szCmoStatFileInName = $2 ;
       }
   else
       {
       my ( @aCustomerLog ) = ( "Cannot parse path and filename from: $szCmoStatFileIn" ) ;
       AppendLog ( "Cannot parse path and filename from: $szCmoStatFileIn", , "", \@aCustomerLog );
       push ( @aErrMsg, "Cannot parse path and filename from: $szCmoStatFileIn" );
       push ( @aErrMsg, "This means that the download of CMO data has finished, but we cannot run a file-missing check" );
       return @aErrMsg;
       }

   $szCmd .= " -qa_path $szCmoStatFileInPath ";
   $szCmd .= " -qa_fn $szCmoStatFileInName ";
   }

# can force value via ini file
#define ICMODBSCHECK_TIME_YES     0  /* error if file is too old compared with QA values; we give a 2 hour leeway before error
#define ICMODBSCHECK_TIME_EXACT   1  /* Default: check exact time match */
#define ICMODBSCHECK_TIME_NO      2  /* Not checking date/time  */
my $check_time = 0;

if ( defined ( $hIniFile{dbstatus_check_time}) )
{
    AppendLog ( "$func: check_time value forced via ini file: dbstatus_check_time: $hIniFile{dbstatus_check_time}" );
    $check_time = $hIniFile{dbstatus_check_time};
}
$szCmd .= " -check_exact_time $check_time";  #

if ( defined ( $hIniFile{dbstatus_check_signature}) )
{
    AppendLog ( "$func: dbstatus_check_signature value forced via ini file: dbstatus_check_singature: $hIniFile{dbstatus_check_signature}" );
    $szCmd .= " -check_signature ". $hIniFile{dbstatus_check_signature};
}
if ( defined ( $hIniFile{dbstatus_addl_cmd}) )
{
    my $sztemp_value = $hIniFile{dbstatus_addl_cmd} ;
    $sztemp_value =~ s/\"//g ;
    AppendLog ( "$func: dbstatus_addl_cmd value forced via ini file: dbstatus_addl_cmd: $sztemp_value" );
    $szCmd .= " $sztemp_value" ;
}
# onwards...
$szCmd .= " -check_size 1";
$szCmd .= " -check_flash 1";

my $dbstatus_txt_fn = "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.txt";
$szCmd .= " -stat_file \"$dbstatus_txt_fn\"";   # usually log subdir, but might be log/flash

AppendLog ( "cmd=$szCmd" );
print "\nRunning QA test on Intex files (\"dbstatus test\")\n";

if ( ! $bDoPostFile && grep ( /-dbstatus/i, @ARGV ))
   {
   print "\nIf there is a dbstatus error, the file will not be posted to the Intex site because the \"-dbstatus\" command line argument was entered";
   print "\nTo run dbstatus check, with upload, please run with the option \"-dbstatus_upload\"\n";
   }
elsif ( ! $bDoPostFile && $szCmoStatFileIn ne "" )
   {
   print "\nIf there is a dbstatus error, the file will not be posted to the Intex site because it is an intraday dbstatus check\n";
   }
elsif ( ! $bDoPostFile )
   {
   print "\nIf there is a dbstatus error, the file will not be posted to the Intex site because upload_dbstatus=y was not in the ini file\n";
   }

system( $szCmd );  # want output to show
my $iRet = $?;
AppendLog("$func: $szCmd returned value: $iRet");
if ( -e  $hCmoState{'flavored_log_dir'} . $slash . "dbstatus.rpt" )
    {
    AddUserToDbstatus ( $hIniFile{'user'}, $hCmoState{'flavored_log_dir'} . $slash . "dbstatus.rpt" ) ;
    }

if ( $iRet > 256 )
    {
    $iRet = $iRet >> 8;
    AppendLog("$func: downshift iRet to $iRet");
    }

# if have error return code, report it
#   define EXCEPTION_ERROR                     1
#   define BAD_ARG_ERROR                       2
#   define COULD_NOT_OPEN_STAT_FILE            3




if ( ($iRet) != 99   )
    {
    my @aMsg = (
                "The dbstatus executable returned an unexpected value",
                "  Expected return value: 99",
                "  Actual return value: " . ($iRet>>8),
                "  For reference, here is the meaning of some bad return values:",
                "    1: the Intex subroutines returned an error (icmo_errdie()); an error msg was printed to STDOUT",
                "    2: bad command line argument",
                "    3: could not open the status file (that dbstatus writes out)",
                );
    if ( uc($hIniFile{'ignore_dbstatus_return'}) eq "Y" )
        {
        AppendLog ( "$func: Return code from dbstatus was detected: $iRet, but will ignore per ignore_dbstatus_return=Y\n" . join ( "\n", @aMsg )  ) ;
        }
    else
        {

        AppendLog ( "ERROR: " . join("\n", @aMsg), "", \@aMsg );

            return (
                "There were internal errors running the dbstatus program; please notify Intex Solutions, Inc",
                "Here is more information:",
                "",
                @aMsg,
                );
         }
    }

possibly_filter_out_dbstatus__lines("$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt", $dbstatus_txt_fn);

# got this far, exe ran ok, results should be in the stat file e.g. log/dbstatus.txt
## version=1.21 (build on 07/20/2001)
## remove_file_cnt=0
## err_file_cnt=17102 (includes remove errors)
## return_code=99 (includes remove errors)
if ( !open ( IN, $dbstatus_txt_fn ) )
    {
    my @aMsg = (
            "After running the dbstatus executable, we could not find its output file",
            "Output file name: $dbstatus_txt_fn",
            );

    AppendLog ( "ERROR: $func: " . join("\n",@aMsg), "", \@aMsg );
    return @aMsg;
    }

my @aLine = <IN>;
close(IN);
AppendLog ("$func: lines from dbstatus output file:\n--------------\n" . join("",@aLine) );

# sample lines from stat file
#     * ------------------
#     * "version=1.04 11/13/99"
#     * "error_msg=xxx"   ..... if have any of these show them
#     * "err_file_cnt=5"  .... if have any of these, tell user so they can ask for a reship
#     * "remove_file_cnt=5"  .... if have any of these, request that user zap these
#     * .... if you get this far with no problems, all is ok ....

# find the err count line and xxx line, or may have an error message
my $iErrCnt = -1;
my $iRemoveCnt = -1;
my $fVersion = -1.0;

foreach my $szLine ( @aLine )
    {
    $szLine =~ s/[\n\r]//g;

    if ( $szLine =~ /^error_msg=(.+)/ )
        {
        return ( "Error from dbstatus: $szLine" );
        }

    if ( $szLine =~ /^err_file_cnt=(\d+)/ ) # e.g. "err_file_cnt=0 (includes remove errors)"
        {
        $iErrCnt = $1;
        }

    if ( $szLine =~ /^remove_file_cnt=(.+)/ )
        {
        $iRemoveCnt = $1;
        }

    if ( $szLine =~ /^version=([\d\.]+)/ )
        {
        $fVersion = $1;
        }
    }

# check version
my $req_version = 1.24;
$req_version = 1.20 if ( $is_unix ) ;

if ( $fVersion == -1 )
   {
        return  ( "ERROR: could not find token \"version\" in status file $dbstatus_txt_fn" );
   }

if ( $fVersion < $req_version )
   {
      return  ( "ERROR: you need at least version $req_version of dbstatus; you have version=$fVersion" );
   }

if ( $iErrCnt == -1 )
   {
        return  ( "ERROR: could not find token \"err_file_cnt\" in status file $dbstatus_txt_fn" );
   }

if ( $iRemoveCnt == -1 )
   {
        return ( "ERROR: could not find token \"remove_file_cnt\" in status file $dbstatus_txt_fn" );
   }

# get the age of the dbstatus file; possibly set warning... cmo_cdu\\cmostat.qa
my @aQaStat = stat($cmostat_qa_fn);          # cmo_cdu\\cmostat.qa
my @aTime = localtime($aQaStat[9]);
my $stamp = sprintf ( "%04d%02d%02d_%02d%02d", $aTime[5] + 1900, $aTime[4] + 1, $aTime[3],   $aTime[2], $aTime[1] );  # #yyyymmdd_hhmm
my $days =  sprintf ( "%.1f", ( time() - $aQaStat[9] ) / (60*60*24)  );
AppendLog ( "$func: QA file: name=$cmostat_qa_fn; stamp=$stamp; age in days=$days" );
print "File=$cmostat_qa_fn; stamp=$stamp\n";
my $max_day = 4;

# possible warning about age of cmo_cdu\\cmostat.qa
my $warning;
$warning = "WARNING: your dbstatus file ($cmostat_qa_fn) is older than $max_day days; age=$days" if ( $days > $max_day );

my @aDbStatusInfo =
    (
     "FYI: The dbstatus QA program uses the input file=$cmostat_qa_fn",
     "which lists all the Intex files that you should have",
     "Autodnld used this command in dbstatus check: cmd=".$szCmd,
     );

# do we have mismatch errors?
# FYI: at bottom of dbstatus.rpt, have line like this: "Number of missing or outdated files  : 17102"
# NOTE: there is an option in .ini file to filter out errors e.g. brokersp.inf
my $mismatch_err = $iErrCnt - $iRemoveCnt;  # error count is remove error plus mismatch errors

if ( $mismatch_err > 0 )
    {


    my $bCmoCusipOnly = CheckIfCmoCusipFileOnly ( "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt" ) ;
    my ( @aMsg ) ;
    if ( $bCmoCusipOnly  )
       {
       AppendLog ( "$func: The only error was for the file cmocusip.inf." );
       @aMsg = (
               "The only error was for the file cmocusip.inf.  You will need to get this file from the Intex website or wait until the next shipment which will include this file."
               ) ;
       return @aMsg;
       }

    if ( defined ( $hIniFile{'save_dbstatus_error_files'}  ) )
       {
       if ( uc($hIniFile{'save_dbstatus_error_files'}) eq "Y" )
          {
          my $szTodayTimeToCopy = stamp_as_yyyymmdd_hhmm ( ) ;
          my $szSrcFile = "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt" ;
          my $szDstFile = "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus_". $szTodayTimeToCopy . ".rpt" ;
          my $szCmd = "$com_spec copy /Y \"$szSrcFile\" \"$szDstFile\"";
          AppendLog ( "$func: Error dbstatus file $szSrcFile saved as $szDstFile" );
          system ( $szCmd ) ;
          }
       }

    my ( $nNumTimeZoneErrors, $nNumOtherErrors ) = CheckIfTimeZoneErrors ( "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt" ) ;
    if ( $nNumTimeZoneErrors > 0  )
       {
       if ( $nNumOtherErrors == 0 )
          {
          $bDoPostFile = ""  ;
          AppendLog ( "$func: All dbstatus errors ($nNumTimeZoneErrors total) are time zone errors. Will not post dbstatus file to ship servers." );
          }
       print "\nOf the errors, $nNumTimeZoneErrors were found to possibly be errors because of time zone issues" ;
       print "\n!!!!!!!!!!!!!!!! To ignore these time zone errors, please insert the line \"dbstatus_check_time=2\" into the file autodnld.ini !!!!!!!!!!!!!!!!!!" ;
       @aMsg = (
               @aMsg,
               "There were discrepancies found by running the dbstatus QA program:",
               "$mismatch_err Intex data file(s) are missing, damaged or stale",
               "Of these errors, $nNumTimeZoneErrors were found to possibly be errors because of time zone issues",
               "!!!!!!!!!!!!!!!! To ignore these time zone errors, please insert the line \"dbstatus_check_time=2\" into the file autodnld.ini !!!!!!!!!!!!!!!!!!",
               "",
               "The deals are listed in this file: $hCmoState{'flavored_log_dir'}$slash"."dbstatus.rpt",
               ) ;
       }
    else
       {
       @aMsg = (
               @aMsg,
               "There were discrepancies found by running the dbstatus QA program:",
               "$mismatch_err Intex data file(s) are missing, damaged or stale",
               "",
               "The deals are listed in this file: $hCmoState{'flavored_log_dir'}$slash"."dbstatus.rpt",
               ) ;
       }
    if (  $bDoPostFile  )
       {
       my ( $bPostError, @aPostErrorMsg ) = PostDbstatusFileToIntex ( "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt" ) ;

       if ( $bPostError )
          {
          @aMsg = (
                  @aMsg,
                  "For a fix-up shipment, please email autodnld_help\@intex.com and attach this file",
                  "We tried to upload the file to Intex automatically, but ran into an error:\nERROR DETAIL:",
                  "",
                  @aPostErrorMsg,
                  "",
                  @aDbStatusInfo,
                  ) ;
          print "\nWe tried to upload the dbstatus.rpt file to Intex but ran into the following error:\n" . join ( "\n", @aPostErrorMsg ) ;
          }
       else
          {
          @aMsg = (   # "Dbstatus file uploaded to Intex", "A new shipment will be processed and posted for download.",
                  @aMsg,
                  "",
                  "!!!!!!!!!!!! This file was uploaded to Intex, The missing/outdated files will AUTOMATICALLY ship out as part of your next regularly scheduled shipment !!!!!!!",
                  ) ;
          if ( scalar ( @aPostErrorMsg ) > 1  )
              {
              my $nNumErrorLines = scalar ( @aPostErrorMsg ) ;
              @aMsg = (
                      @aMsg,
                      "You will receive the standard email notification when this shipment is finished processing",
                      "Upload Error/Warning:\n". join ( "\n", @aPostErrorMsg[1..$nNumErrorLines] ),
                      ) ;

              }
          else
              {
              @aMsg = (
                      @aMsg,
                      ) ;
              }

          @aMsg = (
                  @aMsg,
                  "",
                  @aDbStatusInfo,
                  ) ;
          print "\nDbstatus.rpt was uploaded to the Intex servers.  A new shipment will AUTOMATICALLY be processed and posted"                             ;
          }
       push ( @aMsg, $warning ) if ( defined($warning));
       if ( $nNumTimeZoneErrors > 0 )
          {
          }
       return @aMsg;
       }
   else
       {
       @aMsg = (
                @aMsg,
                "In order to reconcile your database, please email autodnld_help\@intex.com and attach the dbstatus.rpt file which is found in \\autodnld\\log. The missing/outdated files will be included as part of your next regularly scheduled shipment.",
                "FYI: There is an option in Autodnld to automatically upload dbstatus.rpt to Intex, by setting upload_dbstatus=y in autodnld.ini.  Make sure your firewall/security allows files to be uploaded.",
                "",
                @aDbStatusInfo,
                );

       push ( @aMsg, $warning ) if ( defined($warning));
       return @aMsg;
       }
    }

# if have remove count, notify user
if ( $iRemoveCnt )
    {
    my @aMsg =
        (
         "You have some file(s) in your database that should be removed",
         "These files are not supported by Intex anymore",
         "You should have already been informed by Intex about these files",
         "Please consult your account manager if you have any further questions",
         "You can consult the file $hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt for details",
          );

    ComposeAndSendEmail('e06',"Need to remove files from your Intex database", \@aMsg );
    }

# got this far; ran dbstatus and no errors; email user
my @aMsg = @aDbStatusInfo;
push ( @aMsg, $warning ) if ( defined ( $warning ));  # possible warning on age of dbstatus file
ComposeAndSendEmail('e07',"All is OK per dbstatus QA check", \@aMsg ) if ( $szCmoStatFileIn eq "" ) ;
AppendLog ( "$func: finished running and all is OK" );

return ();  # no errors

} # RunDbStatusForCmo

# --------------------- AddUserToDbstatus -- adds user name to the dbstatus file.
sub AddUserToDbstatus
{
my ( $szUserIn, $szFileToAddTo ) = @_ ;
my ( @aDbstatusLines, @aErrMsg ) ;
my $func = "AddUserToDbstatus" ;

my ( $szDbstatusTmp ) = $szFileToAddTo . ".tmp" ;

if ( open ( DBSTATUSOLD, $szFileToAddTo) )
   {
   @aDbstatusLines  = <DBSTATUSOLD> ;
   close DBSTATUSOLD ;
   }

if ( ! rename ( $szFileToAddTo, $szDbstatusTmp ) )
    {
    AppendLog ( "$func: Could not rename $szFileToAddTo to $szDbstatusTmp will not add user to the file" );
    return 1;
    }

my $szTodayYYYYMMDD_HHMM = stamp_as_yyyymmdd_hhmm ( ) ;

my ( $bAddedLine ) ;
if ( open ( NEWDBSTATUS, ">$szFileToAddTo" ) )
    {
    foreach my $szOneLine ( @aDbstatusLines )
        {
        if ( $szOneLine =~ /^\s*\! *STATUS REPORT/ )
           {
           $szOneLine = "!  USER=$szUserIn\n! Time_run=$szTodayYYYYMMDD_HHMM\n" . $szOneLine ;
           $bAddedLine = 1 ;
           }
        print NEWDBSTATUS $szOneLine ;
        }
    if (  $bAddedLine )
       {
       AppendLog ( "$func: Added user to the status report" );
       }
    else
       {
       AppendLog ( "$func: Did not find \"STATUS REPORT\" in the dbstatus file.  Did not add the user name" );
       }
    close NEWDBSTATUS ;
    if ( -e $szFileToAddTo )
        {
        unlink ( $szDbstatusTmp ) ;
        }
    else
        {
        AppendLog ( "$func: After attempting to add the user, the file did not exist.  Will copy back old file before attempt." );
        if ( ! rename ( $szDbstatusTmp, $szFileToAddTo ) )
            {
            AppendLog ( "$func: Could not rename $szDbstatusTmp to $szFileToAddTo " );
            return 1;
            }
        else
            {
            unlink ( $szDbstatusTmp ) ;
            }
        }
    }


} # end AddUserToDbstatus

# ------------------------------------- CheckIfCmoCusipFileOnly ( "$hCmoState{'flavored_log_dir'}$slash" . "dbstatus.rpt" )
sub CheckIfCmoCusipFileOnly
{
my ( $szFileToCheck ) = @_ ;
my ( $bErrorsStarted, $bCmoCusipOnly ) ;


if ( ! open ( DBSTATUS, "$szFileToCheck" ) )
    {
    print ( "Unable to open $szFileToCheck" ) ;
    AppendLog ( "Unable to open $szFileToCheck to check for errors" ) ;
    return ;
    }

my ( @aDbstatusLine ) = <DBSTATUS> ;
close DBSTATUS ;

$bCmoCusipOnly = 0 ;
foreach my $szLine ( @aDbstatusLine )
    {
    $szLine =~ s/[\n\r]//g;
    if ( $szLine =~ /^=END *$|^ *Files You Should Have/i )
        {
        $bErrorsStarted = 1 ;
        next ;
        }
    next if ( ! $bErrorsStarted ) ;
    next if ( $szLine =~ /number of missing/i ) ;
    next if ( $szLine =~ /^\s*$/i ) ;
    next if ( $szLine =~ /--------------/i ) ;

    my ( $szFileName, $szErrType, $szErrMessage ) = split ( /\|/, $szLine ) ;
    $szErrType =~  s/\s//g ;
    $szErrMessage =~ s/^ +| +$//g ;
    if ( $szFileName =~ /cmocusip\.inf/ )
       {
       $bCmoCusipOnly = 1 ;
       }
    elsif ( $szFileName ne "" && $szErrMessage ne "" )
       {
       $bCmoCusipOnly = 0 ;
       last ;
       }
    }

return $bCmoCusipOnly ;

}

# ------------------------------------- PostDbstatusFileToIntex
#
sub PostDbstatusFileToIntex
{
my ( $szDbstatusRptFN ) = @_ ;
my ( $bDoPostFile, @DbstatusLog, $szLastRunDate, $iDaysSinceLastDbstatus ) ;
my ( $bDbstatusFound, @aRemoteDir, @aRemoteDirErr, @aPostErrMsg, $szShipmentNumber ) ;
my ( $bErrorInPost ) = 0 ;

my $func = "PostDbstatusFileToIntex" ;
AppendLog ( "$func(): start" );


my $szTodayYYYYMMDD_HHMM = stamp_as_yyyymmdd_hhmm ( ) ;
my $szTodayYYYYMMDD = substr ( $szTodayYYYYMMDD_HHMM, 0, 8 ) ;

GetRemoteDir
        (
        "/$hIniFile{'user'}/" . $hCmoState{'distrib_word'} . "/.", # e.g. "/tiny_tar/distribtion/."
         \@aRemoteDir,      # return dir listing
         \@aRemoteDirErr,   # possible err msg
         1,                 #ignores errors if not files were found
         );



if ( scalar ( @aRemoteDirErr ) > 0 )
   {
   AppendLog ( "$func: Had error getting dir listing of ship server.  Dbstatus.rpt will not be posted".join ( "\n", @aRemoteDirErr ) );
   @aPostErrMsg = ( "Had error getting dir listing to post dbstatus file to Intex", @aRemoteDirErr );
   return ( 1, @aPostErrMsg ) ;
   }
foreach my $szLine (@aRemoteDir)
    {
    my @aLine = split(/\s+/,$szLine);
    my $szName = $aLine[8];     # cmo_cdi.zip
    $szName=$aLine[1];
    if ( $szName =~ /^shipinfo.(\d+)\./ )
        {
        $szShipmentNumber = $1 ;
        last ;
        }
    }
$szShipmentNumber  =  $szTodayYYYYMMDD  if ( $szShipmentNumber  !~ /\d/ ) ;


@aRemoteDir = ( ) ;
@aRemoteDirErr = ( ) ;
GetRemoteDir
        (
         "/" . $hIniFile{'user'} . "/upload/dbstatus",                # e.g. "/tiny_tar/."
         \@aRemoteDir,      # return dir listing
         \@aRemoteDirErr,   # possible err msg
         1,                 #ignores errors if not files were found
         );

if ( scalar ( @aRemoteDirErr ) > 0 && $aRemoteDirErr[0] !~ /We did not see any files listed on the Intex server/i )
   {
   AppendLog ( "$func: Had error getting dir listing of ./upload/dbstatus ship server.  Dbstatus.rpt will not be posted".join ( "\n", @aRemoteDirErr ) );
   @aPostErrMsg = ( "Had error getting dir listing to post dbstatus file to Intex", @aRemoteDirErr );
   return ( 1, @aPostErrMsg ) ;
   }

my $iMaxRepostDays = 3 ;
my @aLinesError;

foreach my $szLine (@aRemoteDir)
    {
    my @aLine = split(/\s+/,$szLine);
    my $szName = $aLine[8];     # cmo_cdi.zip
    $szName=$aLine[1];
    #if ( $szName =~ /^(2[01]\d\d\d\d\d\d)/i )
    if ( $szName =~ /^$szShipmentNumber/i && $szShipmentNumber ne ""  )  ## non -serialized will always be uploaded.
       {
       @aPostErrMsg = ( "One dbstatus report was already uploaded for this shipment number: $szShipmentNumber", "Only one upload is allowed per shipment", "You will need to email the file to autodnld_help\@intex.com" );
       return ( 1, @aPostErrMsg ) ;
       }
    }

my $sRemoteFileName="/" . $hIniFile{'user'} . "/upload/dbstatus/".$szShipmentNumber."_".$szTodayYYYYMMDD_HHMM."_dbstatus.rpt";
my ($sErr,$sDownloadedFileName)=HTTPGET($sRemoteFileName,'uploadstatus',$szDbstatusRptFN);
if($sErr)
{
   @aLinesError=("$func: Error returned from HTTPGET: $sErr","Please try to post it again by running autodnld with the command line \"-dbstatus_upload\".  Or you can email autodnld_help\@intex.com and attach the file ".$hCmoState{'flavored_log_dir'}.$slash."dbstatus.rpt.");
   return(1,@aLinesError);
}
my $sFileDownload=IO::File->new($sDownloadedFileName);
if (!defined $sFileDownload)
{
   @aLinesError=("$func: Error","Can't open file $sDownloadedFileName. This file will tell up the status of upload");
   return(1,@aLinesError);
}
AppendLog("$func: decode returned status...");
#simply check the status code returned
my $ReError;
while(<$sFileDownload>){
   if($_=~/Status:(\d+)/)
   {
      $ReError=$1;
      last
   }
}
$sFileDownload->close();
return ( 0, "$szShipmentNumber"."_".$szTodayYYYYMMDD_HHMM."_dbstatus.rpt" ) if ($ReError==100);
@aLinesError=("$func:dbstatus upload error","Returned stauts:$ReError","Please try to post it again by running autodnld with the command line \"-dbstatus_upload\".  Or you can email autodnld_help\@intex.com");
return (1,@aLinesError);

} #end PostDbstatusFileToIntex



###########-----------------------Top the list from the file and save into another list-------------------
# return error message if one of the file failed to be opened
# $sLineNum start from 1 to -1, -1 is the whole file to be coped into another one.
sub TopFileList {
   my ($sOrigFile,$sSaveFile,$sLineNum)=@_;

   open ( SHIPLIST, $sOrigFile ) ||return "Can't open $sOrigFile for read";
   my @aAllList=<SHIPLIST>;
   close SHIPLIST;

   open ( SHIPLISTSAVE, ">>$sSaveFile" )||return "Can't write $sSaveFile";
   foreach (@aAllList[0..($sLineNum-1)]) {
      print SHIPLISTSAVE $_;
   }
   close  SHIPLISTSAVE;
#copy the rest into a tmp file, then rename it.
   open ( SHIPLISTNEW, ">$sOrigFile.tmp" )||return "Can't write $sOrigFile.tmp";
   foreach (@aAllList[$sLineNum..$#aAllList]) {
      print SHIPLISTNEW $_;
   }
   close  SHIPLISTNEW;
   rename("$sOrigFile.tmp",$sOrigFile);
   return "";
}##end of TopFileList



#-------------------------------------Compare file list and remove ones already downloaded, Donelist is a disk file in this case
#return error message if one of the file failed to be opened
sub CompareAndRemove {
   my ($szShipListFile,$szShipListDone)=@_;
   my %hDone=();

   open ( SHIPDONE, $szShipListDone )||return "Can't open $szShipListDone" ;
   while (my $sLine=<SHIPDONE>) {
      chomp($sLine);
      $hDone{$sLine}=1;
   }
   close(SHIPDONE);
   open ( SHIPLISTNEW, ">$szShipListFile.tmp" )||return "Can't write $szShipListFile.tmp";
   open ( SHIPLIST, $szShipListFile ) ||return "Can't open $szShipListFile";
   while (my $sLine=<SHIPLIST>) {
      #shiplisdone only has file name on ship server
      my ($sFnServer,$sLocaFn,$sFSize)=split(/\|/,$sLine);
      next if (defined($hDone{$sFnServer}));
      print SHIPLISTNEW $sLine;
   }
   close(SHIPLIST);
   close(SHIPLISTNEW);
   rename("$szShipListFile.tmp",$szShipListFile);

   return "";

}###end of CompareAndRemove

#-------------------------------------CompareAndRemoveMem-----------------------------------------
#-------------------------------------Compare file list and remove ones already downloaded
#return error message if one of the file failed to be opened
sub CompareAndRemoveMem {
   my ($szShipListFile,
       $szDone,
       $szShipListDoneLastReg,      #if defined, e.g., non-intraday, will save the first unsuccessful file name in the file.
       )=@_;

   #szDone is a pointer for hash
   my $func="CompareAndRemoveMem";
   #if in the following scenario,
   #if file1,2,3,4,5,6..., file3 not OK, $sMyLastSuccessFile should take file2, file3 shold be the first file to be downloaded again.
   #if file1,....filen all OK, $sMyLastSuccessFile should take filen. So use the following two variable to track
   my $sMyLastSuccessFile;
   my $sHadFileMissing;
   open ( SHIPLISTNEW, ">$szShipListFile.tmp" )||return "Can't write $szShipListFile.tmp";
   open ( SHIPLIST, $szShipListFile ) ||return "Can't open $szShipListFile";
   while (my $sLine=<SHIPLIST>) {
      #shiplisdone only has file name on ship server
      my ($sFnServer,$sLocaFn,$sFSize)=split(/\|/,$sLine);
      if (defined($szDone->{$sFnServer})){
         #keep track last success file being downloaded
         $sMyLastSuccessFile=$sFnServer if (!defined($sHadFileMissing));
         next;
      }
      print SHIPLISTNEW $sLine;
      $sHadFileMissing=1;
   }
   close(SHIPLIST);
   close(SHIPLISTNEW);
   rename("$szShipListFile.tmp",$szShipListFile);

   if (defined($szShipListDoneLastReg)&&defined ($sMyLastSuccessFile)){
      open(SHIPLISTBREAK,">$szShipListDoneLastReg")||AppendLog("$func: can't write to $szShipListDoneLastReg");
      print SHIPLISTBREAK $sMyLastSuccessFile;
      close SHIPLISTBREAK;
      AppendLog("$func: wrote last successful downloaded filename $sMyLastSuccessFile to $szShipListDoneLastReg");
   }

   return "";

}###end of CompareAndRemoveMem


#-------------------------------------splitshiplist----------------------------------
#return array of spplitted list
# parameter passed inside:
# $szShipListfile: BIG list file downloaded for this shipment
# $szShipListLastReg: last good downloaded file in this shipment
# $szShipListFailedLastReg: failed download due to file missing errors on servers for this shipment
# We push the $szShipListFailedLastReg onto top of the list.
# Add files not downloaded last time due to other reasons, but discount the files already inside $szShipListFailedLastReg in case those files were
# the last in the list and we could make them show up twice.
sub splitshiplist {
   my ($szShipListfile,$szShipListLastReg,$szShipListFailedLastReg)=@_;
   my @aSplittedList;
   my $sDoneFileName;

   my $func="Splitshiplist";
   my %hFailedFile=();
   if ((defined $szShipListFailedLastReg)&& (-e $szShipListFailedLastReg)) {
      #hopefully the failed list is short enough and not exceeding apache file size limit of 60 M
      push(@aSplittedList,$szShipListFailedLastReg);
      if (open(FAILLIST,$szShipListFailedLastReg)){
         while(my $sLine=<FAILLIST>)
         {
            chomp($sLine);
            $hFailedFile{$sLine}=1;
         }
         close(FAILLIST);
         AppendLog("$func: Finised reading last failed download file list from $szShipListFailedLastReg");
      }
      else {
         return "$func: can't open $szShipListFailedLastReg";
      }
   }
   if ((defined ($szShipListLastReg))&&(-e $szShipListLastReg))  {
      # we have a last crash file, we can remove the file from the list
     if (open(SHIPLIST,$szShipListLastReg)){
        $sDoneFileName=<SHIPLIST>;
        chomp($sDoneFileName);
        close(SHIPLIST);
        AppendLog("$func: found last successful downloaded file: $sDoneFileName from $szShipListLastReg");
     }
     else {
        return "$func: can't open $szShipListLastReg";
     }
   }
   open ( SHIPLIST, $szShipListfile ) ||return "Can't open $szShipListfile";
   my $sFilecnt=0;
   my $sFileLstCnt=1;
   my $tmpSplitList=$szShipListfile;
   $tmpSplitList=~ s/\.([a-zA-Z]+)$/$sFileLstCnt\.$1/; #replace the shiplist.txt with shiplist1.txt as such
   open(SPLITLIST,">$tmpSplitList")||return "Can't write $tmpSplitList";
   my $sTotalSize=0;
   my $sQAFlag=0; #make sure that we can find the $sDoneFileName. There is a crash list, then we got to have something in splitted file.
   my $sFileCntMax=50000;
   my $sTotalSizeMax=2000000;
   $sFileCntMax=$hIniFile{'filecntmax'} if (defined $hIniFile{'filecntmax'} && $hIniFile{'filecntmax'}=~/^\d+$/);
   $sTotalSizeMax=$hIniFile{'shiplistsizemax'} if (defined $hIniFile{'shiplistsizemax'} && $hIniFile{'shiplistsizemax'}=~/^\d+$/);
   while (<SHIPLIST>)
      {
         my $sLine=$_;
         chomp($sLine);
         next if (defined($sDoneFileName)&&($sLine!~ /$sDoneFileName/));
         $sQAFlag=1;
         if (defined($sDoneFileName)) #we can kill it now.
         {
            undef($sDoneFileName);
            next; #starting from next one, we need download
         }
         next if (defined $hFailedFile{$sLine});
         my ($sSourceFn, $sOutputFn, $sSize) = split(/\|/, $sLine);
         $sTotalSize +=$sSize; #size is supposed in KB
         if (($sFilecnt>$sFileCntMax) || ($sTotalSize>$sTotalSizeMax)){
            close(SPLITLIST);
            push(@aSplittedList,$tmpSplitList);
            $sTotalSize=$sSize;
            $sFilecnt=0;
            #in case there are other numbers prior to file count
            my $sFileLstCnttmp=$sFileLstCnt+1;
            $tmpSplitList=~ s/$sFileLstCnt\.([^\/\s]+)$/$sFileLstCnttmp\.$1/; #replace the shiplist.txt with shiplist1.txt as such
            $sFileLstCnt=$sFileLstCnttmp;
            open(SPLITLIST,">$tmpSplitList")||return "$func: Can't write $tmpSplitList";
         }
         $sFilecnt++;
         print SPLITLIST $sLine."\n";

      }
   close(SHIPLIST);
   close(SPLITLIST);
   return "$func: can't find file name $sDoneFileName in $szShipListfile" if ($sQAFlag==0);
   push(@aSplittedList,$tmpSplitList);

   return ("",\@aSplittedList);

}     ###end of splitshiplist



# ------------------------------------- CheckIfTimeZoneErrors
#
sub CheckIfTimeZoneErrors
{
my ( $szDbstatusFile ) = @_ ;
my ( $bErrorsStarted ) ;
my ( $nNumTimeZoneErrors ) = 0 ;
my ( %hErrorByType, $nNumOtherErrors, $nNumTotalErrors ) ;

if ( ! open ( DBSTATUS, "$szDbstatusFile" ) )
    {
    print ( "Unable to open $szDbstatusFile" ) ;
    AppendLog ( "Unable to open $szDbstatusFile to check for Time Zone errors" ) ;
    return ;
    }

my ( @aDbstatusLine ) = <DBSTATUS> ;
close DBSTATUS ;

foreach my $szLine ( @aDbstatusLine )
    {
    $szLine =~ s/[\n\r]//g;
    if ( $szLine =~ /^=END *$/ )
        {
        $bErrorsStarted = 1 ;
        next ;
        }
    next if ( ! $bErrorsStarted ) ;

    my ( $szFileName, $szErrType, $szErrMessage ) = split ( /\|/, $szLine ) ;
    $szErrType =~  s/\s//g ;
    $szErrMessage =~ s/^ +| +$//g ;

    if ( $szErrType eq "DATETIME" )
       {
       my ( $szDateShould, $szTimeShould, $szDateOnPc, $szTimeOnPc )  ;
       my ( @aErrMessage ) =  split ( / +/, $szErrMessage ) ;
       if ( scalar ( @aErrMessage ) == 4 )
          {
          $szDateShould = $aErrMessage[0] ;
          $szTimeShould = $aErrMessage[1] ;
          $szDateOnPc   = $aErrMessage[2] ;
          $szTimeOnPc   = $aErrMessage[3] ;
          }
       else
          {
          my ( $nNumErrMessage ) = scalar ( @aErrMessage ) ;
          my ( $iCount ) ;
          for ( $iCount = 0 ; $iCount < $nNumErrMessage ; $iCount ++ )
              {
              if ( $aErrMessage[$iCount] =~ /\// )
                 {
                 if ( $szDateShould eq "" )
                     {
                     $szDateShould = $aErrMessage[$iCount] ;
                     }
                 else
                     {
                     $szDateOnPc   = $aErrMessage[$iCount] ;
                     }
                 next ;
                 }
              if ( $aErrMessage[$iCount] =~ /\:/ )
                 {
                 if ( $szTimeShould eq "" )
                     {
                     $szTimeShould = $aErrMessage[$iCount] ;
                     }
                 else
                     {
                     $szTimeOnPc   = $aErrMessage[$iCount] ;
                     }
                 next ;
                 }
              }
          }
       my $szDate1 = $szDateShould ;
       my $szDate2 = $szDateOnPc ;

       $szDate1 =~ /(\d\d)\/(\d\d)\/(\d\d)/ ;
       $szDate1 = "20".$3.$1.$2 ;

       $szDate2 =~ /(\d\d)\/(\d\d)\/(\d\d)/ ;
       $szDate2 = "20".$3.$1.$2 ;
       my $szDaysBetween = DaysBetween ( $szDate1, $szDate2) ;

       my ( $szTime1 ) = $szTimeShould ;
       $szTime1 =~ s/\:// ;

       my ( $szTime2 ) = $szTimeOnPc ;
       $szTime2 =~ s/\:// ;

       my ( $szDiffTime ) = $szTime1 - $szTime2 ;
       $szDiffTime =~ /(\d?\d)$/ ;
       my $szLastTwoDigits = $1 ;

       if ( ( $szLastTwoDigits < 2 || $szLastTwoDigits > 98 ) && abs ( $szDaysBetween ) < 2 )
          {
          $nNumTimeZoneErrors ++ ;
          }
       else
          {
          $nNumOtherErrors ++ ;
          $hErrorByType{$szErrType} ++ ;
          }
       }
    else
       {
       $nNumOtherErrors ++ ;
       $hErrorByType{$szErrType} ++ ;
#       print "\n $szLine" ;
       }
    }
$nNumTotalErrors = $nNumOtherErrors + $nNumTimeZoneErrors ;

AppendLog ( "Error Report for Dbstatus.rpt:" ) ;
AppendLog ( "Number of Time Zone Errors: $nNumTimeZoneErrors of $nNumTotalErrors" ) ;
foreach my $szOneKey ( sort keys %hErrorByType )
    {
    AppendLog "Number of $szOneKey Errors: $hErrorByType{$szOneKey} of $nNumTotalErrors" ;
    }
return ( $nNumTimeZoneErrors, $nNumOtherErrors ) ;

}  # end CheckIfTimeZoneErrors

#----------------------------------------start of chunk_decoding
#
#
sub chunk_decoding {
   my ($sock, $sDstLocation)=@_;
   my $pDoneList;
   my $szThisChunkSize=0;
   my $szLocalFile='';
   my $szFileLeftOver=0;
   my $szContentFlag=0;
   my $starttick=time(); # use to timeout. will reset if any string look for is found, will check in each while loop
   my $sTimeOut=300; #initial timeout to be 6 minutes
   $sTimeOut=$hIniFile{timeout} if (defined($hIniFile{timeout}));
   my $func="chunk_decoding()";
   my $bChunk = 0;
   my $bReadHeader = 1;

   my $iHttpVerbose = LogThis('http') || 0;

   while (<$sock>)
       {
             print $_ if ( $iHttpVerbose > 0 );
             next if ( $_ =~ /^HTTP/ );
      #pass thru all the header information
             $bChunk = 1 if ( $_=~/Transfer-Encoding: chunked/i );
             last if ($_ !~ /^\S+:\s+.+/);
      #pass back errors
             if($_=~/Error:(\d+)/)
             {
                my $ReError=$1;
                return($ReError,$pDoneList,$szFileLeftOver);
             }
             if ((time()-$starttick)>$sTimeOut) {
                #error code 1010
                return(2010,$pDoneList,$szFileLeftOver);
             }

       }
    $starttick=time(); #reset time
    my $sFileHandle;
    while(1){
        if ($szThisChunkSize==0) {
           if ( $bReadHeader > 0 )
               {
               $bReadHeader = 0;
               }
           else
               {
               <$sock>;
               }
           if ( ! $bChunk ) {
              $szThisChunkSize = 2000000000; ## assume 2 GB max
           } else {
             #need chunk information which is between \r\n size \r\n so got to read twice.
             # So the chunk format:
             # \r\n chunklength(4 bytes)\r\n load of chunklength-1 \n
             # \r\n chunklength(4 bytes)...
             # in hex format:
             # 0D0A0D0D0A########0D0D0A
             my $szHexNum=<$sock>;
             print "\nHex=".$szHexNum if ( $iHttpVerbose > 0 );
             chomp($szHexNum);
             $szThisChunkSize=hex($szHexNum); #in bytes
             print "chunk=".$szThisChunkSize."\n" if ( $iHttpVerbose > 0 );
             if ($szThisChunkSize==0) {

                return (0,$pDoneList,$szFileLeftOver); #Server could end the chunck anytime.
                }
             }
          }
       elsif ($szLocalFile eq '')
          {
          #Need to search file name
            while (<$sock>) {
               $szThisChunkSize -=length($_);
               if ($_ =~ /File-Id:\s*(\S+\.)(zip|txt|inf|qa|Z|\d{12})/i){
                  my $szFileOnShipServer=$1.$2;
                  $starttick=time(); #reset timeout
                  $szLocalFile = $hIniFile{'temp_download_subdir'} . $slash.$szFileOnShipServer;
                  FixSlashes(\$szLocalFile,"native");
                  $szLocalFile=$sDstLocation if (defined $sDstLocation);
                  #push the list to uncompress later
                  push(@$pDoneList,$szFileOnShipServer);
                  print $szFileOnShipServer."\n" if ( $iHttpVerbose > 0 );
                  $sFileHandle=IO::File->new("> $szLocalFile");
                  if (!defined $sFileHandle){
                     AppendLog("$func: can't open $szLocalFile for write");
                     return(2101,$pDoneList,$szFileLeftOver);
                  }
                  last;
               }
               elsif ($_ =~ /^Error:\s*(\d+)/i) {
                return($1,$pDoneList,$szFileLeftOver);
               }
               last if $szThisChunkSize==0; #make sure we are in time to get next chunk length

               if ((time()-$starttick)>$sTimeOut) {
                  #error code 1011
                  return(2011,$pDoneList,$szFileLeftOver);
               }
            }
          if ( $szLocalFile eq '' && $szThisChunkSize > 0 )
            {
             return (0,$pDoneList,$szFileLeftOver); #Server could end the chunck anytime.
            }
          }
       elsif ($szFileLeftOver==0){
          while (<$sock>) {
             $szThisChunkSize -=length($_);
             if($_ =~ /^Content-size:\s*(\d+)/i)
             {

                #Get file length
                $szFileLeftOver=$1; #this size is in decimal.
                $starttick=time(); #reset time
                print "File Size=".$szFileLeftOver if ( $iHttpVerbose > 0 );
                #need to read another /n before proceed, but not sure whether we are reaching end of chunk
                #no document on whether this is allowed or not. So we need to consider this case
                #
                if ($szThisChunkSize>0) {

                <$sock>;
                $szThisChunkSize -=1;
                }
                else {
                   # we need to remember to read extra /n before we grab content
                   $szContentFlag=1;
                }
                last;
             }
             elsif ($_ =~ /^Error:\s*(\d+)/i) {
                return($1,$pDoneList,$szFileLeftOver);
             }
             last if $szThisChunkSize==0; #make sure we are in time to get next chunk length

             if ((time()-$starttick)>$sTimeOut) {
                #error code 1012
                return(2012,$pDoneList,$szFileLeftOver);
             }
          }
       }
       elsif ($szThisChunkSize>0) {
          #got all the information needed
          if ($szContentFlag==1) {
             #there is an extra /n need to be read after content size, left over from previous chunk
             <$sock>;
             $szThisChunkSize -=1;
             $szContentFlag=0; #reset the flag
          }

          #Each chunk always ended with a \n(0x0a) before next chunk length, 0x0A is part of the contents package.

          print "Left Over Chunk(ThisChunkSize)=".$szThisChunkSize."\n" if ( $iHttpVerbose > 0 );
          print "Left Over file=".$szFileLeftOver."\n" if ( $iHttpVerbose > 0 );
          #grab now
          binmode($sock);
          binmode($sFileHandle);
          my $szSizeToGrab=($szThisChunkSize<$szFileLeftOver)?$szThisChunkSize:$szFileLeftOver;
          my $szBuf;
          #easy, simply grab all and do next chunk, due to either internet connection or window
          #buffering, we may not grab all at once. So do a loop and append to $szBuf.
          # Bear in mind, read may block the port.
          # Since this is grabbing from a file, it should be safe to do it once.
          #my $tmpSizeToGrab=$szSizeToGrab;
          #while ($tmpSizeToGrab>0) {
          #   my $szTotalByte=$sock->read($szBuf,$tmpSizeToGrab,length($szBuf));
          #   $tmpSizeToGrab-=$szTotalByte;
          #  }
          my $szTotalByte=$sock->read($szBuf,$szSizeToGrab);
          print "success in reading:".$szTotalByte." bytes to buffer.\n" if ( $iHttpVerbose > 0 );
          my $stmp=syswrite($sFileHandle,$szBuf);
          print "success in writing:".$stmp." bytes to $szLocalFile\n" if ( $iHttpVerbose > 0 );
          #$sock->read($szBuf,$szSizeToGrab);
          #syswrite($sFileHandle,$szBuf,$szSizeToGrab);
          $szFileLeftOver-=$szTotalByte;
          $szThisChunkSize-=$szTotalByte;

          print "Left Over Chunk(ThisChunkSize)=".$szThisChunkSize."\n" if ( $iHttpVerbose > 0 );
          print "Left Over file=".$szFileLeftOver."\n" if ( $iHttpVerbose > 0 );

          if ($szFileLeftOver==0) {
             undef $sFileHandle;
             $szLocalFile='';
          }
          elsif (($szFileLeftOver>0)&&($szThisChunkSize>0)) {
             #chunk ended unexpectedly.
             undef $sFileHandle;
             return(2015,$pDoneList,$szFileLeftOver);
          }
          elsif (($szFileLeftOver <0 )||($szThisChunkSize<0)) {
             #error code 1013
             return(2013,$pDoneList,$szFileLeftOver);
          }
       }

       if ((time()-$starttick)>$sTimeOut) {
          #error code 1010
          return(2014,$pDoneList,$szFileLeftOver);
       }
      }

}########END OF chunk_decoding

# ------------------------------------- DaysBetween
#   -calculates the number of days between two yyyymmdd's
#

sub DaysBetween
{
my ( $szDate1, $szDate2 ) = @_ ;

my ( $szYYYY1, $szMM1, $szDD1 ) ;
my ( $szYYYY2, $szMM2, $szDD2 ) ;
my ( $szNegString, $iStep1, $iStep2, $szTempMM, $szTempYYYY, $szDays, $bLY, $iMonths, $bStart, $bEnd ) ;

if ( $szDate1 < $szDate2 )
   {
   $szNegString = "-" ;
   my $szTempHolder = $szDate1 ;
   $szDate1 = $szDate2 ;
   $szDate2 = $szTempHolder ;
   }

$szYYYY1               = substr ( $szDate1, 0, 4 ) ;
$szTempYYYY = $szYYYY2 = substr ( $szDate2, 0, 4 ) ;

$szMM1             = substr ( $szDate1, 4, 2 ) ;
$szTempMM = $szMM2 = substr ( $szDate2, 4, 2 ) ;
$szMM1 =~ s/^0// ;
$szMM2 =~ s/^0// ;

$szDD1 = substr ( $szDate1, 6, 2 ) ;
$szDD2 = substr ( $szDate2, 6, 2 ) ;
$szDD1 =~ s/^0// ;
$szDD2 =~ s/^0// ;

if ( $szYYYY1 == $szYYYY2 )
    {
    $bLY = LeapYear2 ( $szYYYY1 ) ;
    if ( $szMM1 == $szMM2 )
        {
        $szDays = $szDD1 - $szDD2 ;
        }
    else
        {
        for ( $iStep1 = 0 ; $iStep1 <= ($szMM1 - $szMM2 ) ; $iStep1++ )
            {
            if ( $iStep1 == 0 )
                {
                $szDays = $aDAYSPERMONTH[$szMM2-1] - $szDD2 ;
                if ( $aDAYSPERMONTH[$szMM2-1] == 28  && $bLY )
                    {
                    $szDays++;
                    }
                }
            else
                {
                $szTempMM ++     ;
                if ( $szTempMM == $szMM1 )
                   {
                    $szDays += $szDD1 ;
                   }
                else
                   {
                   $szDays += $aDAYSPERMONTH[$szTempMM-1]  ;
                   if ( $aDAYSPERMONTH[$szTempMM-1] == 28  && $bLY )
                       {
                       $szDays++;
                       }
                   }
                }
            }
        }
    }
else
    {
     for ( $iStep2 = 0 ; $iStep2 <= ($szYYYY1 - $szYYYY2 ) ; $iStep2++ )
         {
         if ( $iStep2 == 0 )
            {
            $iMonths = 12 - $szMM2 ;
            $bStart  = 1 ;
            }
         elsif (  $szYYYY1 == $szTempYYYY  )
            {
            $iMonths = $szMM1 ;
            $bStart  = 0 ;
            $bEnd    = 1 ;
            }
         else
            {
            $szDays += 365 ;
            $szDays ++ if ( LeapYear2 ( $szTempYYYY ) ) ;
            $szTempYYYY++ ;
            $bStart  = 0 ;
            next ;
            }
         for ( $iStep1 = 0 ; $iStep1 <= $iMonths ; $iStep1++ )
             {
             if ( $iStep1 == 0 && $bStart )
                 {
                 $szDays = $aDAYSPERMONTH[$szMM2-1] - $szDD2 ;
                 if ( $aDAYSPERMONTH[$szMM2-1] == 28  && LeapYear2 ( $szTempYYYY )  )
                     {
                     $szDays++;
                     }
                 }
             else
                 {
                 if ( ( $szTempMM == $szMM1 ) && $bEnd )
                    {
                     $szDays += $szDD1 ;
                    last ;
                    }
                 else
                    {
                    $szDays += $aDAYSPERMONTH[$szTempMM-1]  ;
                    if ( $aDAYSPERMONTH[$szTempMM-1] == 28  && LeapYear2 ( $szTempYYYY ) )
                        {
                        $szDays++;
                        }
                    }
                 $szTempMM ++     ;
                 }
             }
         $szTempMM  = 1 ;
         $szTempYYYY++  ;
         }
    }
return  $szNegString.$szDays ;
} ##### end DaysBetween


# ------------------------------------- LeapYear2
#    -used by DaysBetween with leap year stuff.
#
#
sub LeapYear2
{
my ( $false ) = ( 0 == 1 );
my ( $true  ) = ( 1 == 1 );
           my( $YYYY ) = ( @_ );
           my( $leapYear, $YY ) = ( $false, 0 );

           $YY = $YYYY % 100;


           # Now see if a leap year - i think these are the rules
           # One computer calendar sez 2000 is a leapyear and i remember
           # something about divisable by 100 and 400...

           if ( ( $YY % 4 ) == 0 ) {
                      $leapYear = $true;
           }
           if ( ( $YYYY % 100 ) == 0 ) {
                      $leapYear = $false;
           }
           if ( ( $YYYY % 400 ) == 0 ) {
                      $leapYear = $true;
           }
           return ( $leapYear );
} #end LeapYear2


# ------------------------------------- CheckDiskRoomAndPullShipment
# Check for disk room first; if OK, download cdi/cdu set
# Called for one shipment e.g. "last2" for one flavor e.g. "cmodata" (useful globals have been loaded)
# Caller has already done eot.txt stuff

# We email if things are going OK (if error, we return error list and do NOT email)
#   We have already emailed if we pulling some older shipments
#   Email when you start
#   Email when you finish, success or failure

# note globals used: %hCmoState, %::hCmoShipState

# Return list of error info, or empty list

sub CheckDiskRoomAndPullShipment
{
my(
    $paMsgHeader,   # msg header e.g.
                   # "CMO data subdir=$szFullDirPath" );
                   # "Cdi files unpacked to cdi dir=$szCmoCdiDir" );
                   # "Cdu files unpacked to cdu dir=$szCmoCduDir" );
    $phCmo,  # all kinds of info
    ) = @_;

my ( $szErrMsg,  $szFile );
my ( @aErrRet, @aMsg, $szPrefix, $szRet );
my ( $szEmailOkSubject, $szEmailErrSubject, $szEmailStartSubject );
my ( @aErrMsg, @aOkMsg, @aStartMsg, @aThisMsg );

my $func = "CheckDiskRoomAndPullShipment";

AppendLog ( "$func(); start" );

# compose email subjects we may need later
$szEmailStartSubject = "Starting to download $phCmo->{'descr'}";
$szEmailOkSubject = "Finished downloading $phCmo->{'descr'}";
$szEmailErrSubject = "Error downloading $phCmo->{'descr'}";

if ( $hCmoState{'cmo_flavor'} ne $hCrntEnv{'cmodata_keyword'} )
    {
    $szEmailStartSubject .= " [".$hCmoState{'cmo_flavor'}."]";
    $szEmailOkSubject .= " [".$hCmoState{'cmo_flavor'}."]";
    $szEmailErrSubject .= " [".$hCmoState{'cmo_flavor'}."]";
    }

# start email body text we may need later
@aStartMsg = ( "Data was dated $phCmo->{'shipment_stamp'}" );
@aOkMsg =    ( "Data was dated $phCmo->{'shipment_stamp'}" );
@aErrMsg =   ( "Data was dated $phCmo->{'shipment_stamp'}" );

# tell customer what we are up to
print "---- Pull $phCmo->{'descr'} dated $phCmo->{'shipment_stamp'}";

if ( $hCmoState{'cmo_flavor'} eq $hCrntEnv{'cmodata_keyword'} )
    {
        print "\n";
    }
else
    {
        print " ($hCmoState{'cmo_flavor'})\n";
    }

# pull shipinfo file, unpack it, read sif file, decide on disk room needed, see if we have it
# We set file-retry to 2 ... default is 0; acceptable range is 0..2; worker may force retries lower based on ini file setting
# return error inof list if error
$szErrMsg = DownloadShipInfoAndCheckDiskSpace
        (
         $phCmo,
         );

if ( $szErrMsg ne "" )
    {
    return ( "$func(): had error pulling ship info file", "Debug info from DownloadShipInfoAndCheckDiskSpace():", $szErrMsg );
    }

# now we have SIF file in global; can add it to pending start and to pending OK email msg
push ( @aStartMsg, " ", "Shipping information file is as follows:", @::aSIFFile );
push ( @aOkMsg, " ", "Shipping information file is as follows:", @::aSIFFile );

# we are about to start pulling the big stuff; email user that are starting
if ( $hIniFile { 'minimal_email' } eq "N" )
    {
    ComposeAndSendEmail( 'e09', $szEmailStartSubject, \@aStartMsg );
    }

@aThisMsg = HTTPDownLoadSet
    (
    $phCmo,
    );

if ( scalar(@aThisMsg) )
    {
    return ( "$func(): had trouble downloading data file, or unpacking it", "Debug info from HTTPDownLoadSet():", @aThisMsg );
    }

# got this far; all is well; add line to tracking file (always in main log subdir)
# Careful: if special cmo flavor, has leading prefix e.g.  "[flash]"
#   line may have prefix e.g. "[flash]"
#   pass in max size of file; if have multiple flavors, need to save more lines (one client has 9 flavors
if ( $hCmoState{'cmo_flavor'} eq "cmodata" )
    {
    $szPrefix = "";
    }
else
    {
        $szPrefix = "[$hCmoState{'cmo_flavor'}]";   # e.g. "[flash]"
    }
#Successful download will remove the last DoneList file.
my $sDoneListReg=$hCmoState{'flavored_log_dir'}.$slash."shiplistDone_".$phCmo->{"ShipTimeStamp"}.".txt";
AppendLog("$func: Remove file $sDoneListReg if existing and add $phCmo->{'shipment_stamp'} to track file. ");
unlink($sDoneListReg) if (-e $sDoneListReg);
AppendLog("Warning: $func can't remove file: $sDoneListReg") if (-e $sDoneListReg);

$szRet = AddLineToTrackingFile ( $hCmoState{'tracking_file'}, "$szPrefix$phCmo->{'shipment_stamp'}", 1 );

if ( $szRet ne "" )
    {
        @aMsg = (@$paMsgHeader, "", "Error saving line to tracking file: $szRet" );
        ComposeAndSendEmail ( 'e11', "Error in tracking file", \@aMsg );
    }

DropMessageViaHTTP("Autodnld_Shipment_".$phCmo->{"ShipTimeStamp"});
# if we pulled current shipment, check for dbstatus.qa file
# will return one or more lines of error if problem
# if ran it OK, caller will email user to that effect
# NOTE: if have db status error, do not return an error; customer may have multiple cmo flavors
if ( $phCmo->{'path_segment'} eq "" )
    {
    @aErrRet = RunDbStatusForCmo(  );

     if ( scalar(@aErrRet ) )
        {
         @aMsg =  ( @$paMsgHeader, " ", @aErrRet );
         ComposeAndSendEmail ( 'e12', "Error in db status check", \@aMsg );
        }
    }


# email that a cmo was pulled
if ( $hIniFile { 'minimal_email' }  eq "N" )
    {
    ComposeAndSendEmail( 'e13', $szEmailOkSubject, \@aOkMsg);
    }

# got this far: return no error
return ();

} # CheckDiskRoomAndPullShipment


# ------------------------- KeepBuildingInitialCmoTrackFile
# We are running in special capture mode; add lines to CMO tracking file.
# Only called from one place.
# Caller zapped any existing file for us; we just append.
# If have flavored cmodata, need prefix like [flash]

sub KeepBuildingInitialCmoTrackFile
{
   my (
       $paLocalFile,   # fully pathed local eot files; may be log subdir, may be in flavored subdir under log
       ) = @_;

   my ( $szFile, $szLine, $szCmoFlavor, $szOut );

   $szCmoFlavor = $hCmoState{'cmo_flavor'};
   AppendLog ( "KeepBuildingInitialCmoTrackFile(): start; flavor=$szCmoFlavor" );
   AppendLog ( "Add the following lines to the CMO tracking file $hCmoState{'tracking_file'}:", 1 );
   open ( OUT, ">>$hCmoState{'tracking_file'}" );

   foreach $szFile ( @$paLocalFile )
   {
      if ( defined(open ( IN, $szFile )))
      {
         $szLine = <IN>;
         close(IN);
         $szOut = $szCmoFlavor eq "cmodata" ? $szLine : ("[" . $szCmoFlavor . "]" . $szLine);
         print OUT $szOut;
         print "  $szOut";
      }
   }

   close(OUT);

   return 0;

} # KeepBuildingInitialCmoTrackFile


# ------------------------- FindEotInDirListing
# look for a line that has eot.txt or eot.NNNNNN.txt; if none, return undef
# return the filename e.g. "eot.txt" or "eot.NNNNNN.txt"
sub FindEotInDirListing
{
   my ( @aLine ) = @_;    # no CRLF to worry about

   my ( $szLine, $szFile );

   # sample lines:
   #    "d---------   1 owner    group               0 Aug  7  1998 distribution"
   #    "----------   1 owner    group          918358 May 25  1998 tiny_tar.zip"
   #         0        1   2        3               4    5   6    7      8

   foreach $szLine ( @aLine )
   {
      $szFile = (split(/ +/,$szLine))[8];
      #Full http, format  is : UTC filename
      $szFile=(split(/ +/,$szLine))[1];

      if ( !defined($szFile))
      {
         next;
      }

      if ( $szFile eq "eot\.txt" || $szFile =~ /eot\.\d+\.txt/)
      {
         return $szFile;
      }
   }

   return;  # if not found, return undef

} # FindEotInDirListing


# ---------------------------------------- GetAllCMOForOneFlavor
# Possibly download cdi/cdu data from one data subdir e.g. distribution or distribution/flash
# Called from GetAllCMO() only, because we saw cmo subdir(s) on the ship server and .ini file tells us we want that flavor

# more specific cmo state data (e.g. we are pulling last3)... we hash it into %::hCmoShipState e.g. $hCmoShipState{'descr'}
# For example, when we are in xxx(), and have decided a shipment e.g. "last3", we can set val for "cmo_cdi_dir"
# keys for hCmoShipState: ... see top of this module

# Return error info lines, or empty list if all is OK

sub GetAllCMOForOneFlavor
{
my(
    $iCaptureEotOnly,   # special mode: only capture eot's (all we need is a distrib* subdir to be happy)
    $p_did_download,  # will not clear; may set to 1
    ) = @_;

my $func = "GetAllCMOForOneFlavor";
# note global used: %hCmoState

AppendLog ( "$func(): start; capture=$iCaptureEotOnly", 0 ) if ( LogThis( 'gen' ) > 0 );

# figure out paths .. put in email message
if($hCmoState{'cmo_flavor'} eq $hCrntEnv{'cmodata_keyword'})
    {
##    $szCmoFlavorPhrase = "";    # add this to messages
##    $szEmailErrSubject = "Error downloading CMO data";
    }
    else
    {
##        $szCmoFlavorPhrase = "($hCmoState{'cmo_flavor'})";    # add this to messages
##        $szEmailErrSubject = "Error downloading CMO data ($hCmoState{'cmo_flavor'})";
    }

# start email content
my @aMsg = ();
my @aTechMailMsg = ();
AppendCmoStateHashToMsg ( \@aTechMailMsg );

# build useful lists that will help us walk thru the 5 CMO shipping areas
#my @aMarker = ();
my @aLocalFile = ();

#my @aRemoteDir = ();

#my @aDescr = ();
#my @aSerial = ();  # will fill it in as we scan shipping areas; if none, val=undef


# loop thru the 5 shipping areas; try to get the eot file; have to deal with serial numbers
# also, save the dir listings; we want the file size when we eventually pull the file

# NOTE: what Intex shipping does:
#  1) move files to older subdir or byte bucket
#  2) copy files in this order: cdi,cdu,shipinfo,eot
# branch out for http download
my $phCmo = {};
my $sNumOfArchive=6;   #legacy we keep 5 shipments. we could add more if need.
for ( my $iShip = $sNumOfArchive; $iShip >= 0; $iShip-- )
    {
    my ($sThisShipSerial);
    my @aLine = ();
    my @aErrMsg = ();
    $phCmo->{'remote_dir'}="/$hIniFile{'user'}/$hCmoState{'distrib_dir'}/last${iShip}/.";
    #special cases:
    $phCmo->{'remote_dir'}="/$hIniFile{'user'}/$hCmoState{'distrib_dir'}/last/." if ($iShip==1);
    #latest shipment
    $phCmo->{'remote_dir'}="/$hIniFile{'user'}/$hCmoState{'distrib_dir'}/." if ($iShip==0);


    GetRemoteDir
        (
         $phCmo->{'remote_dir'}, # want dir on this path
         \@aLine,               # return lines to us; no CRLF on end
         \@aErrMsg
         );

    # if have dir listing errors, ignore them
    # may be a new customer with no "last4" subdir, for example
    # or only last 4 are given.
    next if (scalar(@aLine==0));
    next if ( scalar(@aErrMsg));
    #push ( @aRemoteDir, $phCmo->{'remote_dir'} );
    #push(@Marker,"$iShip.eot");
    my $szLocalFile="$hCmoState{'flavored_log_dir'}".$slash."$iShip.eot";
    push ( @aLocalFile, $szLocalFile);
    unlink($szLocalFile) if (-e $szLocalFile);

    # look for a line that has eot.txt or eot.NNNNNN.txt; if none, return undef
    # If we cannot find eot file, may be ok: may be new customer with empty last4, for example
    my $szEot = FindEotInDirListing(@aLine); #for non-existing dir, directory is the home directory and no eot file returned.
    AppendLog ( "$func: saw eot file in dir listing; fn=$szEot, remote dir:$phCmo->{'remote_dir'} " ) if (defined($szEot));
    next if ( !defined($szEot));

    if ($szEot =~ /eot\.(\d+)\.txt/ )
        {
        $phCmo->{"ShipTimeStamp"}=$1;   #saved later for continuing download.
        }
    else
        {
        AppendLog ( "$func: Invalid eot file $szEot, skipping" );
        next;
        }


    # get the eot file
    my $szRemoteFileArg = "$phCmo->{'remote_dir'}/$szEot";
    AppendLog ( "$func: about to download file
  remote=$szRemoteFileArg
  local=$szLocalFile" );
    my @aDownloadFileErrMsg;

    @aDownloadFileErrMsg = DownloadFile
        (
         $szRemoteFileArg,
         $szLocalFile,
         1,             # 1 means this: file must exist e.g. download must succeed, but do not check size in bytes
         );

    # any errors?
    if ( scalar(@aDownloadFileErrMsg) || (!(-e $szLocalFile) ))
        {
        unlink ( $szLocalFile );

        my @aMsg = ();
        push ( @aMsg, "$func() we were unable to download an eot file from the Intex server" );
        push ( @aMsg, "src file=$szRemoteFileArg");
        push ( @aMsg, "Debug info from DownloadFile():" );
        push ( @aMsg, @aDownloadFileErrMsg );
        return @aMsg;
        }
    # When we try to get a non-existent file, may get 0 len file (with NT, not with Solaris)
    # Thus, we zap any zero len eot files, based on Tom, EOT file size to be zero should only happen to current dir and only happens if we are posting.
     if (( -e $szLocalFile &&  (stat($szLocalFile))[7] == 0 )&& ($iShip==0))
        {
           #Likely we are posting. retry N times and wait 50 sec between each
           my $sRetries=1;
           while (( -e $szLocalFile &&  (stat($szLocalFile))[7] == 0 )&& ($sRetries<4)) {

                  @aDownloadFileErrMsg = DownloadFile
                      (
                       $szRemoteFileArg,
                       $szLocalFile,
                       1,             # 1 means this: file must exist e.g. download must succeed, but do not check size in bytes
                       );
                  sleep(60); #wait for 60 second prior to retry;
                  $sRetries++;
        }

     }
     # at this point, if eot file is still 0 size, we have to give up
     if ( -e $szLocalFile &&  (stat($szLocalFile))[7] == 0 ){

        my @aMsg = ();
        push ( @aMsg, "$func() downloaded eot file from the Intex server returned size of 0" );
        push ( @aMsg, "src file=$szRemoteFileArg, local file=$szLocalFile");
        push ( @aMsg, "Debug info from DownloadFile():" );
        push ( @aMsg, @aDownloadFileErrMsg );
        return @aMsg;

     }

    # If we are running in special capture mode, create cmotrack.log file and exit
    if ( $iCaptureEotOnly )
        {
        KeepBuildingInitialCmoTrackFile
            (
              \@aLocalFile,
              # .eot files may be in log/flash, for example
              );
        AppendLog ( "$func(): all done with no problems; return value=empty list" );

        foreach my $file ( @aLocalFile )  # don't leave junk in log subdir
            {
            unlink ( $file );
            }

        next;
        }

    # Figure out what we should pull (we have eot.txt from server for this shipment, and not in tracking file)
    # my @aCouldPull = ();

    # if contents of eot file is in tracking file...
    open ( EOT, $szLocalFile );
    my $szEotLine = <EOT>;
    close(EOT);
    $szEotLine =~ s/[\n\r]//g;

    if ( HaveEotInTrackingFile  ( $szEotLine ) )
        {
        AppendLog ( "$func: already have line=$szEotLine in tracking file from file=$szLocalFile" );
        next;
        }
     AppendLog ( "$func: possibly pull data from $phCmo->{'remote_dir'}  based on file=$szLocalFile" );

     # This is a good place to delete intraday shipment done list if one existing since intraday needs to be refreshed afterwards.
     #we keep a Donelist for intraday on disk. We will use it for intraday only and erase it if we have regular downloads happening.
     my $szIdShipListDone="$hCrntEnv{'tgt_log_dir'}".$slash."intraday".$slash."shiplistDone.txt";
     FixSlashes(\$szIdShipListDone,"native");
     if (-e $szIdShipListDone) {
        AppendLog("$func: we find $szIdShipListDone and will delete it.");
        unlink($szIdShipListDone);
     }

    # If we pull data, not pulling the next ones if we get error.
    # As we try to pull shipment but get error, break out of loop

     my %hCmoShipState=();

     # put all kinds of stuff in hCmoShipState
     $phCmo->{'local_eot_file'} = "$iShip.eot";
     if ($iShip >0) {
        $phCmo->{'descr'}="old shipment ($iShip back)";
        $phCmo->{'path_segment'}="last".$iShip;
        $phCmo->{'path_segment'}="last" if ($iShip==1);
        $phCmo->{'short_pull_path'} = $hCmoState{'distrib_word'}."/$phCmo->{'path_segment'}";
     }
     else {

        $phCmo->{'descr'}="latest shipment";
        $phCmo->{'path_segment'}="";
        $phCmo->{'short_pull_path'} = $hCmoState{'distrib_word'};
     }
     $phCmo->{'shipment_stamp'} = $szEotLine;

     # figure out short pull path e.g. distribution/last4 or distribution/flash/last4, obsolete this
     #$phCmo->{'short_pull_path'} = ($hCmoState{'cmo_flavor'} eq "cmodata") ? $hCmoState{'distrib_word'} : $hCmoState{'distrib_word'} . "/$hCmoState{'cmo_flavor'}";

     $phCmo->{'long_pull_path'} = "/$hIniFile{'user'}/$phCmo->{'short_pull_path'}";
     foreach my $szLine (@aLine)
     {
           my @aDirLine = split(/\s+/,$szLine);
           my $szName = $aDirLine[8];     # cmo_cdi.zip
           $szName = $aLine[7] if ( $szName eq "" ) ;
           $szName=$aDirLine[1];
           if (defined($szName) && $szName =~ /^shipinfo\.(.+)/i) {
               $phCmo->{'compressed_info_file'}=$szName;

            }
     }

     $phCmo->{'dir_listing'} = [@aLine];


     AppendLog ( "$func(): we are going to pull the shipment $iShip (flavor=$hCmoState{'cmo_flavor'})" );

     # finally: check disk room, and if enough pull shipment
     # (We email if things are going OK (if error, we return error list and do NOT email))

     my @aPullErr = CheckDiskRoomAndPullShipment
         (
          \@aMsg,
          $phCmo,
          );

     if ( scalar(@aPullErr) )
         {
            unlink($szLocalFile) if (-e $szLocalFile); # don't leave junk in log subdir

            return ( "$func(): had error pulling shipment", "Debug info from CheckDiskRoomAndPullShipment():", @aPullErr );
         }
     else
         {
         ### Want to make sure we don't miss shipments posted while we were downloading.
         ### So, if we just downloaded the shipment from $iShip, we will try $iShip again (by incrmenting $iShip here)
         ### If no new shipments have been posted, then $iShip will be in our tracking file and we will move on
         ### If however there is a new shipment in $iShip, then we will grab it
         $iShip++;
         }

    } # for $iShip

if ( defined ( $hIniFile{'get_id'} ) && (uc($hIniFile{'get_id'} ) eq "Y") && !$::bSkipIntraday)
   {
   my @aIdErrs = DownloadIdShipping () ;
   if ( scalar ( @aIdErrs ) > 0 )
       {
       @aIdErrs  = ( "Error when downloading ID shipment", @aIdErrs ) ;
       print "!!!!!! ERROR: ". join ( "\n", @aIdErrs ) ;
       AppendLog ( "DownloadIdShipping: error trying to download ID shipping: ". join ( "\n", @aIdErrs ) ) ;
       return @aIdErrs ;
       }
   #$::bNeedToRunDbstatus = 1 ;
   }

# if nothing was pulled, done
#if ( $iKeepPulling == 0 )
#    {
#    print "CMO data is already up-to-date for flavor=$hCmoState{'cmo_flavor'}\n";
#   AppendLog ( "$func(): all done with no problems" );
#
#    foreach my $file ( @aLocalFile )  # don't leave junk in log subdir
#        {
#        unlink ( $file );
#        }
#
#    return ();
#    }

# got this far, we pulled one or more shipments: we may want to prune the database
if( $hCmoState{'cmo_flavor'} eq 'cmodata' )
{
        CopyFlashCdu() if (defined $hIniFile{"copy_flash_cdu"} && $hIniFile{"copy_flash_cdu"}==1 );
    AppendLog ( "$func(): about to require autodnld_prune.pl; cwd=" . cwd() );
    require "autodnld_prune.pl";
        prune_cmo_data();
}

$$p_did_download = 1;  # let caller know

AppendLog ( "$func(): all done with no problems" );

foreach my $file ( @aLocalFile )  # don't leave junk in log subdir
{
    unlink ( $file );
}

return ();

} # GetAllCMOForOneFlavor


# ------------------ SetCmoStateHash
# adjust values in global hash: %hCmoState ... also have globals: %hIniFile %hCrntEnv
sub SetCmoStateHash
{
my ( $szCmoFlavor ) = @_;  #  e.g. "cmodata" (magic value) or "flash" etc

my ( $szKey );

$hCmoState{'cmo_flavor'} = $szCmoFlavor;

if($szCmoFlavor eq $hCrntEnv{'cmodata_keyword'})  # "cmodata" ... magic word
    {
    $hCmoState{'distrib_dir'} = $hCmoState{'distrib_word'}; # e.g. distrib
    $hCmoState{'cmo_cdi_dir'} = $hIniFile{'tgt_cdi_dir'}; # e.g. c:\\intex\\cmo_cdi
    $hCmoState{'cmo_cdu_dir'} = $hIniFile{'tgt_cdu_dir'}; # e.g. c:\\intex\\cmo_cdu
    $hCmoState{'flavored_log_dir'} =     $hCrntEnv{'tgt_log_dir'}; # e.g. c:\\autodnld\\log
    }
elsif($szCmoFlavor eq "intraday" )  # "cmodata" ... magic word
    {
    $hCmoState{'distrib_dir'} = $hCmoState{'distrib_word'}; # e.g. distrib
    $hCmoState{'cmo_cdi_dir'} = $hIniFile{'tgt_cdi_dir'}; # e.g. c:\\intex\\cmo_cdi
    $hCmoState{'cmo_cdi_dir'} = $hIniFile{'id_tgt_cdi_dir'} if ( defined ( $hIniFile{'id_tgt_cdi_dir'}) ) ; # e.g. c:\\intex\\cmo_cdi
    $hCmoState{'cmo_cdu_dir'} = $hIniFile{'tgt_cdu_dir'}; # e.g. c:\\intex\\cmo_cdu
    $hCmoState{'cmo_cdu_dir'} = $hIniFile{'id_tgt_cdu_dir'}if ( defined ( $hIniFile{'id_tgt_cdu_dir'}) ) ; # e.g. c:\\intex\\cmo_cdi
    $hCmoState{'flavored_log_dir'} =     "$hCrntEnv{'tgt_log_dir'}$slash$szCmoFlavor"; # e.g. c:\\autodnld\\log

    MkdirAsReq ( $hCmoState{'cmo_cdu_dir'}) if ( ! -d $hCmoState{'cmo_cdu_dir'} ) ;
    MkdirAsReq ( $hCmoState{'cmo_cdi_dir'}) if ( ! -d $hCmoState{'cmo_cdi_dir'} ) ;
    MkdirAsReq ( $hCmoState{'flavored_log_dir'}) if ( ! -d $hCmoState{'flavored_log_dir'} ) ;

    }
else
    {
    $hCmoState{'distrib_dir'} = $hCmoState{'distrib_word'} . "/$szCmoFlavor"; # distrib/flash

    $szKey = "[".$szCmoFlavor."]".'tgt_cdi_dir'; # e.g. [cms]tgt_cdu_dir
    $hCmoState{'cmo_cdi_dir'} = $hIniFile{$szKey}; # e.g. c:\\intex\\cmo_cdi\\cms

    $szKey = "[".$szCmoFlavor."]".'tgt_cdu_dir'; # e.g. [cms]tgt_cdu_dir
    $hCmoState{'cmo_cdu_dir'} = $hIniFile{$szKey}; # e.g. c:\\intex\\cmo_cdu\\cms

    $hCmoState{'flavored_log_dir'} =     "$hCrntEnv{'tgt_log_dir'}$slash$szCmoFlavor"; # e.g. c:\\autodnld\\log\\flash
    }

$hCmoState{'tracking_file'} = "$hCrntEnv{'tgt_log_dir'}$slash" . "CMOTrack.log";
$hCmoState{'id_tracking_file'} = "$hCrntEnv{'tgt_log_dir'}$slash" . "ID_CMOTrack.log";

} # SetCmoStateHash


# ---------------------------------- MakeLocalSubdirPerCmoStateHash
# using %hCmoState, make local subdirs as req'd
# return non zero if error, and put errors in error-list passed by ref.
sub MakeLocalSubdirPerCmoStateHash
{
my ( $paErrMsg ) = @_;

my ($szErr);

$szErr = MkdirAsReq ( $hCmoState{'cmo_cdi_dir'} );

if ( $szErr ne "" )
   {
      @$paErrMsg = ( $szErr );
      return 1;
   }

$szErr = MkdirAsReq ( $hCmoState{'cmo_cdu_dir'} );

if ( $szErr ne "" )
   {
      @$paErrMsg = ( $szErr );
      return 1;
   }

$szErr = MkdirAsReq ( $hCmoState{'flavored_log_dir'} );

if ( $szErr ne "" )
   {
      @$paErrMsg = ( $szErr );
      return 1;
   }

} # MakeLocalSubdirPerCmoStateHash


# -------------------------- AppendCmoStateHashToMsg
sub AppendCmoStateHashToMsg
{
   my ( $paTechMailMsg ) = @_;

   push ( @$paTechMailMsg, "---------- start cmo state variables" );
    push ( @$paTechMailMsg, "Local cdi subdir=$hCmoState{'cmo_cdi_dir'}" );
    push ( @$paTechMailMsg, "Local cdu subdir=$hCmoState{'cmo_cdu_dir'}" );
    push ( @$paTechMailMsg, "Log subdir (for temp. eot files)=$hCmoState{'flavored_log_dir'}" );
   push ( @$paTechMailMsg, "---------- end cmo state variables" );

} # AppendCmoStateHashToMsg


# ------------------------------------- GetAllCMOWrapper
# called from main loop  if customer wants to download cmo data
# Main loop does things like: get cmo; get pooldata...
# Return array of error messages, or () for no errors

sub GetAllCMOWrapper
{
my (
    $iCaptureEotOnly,   # we may want to fake the cmotrack.log files only
    $p_did_download,    # will not clear; may set to 1
    ) = @_;

AppendLog ( "GetAllCMOWrapper(): start - CaptureEotOnly flag=$iCaptureEotOnly" ) if ( LogThis( 'gen' ) > 0 );

# if customer cannot make their cmo cdi/cdu subdir, detect it now
# this error only happens with new users of autodnld the first time they run it
foreach my $subdir ( $hIniFile{'tgt_cdi_dir'}, $hIniFile{'tgt_cdu_dir'} )
    {
    my $err_line = MkdirAsReq ( $subdir );

    if ( $err_line ne '' )
        {
        return ("Could not make Intex data subdir; error traceback: $err_line" );
        }
    }

# get listing of "distrib*" subdir (we already know which it is)
print "Downloading the eot files in the shipment subdirectories...\n";  # $hCmoState{'distrib_word'}
# WARNING: we cannot always detect errors for HTTP format
my @aErrMsg = ();
my @aRemoteDir = ();

GetRemoteDir
    (
     "/$hIniFile{'user'}/" . $hCmoState{'distrib_word'} . "/.", # e.g. "/tiny_tar/distribtion/."
     \@aRemoteDir,              # dir listing
     \@aErrMsg                  # append: error messages for end user
     );

if ( scalar(@aErrMsg)>0)
    {
    @aErrMsg = ();
    push ( @aErrMsg, "Could not get listing of " . $hCmoState{'distrib_word'} . " subdir on ship server");
    AppendLog ( "GetAllCMOWrapper(): done with problems: return error list" );
    return @aErrMsg;
    }
#
# scan the dir listing; build list of additional data subdirs e.g. flash; if also in ini file,
# whether NT or UNIX ship server, dir output is very similar, since NT is set for "UNIX style dir"
# Typical line: "----------   1 owner    group           34659 Nov  1 19:48 shipinfo.000013.zip"
my @aDistributionDir = ();

    # ok, have data in main distrib. subdir, and we have list of other cmo areas, if any
    # get cmo data in in distrib or distribution
    # will email if errors, so we don't need to

   # set all kinds of values e.g. "cmo_cdu_dir"
   SetCmoStateHash ( "cmodata" );
   AppendHashInfoToLogFile ( "Contents of hCmoState hash", \%hCmoState ) if ( LogThis( 'gen' ) > 0 );

   if ( MakeLocalSubdirPerCmoStateHash ( \@aErrMsg ) )
   {
   AppendLog ( "GetAllCMOWrapper(): done with problems: return error list" );
   return ( @aErrMsg );
   }

   # if we are running the special mode where we are making the CMO tracking file from scratch, zap the tracking file
   unlink ( $hCmoState{'tracking_file'} ) if ( $iCaptureEotOnly );

   # download all CMO data for flavor="cmodata" (default type for most customers)
   # if we are in capture-eot mode, once we have the eot's, save them and quick return
   my @aOneFlavorErr = GetAllCMOForOneFlavor
         (
          $iCaptureEotOnly,
          $p_did_download,   # never clear; may set it
          );

if ( scalar(@aOneFlavorErr) )
{
    return ("Error returned when download cmo data", "Debug info from GetAllCMOForOneFlavor():", @aOneFlavorErr );
}

    # ok, main area is done; if we have other cmo flavors, go check them out
    # will email if errors, so we don't need to
    # If there are errors, break out of loop
    foreach my $szDir (@aDistributionDir)
    {
       # set all kinds of values e.g. "cmo_cdu_dir"
       SetCmoStateHash ( $szDir );
       AppendHashInfoToLogFile ( "Contents of hCmoState hash", \%hCmoState ) if ( LogThis( 'gen' ) > 0 );

       if ( MakeLocalSubdirPerCmoStateHash ( \@aErrMsg ) )
       {
       AppendLog ( "GetAllCMOWrapper(): done but have problems: return error list" );
       return ( @aErrMsg );
       }

       AppendLog ( "GetAllCmoWrapper(): call GetAllCMOForOneFlavor() for flavor=$hCmoState{'cmo_flavor'}", 0 );

        my @aDownloadFileErr = GetAllCMOForOneFlavor
             (
              $iCaptureEotOnly,
              $p_did_download,  # never clear; may set it
              );

       if ( scalar(@aDownloadFileErr) )
        {
        return ( "Error download CMO data", "Debug info from GetAllCMOForOneFlavor():", @aDownloadFileErr );
        }
    }

AppendLog ( "GetAllCMOWrapper(): done and all is OK" );
return ();  # empty list means no errors

} # GetAllCMOWrapper



################################################################################################################
################################## pooldata/bonddata stuff #########################################################
################################################################################################################



# ---------------- FigureOutPoolBondHash
#   bond_or_pool          "pool" or "bond"
#   ship_subdir            "pooldata" or "bonddata" ... do a "cd ../pooldata", for example
#   token_after_cmo_cdu   mbspools" or "bonds"
#   parent_dir            d:\\intex\\cmo_cdu\\mbspools
#   tracking_file .       c:\\autodnld\\log\\pooltrak.log  ... set by PossiblyDownloadGroupData()
#   dbstatus_file         bdcstat.qa
#   report_file           c:\\autodnld\\log\\poolstat.rpt OR bondstat.rpt
#   report_root           poolstat.rpt OR bondstat.rpt
#   inf_file              mbscusip.inf OR bdccusip.inf

# typical usage: $hPoolBondState{'pool_or_bond'}

sub FigureOutPoolBondHash
{
my (
    $pool_or_bond,  # pool or 'bond'
    $bArchive
    ) = @_;

$hPoolBondState{'pool_or_bond'} = $pool_or_bond;
$hPoolBondState{'dbstatus_stat_file'} = "$hCrntEnv{'tgt_log_dir'}$slash" ."dbstatus.status.txt";
$hPoolBondState{'report_file'} = "$hCrntEnv{'tgt_log_dir'}$slash$pool_or_bond" . "stat.rpt";  # e.g. c:\\autodnld\\log\\poolstat.rpt
$hPoolBondState{'report_root'} = $pool_or_bond . "stat.rpt";  # e.g. poolstat.rpt
$hPoolBondState{'tracking_file'} = "$hCrntEnv{'tgt_log_dir'}$slash$pool_or_bond" . "trak.log";  # e.g. c:\\autodnld\\log\\pooltrak.log

if ( $pool_or_bond eq "pool" )
    {
    if ( $bArchive )
        {
        $hPoolBondState{'ship_subdir'} = "pooldata_archive";
        $hPoolBondState{'token_after_cmo_cdu'} = "mbspools";
        $hPoolBondState{'dbstatus_file'} = "mbsstat.qa";
        $hPoolBondState{'inf_file'} = "mbscusip.inf";
        }
    else
        {
        $hPoolBondState{'ship_subdir'} = "pooldata";
        $hPoolBondState{'token_after_cmo_cdu'} = "mbspools";
        $hPoolBondState{'dbstatus_file'} = "mbsstat.qa";
        $hPoolBondState{'inf_file'} = "mbscusip.inf";
        }
    }
else
    {
    $hPoolBondState{'ship_subdir'} = "bonddata";
    $hPoolBondState{'token_after_cmo_cdu'} = "bonds";
    $hPoolBondState{'dbstatus_file'} = "bdcstat.qa";
    $hPoolBondState{'inf_file'} = "bdccusip.inf";
    }

# this one depends on earlier value
$hPoolBondState{'parent_dir'} = "$hIniFile{'tgt_cdu_dir'}$slash" . $hPoolBondState{'token_after_cmo_cdu'};

# dump hash to log
my ( $info ) = "FigureOutPoolBondHash(): contents of hPoolBondState is now as follows:";

foreach my $szKey ( sort(keys(%hPoolBondState)))
    {
    $info .= "  $szKey=$hPoolBondState{$szKey}\n";
    }

AppendLog ( $info );

} # FigureOutPoolBondHash


# -------------------- ReadQaFile
# read qa file into list of hash ref: 'file'; 'size'
# if have this in ini file: "pool_data_skip_geo=1", skip .geo files
# typical data lines:
#   file=cmo_cdu\bonds\bdc0112.dat|size=208524442|utc=1008752905|signature=2764222399
#   file=cmo_cdu\mbspools\2000\0007\fhlmc.geo|size=71347860|utc=963414925|signature=
# called by:
#   GenMissingListForBond()
#   GenMissingListForPool()
sub ReadQaFile
{
my (
    $fn,
    $paQa,   # will add to this empty list of hash ref e.g. keys: 'file', 'size', 'utc', 'signature'
    $p_err,
    ) = @_;

AppendLog ( "ReadQaFile: start; fn=$fn" );
open ( QAFILE, $fn );
my ( @aLine ) = <QAFILE>;
close(QAFILE);
chomp(@aLine);

foreach my $line ( @aLine )
    {
    # must have "size=" in line; else, skip it
    next if ( $line !~ /size=/ );

    # if have this in ini file: "pool_data_skip_geo=1", skip .geo files
    next if (   defined ($hIniFile{'pool_data_skip_geo'})   &&   $hIniFile{'pool_data_skip_geo'} == 1  &&   $line =~ /\.geo/i );

    # build hash
    my ( @aToken ) = split ( /\|/, $line );  # e.g. 'file=xxx'
    my $ph = {};

    foreach my $token ( @aToken )
        {
        my ($name,$val) = split(/=/,$token);
        $ph->{$name} = $val if ( defined($val));
        }

    push ( @$paQa, $ph ) if ( scalar(keys(%$ph)) );
    }

} # ReadQaFile


# ---------------- is_utc_diff_ok
# compare two utc values: ok if 1 sec. or less difference (also ok if 1 hour time zone change)
# return 1=ok  0=ng
sub is_utc_diff_ok
{
my (
    $val1,
    $val2,
    ) = @_;

return 0 if ( !defined($val1) || !defined($val2));
my $diff = abs($val1 - $val2);
return 1 if ( $diff <= 1 );
return 1 if ( $diff >= 3599 && $diff <= 3601 );
return 0;  # ng

} # is_utc_diff_ok


# -------------------------- GenMissingListForBond
# figure out file/size pairs that we need using months-back
# optionally purge
# then build list of files that are missing/damaged

# sample cmo_cdu/bonds/bdcstat.qa lines
##   file=cmo_cdu\bonds\bdc0104.dat|size=188282988|utc=988702334
##   file=cmo_cdu\bonds\bdc0105.dat|size=208125430|utc=991381557
##   file=cmo_cdu\bonds\bdc0106.dat|size=208208086|utc=991468567
##   file=cmo_cdu\bonds\bdccusip.inf|size=1337392|utc=991468736
#
sub GenMissingListForBond
{
my (
    $qa_fn,
    $months_back,
    $paQaMissing, # return list of name,size attributes of files that are missing e.g. "bonds\bdc9909.dat,1234567
    $p_err,        # may set error
    ) = @_;

# read qa file into list of hash ref: 'file'; 'size'
my $paQa = [];

ReadQaFile
 (
    $qa_fn,
    $paQa,   # will add to this empty list of name/size pairs
    $p_err,
  );

return if ( $$p_err ne "" );

# walk the qa file; build list of dat and non-dat files e.g. 'file=cmo_cdu\bonds\bdc0112.dat|size=208524442|utc=1008752905|signature=2764222399'
my @aDatTemp = ();
my @aNonDat = ();

foreach my $phQa ( @$paQa )
    {
    my $file = $phQa->{'file'};
    my $size = $phQa->{'size'};

    if ( $file =~ /\.dat/ )
        {
        push ( @aDatTemp, $phQa );
        }
    else
        {
        push ( @aNonDat, $phQa );
        }
    }

# to pick out the dat files we want, just sort the list ... good until 2100!
# aDat after splicing:
##   0  'cmo_cdu\\bonds\\bdc0106.dat,208422680'
##   1  'cmo_cdu\\bonds\\bdc0105.dat,208125430'
# aNonDat example:
##       cmo_cdu\bonds\bdccusip.inf,1344880
my @aDat = reverse ( sort { $a->{'file'} cmp $b->{'file'} } @aDatTemp );
splice ( @aDat, $months_back );      # e.g. have 0106,0105,0104; after splice after have 0106,0105

# put info in log
my $info = '';

foreach my $phQa ( @aDat )
    {
    $info .= " $phQa->{'file'}";
    }

AppendLog ( "GenMissingListForBond: dat bond files we should have: $info" );

$info = '';

foreach my $phQa ( @aNonDat )
    {
    $info .= " $phQa->{'file'}";
    }

AppendLog ( "GenMissingListForBond: non-dat bond files we should have: $info" );

# need to purge?
my ( $purge_flag ) = $hIniFile{'bond_data_purge'};
$purge_flag = 0 if ( !defined($purge_flag));
AppendLog ( "GenMissingListForBond: Purging of bond data is enabled" ) if ( $purge_flag );

# need to qa_purge?
my ( @aMatch ) = grep ( /bond_data_purge/, @ARGV );
my ( $qa_purge_flag ) = scalar(@aMatch) ? 1 : 0;
AppendLog ( "GenMissingListForBond: Fake purging of bond data is enabled" ) if ( $purge_flag );

# optional: purging ... easy, since flat directory
# if file is not in dat file list or in non-dat list, zap it
if ( $purge_flag || $qa_purge_flag )
    {
    # need list of dat and non dat files
    my @aDatRoot = ();

    foreach my $phQa ( @aDat )
        {
        push ( @aDatRoot, $phQa->{'file'} );
        }

    my @aNonDatRoot = ();

    foreach my $phQa ( @aNonDat )
        {
        push ( @aNonDatRoot, $phQa->{'file'} );
        }

    my ( $subdir ) = "$hIniFile{'tgt_cdu_dir'}$slash" . "bonds";  # e.g. d:\temp\autodnld\cmo_cdu\bonds
    opendir ( BONDDIR, $subdir );

    while (my $file = readdir(BONDDIR))
        {
        my ( $pathed_file ) = $subdir . $slash . $file;
        FixSlashes(\$pathed_file,"native");
        next if ( -d $pathed_file ); # skip subdir
        next if ( scalar(grep(/$file/,@aDatRoot))); # skip if in our Dat list (.dat files)
        next if ( scalar(grep(/$file/,@aNonDatRoot))); # skip if in out non-dat list (.inf file)
        next if ( $file =~ /bdcstat.qa/); # skip if QA file; not in .qa file, but useful to leave around

        if ( -e $pathed_file )
            {
            if ( $purge_flag )
                {
                AppendLog ( "Purge old bond file (we are retaining up to $months_back): $pathed_file", 1 );
                unlink ( $pathed_file );
                }
            else
                {
                AppendLog ( "Do NOT purge old bond file (we are retaining up to $months_back): $pathed_file", 1 );
                }
            }
        }
}

# compare wanted against local hard disk so we can return a missing list
foreach my $phQa ( @aDat, @aNonDat )
    {
    my $file = $phQa->{'file'};
    my $size = $phQa->{'size'};
    my ( $pathed_file ) = $hIniFile{'tgt_cdu_dir'} . substr($file,7);
    FixSlashes(\$pathed_file,"native");
    my ( @aStat ) = stat($pathed_file);

    # missing file?
    if ( scalar(@aStat) == 0 )
        {
        AppendLog ( "GenMissingListForBond: file=$file is missing");
        push ( @$paQaMissing, $phQa );
        next;
        }

    # size mismatch?
    if ( $aStat[7] != $size )
        {
        AppendLog ( "GenMissingListForBond: download because size mismatch for file=$file");
        push ( @$paQaMissing, $phQa );
        next;
        }

    # bad utc? (check can be suppressed via ini file)
    if ( !defined($hIniFile{'suppress_utc_check'})  &&  $hPoolBondState{'cannot_force_utc'} == 0  &&  !is_utc_diff_ok ( $aStat[9], $phQa->{'utc'})  )
        {
        AppendLog ( "GenMissingListForBond(): utc mismatch for file=$file");
        push ( @$paQaMissing, $phQa );
        next;
        };
    }

} # GenMissingListForBond


# ----------------------------- PurgePoolData ( !!!!! recurses !!!!!!)
# use to purge pool data
sub PurgePoolData
{
my (
    $crnt_subdir,      # absolute path to start, will keep adding to this as we recurse (native format)
    $crnt_rel_subdir,   # relative path to start e.g. "cmo_cdu\\mbspools" (native format)
                       # e.g. for top level pool files will be 'cmo_cdu\mbspools'
    $paFileToKeep,                # only want these files (NT format always) e.g. 'cmo_cdu\\mbspools\\mbscusip.inf'
     $qa_purge_flag,    # if 1, fake the delete
    ) = @_;

# get dir contents into a list
if ( ! opendir ( POOLDIR, $crnt_subdir ))
    {
    AppendLog ( "ERROR: PurgePoolData: could not open subdir=$crnt_subdir", 1 );
    return;
    }

my ( @aFile ) = readdir(POOLDIR);
closedir(POOLDIR);

# for each entry: ignore dots, put dir in list, process files
my(@aDir) = ();

foreach my $root ( @aFile )
    {
    next if ( $root eq "." || $root eq ".." );

    # if dir, remember it (native format)
    if ( -d "$crnt_subdir$slash$root" )
        {
        push ( @aDir, $root ) ;
        }
    else # if file, process it (careful: rel subdir is native format, paRoot is NT format)
        {
        my ( $match ) = "$crnt_rel_subdir/$root";  # this match value is always cmo_cdu\\mbspools etc etc, same as to-keep list
        FixSlashes ( \$match, "nt" );
        $match =~ s/\\/\\\\/g;
        my ( @aMatch ) = grep (/^$match$/i,@$paFileToKeep );  # match forced to NT format; paRoot is always NT format

        if ( scalar(@aMatch) == 0 && $root ne "mbsstat.qa" )
            {
            if ( $qa_purge_flag )
                {
                AppendLog ( "Fake purge of pool file=$crnt_subdir$slash$root", 1 );
                }
            else
                {
                AppendLog ( "PurgePoolData: purge pool file=$crnt_subdir$slash$root", 1 );
                unlink ( "$crnt_subdir$slash$root" );
                }
            }

        } # else a file

    } # foreach

# recurse down
foreach my $dir ( @aDir )
    {
    PurgePoolData
        (
         lc("$crnt_subdir$slash$dir"),  # absolute subdir (native format)
         lc("$crnt_rel_subdir$slash$dir"),  # relative subdir (native format)
         $paFileToKeep,                              # nt format always
         $qa_purge_flag,
         );
    }

} # PurgePoolData


# ----------------------- dump_val_from_hash_list
sub dump_val_from_hash_list
{
my (
    $title,
    $key,
    $paQa,
    ) = @_;

print "\ndump val from hash list: $title\n";

foreach my $ph ( @$paQa )
    {
    print "  $ph->{$key}\n";
    }

} # dump_val_from_hash_list


# -------------------------- GenMissingListForPool
# figure out file/size pairs that we need using months-back
# optionally purge any other files (-pool_data_purge)
# then figure out list of missing/damaged files that the caller should download

# sample cmo_cdu/bonds/mbsstat.qa lines
##   file=cmo_cdu\mbspools\fhlmc.hdr|size=17325800|utc=991412406
##   file=cmo_cdu\mbspools\2001\gnmab.dat|size=78588968|utc=989392650
##   file=cmo_cdu\mbspools\2001\0106\gnma2.geo|size=10699910|utc=991749626

sub GenMissingListForPool
{
my (
    $qa_fn,
    $months_back,
    $paQaMissing,       # return list of hash ref e.g. file=>"pools\bdc9909.dat", size=>1234567
    $p_err,        # may set error
    ) = @_;

my $func = 'GenMissingListForPool';

# read qa file into list of hash ref: 'file'; 'size'
# if have this in ini file: "pool_data_skip_geo=1", skip .geo files
my $paQa = [];

ReadQaFile
 (
    $qa_fn,
    $paQa,   # will add to this empty list of hash ref
    $p_err,
  );

return if ( $$p_err ne "" );
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\paQa", $paQa );

# walk the hash ref; divide into level 0/1/2
my @aLevel0 = ();
my @aLevel1 = ();
my @aLevel2 = ();
my ( $digits_ix ) = 17;

foreach my $phQa ( @$paQa )
    {
    my $file = $phQa->{'file'};
    my $size = $phQa->{'size'};

    # level 0 file?
    if ( substr($file,$digits_ix,1) !~ /\d/ )
        {
        push ( @aLevel0, $phQa ); # 'cmo_cdu\\mbspools\\mbscusip.inf'
        }
    # level 2 file?
    elsif ( substr($file,$digits_ix,9) =~ /\d{4}\\\d{4}/ ) # e.g. 'cmo_cdu\\mbspools\\2001\\0112\\fnma.arm'
        {
        push ( @aLevel2, $phQa );
        }
    # level 1 file e.g. 'cmo_cdu\\mbspools\\2001\\gnmab.dat'
    else
        {
        push ( @aLevel1, $phQa );
        }
    }

dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aLevel0.txt", \@aLevel0 );
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aLevel1.txt", \@aLevel1 );
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aLevel2.txt", \@aLevel2 );

# now walk the level2 files (latest first)
# build a list for N months back; may have several for each month; we have a $months_back value to be obeyed
# also, build a list for 1 month back; may have several for this month
# also, build a deduped list of yyyy codes that we will need
# typical list:
#   first in list ... 'cmo_cdu\\mbspools\\2001\\0112\\gnma2.geo'
#   last in list  ... 'cmo_cdu\\mbspools\\2000\\0001\\fhlmc.arm'
my %hYyyy = ();
@aLevel2 = sort { $a->{'file'} cmp $b->{'file'} } @aLevel2;
@aLevel2 = reverse(@aLevel2);
my ( $last_tag ) = "";
my ( $so_far ) = -1;
my ( @aLevel2MonthsBack ) = ();  # build this list
my ( @aLevel2OneMonthBack ) = ();  # build this list

foreach my $phQa ( @aLevel2 )
{
    my $file = $phQa->{'file'};   # cmo_cdu\mbspools\2001\0106\gnma2.geo,10699910
    my $size = $phQa->{'size'};
    my ( $yyyy ) = substr($file,$digits_ix,4);
    my ( $tag ) = substr($file,$digits_ix,9);   # e.g. 2001\\0106

    # if we are starting a new set e.g. 2001\\0106 ...
    if ( $tag ne $last_tag )
        {
        $so_far++;
        last if ( $so_far >= $months_back );
        $hYyyy{substr($tag,0,4)} = 1;
        $last_tag = $tag;
        }

    # possibly add to list for first month
    push ( @aLevel2OneMonthBack, $phQa ) if ( $so_far == 0 );

    # add to list for all months (NOTE: we have already jumped out of loop if have gone back enough months)
    push ( @aLevel2MonthsBack, $phQa );
}

my ( @aYyyy ) = keys(%hYyyy);

dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aLevel2MonthsBack.txt",   \@aLevel2MonthsBack        );
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aLevel2OneMonthBack.txt", \@aLevel2OneMonthBack      );
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aYyyy",                   \@aYyyy                    );

# now we can build list: files from level 0,1 and 2 that we may download
# want all of level0, some of level1 (based on year), plus level2-wanted
# then sort so the newest files are first
my ( @aAllLevel ) = ();
push ( @aAllLevel, @aLevel0 );

foreach my $phQa ( @aLevel1 )
{
    my $file = $phQa->{'file'};
    my $size = $phQa->{'size'};
    my ( $yyyy ) = substr($file,$digits_ix,4);
    push ( @aAllLevel, $phQa ) if ( scalar(grep ( /$yyyy/, @aYyyy  )));
}

push ( @aAllLevel, @aLevel2MonthsBack );
@aAllLevel = sort { $a->{'file'} cmp $b->{'file'} } @aAllLevel;
@aAllLevel = reverse(@aAllLevel);
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aAllLevel.txt", \@aAllLevel );

# now we can build list: files from level 0,1 and 2 that we may check utc on
# want all of level0, some of level1 (based on year), plus level2-wanted
# then sort so the newest files are first
my ( @aAllLevelUtc ) = ();

foreach my $phQa ( @aLevel0 )
{
    push ( @aAllLevelUtc, $phQa->{'file'} );
}

foreach my $phQa ( @aLevel1 )
{
    my $file = $phQa->{'file'};
    my ( $yyyy ) = substr($file,$digits_ix,4);
    push ( @aAllLevelUtc, $file ) if ( scalar(grep ( /$yyyy/, @aYyyy  )));
}

foreach my $phQa ( @aLevel2OneMonthBack )
{
    push ( @aAllLevelUtc, $phQa->{'file'} );
}

@aAllLevelUtc = sort @aAllLevelUtc;
dump_ref_for_debug ( "d:\\temp\\autodnld_debug\\aAllLevelUtc.txt", \@aAllLevelUtc );

# need to purge for real
my ( $purge_flag ) = $hIniFile{'pool_data_purge'};
$purge_flag = 0 if ( !defined($purge_flag));

# need to QA the purge logic?
my ( @aMatch ) = grep ( /pool_data_purge/, @ARGV );
my ( $qa_purge_flag ) = scalar(@aMatch) ? 1 : 0;

if  ( $purge_flag || $qa_purge_flag  )
{
    # need list of fn only
    my @aRoot = ();
    foreach my $phQa ( @aAllLevel )
        {
        push ( @aRoot, $phQa->{'file'} );
        }

    PurgePoolData               # note: this routine recurses
        (
         "$hIniFile{'tgt_cdu_dir'}$slash$hPoolBondState{'token_after_cmo_cdu'}",   # absolute path (native format) ... mbspools/bonds
         "cmo_cdu$slash$hPoolBondState{'token_after_cmo_cdu'}",                 # relative path to start (native format)
         \@aRoot,                                                                 # only want these files (nt format always)
         $qa_purge_flag,                                                              # if set, don't really unlink
         );
}

# now see if any files in our "wanted" list are missing/damaged/stale
foreach my $phQa (@aAllLevel )
{
    my $root = $phQa->{'file'};
    my $file = "$hIniFile{'tgt_cdu_dir'}/" . substr($root,8);
    FixSlashes ( \$file, "native" );
    my ( @aStat ) = stat($file);

    # missing?
    if ( scalar(@aStat) == 0 )
        {
        AppendLog ( "GenMissingListForPool: file missing=$file" );
        push ( @$paQaMissing, $phQa );
        next;
        }

    # bad size?
    if ( $aStat[7] != $phQa->{'size'} )
        {
        AppendLog ( "GenMissingListForPool: download because size mismatch for file=$file");
        push ( @$paQaMissing, $phQa );
        next;
        }

    # bad utc?
##    print "\n root=$root; utc=$aStat[9]; expected=$phQa->{'utc'}\n";
    my $root_pattern = $root;
    $root_pattern =~ s/\\/\\\\/g;

    if ( !defined($hIniFile{'suppress_utc_check'}) )                 # can use ini file to turn off
        {
        if ( $hPoolBondState{'cannot_force_utc'} == 0 )         # client file system may not support utc
            {
            if ( scalar(grep(/^$root_pattern$/,@aAllLevelUtc)) )  # list of files that we check UTC on ... we don't want to check older files
                {
                if ( !is_utc_diff_ok ( $aStat[9], $phQa->{'utc'}) )  # within 1 second (or one hour diff is OK also)
                    {
                    my $msg = "$func(): utc mismatch; file=$file; actual=" . scalar(localtime($aStat[9]) );
                    $msg .= "; expected=" . scalar(localtime($phQa->{'utc'}));
                    AppendLog ( $msg );
                    push ( @$paQaMissing, $phQa );
                    next;
                    }
                else
                    {
##                    print " ...utc is OK or is not checked\n";
                    }
                }
            }
        }
} # file

} # GenMissingListForPool


# ------------------------ GenMissingListForPoolBond
# figure out hash ref for files that we need using months-back
# optionally purge any other files
# then figure out list of missing/damaged files, if any, that the caller should download

# NOTE: $hPoolBondState has been set

# return error msg or ""

sub GenMissingListForPoolBond
{
my (
    $paMissing, # return list of name,size attributes of files that are missing e.g.
                                #    "bonds\bdc9909.dat,1234567
                                #                OR
                                #    "mbspools\1999\9909\fhlmc.arm,1234567
    $bArchive
       ) = @_;

my ( $szStatFile ) = $hPoolBondState{'dbstatus_stat_file'};
my ( $pool_or_bond ) = $hPoolBondState{'pool_or_bond'};

# error if no qa file
my $szQaFile = "$hPoolBondState{'parent_dir'}$slash$hPoolBondState{'dbstatus_file'}";

if(!( -e $szQaFile ) )
    {
       return "Could not find dbstatus file $szQaFile";
    }

# parse the dbstatus file, building lists of hash ref to download and to purge

# sample cmo_cdu/mbspools/mbsstat.qa lines
##   file=cmo_cdu\mbspools\fhlmc.hdr|size=17325800|utc=991412406
##   file=cmo_cdu\mbspools\1999\fhlmc.dat|size=68956152|utc=945794968
##   file=cmo_cdu\mbspools\2001\0105\gnma2.geo|size=10683355|utc=983807390

# sample cmo_cdu/bonds/bdcstat.qa lines
##   file=cmo_cdu\bonds\bdc0104.dat|size=188282988|utc=988702334
##   file=cmo_cdu\bonds\bdc0105.dat|size=208125430|utc=991381557
##   file=cmo_cdu\bonds\bdc0106.dat|size=208208086|utc=991468567
##   file=cmo_cdu\bonds\bdccusip.inf|size=1337392|utc=991468736

my ( $months_back ) = ($pool_or_bond eq "pool" ? $hIniFile{'pool_data_months_back'} : $hIniFile{'bond_data_months_back'});

if ( $pool_or_bond eq 'pool' && $bArchive )
    {
    if ( $months_back - 24 > 0 )
        {
        $months_back -= 24;
        }
    else
        {
        $months_back = 1;
        }
    }

my ( $purge_flag ) = ($pool_or_bond eq "pool" ? $hIniFile{'pool_data_purge'} : $hIniFile{'bond_data_purge'});
$purge_flag = 0 if ( !defined($purge_flag));
my $err = "";

if ( $pool_or_bond eq 'bond' )
    {
    GenMissingListForBond
        (
         $szQaFile,
         $months_back,
         $paMissing, # return list of name,size attributes of files that are missing e.g. "bonds\bdc9909.dat,1234567
         \$err,
         );
    }
    else
    {
    # figure out hash ref for files we need using months-back
    # optionally purge any other files
    # then figure out list of missing/damaged files, if any, that the caller should download
    GenMissingListForPool
        (
         $szQaFile,
         $months_back,
         $paMissing, # return list of name,size attributes of files that are missing e.g.
                                #    "mbspools\1999\9909\fhlmc.arm,1234567
         \$err,

         );

    }

return $err;

} # GenMissingListForPoolBond


# -------------------------------------------- PossiblyUpdateBondOrPoolDataInf
# We may have to copy .inf file up one subdir level
# Return non zero if error

sub PossiblyUpdateBondOrPoolDataInf
{
my ( $szFlavor ) = @_;   # "pool" or "bond"

# figure out src/dst files; don't worry about slash direction yet
my $szSrc = "$hIniFile{'tgt_cdu_dir'}/$hPoolBondState{'token_after_cmo_cdu'}/$hPoolBondState{'inf_file'}";
my $szDst = "$hIniFile{'tgt_cdu_dir'}/$hPoolBondState{'inf_file'}";

# clean up slashes; compose copy command
FixSlashes ( \$szSrc, "native" );
FixSlashes ( \$szDst, "native" );

my $szCmd;

if($is_unix)
    {
    $szCmd = "cp -p \"$szSrc\" \"$szDst\"";
    }
else
    {
    $szCmd = "$com_spec copy /Y \"$szSrc\" \"$szDst\"";   # $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c"
    }

AppendLog ( "PossiblyUpdateBondOrPoolDataInf: src=$szSrc dst=$szDst" );

# if no src, done
if ( ! ( -e $szSrc ))
    {
    return 0;
    }

# have src; if no dst, copy and done
if ( ! ( -e $szDst ))
    {
    AppendLog ( "Copy bond/pool data inf file to cmo_cdu: cmd=$szCmd", 0 );  # 0 = no console
    my $bReturnCode = system ( $szCmd );
    return $bReturnCode;
    }

# got this far, have both src and dst; check stamps
if ( is_utc_diff_ok ( (stat($szSrc))[9], (stat($szDst))[9] ) )  # compare two utc values: ok if 1 sec. or less difference (also ok if 1 hour time zone change)
    {
    return 0;
    }

AppendLog ( "PossiblyUpdateBondOrPoolDataInf: copy file to cmo_cdu: cmd=$szCmd" );
my $bReturnCode = system ( $szCmd );
return $bReturnCode;

} # PossiblyUpdateBondOrPoolDataInf


# ---------------------- get_stamp_of_last_pool_bond_shipment
# generate a time/date string for the last time pool/bond data was shipped
# called
#   when we are looking for a pool or bond shipment
#   when we are running the -c option and faking the eot file

# there is an eot.txt file in the pooldata subdir (for example), but the contents are not useful:
##  fnma.hsp.Z      2077257     7360006
##  mbscusip.inf.Z      8972725 27386923

# so instead, get the stamp of the eot.txt file from the dir listing

# NOTE: caller must have already called FigureOutPoolBondHash()
# return list of error messages, or emtpy list
sub get_stamp_of_last_pool_bond_shipment
{
my (
    $pszEotLine,   # place string here
    ) = @_;

my ( @aMatch, @aRemoteDir, @aMsg, @aToken );

# we cannot use the contents of the eot.txt file; instead, we need its time/date stamp
my @aUserErrMsg = ();
my $szSubdir = "/$hIniFile{'user'}/../$hPoolBondState{'ship_subdir'}/.";  # pooldata or bonddata
my @aTraceBack = ();

GetRemoteDir
    (
      $szSubdir,                # e.g. "/tiny_tar/../pooldata/."
      \@aRemoteDir,      # return dir listing
      \@aTraceBack,
      );

if ( scalar(@aTraceBack) )
    {
    @aMsg = ();
    push ( @aMsg, "Error getting dir on ship server; subdir=$szSubdir" );
    push ( @aMsg, "---- start traceback from GetRemoteDir()", @aTraceBack, "---- end traceback" );
    return @aMsg;
   }

# compose our quasi eot line from stamp tokens e.g. "54 Nov  6  3:08"
#  ----------   1 owner    group              70 Jul 18 12:22 eot.txt
@aMatch = grep(/eot\.txt/,@aRemoteDir);

if ( scalar(@aMatch) != 1 )
    {
    @aMsg = ();
    push ( @aMsg, "Could not find eot.txt file in dir on ship server; subdir=$szSubdir" );
    push ( @aMsg, "---- dir listing" . join("\n",@aRemoteDir) . "\n---- end dir listing" );
    return @aMsg;
    }

@aToken = split ( /\s+/,$aMatch[0] );
$$pszEotLine = "$aToken[5] $aToken[6] $aToken[7]";
$$pszEotLine=$aToken[0];

return ();

} # get_stamp_of_last_pool_bond_shipment


# ----------------------- PossiblyDownloadGroupData
# get pooldata or bonddata (get only one set of files per one "shipped" file)
# Called from 2 places within xxx() if user has said yes to pool or bond data
# global: %hPoolBondState (caller has set members) ... see log file for member values
# Send emails: starting, done
# Return () if no error; else, error message list (and caller will email the error list)

sub PossiblyDownloadGroupData
{
my (
    $p_did_download,  # never cleared; may set to 1
    $bArchive,
    $paDownloadedFiles
    ) = @_;

my $pool_or_bond = $hPoolBondState{'pool_or_bond'};   # caller filled in correct field values
print "\n==== Check for new $pool_or_bond data\n";
AppendLog ( "PossiblyDownloadGroupData(): start" );

# we cannot use the contents of the eot.txt file; instead, we need its time/date stamp for the dir listing
my $szEotLine = "";
my @aTraceBack = ();
if ( ! $bArchive )
    {
    @aTraceBack = get_stamp_of_last_pool_bond_shipment ( \$szEotLine );
    }

if ( scalar(@aTraceBack) )
    {
    my @aMsg = ();
    push ( @aMsg, "Error figuring out time stamp for eot.txt" );
    push ( @aMsg, "---- start traceback from get_stamp_of_last_pool_bond_shipment()", @aTraceBack, "---- end traceback" );
    return @aMsg;
    }

AppendLog( "PossiblyDownloadGroupData(): timestamp for latest shipment: $szEotLine", 1);

if ( ! $bArchive )
    {
    # already have that shipment?
    if ( HaveEotInTrackingFile  ( $szEotLine, $pool_or_bond ) )
        {
        print "Already have timestamp in tracking file $pool_or_bond" . "trak.log\n";
        AppendLog ( "PossiblyDownloadGroupData(): Already have timestamp in tracking file $pool_or_bond" . "trak.log" );
        return ();
        }

    # talk to console
    print "There is a newer status file to be downloaded\n";
    }

# we have a change in eot; need to pull qa file
my $szRemoteFile = "/$hIniFile{'user'}/../$hPoolBondState{'ship_subdir'}/$hPoolBondState{'dbstatus_file'}";  # unix format always
my $szLocalFile =  "$hPoolBondState{'parent_dir'}$slash$hPoolBondState{'dbstatus_file'}";

@aTraceBack = DownloadFile
    (
     $szRemoteFile,
     $szLocalFile,
     1,              # file must exist after download, but don't verify size e.g. download must succeed
     );

if ( scalar(@aTraceBack) )
    {
    my @aMsg = ();
    push ( @aMsg, "Error downloading dbstatus QA file $hPoolBondState{'dbstatus_file'} for $pool_or_bond data" );
    push ( @aMsg, "Remote file was $szRemoteFile");
    push ( @aMsg, "Local file was $szLocalFile");
    push ( @aMsg, "---- start traceback from DownloadFile()", @aTraceBack, "---- end traceback from DownloadFile()" );
    return @aMsg;
    }

# we usually have a status file: does utime work etc (if first time with new software, no file present)
# hash members of hPoolBondState relating to utc:
##  cannot_force_utc ... from status file
##  tried_to_set_utc_cnt ...  will remember if errors
##  utc_err_cnt ... will remember if tried
my $status_fn = "$hIniFile{'autodnld_home'}$slash" . "log$slash$hPoolBondState{'pool_or_bond'}.status.log";  # e.g. 'pool.status.log'
my $phStatus = read_name_val_file ( $status_fn );
$hPoolBondState{'cannot_force_utc'} = defined($phStatus->{'cannot_force_utc'}) ? $phStatus->{'cannot_force_utc'} : 1;
$hPoolBondState{'tried_to_set_utc_cnt'} = 0;
$hPoolBondState{'utc_err_cnt'} = 0;
AppendLog ( "PossiblyDownloadGroupData: just read fn=$status_fn; cannot_force_utc=$hPoolBondState{'cannot_force_utc'}" );

# figure out hash ref of files that we need using months-back
# optionally purge any other files
# then figure out list of missing/damaged files that the caller should download
my @aFileToDownloadRc = ();

my $szError = GenMissingListForPoolBond
    (
     \@aFileToDownloadRc,   # return list of hash ref of files that are missing/stale etc
     $bArchive
     );

if ( $szError ne "" )
    {
    my @aMsg = ();
    push ( @aMsg, "Error processing dbstatus QA file $hPoolBondState{'dbstatus_file'} for $pool_or_bond data" );
    push ( @aMsg, "Error traceback: $szError" );
    return @aMsg;
    }

if ( scalar(@aFileToDownloadRc) == 0 )
    {
    print "There are no files to download (this is a little surprising since there was a new status file on the Intex server)\n";
    AppendLog ( "PossiblyDownloadGroupData(): There are no files to download (this is a little surprising since there was a new status file on the Intex server)");

    AddLineToTrackingFile
        (
         "$hCrntEnv{'tgt_log_dir'}$slash$pool_or_bond" . "trak.log",  # e.g c:\\autodnld\\log\\pooltrak.log
         $szEotLine,
         );

    return ();
    }

# we need to know if we are downloading HSP files only (affects email in some cases)
my $iHspOnly = 1;

foreach my $phQa ( @aFileToDownloadRc )
    {
    if  ( $phQa->{'file'} !~ /\.hsp$/ )
        {
        $iHspOnly = 0;
        }
    }

# build hash of file size as compressed in %hCompressedSize; this is not available in the .qa file
my ( @aDirLine ) = ();
my ( @aDirMsg ) = ();

GetRemoteDir
    (
     "/$hIniFile{'user'}/../$hPoolBondState{'ship_subdir'}",
     \@aDirLine,               # return lines to us; no CRLF on end
     \@aDirMsg
     );

if ( scalar(@aDirMsg ) )
    {
    my @aMsg = ();
    push ( @aMsg, "Error obtaining dir listing on Intex server" );
    push ( @aMsg, "We were trying to download $pool_or_bond data" );
    push ( @aMsg, "Directory: /$hIniFile{'user'}/../$hPoolBondState{'ship_subdir'}" );
    return @aMsg;
    }

my %hCompressedSize = ();

foreach my $line ( @aDirLine )
    {
    my ( @aToken ) = split ( /\s+/,$line );
    next if ( !defined($aToken[8]) || $aToken[8] !~ /\.Z$/ );
    $hCompressedSize{$aToken[8]} = $aToken[4];
    }

# start preparing email messages
my $szStartTitle =     "Start downloading " . ($iHspOnly ? "daily-" : "" ) . $pool_or_bond . "data shipment(s)";
my $szFinishTitle = "Finished downloading " . ($iHspOnly ? "daily-" : "" ) . $pool_or_bond . "data shipment(s)";
my @aStartMsg = ("We will be downloading the following file(s):");
my @aFinishMsg = ("We finished downloading the following file(s):");

# scan the list of files; add each to email msg; also add up compressed size
my $total_compressed_size = 0;

foreach my $phQa ( @aFileToDownloadRc )
    {
    push ( @aStartMsg, "  $phQa->{'file'} ($phQa->{'size'} bytes)" );
    push ( @aFinishMsg, "  $phQa->{'file'} ($phQa->{'size'} bytes)" );
    $total_compressed_size += $phQa->{'size'};
    }
if ( $hIniFile { 'minimal_email' } eq "N" )
    {

    # send start msg now; (will send finish msg later if no errors)
    ComposeAndSendEmail
        ( 'e16',
          $szStartTitle,
          \@aStartMsg,
          );
    }

# download each file
print "We will download " . scalar(@aFileToDownloadRc) . " files; total compressed bytes=$total_compressed_size\n";
my $iStartTime = time();

foreach my $phQa ( @aFileToDownloadRc )  # e.g. "file=cmo_cdu\mbspools\fhlmc.hdr|size=16041000|utc=941476560"
    {
    # figure out relative path plus root e.g. xxx from line from .qa file; then figure out local and remote file
    my $relative_path_plus_root = $phQa->{'file'};
    FixSlashes ( \$relative_path_plus_root, 'native' );
    $relative_path_plus_root = substr($relative_path_plus_root, ($pool_or_bond eq "pool" ? 17 : 14));

    my $local_file_after_decompress = "$hPoolBondState{'parent_dir'}$slash$relative_path_plus_root";
    my $remote_file = "/$hIniFile{'user'}/../$hPoolBondState{'ship_subdir'}/$relative_path_plus_root.Z";

    my $iSize = $phQa->{'size'};
    print ( "\nDownload file=$relative_path_plus_root; uncompressed size=$iSize\n" );
    AppendLog ( "PossiblyDownloadGroupData(): within loop: do another file:
  remote=$remote_file;
  local_after_decompress=$local_file_after_decompress;
  uncompressed_size=$iSize" );

    # want filename after pooldata/bonddata only e.g.
    #      cmo_cdu\bonds\bdc9909.dat ==> bdc9909.dat
    #      cmo_cdu\mbspools\1999\9909\fnma.geo ==> 1999\9909\fnma.geo

    my @aTraceBack = DownloadAndDecompressZFile
        (
         $remote_file,  # e.g. /user/../mbspools/...
         $local_file_after_decompress,
         $iSize,           # final size when decompressed
         $hCompressedSize{"$relative_path_plus_root.Z"},   # compressed size ... optional
         );

    if ( scalar(@aTraceBack) )
        {
        my $bAttribRights  ;
        if ( grep ( /had error return code/i,@aTraceBack) )
           {
           $bAttribRights = CheckAttribOfFile ( $local_file_after_decompress ) ;
           }
        AppendLog ( "PossiblyDownloadGroupData(): Error downloading $pool_or_bond" . "data file" );
        my @aMsg = ();
        push ( @aMsg, "Error downloading $pool_or_bond" . "data file");
        if ( $bAttribRights )
            {
            AppendLog ( "PossiblyDownloadGroupData(): Decompress error was from no write access for file $local_file_after_decompress" );
            push ( @aMsg, "Error was caused by not having write access for file=$local_file_after_decompress" );
            push ( @aMsg, "!!!!!!!!!!!!!!!!!!!!!!! SOLUTION !!!!!!!!!!!!!!!!!!!!!: Grant write access to that file or preferably the whole folder and its sub-folders" );
            }

        push ( @aMsg, "Remote file was $relative_path_plus_root");
        push ( @aMsg, "Local file was $local_file_after_decompress");
        push ( @aMsg, "---- start traceback from DownloadFile()", @aTraceBack, "---- end traceback from DownloadFile()" );

        return @aMsg;
        }

    # try to force utc; remember that we tried, remember if we fail
    utime ( $phQa->{'utc'}, $phQa->{'utc'}, $local_file_after_decompress );
    my $utc = (stat($local_file_after_decompress))[9];
    $hPoolBondState{'tried_to_set_utc_cnt'}++;

    if ( is_utc_diff_ok ( $utc, $phQa->{'utc'} ) )  # compare two utc values: ok if 1 sec. or less difference (also ok if 1 hour time zone change)
        {
        AppendLog ("PossiblyDownloadGroupData: set utc ok: file=$local_file_after_decompress; wanted and got utc=$phQa->{'utc'}");
        }
    else
        {
        $hPoolBondState{'utc_err_cnt'}++;
        AppendLog "PossiblyDownloadGroupData: had error setting utc: file=$local_file_after_decompress; wanted utc=$phQa->{'utc'}; got utc=$utc\n";
        }

    push( @$paDownloadedFiles, [ $remote_file, $local_file_after_decompress, sprintf("%.0f", ( $iSize/1024 ) + .5 ) ] );
    } # each file

# got this far; have not returned yet; thus, no errors downloading
AddLineToTrackingFile
    (
     "$hCrntEnv{'tgt_log_dir'}$slash$pool_or_bond" . "trak.log",  # e.g c:\\autodnld\\log\\pooltrak.log
     $szEotLine,
     );

# may have to copy inf file up to cmo_cdu subdir
my $bCopyReturn = PossiblyUpdateBondOrPoolDataInf( $pool_or_bond );

if ( $bCopyReturn == 256 )
   {
   my $szDstFile = "$hIniFile{'tgt_cdu_dir'}/$hPoolBondState{'inf_file'}" ;
   AppendLog ( "PossiblyDownloadGroupData(): Error copying to $szDstFile" );
   my @aMsg = ();
   push ( @aMsg, "Error downloading $pool_or_bond" . "data file");
   push ( @aMsg, "File=$szDstFile does not have write access");
   push ( @aMsg, "!!!!!!!!!!!!!!!!!!!!!!! SOLUTION !!!!!!!!!!!!!!!!!!!!!: Grant write access to that file or preferably the whole folder and its sub-folders" );
   return @aMsg;
   }

# send "done" email
push ( @aFinishMsg, "Elapsed time to download and decompress files: " . sprintf ( "%.1f", (time() - $iStartTime) / 60 ) . " minutes" );

if ( $hIniFile { 'minimal_email' } eq "N" )
    {
    ComposeAndSendEmail
        (
         'e18',
         $szFinishTitle,
         \@aFinishMsg,
         );
     }

$$p_did_download = 1;

# save the status file
# remember if we have utc problems
if ( $hPoolBondState{'tried_to_set_utc_cnt'} )
    {
    $phStatus->{'cannot_force_utc'} = $hPoolBondState{'utc_err_cnt'} ? 1 : 0;
    my $write_err = '';
    write_name_val_file ( $status_fn, $phStatus, \$write_err );
    }

return ();

}  # PossiblyDownloadGroupData



# --------------- CreateGroupDataDownloadedList
# write a shiplist.txt file for group data if saving serialized files for tracking

sub CreateGroupDataDownloadedList
{
my ( $paFiles, $sType ) = @_;

if ( $hIniFile{save_serialized_group_shiplist} )
    {
    my $sSaveShiplist = $hCmoState{'flavored_log_dir'}.$slash."shiplist_".$sType.".".time().".txt" ;
    open( FILE, ">".$sSaveShiplist );
    foreach my $pa (@$paFiles)
        {
        print FILE $$pa[0]."\|".$$pa[1]."\|".$$pa[2]."\n";
        }
    close(FILE);
    }
return;
}

# --------------- FakeGroupDataTrackingFile
# write a tracking file so that autodnld thinks we are up to date

# NOTE: pool/bond state data; we hash it; typical usage: $hPoolBondState{'pool_or_bond'}
# keys:
#   pool_or_bond         "pool" or "bond"
#   token_after_cmo_cdu "mbspools" or "bonds"
#   parent_dir            d:\\intex\\cmo_cdu\\mbspools
#   etc, etc

# if have errors, write to screen

# return 0=ok, else non zero

sub FakeGroupDataTrackingFile
{
my (
    $pool_or_bond,   # pool Or "bond"
    ) = @_;

AppendLog ( "FakeGroupDataTrackingFile(); start" );

SetCmoStateHash ( "cmodata" );  # need flavored_log_dir
FigureOutPoolBondHash ( $pool_or_bond );

# gen the eot.txt line
my($szEotLine) = ();
my(@aTraceBack) = get_stamp_of_last_pool_bond_shipment ( \$szEotLine );

if ( scalar(@aTraceBack) )
    {
    my ( @aCustomerLog ) = ( "Error generating eot string file for $hPoolBondState{'pool_or_bond'} data", "---- start traceback from get_stamp_of_last_pool_bond_shipment()" . join("\n",@aTraceBack) . "\n---- end traceback" ) ;
    AppendLog ( "Error generating eot string file for $hPoolBondState{'pool_or_bond'} data", 1 );
    AppendLog ( "---- start traceback from get_stamp_of_last_pool_bond_shipment()" . join("\n",@aTraceBack) . "\n---- end traceback", 1, \@aCustomerLog );
    return 1;
    }

# add to tracking file
my($szErr) = AddLineToTrackingFile
    (
     $hPoolBondState{'tracking_file'},   # fully pathed file
     $szEotLine,                    # last shipment
     );

if ($szErr ne "" )
    {
    my ( @aCustomerLog ) = ( "Error unable to write to tracking file", "Traceback: \n $szErr" ) ;
    AppendLog ( "ERROR: unable to write to tracking file", 1 );
    AppendLog ( "Traceback from AddLineToTrackingFile(): $szErr", \@aCustomerLog );
    return 1;
    }

# all went well...
AppendLog ( "We added the line $szEotLine to the $pool_or_bond tracking file ($hPoolBondState{'tracking_file'})", 1 );
return 0;

} # FakeGroupDataTrackingFile

######################################################################################################
#################################### perf/remit ######################################################
######################################################################################################


# --------------------------- possibly_get_perf_or_remit_file    (also hist files now)
# we are processing one type e.g. abfr; we have scanned the .qa file and found a data line in it
# final size must match value that is passed in
# return 1 if error

sub possibly_get_perf_or_remit_file
{
my (
     $flavor,   # perf or "remit" or rmtd
     $ty,       # e.g. abag
     $paTriplet,   # the caller has split the data line on '|' for use, so now we have a list of key/val e.g.
                #    file=abag\abaghist.txt
                #    size=39
                #    utc=988358492
     $paEmailTxt,  # add lines here
     $phStatus,  # status from last time we ran this perf flavor ... we want 'cannot_force_utc'
     $p_tried_to_set_utc_cnt,  # will remember if errors
     $p_utc_err_cnt, # will remember if errors
     $paDownloadedFiles
     ) = @_;

AppendLog ( "possibly_get_perf_or_remit_file(): start; flavor=$flavor");
my ( @aMsg );
my ( $tgt_subdir ) = $hIniFile{"tgt_$flavor" . 'data_dir'};
$tgt_subdir  = $hIniFile{"tgt_$flavor" . '_data_dir'} if ( $flavor eq "deal_remit" ||  $flavor eq "tranche_remit" );
 $tgt_subdir  = $hIniFile{"tgt_cdu_dir"} if ( ! defined ( $tgt_subdir ) && $flavor eq "hist" ) ;

# hash the name/val/utc triplets in the data line from the .qa file e.g.
##   'prefix_plus_file' => 'abag\\abaghist.txt' ... prefix is the same as our "$ty"
##   'size' => 39
##   'utc' => 988358492
my ( $phPara ) = {};

foreach my $name_val ( @$paTriplet )     # file=abfr\abfrhist.txt,size=321719,utc=1007110888,signature=1030855698
    {
    my ( @aToken ) = split(/=/,$name_val );
    $phPara->{$aToken[0]} = $aToken[1];
    }

# now add a few more goodies: plain file name etc
$phPara->{'prefix_plus_file'} = $phPara->{'file'};
my ( $ix ) = rindex($phPara->{'prefix_plus_file'}, "\\" );        # e.g. abag\\abaghist.txt
$phPara->{'file'} = substr($phPara->{'prefix_plus_file'},$ix+1);  # e.g. abaghist.txt

# ok, hash is all done e.g.
##    'file' => 'abfrhist.txt'
##    'prefix_plus_file' => 'abfr\\abfrhist.txt'
##    'size' => 308172
##    'utc' => 1004691678

# figure out filenames; do we have file, and with the right size?
my ( $final_dst_file_file ) = "$tgt_subdir/$phPara->{'prefix_plus_file'}";   # d:\temp\autodnld\perfdata/abag\abaghist.txt
 $final_dst_file_file  = "$tgt_subdir/$phPara->{'file'}" if ( $flavor eq "hist" ) ;   # d:\temp\autodnld\perfdata/abag\abaghist.txt
FixSlashes ( \$final_dst_file_file, "native" );                                 # d:\temp\autodnld\perfdata\abag\abaghist.txt


my ( @aStat ) = stat($final_dst_file_file );
my $size_ok;

if ( scalar(@aStat) > 0 && $aStat[7] == $phPara->{'size'} )
    {
    #AppendLog ( "size match for file=$phPara->{'prefix_plus_file'}" );
    $size_ok = 1;
    }
else
    {
    AppendLog ( "download because size mismatch for file=$phPara->{'prefix_plus_file'}" );
    $size_ok = 0;
    }

# maybe we can check the UTC also
# we have a remembrance if utc was ok from a previous time in phStatus
my $utc_ok = 1;

if ( $size_ok == 1  &&  defined($phStatus->{'cannot_force_utc'})  &&  $phStatus->{'cannot_force_utc'} == 0  &&  $$p_utc_err_cnt == 0 )
     {
     if ( is_utc_diff_ok ( $aStat[9], $phPara->{'utc'} ) )
         {
         #AppendLog ( "size match and UTC match for file=$phPara->{'prefix_plus_file'}" );
         }
     else
         {
         AppendLog ( "size match but UTC mismatch for file=$phPara->{'prefix_plus_file'}" );
         $utc_ok = 0;
         }
     }

if ( $size_ok && $utc_ok )
     {
     #AppendLog ( "no need to download file=$phPara->{'prefix_plus_file'}" );
     return;
     }

# ok, need to download the file and uncompress Z file .. .may use temp subdir
AppendLog ( "Download compressed data for $phPara->{'prefix_plus_file'}", 1 );
my ( $remote_file) = "/$hIniFile{'user'}/../$flavor" . "data/$phPara->{'prefix_plus_file'}.Z";     # ../perfdata/abag/abaghist.txt.Z
$remote_file = "/$hIniFile{'user'}/../$flavor" . "_data/$phPara->{'prefix_plus_file'}.Z" if ( $flavor eq "deal_remit" || $flavor eq "tranche_remit" );     # ../perfdata/abag/abaghist.txt.Z
my ( $local_file ) = "$tgt_subdir$slash$ty$slash$phPara->{'file'}";
 $local_file  = "$tgt_subdir$slash$phPara->{'file'}" if ( $flavor eq "hist" ) ;

if ( defined ( $hCrntEnv{'gets_custom_'.$flavor.'_data'} )  )
   {
   if ( $hCrntEnv{'gets_custom_remit_data'} == 1 )
      {
      #$remote_file  = "/$hIniFile{'user'}/../$flavor" . "data/$ty/$flavor" . "stat.qa";
      $remote_file  = "/$hIniFile{'user'}/$flavor" . "data/$phPara->{'prefix_plus_file'}.Z";
      }
   }

@aMsg = DownloadAndDecompressZFile
    (
     $remote_file,
     $local_file,
     $phPara->{'size'},  # final size when decompressed
     );

if ( scalar(@aMsg))
    {
    my ( @aEmail ) =
        (
         "ERROR: Unable to download data file for $flavor data",
         "File on Intex server: $remote_file",
         "Destination file on your machine: $local_file",
         "Debug information:",
         "------------------------",
         @aMsg,
         );

    ComposeAndSendEmail
        (
         'e__',
          "ERROR: unable to download data file for $flavor data",
          \@aEmail,
          );
    AppendLog ( "SKIP","", \@aEmail) ;

    return 1;
    }


push( @$paDownloadedFiles, [ $remote_file, $local_file, sprintf("%.0f", ( $phPara->{'size'}/1024 ) + .5 ) ] );

# ok, file has been downloaded ok, try to force the UTC
# if have problems, tell the caller
utime ( $phPara->{'utc'}, $phPara->{'utc'}, $local_file );
my $utc = (stat($local_file))[9];
$$p_tried_to_set_utc_cnt++;

if ( is_utc_diff_ok ( $utc, $phPara->{'utc'} ) )
    {
    AppendLog "UTC worked ok: file=$local_file;  want=$phPara->{'utc'}; got=$utc\n";
    }
else
    {
    $$p_utc_err_cnt++;
    AppendLog "UTC had error: file=$local_file;  want=$phPara->{'utc'}; got=$utc\n";
    }

# no errors
push ( @$paEmailTxt, "  downloaded file: $local_file" );
return 0;

} # possibly_get_perf_or_remit_file

# --------------------------- possibly_get_perf_or_remit_diff_file
# we are processing one type e.g. abfr; we have scanned the .qa file and found a data line in it
# final size must match value that is passed in
# return 1 if error

sub possibly_get_perf_or_remit_diff_file
{
my (
     $flavor,   # perf or "remit" or rmtd
     $ty,       # e.g. abag
     $paTriplet,   # the caller has split the data line on '|' for use, so now we have a list of key/val e.g.
                #    file=abag\abaghist.txt
                #    size=39
                #    utc=988358492
     $paEmailTxt,  # add lines here
     $phStatus,  # status from last time we ran this perf flavor ... we want 'cannot_force_utc'
     $p_tried_to_set_utc_cnt,  # will remember if errors
     $p_utc_err_cnt, # will remember if errors
     $paDownloadedFiles
     ) = @_;

AppendLog ( "possibly_get_perf_or_remit_diff_file(): start; flavor=$flavor");
my ( @aMsg );
my ( $tgt_subdir ) = $hIniFile{"tgt_remit" . 'data_dir'};
if ( defined ( $hIniFile{"tgt_$flavor" . 'data_dir'} ) )
    {
    $tgt_subdir  = $hIniFile{"tgt_$flavor" . 'data_dir'};
    }
if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
    {
    $tgt_subdir = $hIniFile{"tgt_" .$flavor. '_data_dir'};
    }


# hash the name/val/utc triplets in the data line from the .qa file e.g.
##   'prefix_plus_file' => 'abag\\abaghist.txt' ... prefix is the same as our "$ty"
##   'size' => 39
##   'utc' => 988358492
my ( $phPara ) = {};

foreach my $name_val ( @$paTriplet )     # file=abfr\abfrhist.txt,size=321719,utc=1007110888,signature=1030855698
    {
    my ( @aToken ) = split(/=/,$name_val );
    $phPara->{$aToken[0]} = $aToken[1];
    }

# now add a few more goodies: plain file name etc
$phPara->{'prefix_plus_file'} = $phPara->{'file'};
my ( $ix ) = rindex($phPara->{'prefix_plus_file'}, "\\" );        # e.g. abag\\abaghist.txt
$phPara->{'file'} = substr($phPara->{'prefix_plus_file'},$ix+1);  # e.g. abaghist.txt
$phPara->{'prefix'} = substr($phPara->{'prefix_plus_file'},0,$ix+1);  # e.g. abaghist.txt
$phPara->{'prefix'} =~ s/[\\\/]//g ;

# ok, hash is all done e.g.
##    'file' => 'abfrhist.txt'
##    'prefix_plus_file' => 'abfr\\abfrhist.txt'
##    'prefix' => abfr
##    'size' => 308172
##    'utc' => 1004691678

# figure out filenames; do we have file, and with the right size?
my ( $final_dst_file_file ) = "$tgt_subdir/$phPara->{'prefix_plus_file'}";   # d:\temp\autodnld\perfdata/abag\abaghist.txt
FixSlashes ( \$final_dst_file_file, "native" );                                 # d:\temp\autodnld\perfdata\abag\abaghist.txt
my ( @aStat ) = stat($final_dst_file_file );
my $size_ok;

if ( scalar(@aStat) > 0 && $aStat[7] == $phPara->{'size'} )
    {
##    AppendLog ( "size match for file=$phPara->{'prefix_plus_file'}" );
    $size_ok = 1;
    }
else
    {
    AppendLog ( "download because size mismatch for file=$phPara->{'prefix_plus_file'}" );
    $size_ok = 0;
    }

# maybe we can check the UTC also
# we have a remembrance if utc was ok from a previous time in phStatus
my $utc_ok = 1;

if ( $size_ok == 1  &&  defined($phStatus->{'cannot_force_utc'})  &&  $phStatus->{'cannot_force_utc'} == 0  &&  $$p_utc_err_cnt == 0 )
     {
     if ( is_utc_diff_ok ( $aStat[9], $phPara->{'utc'} ) )
         {
##         AppendLog ( "size match and UTC match for file=$phPara->{'prefix_plus_file'}" );
         }
     else
         {
         AppendLog ( "size match but UTC mismatch for file=$phPara->{'prefix_plus_file'}" );
         $utc_ok = 0;
         }
     }

if ( $size_ok && $utc_ok )
     {
##     AppendLog ( "no need to download file=$phPara->{'prefix_plus_file'}" );
     return;
     }

# ok, need to download the file and uncompress Z file .. .may use temp subdir
AppendLog ( "Download compressed data for $phPara->{'prefix_plus_file'}", 1 );
my ( $remote_file) = "/$hIniFile{'user'}/../remitdata/$phPara->{'prefix'}/diff/$phPara->{'file'}.Z";     # ../perfdata/abag/abaghist.txt.Z
if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
   {
   $remote_file = "/$hIniFile{'user'}/../$flavor"."_data/$phPara->{'prefix'}/diff/$phPara->{'file'}.Z";     # ../perfdata/abag/abaghist.txt.Z
   }
my ( $local_file ) = "$tgt_subdir$slash$ty$slash$phPara->{'file'}";

if ( defined ( $hCrntEnv{'gets_custom_'.$flavor.'_data'} )  )
   {
   if ( $hCrntEnv{'gets_custom_'.$flavor.'_data'} == 1 )
      {
      #$remote_file  = "/$hIniFile{'user'}/../$flavor" . "data/$ty/$flavor" . "stat.qa";
      if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
          {
          $remote_file  = "/$hIniFile{'user'}/$flavor" . "_data/$phPara->{'prefix_plus_file'}.Z";
          }
      else
          {
          $remote_file  = "/$hIniFile{'user'}/$flavor" . "data/$phPara->{'prefix_plus_file'}.Z";
          }
      }
   }

@aMsg = DownloadAndDecompressZFile
    (
     $remote_file,
     $local_file,
     $phPara->{'size'},  # final size when decompressed
     );

if ( scalar(@aMsg))
    {
    my ( @aEmail ) =
        (
         "ERROR: Unable to download diff data file for $flavor data",
         "File on Intex server: $remote_file",
         "Destination file on your machine: $local_file",
         "Debug information:",
         "------------------------",
         @aMsg,
         );

    ComposeAndSendEmail
        (
         'e__',
          "ERROR: unable to download diff data file for $flavor data",
          \@aEmail,
          );
    AppendLog ( "SKIP","", \@aEmail) ;

    return 1;
    }

push( @$paDownloadedFiles, [ $remote_file, $local_file, sprintf("%.0f", ( $phPara->{'size'}/1024 ) + .5 ) ] );

# ok, file has been downloaded ok, try to force the UTC
# if have problems, tell the caller
utime ( $phPara->{'utc'}, $phPara->{'utc'}, $local_file );
my $utc = (stat($local_file))[9];
$$p_tried_to_set_utc_cnt++;

if ( is_utc_diff_ok ( $utc, $phPara->{'utc'} ) )
    {
    AppendLog "UTC worked ok: file=$local_file;  want=$phPara->{'utc'}; got=$utc\n";
    }
else
    {
    $$p_utc_err_cnt++;
    AppendLog "UTC had error: file=$local_file;  want=$phPara->{'utc'}; got=$utc\n";
    }

# no errors
push ( @$paEmailTxt, "  downloaded file: $local_file" );
return 0;

} # possibly_get_perf_or_remit_diff_file

# ------------------------------ GetPerfOrRemitData
# get any perf or remit data
# called because we have this ini file:
##  perfdata=abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,ag,cmbs,wl
##          AND/OR
##  remitdata=ab_au,ab_cc,ab_eq,ab_fp,ab_he,ab_mh,ab_rv,cmbs,wl

# if error, email user and return 1

sub GetPerfOrRemitData
{
my (
    $flavor,  # perf or "remit"
    $subdir_list,  # e.g. abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,cmbs,wl
    $p_did_download,
    $paDownloadedFiles,
    ) = @_;

$$p_did_download = 0;
my ( $tgt_subdir ) = $hIniFile{"tgt_$flavor" . 'data_dir'};
$tgt_subdir  = $hIniFile{"tgt_$flavor" . '_data_dir'} if ( $flavor eq "deal_remit" || $flavor eq "tranche_remit" ) ;
 $tgt_subdir  = $hIniFile{"tgt_cdu_dir"} if ( ! defined ( $tgt_subdir ) && $flavor eq "hist" ) ;

AppendLog ( "GetPerfOrRemitData(): start;" );
AppendLog ("\n==== Check for new performance data", 1 ) if ( $flavor eq 'perf' );
AppendLog ("\n==== Check for new remittance data", 1 ) if ( $flavor eq 'remit' );
AppendLog ("\n==== Check for new deal remittance data", 1 ) if ( $flavor eq 'deal_remit' );
AppendLog ("\n==== Check for new tranche remittance data", 1 ) if ( $flavor eq "tranche_remit" );
AppendLog ("\n==== Check for new hist data", 1 ) if ( $flavor eq 'hist' );

# must have tgt subdir ... if missing in ini file, we compute a default, so this error should not happen any more
if ( !defined ( $tgt_subdir  ) )
    {
    my ( @aEmail ) =
        (
         "ERROR: you need to define a destination subdirectory for $flavor data",
         "in your autodnld.ini file e.g.:",
         "  tgt_$flavor" . "data_dir=c:\\intex\\$flavor" . "data",
         );

    ComposeAndSendEmail
        (
         'e__',
         "ERROR: you need to define \"tgt_$flavor" . "data_dir\" in your autodnld.ini file",
         \@aEmail,
         );
    AppendLog ( "SKIP","", \@aEmail) ;

    return 1;
    }

# we have a status file: does utime work etc
my $status_fn = "$hIniFile{'autodnld_home'}$slash" . "log$slash$flavor.status.log";
my $phStatus = read_name_val_file ( $status_fn );

# build up email here
my($paEmailTxt) = [];

# check each type that client is entitled to e.g. abfr
my $utc_err_cnt = 0;
my $tried_to_set_utc_cnt = 0;

my $iMaxMonths = 0;
if ( $flavor eq 'remit' || $flavor eq 'deal_remit' || $flavor eq 'tranche_remit' )
    {
    if ( defined( $hIniFile{$flavor.'_data_months_back'} ) )
        {
        $iMaxMonths = $hIniFile{$flavor.'_data_months_back'};
        }
    }

my @aTimeNow = localtime();
my $iCurYyyymm = sprintf( "%04d%02d", $aTimeNow[5]+1900, $aTimeNow[4]+1 );

foreach my $ty ( split ( /,/,$subdir_list ))
    {
    AppendLog ( "  check type=$ty", 1 );

    # mkdir if needed ... no error checking because ???
    MkdirAsReq ( "$tgt_subdir$slash$ty" ) if ( $flavor ne "hist" ) ;

    # always get the XXXXstat.qa file; else email error and return 1
    # this file is small, so not the end of the world that we always grab the whole file
    my ( $local_file ) = $tgt_subdir;
    if ( $flavor eq 'hist' )  ## in case want in root
        {
        $local_file .= "$slash$flavor" . "stat.qa";  # d:\temp\autodnld\perfdata\perfstat.qa
        }
    elsif ( $flavor eq 'deal_remit' || $flavor eq "tranche_remit" )  ## in case want in root
        {
        $local_file .= "$slash$ty$slash" . "remitstat.qa";  # d:\temp\autodnld\perfdata\perfstat.qa
        }
    else
        {
        $local_file .= "$slash$ty$slash$flavor" . "stat.qa";  # d:\temp\autodnld\perfdata\perfstat.qa
        }
    my ( $remote_file ) = "/$hIniFile{'user'}/../$flavor" . "data/$ty/$flavor" . "stat.qa";              # /bancone_cap/../perfdata/abag/perfstat.qa
    $remote_file  = "/$hIniFile{'user'}/../$flavor" . "_data/$ty/" . "remitstat.qa" if ( $flavor eq "deal_remit" || $flavor eq "tranche_remit"  );              # /bancone_cap/../perfdata/abag/perfstat.qa
    if ( defined ( $hCrntEnv{'gets_custom_'.$flavor.'_data'} )  )
       {
       if ( $hCrntEnv{'gets_custom_remit_data'} == 1 )
          {
          #$remote_file  = "/$hIniFile{'user'}/../$flavor" . "data/$ty/$flavor" . "stat.qa";
          $remote_file  = "/$hIniFile{'user'}/$flavor" . "data/$ty/$flavor" . "stat.qa";
          }
       }

    my ( @aMsg )= DownloadFile
         (
          $remote_file,
          $local_file,
          1,                      # 1=file must exist after downloading, but size not important
          );

    if ( scalar(@aMsg))
        {
        my ( @aEmail ) =
            (
             "ERROR: Unable to retrieve $flavor" . "stat.qa file for $flavor data",
             "File on Intex server: $remote_file",
             "Destination file on your machine: $local_file",
             "Debug information:",
             "------------------------",
             @aMsg,
             );

        ComposeAndSendEmail
            (
             'e__',
             "ERROR: unable to download $flavor" . "stat.qa file for $flavor data",
             \@aEmail,
             );
        AppendLog ( "SKIP", "", \@aEmail) ;

        #return 1;
        next ; ### will try the remainder of the files instead of quitting.
        }

    # for one type e.g. wl, inhale eot file
    open ( TRACK, $local_file );
    my ( @aQa ) =  <TRACK>;
    close(TRACK);
    unlink ( $local_file ) ;

    # scan the .qa file; if perfdata, has only one data line in it; if remit, has NN lines; put data lines into array
    ##  file=ab_mh\remit.mh.200103|size=2657571|utc=990827223|signature=
    ##  file=ab_mh\remit.mh.200104|size=2713825|utc=993851707|signature=
    ##  file=ab_mh\remit.mh.200105|size=2913133|utc=996271041|signature=
    my @aQaLine = ();

    foreach my $line ( @aQa )  # still have cr/lf ... about to zap then
        {
        next if ( $line !~ /^file=[a-z]/ );
        $line =~ s/[\n\r]//g;
        push ( @aQaLine, $line );
        }

    # put latest files at the top
    @aQaLine = reverse(@aQaLine);

    # walk the lines, pulling the file that corresponds to each line, but jump out early if limit is set
    foreach my $line ( @aQaLine )
        {
        my ( @aTriplet ) = split(/\|/,$line);

        if ( $iMaxMonths > 0 )
            {
            if ( $aTriplet[0] =~ /file=.*\.(\d\d\d\d\d\d)\./ )
                {
                my $iFileYyyymm = $1;
                if( months_diff( $iCurYyyymm, $iFileYyyymm ) > $iMaxMonths )
                    {
                    next;
                    }
                }
            }

        AppendLog ( "GetPerfOrRemitData(): call worker to pull another $flavor file: $aTriplet[0]" );

        my ( $ret ) = possibly_get_perf_or_remit_file
            (
             $flavor,   # perf or "remit"
             $ty,       # e.g. abag
             \@aTriplet,   # e.g.
                        #    file=abag\abaghist.txt
                        #    size=39
                        #    utc=988358492
             $paEmailTxt,
             $phStatus,  # status from last time we ran this perf flavor ... we want 'cannot_force_utc'
             \$tried_to_set_utc_cnt,
             \$utc_err_cnt,  # will be remembered in config file
             $paDownloadedFiles
             );

        } # each line

    } # for each type e.g. abfr

# remember if we have utc problems if we learned anything this time around
if ( $tried_to_set_utc_cnt )
    {
    $phStatus->{'cannot_force_utc'} = $utc_err_cnt ? 1 : 0;
    my $write_err = '';
    write_name_val_file ( $status_fn, $phStatus, \$write_err );
    }

my $bSendEmail = 1 ;
if ( ! defined ( $hIniFile{'send_histdata_email'}  ))
    {
    $bSendEmail = 0 ;
    }
elsif ( defined ( $hIniFile{'send_histdata_email'}  ) && uc ( $hIniFile{'send_histdata_email'} ) eq 'N'  )
    {
    $bSendEmail = 0 ;
    }

# if have some success, tell user
$$p_did_download = 1;  # tell user

if ( scalar ( @$paEmailTxt ) && $bSendEmail )
    {

    my $szSubjecttoSend ;
    if ( $flavor eq 'perf' )
       {
       $szSubjecttoSend   = "Downloaded performance (historical) data" ;
       }
    elsif ( $flavor eq 'hist' )
       {
       $szSubjecttoSend   = "Downloaded historical data" ;
       }
    elsif ( $flavor eq 'deal_remit' )
       {
       $szSubjecttoSend   = "Downloaded deal remittance data" ;
       }
    elsif ( $flavor eq 'tranche_remit' )
       {
       $szSubjecttoSend   = "Downloaded tranche remittance data" ;
       }
    else
       {
       $szSubjecttoSend   = "Downloaded remittance data" ;
       }

    ComposeAndSendEmail
        (
          'e__',
          $szSubjecttoSend   , # email subject
          $paEmailTxt,          # msg to email; no EOL on lines; we will add them
          );
    }


} # GetPerfOrRemitData



# ------------------------------ GetRemitDiffData
# get remit diff data
# called because we have this ini file:
##  perfdata=abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,ag,cmbs,wl
##          AND/OR
##  remitdata=ab_au,ab_cc,ab_eq,ab_fp,ab_he,ab_mh,ab_rv,cmbs,wl

# if error, email user and return 1

sub GetRemitDiffData
{
my (
    $flavor,  # perf or "remit"  tranche_remit
    $subdir_list,  # e.g. abag,abau,abcc,abeq,abfp,abfr,abhe,abmh,abre,absl,cmbs,wl
    $p_did_download,
    $paDownloadedFiles
    ) = @_;

$$p_did_download = 0;



my ( $tgt_subdir ) = $hIniFile{"tgt_remit" . 'data_dir'};

if ( defined ( $hIniFile{"tgt_$flavor" . 'data_dir'} ) )
    {
    $tgt_subdir  = $hIniFile{"tgt_$flavor" . 'data_dir'} ;
    }
if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
    {
    $tgt_subdir = $hIniFile{"tgt_" .$flavor. '_data_dir'};
    }


AppendLog ( "GetRemitDiffData(): start;" );
AppendLog ("\n==== Check for new diff remittance data", 1 ) if ( $flavor eq 'rmtd' );
AppendLog ("\n==== Check for new diff tranche remittance data", 1 ) if ( $flavor eq 'tranche_remit' );
AppendLog ("\n==== Check for new diff deal remittance data", 1 ) if ( $flavor eq 'deal_remit' );

# must have tgt subdir ... if missing in ini file, we compute a default, so this error should not happen any more
if ( !defined ( $tgt_subdir  ) )
    {
    my ( @aEmail ) =
        (
         "ERROR: you need to define a destination subdirectory for $flavor diff data",
         "in your autodnld.ini file e.g.:",
         "  tgt_$flavor" . "data_dir=c:\\intex\\$flavor" . "data",
         );
    if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
        {
        ComposeAndSendEmail
            (
             'e__',
             "ERROR: you need to define \"tgt_$flavor" . "_data_dir\" in your autodnld.ini file",
             \@aEmail,
             );
        AppendLog ( "SKIP","", \@aEmail) ;

        }
    else
        {
        ComposeAndSendEmail
            (
             'e__',
             "ERROR: you need to define \"tgt_$flavor" . "data_dir\" in your autodnld.ini file",
             \@aEmail,
             );
        AppendLog ( "SKIP","", \@aEmail) ;

        }
    return 1;
    }

# we have a status file: does utime work etc
my $status_fn = "$hIniFile{'autodnld_home'}$slash" . "log$slash$flavor.status.log";
my $phStatus = read_name_val_file ( $status_fn );

# build up email here
my($paEmailTxt) = [];

# check each type that client is entitled to e.g. abfr
my $utc_err_cnt = 0;
my $tried_to_set_utc_cnt = 0;

foreach my $ty ( split ( /,/,$subdir_list ))
    {
    AppendLog ( "  check type=$ty", 1 );

    # mkdir if needed ... no error checking because ???
    MkdirAsReq ( "$tgt_subdir$slash$ty" );

    # always get the XXXXstat.qa file; else email error and return 1
    # this file is small, so not the end of the world that we always grab the whole file
    my ( $local_file ) = $tgt_subdir;
    if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
        {
        $local_file .= "$slash$ty$slash" . "diff$slash"."rmtdstat.qa" ;  # d:\temp\autodnld\perfdata\perfstat.qa
        }
    else
        {
        $local_file .= "$slash$ty$slash$flavor" . "stat.qa";  # d:\temp\autodnld\perfdata\perfstat.qa
        }

    my ( $remote_file ) = "/$hIniFile{'user'}/../remit" . "data/$ty/diff/$flavor" . "stat.qa";              # /bancone_cap/../perfdata/abag/perfstat.qa
    $remote_file  = "/$hIniFile{'user'}/../$flavor" . "_data/$ty/diff/rmtdstat.qa"  if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" ) ;              # /bancone_cap/../perfdata/abag/perfstat.qa

    if ( defined ( $hCrntEnv{'gets_custom_'.$flavor.'_data'} )  )
       {
       if ( $hCrntEnv{'gets_custom_remit_data'} == 1 )
          {
          #$remote_file  = "/$hIniFile{'user'}/../$flavor" . "data/$ty/$flavor" . "stat.qa";
          $remote_file  = "/$hIniFile{'user'}/$flavor" . "data/$ty/$flavor" . "stat.qa";
          }
       }

    my ( @aMsg )= DownloadFile
         (
          $remote_file,
          $local_file,
          1,                      # 1=file must exist after downloading, but size not important
          );

    if ( scalar(@aMsg))
        {
        if ( $flavor eq "tranche_remit" || $flavor eq "deal_remit" )
            {
            my ( @aEmail ) =
                (
                 "ERROR: Unable to retrieve rmtdstat.qa file for $flavor data",
                 "File on Intex server: $remote_file",
                 "Destination file on your machine: $local_file",
                 "Debug information:",
                 "------------------------",
                 @aMsg,
                 );

            ComposeAndSendEmail
                (
                 'e__',
                 "ERROR: unable to download rmtdstat.qa file for $flavor data",
                 \@aEmail,
                 );
            AppendLog ( "SKIP", "", \@aEmail) ;
            }
        else
            {
            my ( @aEmail ) =
                (
                 "ERROR: Unable to retrieve $flavor" . "stat.qa file for $flavor data",
                 "File on Intex server: $remote_file",
                 "Destination file on your machine: $local_file",
                 "Debug information:",
                 "------------------------",
                 @aMsg,
                 );

            ComposeAndSendEmail
                (
                 'e__',
                 "ERROR: unable to download $flavor" . "stat.qa file for $flavor data",
                 \@aEmail,
                 );
             AppendLog ( "SKIP", "", \@aEmail) ;
             }


        #return 1;
        next ; ### will try the remainder of the files instead of quitting.
        }

    # for one type e.g. wl, inhale eot file
    open ( TRACK, $local_file );
    my ( @aQa ) =  <TRACK>;
    close(TRACK);

    # scan the .qa file; if perfdata, has only one data line in it; if remit, has NN lines; put data lines into array
    ##  file=ab_mh\remit.mh.200103|size=2657571|utc=990827223|signature=
    ##  file=ab_mh\remit.mh.200104|size=2713825|utc=993851707|signature=
    ##  file=ab_mh\remit.mh.200105|size=2913133|utc=996271041|signature=
    my @aQaLine = ();

    foreach my $line ( @aQa )  # still have cr/lf ... about to zap then
        {
        next if ( $line !~ /^file=[a-z]/ );
        $line =~ s/[\n\r]//g;
        push ( @aQaLine, $line );
        }

    # put latest files at the top
    @aQaLine = reverse(@aQaLine);
    my $so_far = 0;

    # walk the lines, pulling the file that corresponds to each line, but jump out early if limit is set
    foreach my $line ( @aQaLine )
        {
        my ( @aTriplet ) = split(/\|/,$line);
        my $szFileDiff = $aTriplet[0] ;
        $szFileDiff =~ /\.(\d+)$/ ;
        my $szThisDiffDate = $1 ;

        my $szTodayYYYYMMDD_HHMM = stamp_as_yyyymmdd_hhmm ( ) ;
        my $szTodayYYYYMMDD = substr ( $szTodayYYYYMMDD_HHMM, 0, 8 ) ;
        my $szDaysBetweenDiff = DaysBetween ( $szThisDiffDate, $szTodayYYYYMMDD ) ;
        if ( $flavor eq "tranche_remit" )
           {
           next if ( abs ( $szDaysBetweenDiff ) > $hIniFile{'tranche_remit_diff_data_days_back'} ) ;
           }
        elsif ( $flavor eq "deal_remit" )
           {
           next if ( abs ( $szDaysBetweenDiff ) > $hIniFile{'deal_remit_diff_data_days_back'} ) ;
           }
        else
           {
           next if ( abs ( $szDaysBetweenDiff ) > $hIniFile{'rmtd_data_days_back'} ) ;
           }
        AppendLog ( "GetRemitDiffData(): call worker to pull another $flavor file: $aTriplet[0]" );

        my ( $ret ) = possibly_get_perf_or_remit_diff_file
            (
             $flavor,   # perf or "remit" or rmtd
             $ty,       # e.g. abag
             \@aTriplet,   # e.g.
                        #    file=abag\abaghist.txt
                        #    size=39
                        #    utc=988358492
             $paEmailTxt,
             $phStatus,  # status from last time we ran this perf flavor ... we want 'cannot_force_utc'
             \$tried_to_set_utc_cnt,
             \$utc_err_cnt,  # will be remembered in config file
             $paDownloadedFiles
             );

        $so_far++;

     #  # possibly jump out early
     #  if (  $hIniFile{'rmtd_data_days_back'} <= $so_far )
     #      {
     #      AppendLog ( "GetRemitDiffData(): stop considering remit data files because we hit limit of $hIniFile{'remit_data_months_back'}" );
     #      last;
     #      }

        } # each line

    } # for each type e.g. abfr

# remember if we have utc problems if we learned anything this time around
if ( $tried_to_set_utc_cnt )
    {
    $phStatus->{'cannot_force_utc'} = $utc_err_cnt ? 1 : 0;
    my $write_err = '';
    write_name_val_file ( $status_fn, $phStatus, \$write_err );
    }

# if have some success, tell user
if ( scalar ( @$paEmailTxt ))
    {
    $$p_did_download = 1;  # tell user

    ComposeAndSendEmail
        (
          'e__',
          ($flavor eq 'perf' ) ? "Downloaded performance (historical) data" : "Downloaded remittance diff data", # email subject
          $paEmailTxt,          # msg to email; no EOL on lines; we will add them
          );
    }


} # GetRemitDiffData

######################################################################################################################
######################################################################################################################


# --------------------- TryToDownloadAllDataTypes
# First check connection, then check for all data types that this customer downloads
# If one download type fails, don't continue with the other downloads e.g. if cmo fails, don't try for pooldata
# If have errors, email customer
# Return non zero if error (but currently ignored by caller)

sub TryToDownloadAllDataTypes
{
AppendLog ("TryToDownloadAllDataTypes(): start" );

# Check access to remote ship server; if have error may not email (if server is still down)
# NOTE: when we check access via "autodnld -t", we always show the error msg's right away
print "\n==== Check access to Intex server for user=$hIniFile{'user'}\n";
my $status;   # will return one of these phrases: up/down
my $just_changed;  # will return 1/0
my $down_for_nn_hours;  # will return 1/0

my @aAccessErr = CheckAccessToIntexServer
    (
     \$status,   # will return one of these phrases: up/down (but also check list of err msg that is returned)
     \$just_changed,  # will return 1/0
     \$down_for_nn_hours,  # will return 1/0
     );

if ( scalar(@aAccessErr) )
    {
    if ( $status eq 'down'  &&  $down_for_nn_hours == 1 )   # time to email after NN hours?
        {
        ComposeAndSendEmail
            (
             'e__',
             "ERROR: still cannot access Intex server",  # subject
             ["Debug information:",@aAccessErr],
             );

        print "\nERROR: still cannot access Intex server
Debug info:
" . join("\n",@aAccessErr) . "\n";
        AppendLog ( "SKIP", "", \@aAccessErr) ;

        return;
        }
    elsif ( $status eq 'down'  &&  $just_changed == 0 )   # still down; do not bombard users with email
        {
        print "\nERROR: still cannot access Intex server
Debug info:
" . join("\n",@aAccessErr) . "\n";
        AppendLog ( "SKIP", "", \@aAccessErr) ;

        return;
        }
    else
        {
        ComposeAndSendEmail
            (
             'e__',
             "ERROR: Intex autodnld failed",
             ["Debug information:",@aAccessErr],
             );
        AppendLog ( "SKIP", "", \@aAccessErr) ;

        print "\nERROR: cannot access Intex server
Debug info:
" . join("\n",@aAccessErr) . "\n";
        return;
        }
    }

# ok, ship server is available

AppendLog ( "TryToDownloadAllDataTypes(): Access to ship server is OK; distrib subdir=" . $hCmoState{'distrib_word'} );

# read .inf file if first time to figure out data types that customer gets; add settings to $hCrntEnv
ReadInfFile() ;
# if customer gets cmo data, give it a try
my $download_cmo_pool_bond_cnt = 0;  # keep count of downloads for a possible replicate

if ( $hCrntEnv{'gets_cmo_data'} )  # you can disable cmo using ARGV: -suppress_inf_cmo
    {
    print "\n==== Check for new CMO data\n";
    AppendLog ("TryToDownloadAllDataTypes(): Check for new CMO data");

    # return non empty string if need to email error (one blank=no email)
    my $iCaptureEotOnly=0;
    my $did_download = 0;

    my @aWrapperErrMsg = GetAllCMOWrapper
        (
         $iCaptureEotOnly,
         \$did_download,    # never clear; may set it
         );

    # if error...
    if ( scalar(@aWrapperErrMsg))
        {
        my @aMsg =
            ("Error trying to locate CMO data on ship server",
             "Debug info:",
             @aWrapperErrMsg,
             "This just may be a connection glitch during this launch.",
             "To verify you have successfully downloaded data during a prior launch, please open text file called cmotrack.log which is found in the autodnld\\log folder.  Scroll to the bottom.  The date\/time represent the last successful download.",
             );

        ComposeAndSendEmail
            (
             'e__',
              "ERROR: accessing CMO data",
              \@aMsg,
              );
        AppendLog ( "SKIP", "", \@aMsg) ;

        print join("\n",@aMsg) . "\n";
        }

    if ( $did_download )
        {
        $download_cmo_pool_bond_cnt++;
        }
    }

my @aDownloadedFiles = ();

# if customer gets pool data, give it a try
if( $hCrntEnv{'gets_pool_data'}  )   # you can disable pooldata using ARGV: -suppress_inf_pooldata
    {
    SetCmoStateHash ( "cmodata" ); # need flavored_log_dir
    FigureOutPoolBondHash ( "pool" );   # assumes 'bond_or_pool' is set
    my $did_download = 0;

    my @aErrMsg = PossiblyDownloadGroupData
        (
         \$did_download,  # may set to 1
         0,
         \@aDownloadedFiles,
         );

    if ( $did_download )
        {
        $download_cmo_pool_bond_cnt++;
        }

    # if have error, keep going (cmo was OK)
    if ( scalar(@aErrMsg) )
        {
        ComposeAndSendEmail
            ( 'e__',
              "ERROR: Download of pooldata failed",
              \@aErrMsg,
              );
        AppendLog ("SKIP", "", \@aErrMsg );

        print "ERROR: Download of pool data failed\nDebug info:\n" . join("\n",@aErrMsg) . "\n";
        }
    }

if( $hCrntEnv{'gets_pool_data_archive'} )
    {
    SetCmoStateHash ( "cmodata" ); # need flavored_log_dir
    FigureOutPoolBondHash ( "pool", 1 );   ### Archive area
    my $did_download = 0;

    my @aErrMsg = PossiblyDownloadGroupData
        (
         \$did_download,  # may set to 1
         1,
         \@aDownloadedFiles
         );

    if ( $did_download )
        {
        $download_cmo_pool_bond_cnt++;
        }

    # if have error, keep going (cmo was OK)
    if ( scalar(@aErrMsg) )
        {
        ComposeAndSendEmail
            ( 'e__',
              "ERROR: Download of old pooldata failed",
              \@aErrMsg,
              );
        AppendLog ("SKIP", "", \@aErrMsg );

        print "ERROR: Download of old pool data failed\nDebug info:\n" . join("\n",@aErrMsg) . "\n";
        }
    }

# if customer gets bond data, give it a try
if( $hCrntEnv{'gets_bond_data'} )
    {
    SetCmoStateHash ( "cmodata" ); # need flavored_log_dir
    FigureOutPoolBondHash ("bond");
    my $did_download = 0;

    my @aErrMsg = PossiblyDownloadGroupData
        (
         \$did_download,
         0,
         \@aDownloadedFiles,
         );

    if ( $did_download )
        {
        $download_cmo_pool_bond_cnt++;
        }

    # if have error, keep going (cmo was OK)
    if ( scalar(@aErrMsg) )
        {
        ComposeAndSendEmail
            ( 'e__',
              "ERROR: Download of bond data failed",
              \@aErrMsg,
              );

        AppendLog ("SKIP", "", \@aErrMsg );
        print "ERROR: Download of bond data failed\nDebug info:\n" . join("\n",@aErrMsg) . "\n";
        }
    }


# if customer gets perfdata, give it a try
my $perf_download_cnt = 0;  # keep count of downloads for a possible replicate

if ( $hCrntEnv{'gets_perf_data'} ne '' )
    {
    my $did_download = 0;

    GetPerfOrRemitData
        (
         'perf',
          $hCrntEnv{'gets_perf_data'},      # want codes e.g. abfr,cmbs
         \$did_download,
         \@aDownloadedFiles
         );

    $perf_download_cnt++ if ( $did_download );
    }

# remitdata
my $remit_download_cnt = 0;
my $deal_remit_download_cnt = 0;
my $tranche_remit_download_cnt = 0;

if ( $hCrntEnv{'gets_remit_data'} ne "" )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetPerfOrRemitData
        (
         'remit',
         $hCrntEnv{'gets_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;

    $remit_download_cnt++ if ( $did_download );
    }

if ( $hCrntEnv{'gets_deal_remit_data'} ne "" )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetPerfOrRemitData
        (
         'deal_remit',
         $hCrntEnv{'gets_deal_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;


    $deal_remit_download_cnt++ if ( $did_download );
    }

if ( $hCrntEnv{'gets_tranche_remit_data'} ne "" )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetPerfOrRemitData
        (
         'tranche_remit',
         $hCrntEnv{'gets_tranche_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;


    $tranche_remit_download_cnt++ if ( $did_download );
    }

# histdata
my $hist_download_cnt = 0;


if ( $hCrntEnv{'gets_hist_data'} ne "" )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetPerfOrRemitData
        (
         'hist',
         $hCrntEnv{'gets_hist_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;


    $hist_download_cnt++ if ( $did_download );
    }
my $remit_diff_download_cnt = 0;

if ( $hCrntEnv{'gets_remit_data'} ne "" && uc($hIniFile{'get_remit_diff_files'}) eq 'Y' )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetRemitDiffData
        (
         'rmtd',
         $hCrntEnv{'gets_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;

    $remit_diff_download_cnt++ if ( $did_download );
    }

my $tranche_remit_diff_download_cnt = 0;
if ( $hCrntEnv{'gets_tranche_remit_data'} ne "" && uc($hIniFile{'get_tranche_remit_diff_files'}) eq 'Y' )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetRemitDiffData
        (
         'tranche_remit',
         $hCrntEnv{'gets_tranche_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;

    $tranche_remit_diff_download_cnt++ if ( $did_download );
    }

my $deal_remit_diff_download_cnt = 0 ;
if ( $hCrntEnv{'gets_deal_remit_data'} ne "" && uc($hIniFile{'get_deal_remit_diff_files'}) eq 'Y' )
    {
    # email if error ???  email if ok ???
    my $did_download = 0;

    GetRemitDiffData
        (
         'deal_remit',
         $hCrntEnv{'gets_deal_remit_data'},
         \$did_download,
         \@aDownloadedFiles,
         ) ;

    $deal_remit_diff_download_cnt++ if ( $did_download );
    }

if ( scalar(@aDownloadedFiles) > 0 )
    {
    CreateGroupDataDownloadedList( \@aDownloadedFiles, 'group' );
    }



####################### possibly replicate

# for each data type: if the download count is GT 0, and if we have replicate subdirs, do the replication
possibly_replicate
    (
     $download_cmo_pool_bond_cnt,
     $perf_download_cnt,
     $remit_download_cnt,
     $remit_diff_download_cnt,
     $hist_download_cnt,
     $tranche_remit_download_cnt,
     $deal_remit_download_cnt,
     $tranche_remit_diff_download_cnt,
     $deal_remit_diff_download_cnt,
     );

return 0;

} # TryToDownloadAllDataTypes


# ----------------------- CheckLatestAutodnldVersion
# we can tell who is using autodnld by looking at GET in log file

##  -rw-rw-rw-   1 finance  5             279 Apr 24 11:29 autodnld.version.2.49a.txt
##  -rw-rw-rw-   1 finance  5             279 Apr 24 21:36 autodnld.version.2.49c.txt
##  -rw-rw-rw-   1 finance  5             279 May  1 10:12 autodnld.version.2.49d.txt

# NOTE: maybe some day check current version against latest version

sub CheckLatestAutodnldVersion
{
my ( $szLocalFile, $szFile, $szRemoteFile   );
my $func="CheckLatestAutodnldVersion()";
# grab special marker file
$szFile = "autodnld.version.$release_version.txt";  # e.g. 2.43
$szLocalFile =  "$hCrntEnv{'tgt_log_dir'}$slash" . $szFile;
$szRemoteFile = "/$hIniFile{'user'}/../public/$szFile";

my @aErr=DownloadFile
    (
     $szRemoteFile,
     $szLocalFile,
     0,                  # 0=no error check for existence after we try to download
     );
AppendLog("$func:".join("\n",@aErr))if(scalar(@aErr));
unlink ( $szLocalFile );

} # CheckLatestAutodnldVersion


# --------------- CreateFakeTrackingFiles
sub CreateFakeTrackingFiles
{
AppendLog("User is calling -c option to CreateFakeTrackingFiles");
# read .inf file if first time to figure out data types that customer gets; add settings to $hCrntEnv
ReadInfFile();

# warn users that this is a special option
print "
********************************************
********************************************
WARNING: the -c option \"fools\" autodnld
into thinking that all your data is totally
up to date.
********************************************
********************************************\n";



FakeGroupDataTrackingFile("pool") if( $hCrntEnv{'gets_pool_data'} );
FakeGroupDataTrackingFile("bond") if( $hCrntEnv{'gets_bond_data'} );

# no faking needed for perf data

# no faking needed for remit data

print "\n";

# cmo data?
my $iCaptureEotOnly = 1;
my $did_download = 0;

GetAllCMOWrapper
    (
     $iCaptureEotOnly,
     \$did_download,   # never clear; may set it
     );

} # CreateFakeTrackingFiles

########################################
# CheckAttribOfFile
#   -checks if a file is read only using attrib command
#
#

sub CheckAttribOfFile
{
my ( $szFileToCheck ) = @_ ;
my $szFiletoCheckPattern = $szFileToCheck ;
$szFiletoCheckPattern =~  s/([\\\/])/\\$1/g ;

my $szThisCmd = "attrib $szFileToCheck" ;

my @aCmdLines = `$szThisCmd` ;

foreach my $szOneLine ( @aCmdLines )
   {
   next if ( $szOneLine =~ /^\s*$/ ) ;
   if ( $szOneLine =~ /^A +R +$szFiletoCheckPattern/i )
      {
      return 1 ;
      }
   }

}

# ------------------ TestEmail
# Remember, emails have sections like to "--- How to contact..." and "--- System informaiton"...
sub TestEmail
{
$hCrntEnv{'email_retries'} = 1;

AppendLog ( "TestEmail(): start" );

ComposeAndSendEmail
    (
     $magic_email_id_for_testing,  # global
      "Test email sent by autodnld",
     ["This email message was sent by autodnld as a test"],
      );

print "\nEmail testing completed
Please check your email to see if you have received a message from autodnld

Press enter key to exit this test > ";
<STDIN>;

} # TestEmail


# -------------------------------- TestDbStatus
# run dbstatus qa for cmo and/or pool and/or bond
# called because
##   have -dbstatus command option
##   ??? other places ???
sub TestDbStatus
{
print "---- Run db status test(s)\n";

# read .inf file if never read yet to figure out data types that customer gets; add settings to $hCrntEnv
ReadInfFile();

if($hCrntEnv{'gets_cmo_data'} )
    {
    my $szCmoFlavor = "cmodata";
    SetCmoStateHash ( $szCmoFlavor);
    my @aErrMsg = RunDbStatusForCmo( 1 );

    if ( scalar(@aErrMsg) )
        {
        print "\nThere were errors:\n".join("\n",@aErrMsg)."\n";
        return 1;
        }

    print "There were no cmo db status errors, and an email was sent to that effect\n";
    }

return 0;

} # TestDbStatus

# -------------------------------- TestDbStatusWithUpload
# run dbstatus qa for cmo
# called because
##   have -dbstatus_upload command option
##   ??? other places ???
sub TestDbStatusWithUpload
{
print "---- Run db status test(s)\n";

# read .inf file if never read yet to figure out data types that customer gets; add settings to $hCrntEnv
ReadInfFile();

if($hCrntEnv{'gets_cmo_data'} )
    {
    my $szCmoFlavor = "cmodata";
    SetCmoStateHash ( $szCmoFlavor);
    my @aErrMsg = RunDbStatusForCmo(  );

    if ( scalar(@aErrMsg) )
        {
        print "\n\n\nThere were errors:\n".join("\n",@aErrMsg)."\n";
        return 1;
        }

    print "There were no cmo db status errors, and an email was sent to that effect\n";
    }

return 0;

} # TestDbStatusWithUpload


#-------------------------------------------OneHttpTest-------------------------------------------
#Input: 1 initial config, 2
# return: 0 success, 1 failure;
sub OneHttpTest {
  my $func="OneHttpTest()";
  # in case log file not defined during initial set up
  if (! defined $hCrntEnv{'log_file'})
  {
      $hCrntEnv{'tgt_log_dir'} = $hIniFile{'autodnld_home'} . $slash . "log";
      $hCrntEnv{'log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "autodnld.log";
  }
 #continue https test, need to initialize some variables for the sub
 AppendLog( "$func: now try to write a test file in current directory to upload....");

 my $szFileList="filelist.txt";
 my $oFileList=IO::File->new(">".$szFileList);
 if (defined $oFileList) {
    print $oFileList "HTTPTEST-autodnld.zip";
    $oFileList->close();
    AppendLog("$func: Start to upload $szFileList to Intex ....");

    my ($error,$sTempBinFile)=HTTPConnect($szFileList, 1);
    if($error eq '' ) {

       if ( ! -e $sTempBinFile )
           {
           my $sMsg = "$func:  ERROR - HTTPConnect Error - No error returned, but no content downloaded to $sTempBinFile. Please send a screen capture of this window, attaching file:".$hCrntEnv{'log_file'}." to autodnld_help\@intex.com\n";
           AppendLog($sMsg, 1);
           return 1;
           }

       AppendLog("Finished downloading a test file to $sTempBinFile. Start decoding...\n");
       my $sTempBufFH=IO::File->new("$sTempBinFile");
       if ( ! defined( $sTempBufFH ) )
           {
           my $sMsg = "$func:  ERROR - Unable to open download buffer file $sTempBinFile to read.  Please check permissions on this folder.\n";
           AppendLog( $sMsg, 1 );
           return 1;
           }

       my ($httpError,$pDoneList,$sFileLeftOver)=chunk_decoding($sTempBufFH);
       $sTempBufFH->close();
       my $szTestFile=$hIniFile{'temp_download_subdir'} . $slash.$$pDoneList[0];
      if ($httpError||$sFileLeftOver!=0)
      {
         my $sMsg = "$func:   ERROR - Server returned status:".$httpError.$hErrorMeaning{$httpError}." and Fileleftover=$sFileLeftOver. Please send a screen capture of this window, attaching files:".$hCrntEnv{'log_file'}.",$szTestFile,$sTempBinFile, to autodnld_help\@intex.com\n";
         AppendLog( $sMsg, 1 );
         return 1;
      }
      else {
         my $sMsg = "https test success! You can open $szTestFile to confirm that it can be unzipped correctly.\n";
         AppendLog( $sMsg, 1 );
         return 0;
      }
    }
    else {
       my $sMsg = "$func:  ERROR - HTTPConnect Error:".$error."\nPlease send the screen capture of this window, attaching files:".$hCrntEnv{'log_file'}.",$sTempBinFile, to autodnld_help\@intex.com\n";
       AppendLog( $sMsg, 1 );
       return 1;
    }
 }
 else {
    my $sMsg = "$func:  ERROR - Can't write a file in local directory prior to https test. Please check write permission of this directory!";
    AppendLog( $sMsg, 1 );
    return 1;
 }

}# end of OneHttpTest

#-------------------------------------------OneHttpFileTest-------------------------------------------
#Input: 1 initial config, 2
# return: 0 success, 1 failure;
sub OneHttpFileTest {

 while ( 1 )
    {
    my $iSleep = 5;
    my $local_file_after_decompress = "$hIniFile{'tgt_cdu_dir'}${slash}file_test.txt";
    my $remote_file = "/$hIniFile{'user'}/../public/test/file_test.txt.Z";
    my $iSize = 499998000;
    my $iCmpSize = 233994139;

    unlink($local_file_after_decompress);
    my @aTraceBack = DownloadAndDecompressZFile
        (
         $remote_file,  # e.g. /user/../mbspools/...
         $local_file_after_decompress,
         $iSize,           # final size when decompressed
         $iCmpSize,        # compressed size ... optional
         );
    my $sOut = "";
    if ( ! -e $local_file_after_decompress )
        {
        $sOut = "ERROR: File download failed";
        }
    elsif ( -s $local_file_after_decompress != $iSize )
        {
        $sOut = "ERROR: File download failed, size mismatch";
        }
    else
        {
        $sOut = "SUCCESS: File download succeeded";
        }
    $sOut .= ", sleeping for $iSleep seconds and trying again";
    AppendLog( $sOut );
    print $sOut."\n";
    sleep($iSleep);
    }

} # end of OneHttpFileTest

##--------------------TouchMarkFile-----

sub TouchMarkFile {
   my ($sFileName,)=@_;
   print "Write $sFileName..\n";
   if(!open(PARAMS,">$sFileName"))
     {
     print "ERROR: could not write $sFileName\n";
     exit(1);
     }
   print PARAMS time();
   close(PARAMS);
}
# ------------------------------ TestAutodnld
# Various tests: email, connection (also check subdirs), diskspace (unix only)
#
sub TestAutodnld
{
my ( $iFoundTransfer, $szYesNo, @aMsg, @aTraceBack, $szLine, $szOldConnection, @aValidServer, @aInValidServer );

print "\nAutodnld connection test:\n";

print "\nDo you want to test access to the Intex server?\n";
print "Please enter y/n and press enter > ";
$szYesNo = <STDIN>;
exit(0) if ( $szYesNo =~ /^n/i );
if ( $szYesNo =~ /^y/i )
    {
    my @aMsg = CheckAccessToIntexServer(undef,undef,undef, 1 );  ## will not check alternate servers here.

    if ( scalar(@aMsg) )
       {
       push @aInValidServer, $hIniFile{'connection'} ;
       print "There were ERRORS accessing the Intex server
About to show debug information ... press enter key > ";
       <STDIN>;
       print "\n" . join("\n",@aMsg) . "\n\n ... press return key to end test > ";
       <STDIN>;
       }
    else
       {
       push @aValidServer, $hIniFile{'connection'} ;
       print "There were no difficulties accessing the Intex server; ";
       print "Press any key to end access test >";
       <STDIN>;
       }
    }

# servere access (also look for distrib*)?
if ( uc( $hIniFile{'try_alternate_server'} ) ne "N" )
    {
    if ( defined  ( $hIniFile{'new_servers'} ) )
       {
       my @aNewServers = split ( /\,/, $hIniFile{'new_servers'} ) ;
       AppendLog ( "TestAutodnld (): Found ini entry for \"new_servers\".  will add the following servers to the list of servers to check: ". join ( ", ", @aNewServers ) ) ;
       push @aPossibleIntexServers, @aNewServers ;
       }

    print "\nDo you want to test access to alternate Intex servers?";
    print "\nWe will keep track of which ones were successful. Later if there is an error with one server we will try the other ones.";
    print "\nThe list of servers we will check are:\n". join ("\n", @aPossibleIntexServers ) ."\n";
    print "Please enter y/n and press enter > ";


    $szYesNo = <STDIN>;

    if ( $szYesNo =~ /^y/i )
        {
        $szOldConnection = $hIniFile{'connection'} ;
        foreach my $szOneServer ( @aPossibleIntexServers )
            {
            next if ( uc($szOneServer) eq uc ( $szOldConnection )  ) ;
            print "\nStart of test of the server=$szOneServer:\n" ;
            AppendLog ( "TestAutodnld (): Start of test of the server=$szOneServer:"  ) ;
            $hIniFile{'connection'} = $szOneServer ;
            my @aMsg = CheckAccessToIntexServer(undef,undef,undef, 1);

            if ( scalar(@aMsg) )
               {
               push @aInValidServer, $szOneServer ;
               AppendLog ( "TestAutodnld (): There were ERRORS accessing the Intex server=$szOneServer:\n" .  join("\n",@aMsg) ) ;
               print "There were ERRORS accessing the Intex server=$szOneServer
About to show debug information ... > ";
               print "\n" . join("\n",@aMsg) . "\n\n ... Will try next server > ";
               }
            else
               {
               push @aValidServer, $szOneServer ;
               AppendLog ( "TestAutodnld (): There were no difficulties accessing the Intex server=$szOneServer\n" .  join("\n",@aMsg) ) ;
               print "There were no difficulties accessing the Intex server=$szOneServer;  ";
               }
            }
        AppendLog ( "TestAutodnld (): The invalid servers are:\n".join ( "\n", @aInValidServer ) . "\n\n" ) ;
        print "\nThe invalid servers are:\n".join ( "\n", @aInValidServer ) . "\n\n";
        if ( scalar ( @aValidServer ) )
           {
           AppendLog ( "TestAutodnld (): The valid servers are:\n".join ( "\n", @aValidServer ) ) ;
           print "\nThe valid servers are:\n".join ( "\n", @aValidServer ) ;
           if ( open ( VALID, ">". $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "available_servers.txt" ) )
               {
               print VALID join ( "\n", @aValidServer ) ;
               }
           print "\n\n\nWe keep this list of valid servers in the file: ". $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "available_servers.txt";
           print "\nYou can edit the lines in this file to change the check order, and check list.";
           print "\nAlso for any new servers that may come online you can add a line to the ini file \"new_servers=SERVER1,SERVER2,etc.\". You will receive a notice from Intex if any new servers come online\n\n";
           }
        else
           {

          my @aTempListOfFiveCauses =
              (
               "1) Problem connecting from the autodnld machine to your firewall",
               "2) Firewall machine not allowing access to Intex server",
               "3) Intex server not online",
               "4) Your IP address has changed",
               "5) Incorrect password provided to the Intex server",
               "Also see if any changes made to your firewall",
               );
           AppendLog ( "TestAutodnld (): There were no valid servers" ) ;
           print "\n!!!!!!!! There were no valid servers!!!!!!!!!!" ;
           print "\n!!!!!!!! Please check your internet connection !!!!!!!!!!" ;
           print "\nPossible causes:\n" . join ( "\n", @aTempListOfFiveCauses ) ;
           }

        }

    }
TestOthers();

print "\nNormal end of testing\n";
return;
} # End of TestAutodnld

#-----------------------------TestOthers----------------------------
# Additional test besides connection, if ever get to this stage
# email test, disk_space_cmd test etc.
sub TestOthers {
   my ($szYesNo,@aTraceBack,$szLine);
# email test?
if ( $hIniFile{'email_to'} ne "")
    {
       print "\nDo you want to test email?\n";
       print "Please enter y/n and press enter > ";
       $szYesNo = <STDIN>;

       if ( $szYesNo =~ /^y/i )
           {
           # will show debug info
           TestEmail();
           }
    }

# test diskspace command
# NOTE: only if there is a disk space command (UNIX only), test it
if ( defined($hIniFile{'disk_space_cmd'}) && length($hIniFile{'disk_space_cmd'})  )
    {
    print "\nThere is a supplementary diskspace Perl script which can be tested
Perform test now <y/n>? > ";
    my $szResponse = scalar(<STDIN>);

    if ($szResponse !~ /[yY]/)
        {
        my( $iDiskSpace);
        AppendLog ("\n\nTesting disk_space_cmd:\n",1 ); # print flag = 1
        $iDiskSpace = DiskSpaceAvailable( $hIniFile{'tgt_cdu_dir'}, \@aTraceBack);
        AppendLog ("\n\nThere are $iDiskSpace bytes in subdir=$hIniFile{'tgt_cdu_dir'}\n",1 ); # print flag = 1

        # show traceback
        print "\n --------- traceback from disk space routine \n";

        foreach $szLine (@aTraceBack )
            {
            print "$szLine\n";
            }

        print "----------- end traceback\n";
        }
    }
 return;
} #end of TestOthers


####  DownloadIdShipping

sub DownloadIdShipping
{


my ( @aIdLines, @aIdLinesErr ) ;
my $szRemoteIdDir        = "/$hIniFile{'user'}/$hCmoState{'distrib_word'}/id/";
my $func = "DownloadIdShipping" ;
#Checked with Christine, we don't do dbstatus for ID.
$::bNeedToRunDbstatus = 0 ;
print "\nChecking for intra-day shipping files..." ;
my $sOrigCMOFlavor=$hCmoState{'cmo_flavor'}; #save for restore back after ID shipping
$hCmoState{'cmo_flavor'}  = "intraday" ; ## for use in checking eot lines
SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
my $szTrackingFile = $hCmoState{'id_tracking_file'} ;
AppendHashInfoToLogFile ( "Contents of hCmoState hash", \%hCmoState ) if ( LogThis( 'gen' ) > 0 );

AppendLog ( "$func: starting processing id shipment" ) ;


AppendLog ( "$func: getting remote dir: $szRemoteIdDir        " ) ;
GetRemoteDir
    (
     $szRemoteIdDir, # want dir on this path
     \@aIdLines,               # return lines to us; no CRLF on end
     \@aIdLinesErr,
     2
     );
if ( scalar ( @aIdLinesErr ))
    {
    AppendLog ( "$func: error getting remote dir:".  join ( "\n", @aIdLinesErr )  ) ;
    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return ( @aIdLinesErr ) ;
    }


my $szEot = FindEotInDirListing ( @aIdLines);

if ( defined($szEot) )
   {
   }
else
   {
   AppendLog ( "$func: no eot file present...assume no id shipments available" ) ;

   $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
   SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
   return ;
   }

# if have serial number, remember it
my $szIdShipNum = $1 if ( $szEot =~ /eot\.(\d+)\.txt/ );

my $szRemoteFileArg = "$szRemoteIdDir"."$szEot";
my $szLocalFileArg =  "$hCmoState{'flavored_log_dir'}$slash" . "id.eot" ;

AppendLog ( "$func: about to download file
remote=$szRemoteFileArg
local=$szLocalFileArg" );
my @aDownloadFileErrMsg;

@aDownloadFileErrMsg = DownloadFile
   (
   $szRemoteFileArg,
   $szLocalFileArg,
   1,             # 1 means this: file must exist e.g. download must succeed, but do not check size in bytes
   );

if ( scalar(@aDownloadFileErrMsg) )
    {
    unlink ( $szLocalFileArg );

    my @aMsg = ();
    push ( @aMsg, "$func() we were unable to download an eot file from the Intex server" );
    push ( @aMsg, "src file=$szRemoteFileArg");
    push ( @aMsg, "Debug info from DownloadFile():" );
    push ( @aMsg, @aDownloadFileErrMsg );
    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return @aMsg;
    }

if ( ! ( -e $szLocalFileArg ) )
    {
    my @aMsg = ();
    push ( @aMsg, "$func(): we were not able to download the eot file from the intraday CMO area" );

    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return @aMsg;
    }

my @aCouldPull = ();
my @aEotLine= ();

# if contents of eot file is in tracking file...
open ( EOT, $szLocalFileArg );
my $szEotLine = <EOT>;
close(EOT);
$szEotLine =~ s/[\n\r]//g;

if ( HaveEotInTrackingFile  ( $szEotLine, "id" ) )
    {
    AppendLog ( "$func: already have line=$szEotLine in tracking file $szTrackingFile from file=$szLocalFileArg " );
    print "\nProcessing ID shipment: already have line=$szEotLine in tracking file $szTrackingFile will not re-check for new files\n" ;

    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return ;
    }
else
    {
    AppendLog ( "$func: possibly pull data; file=$szLocalFileArg " );
    }

### cycle through all files and get them


## get ship info to check diskroom
my ( $szCompressedFmt, $szLocalFileShipInfo  ) ;
foreach my $szLine (@aIdLines)
    {
    my @aLine = split(/\s+/,$szLine);
    my $szName = $aLine[8];     # cmo_cdi.zip
    $szName=$aLine[1];
    if ( $szName =~ /shipinfo.\d+\.([^\d]+)$/i  )
        {
        $szCompressedFmt = $1 ;
        last ;
        }
    }
if ( $szCompressedFmt eq "" )
    {

    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return ( "Unable to see a shipinfo file on the Intex server under the split directory" ) ;
    }

my $phCmo = {};
my %hCmoShipState=();

# put all kinds of stuff in hCmoShipState
$phCmo->{'local_eot_file'} = $szLocalFileArg ;
$phCmo->{'descr'} = "id shipment" ;
$phCmo->{'shipment_stamp'} = $szEotLine ;

# figure out short pull path e.g. distribution/last4 or distribution/flash/last4
$phCmo->{'short_pull_path'} =  $hCmoState{'distrib_word'} . "/id";
$phCmo->{'long_pull_path'} = "/$hIniFile{'user'}/$phCmo->{'short_pull_path'}";
$phCmo->{'dir_listing'}    =  \@aIdLines ;

## xompress_extension is unknown.
if ( defined( $szIdShipNum  ) )
    {
    $phCmo->{'compressed_info_file'} =  "shipinfo.$szIdShipNum.$szCompressedFmt" ;
    $phCmo->{'ShipTimeStamp'} = $szIdShipNum;
    }
else
    {
    $phCmo->{'compressed_info_file'} =  "shipinfo.$szCompressedFmt" ;
    }
my $szIdShipListfile = $hCmoState{'flavored_log_dir'} ."$slash"."shiplist.txt" ;

my $szIdCmoStatQA = $hCmoState{'flavored_log_dir'} ."$slash"."cmostat.qa" ;
FixSlashes(\$szIdShipListfile,"native");
FixSlashes(\$szIdCmoStatQA,"native");

unlink ( $szIdShipListfile ) ;

my $szErrMsg = DownloadShipInfoAndCheckDiskSpace
        (
         $phCmo,
         );

if ( $szErrMsg ne "" )
    {

   $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
   SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return ( "$func(): had error pulling ship info file", "Debug info from DownloadShipInfoAndCheckDiskSpace():", $szErrMsg );
    }


my @aMsg ;
if ( ! -e $szIdShipListfile )
   {
    push ( @aMsg, "$func() we were unable to uncompress the shiplist file for intra-day shipping" );
    push ( @aMsg, "file=$szIdShipListfile did not exist");

    $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
    SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
    return @aMsg;
   }
#we keep a Donelist for intraday on disk. We will use it for intraday only and erase it if we have regular downloads happening.
my $szIdShipListDone="$hCrntEnv{'tgt_log_dir'}".$slash."intraday".$slash."shiplistDone.txt";
FixSlashes(\$szIdShipListDone,"native");

if (-e $szIdShipListDone) {
   AppendLog("$func: Found intraday $szIdShipListDone and we will remove the files already downloaded from $szIdShipListfile");
   my $szErrMsg=CompareAndRemove($szIdShipListfile,$szIdShipListDone);
   if ( $szErrMsg ne "" )
       {
      #report error and plow ahead
         AppendLog("$func: CompareAndRemove $szIdShipListDone from $szIdShipListfile returned error:".$szErrMsg.". We ignore and continue...");
       }
  elsif ((stat($szIdShipListfile))[7]==0) {
     AppendLog("$func: After comparing $szIdShipListDone and $szIdShipListfile, it appears that your intraday is up to date. No need to download.");
     $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
     SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
     return;
  }
}

my $szIDRetry=1; # for http grab, we will retry three times in stream fashion. For legacy mode, that means three errors
   #we use the list to keep  track how many still missing
#loop this retry 3 times or files to be downloaded are empty
if ($hCmoState{'usehttp'}=~ /HTTP/i)
      {
   #retry is done in subroutine
         my @aThisMsg = HTTPDownLoadSet
                  (
                     $phCmo,
                     );

         if ( scalar(@aThisMsg) )
            {

               $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
               SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
               return ( "$func(): had trouble downloading data file, or unpacking it", "Debug info from Download", @aThisMsg );
            }
         }
else {

   while (($szIDRetry<=3)&&(-e $szIdShipListfile)&& ((stat($szIdShipListfile))[7]>0)) {
      #legacy mode
       open ( SHIPLIST, $szIdShipListfile );
       my @aShipList = <SHIPLIST>;
       close(SHIPLIST);
       my $phDone;
       foreach my $szOneShipList ( @aShipList )
            {
            $szOneShipList =~ s/[\n\r]//g;
            my ( $szFileOnShipServer, $szFileToBeOnLocal ) = split ( /\|/, $szOneShipList )  ;
            my $szFirstChar = substr ( $szFileOnShipServer, 0 , 1 ) ;
            my $szSecondChar = substr ( $szFileOnShipServer, 1 , 1 ) ;
            my $bIsCdi  = ( $szFileToBeOnLocal =~ /cmo_cdi/i ? 1 : 0 ) ;
            my $bIsCdu  = ( $szFileToBeOnLocal =~ /cmo_cdu/i ? 1 : 0 ) ;

            my $szDirToBeOnLocal = $szFileToBeOnLocal ;
            $szDirToBeOnLocal =~ s/cmo_cdi|cmo_cdu// ;
            $szDirToBeOnLocal =~ s/\/[^\/]+$/\// ;
            AppendLog ( "$func: will download new file with retry count=$szIDRetry: $szFileOnShipServer to go here $szFileToBeOnLocal" );
            print "Downloading zip file for....$szFileToBeOnLocal\n" ;
            my $szRemoteDir = "/shipdata/links/$szFirstChar/$szSecondChar/" ;
            my $szRemoteFile = "$szRemoteDir".$szFileOnShipServer ;
            my $szLocalFile = $hIniFile{'temp_download_subdir'} . $slash. $szFileOnShipServer ;
            my $szLocalDir ;

            my @aIdShipDirFiles ;
            my @aIdShipDirFilesErr ;

            if ( $bIsCdi )
               {
               #$szLocalDir = $hCmoState{'cmo_cdi_dir'} . $szDirToBeOnLocal ;
               $szLocalDir = $hCmoState{'cmo_cdi_dir'} ;
               }
            elsif ( $bIsCdu )
               {
               #$szLocalDir = $hCmoState{'cmo_cdu_dir'} . $szDirToBeOnLocal;
               $szLocalDir = $hCmoState{'cmo_cdu_dir'} ;
               }
            else
               {
               AppendLog ( "$func: problem, could not determine if file is cdi or cdu: $szFileToBeOnLocal" );
               next ;
               }

            FixSlashes(\$szLocalFile,"native");
            FixSlashes(\$szLocalDir,"native");

            my ( @aErr) = DownloadFile
                        (
                         $szRemoteFile,
                         $szLocalFile,
                         1 ,   # file must exist after downloading, and size must be NNN
                         );
              if ( @aErr)
                 {

                  $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
                  SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
                  return ("There were errors when downloading file=$szRemoteFile", "--- Traceback:", @aErr );
                 }

              my @aErrMsg ;
              if( UncompressFile
                  (
                   $szLocalFile,
                   \@aErrMsg,
                   $szLocalDir , # unless Win and .zip, will chdir() to dest subdir
                   ))
                  {

                  $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
                  SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
                  return ("There were errors when decompressing file=$szLocalFile (file in use?)", "--- Traceback:", @aErrMsg);
                  }

              # zap the compressed cdi file (may be serialized and they pile up fast)
              ZapSerializedFile ( $szLocalFile ); # if .Z file, also try to zap file w/o the Z

             open (SHIPDONE, ">>$szIdShipListDone" ) ;
             print SHIPDONE "$szFileOnShipServer\n" ;
             close(SHIPDONE);
             $phDone->{$szFileOnShipServer}=1;

            }


    $szErrMsg=CompareAndRemoveMem($szIdShipListfile,$phDone);
    if ( $szErrMsg ne "" )
        {

        $hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
        SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
        return ( "$func(): had error---",$szErrMsg,"---please check read/write access of the file" );
        }

    $szIDRetry++;
   }
}

AddLineToTrackingFile ( $szTrackingFile, $szEotLine ) ;
AppendLog ( "$func: All done processing id shipping.") ;


my $cmostat_qa_fn = "$hCmoState{'cmo_cdu_dir'}$slash" . "cmostat.qa";

if ( $::bNeedToRunDbstatus )
   {
    my $szIdDbstatusOutput = $hCmoState{'flavored_log_dir'} ."$slash"."dbstatus_intraday.rpt" ;
    FixSlashes(\$szIdDbstatusOutput,"native");

    my @aErrRet = RunDbStatusForCmo ( "", $szIdCmoStatQA, );

     if ( scalar(@aErrRet ) )
        {
         my @aMsg =  ( @aErrRet );
         ComposeAndSendEmail ( 'e12', "Error in db status check", \@aMsg );
        }
   }

#copy_file ( $szIdCmoStatQA, $cmostat_qa_fn ) ; ### so to run dbstatus later.

$hCmoState{'cmo_flavor'}  = $sOrigCMOFlavor;
SetCmoStateHash ( $hCmoState{'cmo_flavor'}  ) ;
return ;

} # end DownloadIdShipping

## UpdateExe downloads and replace the latest exe file.
#
#
sub UpdateExe
{
my $szLocalExe = $hIniFile{'autodnld_home'} . $slash . "scripts" . $slash . "autodnld_run.exe"  ;
my $func = "UpdateExe" ;
if ( ! -e $szLocalExe  )
    {
    print "\n\n...a local exe does not exist.. so will not download" ;
    return ( 0, "Not using an exe" ) ;
    }
if ( $is_unix )
    {
    AppendLog ( "$func(): Error, this function is for windows only.", 0 );
    return ( 1, "Cannot Update the exe because you are running in unix, and this is not available to unix clients for technical reasons" ) ;
    }

my ( $szThisVersionDate ) ;

my $szLocalLastUpdate = $hIniFile{'autodnld_home'} . $slash . "log" . $slash . "last_update.txt"  ;


if ( -e $szLocalLastUpdate )
    {
    open ( UPDATE, $szLocalLastUpdate ) ;
    my @aUpdateLines = <UPDATE> ;
    close UPDATE ;
    foreach my $szOneUpdateLine ( @aUpdateLines )
        {
        if ( $szOneUpdateLine =~ /^(\d+)/ )
           {
           $szThisVersionDate = $1 ;
           last ;
           }
        }
    }
else
    {
    $szThisVersionDate = 0 ;
    }

my ( $iSizeLocal ) = ( stat ( $szLocalExe ) )[7] ;
my ( @aDirLine, @aDirMsg ) ;

print "\nChecking for an update to autodnld software...." ;

AppendLog ( "$func(): Will try to download the lateset autodnld.exe file", 0 );
if ( $is_unix )
    {
    AppendLog ( "$func(): Error, this function is for windows only.", 0 );
    return ( 1, "Cannot Update the exe because you are running in unix, and this is not available to unix clients for technical reasons" ) ;
    }

AppendLog ( "$func(): About to download the latest exe.  The file is named a txt file on the intex server to make it easier to download.", 0 );

my $szExeFile = "autodnld.version.exc.txt";  # e.g. 2.43
my $szLocalFile =  $hIniFile{'autodnld_home'} . $slash . "scripts" . $slash . "autodnld_run.new" ;
my $szRemoteFile = "/$hIniFile{'user'}/../public/$szExeFile";

unlink ( $szLocalFile  ) ;

GetRemoteDir
    (
     "/$hIniFile{'user'}/../public/",
     \@aDirLine,               # return lines to us; no CRLF on end
     \@aDirMsg
     );
my ( $bFoundFile ) ;

AppendLog ( "$func(): Start Looking for new exe", 0 ) ;
my ( $szVersionAvailable ) = "200504011233" ;
my ( $bSameVersion ) = 0 ;

foreach my $szOneLine ( @aDirLine )
    {
    my @aToken = split( /\s+/, $szOneLine );
    my $szName = $aToken[1] ;
    my $iSize = $aToken[2] ;
    if ( $szName =~ /autodnld\.version\.exc\.txt\.(\d+)/i )
        {
        my ( $szThisVersionAvailable ) = $1 ;
        if ( $szThisVersionDate >= $szThisVersionAvailable )
            {
            $bSameVersion  = 1 ;
            AppendLog ( "$func():Found Autodnld version from time: $szThisVersionAvailable on intex server is not newer than local one will not download" ) ;
            }
        elsif ( $szThisVersionDate < $szThisVersionAvailable && $szThisVersionAvailable > $szVersionAvailable )
            {
            $bFoundFile = 1 ;
            $szVersionAvailable = $szThisVersionAvailable ;
            $szRemoteFile = "/$hIniFile{'user'}/../public/$szName";
            $iSizeLocal=$iSize; #this is the expected size of the new file
            AppendLog ( "$func(): autodnld on intex server is different...will proceed to download", 0 ) ;
            }
        }
    }

return ( 0, "\nAutodnld on intex server is same as local one...does not need updating" )  if ( ! $bFoundFile && $bSameVersion  ) ;
return ( 1, "Could not find the autodnld update file" )  if ( ! $bFoundFile ) ;

#return "" ;

DownloadFile
    (
     $szRemoteFile,
     $szLocalFile,
     #0,                  # 0=no error check for existence after we try to download
     );

if ( -e $szLocalFile )
    {
    ## Check size
    my ( $iSizeActualLocal ) = ( stat ( $szLocalFile ) )[7] ;
    if ( $iSizeLocal != $iSizeActualLocal )
       {
       AppendLog ( "$func(): Failed downloading exe, after transfer, file is not same size. supposed to be $iSizeLocal but is $iSizeActualLocal", 0 );
       AppendLog ( "$func(): Renaming downloaded file as $szLocalFile" . ".bad" , 0 );
       rename ( $szLocalFile , $szLocalFile .".bad"  )  ;
       return ( 1, "Failed downloading new file, after transfer, file is not same size. supposed to be $iSizeLocal but is $iSizeActualLocal" ) ;
       }
    #looks like download succesfully

    rename($szLocalFile, $szLocalFile.".exe");
    my @aResult = `$szLocalFile.exe -ta`;
    rename($szLocalFile.".exe", $szLocalFile);
    AppendLog("$func(): Ran new autodnld version in test mode. Here is the result:\n".join("\n", @aResult));
    if(!grep(/Autodnld Test Success!/, @aResult))
    {
        AppendLog ( "$func(): New autodnld successfully downloaded, but failed in test mode.", 0 );
        rename ( $szLocalFile , $szLocalFile .".bad"  )  ;
        return ( 1, "New autodnld successfully downloaded, but failed in test mode." ) ;
    }
    else
    {
        AppendLog ( "$func(): New autodnld successfully downloaded, succeeded in test mode.", 0 );
    }

    open ( UPDATE, ">$szLocalLastUpdate" ) ;
    print UPDATE "$szVersionAvailable" ;
    close UPDATE ;
    return 0;
    }
else
    {
    AppendLog ( "$func(): Failed downloading exe, after transfer, file did not exist", 0 );
    return ( 1, "Failed downloading new file, after transfer, file did not exist" ) ;
    }
}

# ----------------------------- main
# QA: cd d:/autodnld/scripts, and run:  perl -w autodnld_run.pl
$| = 1;
my $func = "main";

# if running .pl source, pull in modules (same subdir)
# if compiled, we used arg to imbed the source in the exe
# if debug, may have to use -I switch
require "autodnld_download_file.pl";
require "autodnld_get_dir.pl";
require "autodnld_replicate_database.pl";

## chdir ( "d:/autodnld/scripts" );

# NOTE: error handling: if error, sub's should pass back lists of error messages; also, write to log file immediately
print "==== Intex autodnld; version $release_version ($release_date) ====\n";

# ok, start bootstrapping ourself up
$hCrntEnv{'email_retries'} = 3;
$hCrntEnv{'cmodata_keyword'} = "cmodata";
@::aSIFFile = ();    # lines in .sif file: has amount of megs in shipment, total files etc (crlf cleaned off)

# if -config or -self_extracting_exe arg, do the config and done
if ( scalar(grep(/\-config/i, @ARGV ) ) )
{
    %hIniFile = ();   # will call back to this module, so share global
    require "autodnld_config.pl";
    edit_ini_file();  # will exit();
}

# read ini file into global "%hIniFile"; if multiple tgt_cdu_dir, split off the extra subdirs; no checking for missing values yet
# NOTE: inf file has NOT been read yet; it is read much later on; we do various computations when we read the inf file
# caller will next call CheckAndDeriveIniInfo() if we return w/o error
# if error (only error is cannot read .ini file: write to console and return non zero if error; caller will abort autodnld program; NOTE: there is NO log file yet
if ( ReadIniFile("autodnld.ini" ) )
{
    print "Exiting autodnld program due to error reading ini file\n";
    exit(1);
}

# set useful globals; fatal error to console if cannot
if ( !defined ($hIniFile{'operating_system'}))
{
    print "Exiting autodnld program due to error in .ini file:
  There is no value for \"operating_system\"\n";
  my ( @aCustomerLog ) = ( "Error in autodnld.ini file", "Needs a value for \"operating_system\"" ) ;
  AppendLog ( "SKIP","", \@aCustomerLog ) ;
   exit(1);
}

if ( $hIniFile{'operating_system'} eq "unix" )    # unix/nt/win95/win98
{
   $is_unix = 1;
   $slash = "/";    # global
}
else
{
   $is_unix = 0;
   $slash = "\\";    # global
   $com_spec = $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c";
}

# make sure we have temp_download_subdir if defined in ini file (no error checking because ???)
MkdirAsReq ( $hIniFile{'temp_download_subdir'} ) if ( defined ( $hIniFile{'temp_download_subdir'} ) );

# we are about to compute names of log files; fatal error to console if cannot
if ( !defined ($hIniFile{'autodnld_home'}))
{
    print "Exiting autodnld program due to error in .ini file:
  There is no value for \"autodnld_home\"\n";
  my ( @aCustomerLog ) = ( "Error in autodnld.ini file", "Needs a value for \"autodnld_home\"" ) ;
  AppendLog ( "SKIP","", \@aCustomerLog ) ;
   exit(1);
}

$hCrntEnv{'tgt_log_dir'} = $hIniFile{'autodnld_home'} . $slash . "log";

# compute names of log files (for cmo flavor=flash, use log/flash etc)
$hCrntEnv{'log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "autodnld.log";
$hCrntEnv{'error_log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "last_error.log";
$hCrntEnv{'successful_log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "successful_download.log";
$hCrntEnv{'sum_log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "autodnld.sum.log";
$hCrntEnv{'email_log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "email.log";
$hCrntEnv{'replicate_session_log_file'} = "$hCrntEnv{'tgt_log_dir'}" . $slash . "replicate.session.log";
print "FYI: Log file=$hCrntEnv{'log_file'}\n";
AppendLog ( "\n\n".scalar(localtime())." --------------------------- START; version=$release_version ($release_date); pid=$$" );

# check for missing ini values; fill in default values if missing; derive a few %hCrntEnv keys also
if ( CheckAndDeriveIniInfo() )
{
   exit(1);
}

if ( LogThis('gen') > 0 )
    {
    AppendHashInfoToLogFile ( "Contents of hIniFile hash (full)", \%hIniFile )
    }
else
    {
    AppendHashInfoToLogFile ( "Contents of hIniFile hash", \%hIniFileOrig );
    }

# add to log if UNIX: os info
if ( $hIniFile{'operating_system'} eq "unix" )
    {
    my ( @aLine );
    @aLine = `uname -a`;
    AppendLog ( "uname -a output: " . join("",@aLine) );
    }

# check disk room for log subdir
if ( 1 )
{
    my ( @aTrace ) = ();
    my ( $free ) = DiskSpaceAvailable ( "$hCrntEnv{'tgt_log_dir'}", \@aTrace );

    if ( $free < 50000000 )
        {
        my ( @aCustomerLog ) = ( "Not enough diskroom", "We checked room in  the log subdir=$hCrntEnv{'tgt_log_dir'}", "We need at least 50 meg.", "Size we obtained=$free.", "--- Debug info ----:".join ("\n",@aTrace) ) ;
        AppendLog ( "ERROR: not enough disk room
  We checked room in  the log subdir=$hCrntEnv{'tgt_log_dir'}
  We need at least 50 meg.
  Size we obtained=$free.
--- Debug info ----:
" . join("\n",@aTrace) . "\n","", \@aCustomerLog );

        print  "ERROR: not enough disk room
  We checked room in  the log subdir=$hCrntEnv{'tgt_log_dir'}
  We need at least 50 meg.
  Size we obtained=$free.
--- Debug info ----: ";
        exit(1);
        }
}

$::bLeaveUncompressed = 0;

# dump hCrntEnv hash to log
AppendHashInfoToLogFile  ( "Contents of hCrntEnv hash ... will dump it again when we read the .inf file:", \%hCrntEnv ) if ( LogThis( 'gen' ) > 0 );

# parse command line arg
for ( my $ii = 0; $ii < scalar(@ARGV); $ii++ )
{
   my $szArg = $ARGV[$ii];

   # -bond_data_purge ... will process later
   next if (lc($szArg) eq "-bond_data_purge" );

   # -get_pooldata_archive ... will process later
   next if (lc($szArg) eq "-get_pooldata_archive" );

   # -c ... will process later
   next if (lc($szArg) eq "-c" );

   # -config ... already done earlier

   if ( scalar(grep(/^\-force_redownload$/i, @ARGV )))
       {
       next ;
       }

   # -dbstatus arg?
   if ( scalar(grep(/^\-dbstatus$/i, @ARGV )))
       {
       TestDbStatus();
       print "Normal end of running autodnld with special -dbstatus switch\n";
       exit(0);
       }

   if ( scalar(grep(/^\-ip$/i, @ARGV )))
       {
       if (  $hIniFile{'operating_system'} eq "unix" )
          {
          print "\nThis option not supported by unix version\n" ;
          exit ( 1 ) ;
          }
       my ( $bErrorIp, $szIpMsgsBack ) = CheckIPAddresses ();
       if ( $bErrorIp )
          {
          print "\n!!!! Error validating IP address !!!!\n\n\n\n" ;
          }
       print "$szIpMsgsBack \n\nNormal end of running autodnld with special -ip  switch\n";
       exit(0);
       }

   if ( scalar(grep(/^\-update_exe$/i, @ARGV )))
       {
       if (  $hIniFile{'operating_system'} eq "unix" )
          {
          print "\nThis option not supported by unix version\n" ;
          exit ( 1 ) ;
          }
       my ( $bErrorIp, $szIpMsgsBack ) = UpdateExe ();
       if ( $bErrorIp )
          {
          print "\n!!!! Error updating the exe !!!!\n\n\n\n" ;
          }
       else
          {
          print "\n\n\nSUCCESS running UpdateExe" ;
          }
       print "$szIpMsgsBack \n\nNormal end of running autodnld with special -update_exe switch\n";
       exit(0);
       }

   if ( scalar(grep(/^\-update_exe_auto$/i, @ARGV )))
       {
       if (  $hIniFile{'operating_system'} eq "unix" )
          {
          print "\nThis option not supported by unix version\n" ;
          exit ( 1 ) ;
          }
       my  ( $bDontUpdate ) ;
       if ( defined ( $hIniFile{'skip_update_exe'} ) )
          {
          $bDontUpdate  = 1 if ( uc($hIniFile{'skip_update_exe'}) eq "Y" ) ;
          }


       if ( $bDontUpdate )
          {
          print "\nWill not update exe per ini flag skip_update_exe=y\nRun with -update_exe flag to force update" ;
          AppendLog ( "Will not update exe per ini flag skip_update_exe=y" );
          exit ( 0 ) ;
          }
       else
          {
          my ( $bErrorIp, $szIpMsgsBack ) = UpdateExe ();
          if ( $bErrorIp )
             {
             print "\n!!!! Error updating the exe !!!!\n\n\n\n" ;
             }
          else
             {
             print "\n\n\nSUCCESS downloading newest exe" ;
             }
          print "$szIpMsgsBack \n\nNormal end of running autodnld with special -update_exe  switch\n";
          exit(0);
          }
       }

   if ( scalar(grep(/^\-dbstatus_upload$/i, @ARGV )))
       {
       my @aMsg = CheckAccessToIntexServer();

       if ( scalar(@aMsg) )
          {
          print "There were ERRORS accessing the Intex server"  ;
          print "\n" . join("\n",@aMsg) ;
          exit ( 1 ) ;
          }
       $hIniFile{"upload_dbstatus"} = "Y" ;
       TestDbStatusWithUpload();
       print "Normal end of running autodnld with special -dbstatus_upload switch\n";
       exit(0);
       }
   if ( scalar(grep(/^\-get_id$/i, @ARGV )))
       {

       my @aMsg = CheckAccessToIntexServer();
       ReadInfFile();

       if ( scalar(@aMsg) )
          {
          print "There were ERRORS accessing the Intex server"  ;
          print "\n" . join("\n",@aMsg) ;
          exit ( 1 ) ;
          }

       my @aIdErrs = DownloadIdShipping () ;

       if ( scalar ( @aIdErrs ) > 0 )
           {
           print "!!!!!! ERROR processing ID shipment: ". join ( "\n", @aIdErrs ) ;
           exit ( 0 ) ;
           }
       print "Normal end of running autodnld with special -get_id switch\n";
       exit(0);
       }
   if ( scalar(grep(/^\-in_use$/i, @ARGV )))
       {
       my @aMsg =
           (
            "We checked the \"in_use\" temp directory for files to copy.",
            "Below is a summary:\n",
             );
       my ( $bAllFiles, $paLinesBack, $bNoneFound ) = CheckForInUseFiles ( ) ;

       if ( $bNoneFound )
          {
          push ( @aMsg, "We did not find any files to copy in the in_use directory.\n" ) ;
          AppendLog ( "CheckForInUseFiles (): We did not find any files to copy in the in_use directory." ) ;
          }
       elsif ( scalar ( @$paLinesBack ) )
          {
          push ( @aMsg, "ERROR: !!!! We found some files, and tried to copy them, \nbut were still not able to copy the files\nHere is a list of the files:\n" ) ;
          foreach my $szOneLine ( @$paLinesBack )
             {
             my ( $szJunkJunk, $szFileToCopy, $szDestFile ) = split ( / +/, $szOneLine ) ;

             push ( @aMsg, "$szFileToCopy ===> \n$szDestFile" ) ;
             push ( @aMsg, "COMMAND TO RUN:\n\"$szOneLine\"\n" ) ;
             }
          #ComposeAndSendEmail( 'e__', "ERROR: File(s) in use, please follow instuctions in email.", \@aMsg ) if ( scalar ( @$paLinesBack ) > 0 );
          #AppendLog ( "uncompress_zip_under_win(): We had unpack errors from files in use files were saved in temp directory.  Email was sent and detail can be found in $hCrntEnv{'error_log_file'}", "", \@aMsg ) ;
          }
       else
          {
          push ( @aMsg, "We found files to copy in the \"in_use\" directory, and successfully copied them.\n" ) ;
          }
       print join ( "\n", @aMsg ) ;
       print "Normal end of running autodnld with special -in_use switch\n";
       exit(0);
       }

   if ( scalar(grep(/^\-kill_autodnld$/i, @ARGV )))
       {
       my @aMsg = TrytoKillAutodnld();

       if ( scalar(@aMsg) )
          {
          print "\n" . join("\n",@aMsg) ;
          exit ( 1 ) ;
          }
       print "\nThe other autodnld was killed" ;
       exit(0);
       }

   # -h arg?
   if ( lc($szArg) eq "-h" )
   {
      print "-h argument found: change to subdir=$ARGV[$ii+1]\n";
      chdir ( $ARGV[$ii+1] );
      next;
   }

   # -pool_data_purge ... will process later
   next if (lc($szArg) eq "-pool_data_purge" );

   # -prune
   if (lc($szArg) eq "-prune" )
       {
       require "autodnld_prune.pl";
       prune_cmo_data();
       exit(0);
       }
   # -copyflash
   if (lc($szArg) eq "-copyflash" && defined $hIniFile{"copy_flash_cdu"} && $hIniFile{"copy_flash_cdu"}==1)
       {
                #make it verbose
                $hCrntEnv{verbose} = 1;
                CopyFlashCdu();
                exit(0);
       }

   ################# add to html doc soon #################
   # -prune_batch ... will process later
   next if (lc($szArg) eq "-prune_batch" );

   # -prune_depth_report... will process later
   next if (lc($szArg) eq "-prune_depth_report" );

   # -prune_deficit_report... will process later
   next if (lc($szArg) eq "-prune_deficit_report" );

   # -prune_verbose ... will process later
   next if (lc($szArg) eq "-prune_verbose" );

   # ... will process later
   next if (lc($szArg) eq "" );

   # ... will process later
   next if (lc($szArg) eq "" );

    # replicate ...
   if ( lc($szArg) eq "-replicate" )
       {
       # read inf file, which will gen list of extra-int subdirs if appropriate
       ReadInfFile();

       # for each data type: if the download count is GT 0, and if we have replicate subdirs, do the replication
       possibly_replicate
           (
            1,                  # $download_cmo_pool_bond_cnt,
            1,                  # $perf_download_cnt,
            1,                  # $remit_download_cnt,
            );

       exit(0);
       }

   # -replicate_verbose ... will process later
   next if (lc($szArg) eq "-replicate_verbose" );

   # -suppress_inf_XXX
   next if ( $szArg =~ /suppress_inf_/i );

   # -t*: test mode...
   if ( lc($szArg) =~ /^\-t/i )
       {
         if ( lc($szArg) =~ /\-tf/i )
             {
             OneHttpFileTest();
             exit(1);
             }

       if ( lc($szArg) =~ /^\-ta/i )
           {
           my $sTestResult=OneHttpTest();
           if ($sTestResult==0)
               {
               AppendLog("Https test success. We are checking whether Intex has set you up as a https client...");
               my $sStatus=ReadInfFile(1); # return 1 means no inf being downloaded at all. 0 means success download.
               if (defined $hCmoState{'usehttp'})
                   {
                   DropMessageViaHTTP("https_test_success");
                   AppendLog("Autodnld Test Success! You can take advantage of the full https download.",1);
                   exit(0);
                   }
               elsif ($sStatus==0)
                   {
                   #download was success
                   DropMessageViaHTTP("https_need_setup");
                   AppendLog("You are ready to use full https for download. Please contact autodnld_help\@intex.com to set it up on Intex side!!",1);
                   exit(0);
                   }
               else
                   {
                   #not be able to download inf correctly. something wrong? e.g., may not be the right password?
                   AppendLog("Download your inf file failed. Please check your password, or contact autodnld_help\@intex.com",1);
                   exit(1);
                   }
               }
           else
               {
               print "\nHttps test failed. Please check your firewall configuration to enable https connection to *.intex.com:443";
               exit(1);
               }
           exit(1);
           }

         print "\nDo you want to test https access to the Intex server?\n";
         print "Please enter y/n and press enter, y will start test, n will exit the program > ";
         my $szYesNo = <STDIN>;
         exit(0) if ( $szYesNo =~ /^n/i );
         my $sTestResult=OneHttpTest();
         if ($sTestResult==0) {
            AppendLog("Https test success. We are checking whether Intex has set you up as a https client...");
            my $sStatus=ReadInfFile(1); # return 1 means no inf being downloaded at all. 0 means success download.
            if (defined $hCmoState{'usehttp'}) {
                DropMessageViaHTTP("https_test_success");
                AppendLog("Autodnld Test Success! You can take advantage of the full https download.",1);
                TestOthers();
                exit(0);
           }
           elsif ($sStatus==0) {
              #download was success
              DropMessageViaHTTP("https_need_setup");
              AppendLog("You are ready to use full https for download. Please contact autodnld_help\@intex.com to set it up on Intex side!!",1);
              TestOthers();
              exit(0);
           }
           else {
              #not be able to download inf correctly. something wrong? e.g., may not be the right password?
              AppendLog("Download your inf file failed. Please check your password, or contact autodnld_help\@intex.com",1);
              exit(1);
           }
         }
         else {
            print "\nHttps test failed. Please check your firewall configuration to enable https connection to *.intex.com:443";
            exit(1);
         }
       }

   # -u
   if ( lc($szArg) eq "-u" )
       {
       AppendLog ( "leave-uncompressed flag is on");
       $::bLeaveUncompressed = 1;
       next;
       }

    # -skip_id
    if( lc $szArg eq "-skip_id")
    {
      AppendLog("skip_id flag is on");
      $::bSkipIntraday = 1;
      next;
    }

   # -v*: version...
   if ( lc($szArg) =~ /^\-v/i )
       {
       print "\nIntex Autodnld: version=$release_version ($release_date)\n\n";
       exit(0);
       }

   # got this far; error
   print "Unexpected command line argument: $szArg\n";
   exit(1);

} # szarg

# The autodnld script is not re-entrant; try to detect if another instance is running
my $lock_fn;

if ( $is_unix ) # use process list
{
    AppendLog ( "main(): running UNIX; need to examine a process list" );

    # figure out command for a process list and run it
    # can use NONE as the ps command
    my ( $ps_command ) = $hIniFile{'ps_command'};
    $ps_command = 'ps -af' if ( !defined( $ps_command ));

    if ( lc($ps_command) ne 'none' )
        {
        my ( @aLine ) = `$ps_command`;

        # grep the output
        if ( scalar ( grep ( /perl autodnld\.pl/i, @aLine )) > 1 )
            {
            my ( @aCustomerLog ) = ( "ERROR: another instance of Intex Auto Download is already running\nWe ran cmd=$ps_command for a process listing\nWe found the string \"perl autodnld.pl\" in the process-list output","Please stop any other autodnld's running" ) ;
            AppendLog ( "ERROR: another instance of Intex Auto Download is already running
  We ran cmd=$ps_command for a process listing
  We found the string \"perl autodnld.pl\" in the process-list output", 1, \@aCustomerLog );
            exit(1);
            }
        else
            {
            AppendLog ( "There is not another instance of Intex Auto Download already running
  We ran cmd=$ps_command for a process listing
  We tried to find the string \"perl autodnld.pl\" in the process-list output" );
            }
        }
    else
        {
        AppendLog ( "disable multi-instance checking since ps_command has value of NONE" );
        }
} # is unix
else  # non-unix ... leave a file open .. ok for win98??
{
    $lock_fn = "$hCrntEnv{'tgt_log_dir'}$slash" . "autodnld.is.running.txt";
    AppendLog ( "main(): We will use a lock file; fn=$lock_fn" );

    if( -e $lock_fn )
        {
        my @aMsgBody=("We found another autodnld process running by checking $lock_fn. \n");
        AppendLog ( "main(): we found a lock file on the hard disk; this is undesirable but not fatal yet; we will try to erase it");
        if ( !unlink($lock_fn) )
            {
            my ( @aCustomerLog ) = ( "ERROR: we could not erase the lock file; another process is holding it open\nWe know this because there is a file we cannot erase\nFile name=$lock_fn", "Please stop any other autodnld's running" ) ;
            AppendLog ( "main(): ERROR: we could not erase the lock file; another process is holding it open","", \@aCustomerLog);

            push ( @aMsgBody, "ERROR: we could not erase the lock file; another process is holding it open.\n" ) ;
            print "\nERROR: another instance of Intex Auto Download is already running. We know this because there is a file we cannot erase
                  File name=$lock_fn\n";

            if (  uc($hIniFile{'kill_autodnld'}) eq "Y" )
               {
               my $szMsgBack = TrytoKillAutodnld ( ) ;
               if ( $szMsgBack )
                  {
                  my ( @aCustomerLog ) = ( "ERROR: we tried to kill the other autodnld, but got the following error:\n$szMsgBack" ) ;
                  AppendLog ( "main(): ERROR: we tried to kill the other autodnld, but got the following error:\n$szMsgBack","", \@aCustomerLog);
                  print "\nERROR: We tried to kill the process, but got the following error: $szMsgBack\n" ;
                  push(@aMsgBody, "ERROR: you set kill_autodnld=y in your autodnld.ini file, we tried to kill the other autodnld process. But failed with the following error:\n$szMsgBack\nAutodnld failed. Please stop any other autodnld's running. \n");
                  ComposeAndSendEmail
                     ('e22',"AutoDnld Failed",\@aMsgBody);
                  exit ( 1 ) ;
                  }
               else
                  {
                  print "\nWe killed the other autodnld, per kill_autodnld=y in the .ini file." ;
                  AppendLog ( "main(): We were successful in killing the other autodnld.  Will continue now..." );
                  push(@aMsgBody,"Warning: We killed the other autodnld, per kill_autodnld=y in the .ini file. Will continue now...");
                  ComposeAndSendEmail
                     ('e22',"AutoDnld Warning",\@aMsgBody);
                  }
               }
            else
               {
                push(@aMsgBody,"ERROR: You didn't set kill_autodnld=y in your autodnld.ini file. Please check $lock_fn and manually stop any other autodnld running process.\nAutodnld failed.\n" ) ;
                ComposeAndSendEmail
                     ('e22',"AutoDnld Failed",\@aMsgBody);

                exit(1);
               }
            }
        else
            {
            AppendLog ( "main(): we were able to erase the lock file; all is OK so far");
            push(@aMsgBody,"We were able to erase the lock file and continue....");
            ComposeAndSendEmail
            ('e22',"AutoDnld Warning",\@aMsgBody);
            }

        }
    else
        {
        AppendLog ( "main(): we did not find an existing lock file on the hard disk; this is normal; no need to try to erase it") if ( LogThis('gen') > 0 );
        }

    AppendLog ( "main(): open a lock file for write and leave it open; fn=$lock_fn" );
    open(INPROC,">$lock_fn");
    print INPROC "# Lock file for autodnld.pl
start_time=" . scalar(localtime()) . "
pid=$$\n";
    INPROC->flush();  # need IO::File to do this
}

# -c arg? (create tracking files)
if ( scalar(grep(/^\-c$/i, @ARGV )))
{
   CreateFakeTrackingFiles();
   print "Normal end of running autodnld with special -c switch\n";

   # if non-unix, let go of the lock file ... 2 places
   if ( !$is_unix )
       {
       close(INPROC);
       unlink ( $lock_fn );
       }

   exit(0);
}

PossiblyShrinkAllLogFiles();    # 4 or so of them

# look for illegal ini file value
if ( defined($hIniFile{file_download_retry_count}) )
{
    my $limit = $hIniFile{file_download_retry_count};

    if ( $limit < 0  ||  $limit > 2 )
        {
        my ( @aCustomerLog ) = ( "Illegal value for \"file_download_retry_count\" in the autodnld.ini file", "Acceptable value is between 0 and 2", "Value in the file was $limit" ) ;
        my $msg = "you have an illegal value in autodnld.ini
The illegal line starts with this: file_download_retry_count
The permitted values are 0, 1 or 2";

        AppendLog ( "$func: $msg", "", \@aCustomerLog );
        print "ERROR: $msg\n";
        exit(1);
        }
}

# look for illegal ini file value
if ( defined($hIniFile{'eot_file_retry'}) )  # may be undef  ... or may be "try=5;interval=10"
{
    my ( @aCustomerLog ) = ( "Illegal setting in autodnld.ini file", "\"eot_file_retry\" is no longer supported", "Please remove it from autodnld.ini" ) ;
    my $msg = "you have a extra line in autodnld.ini that is no longer supported
The line starts with this: eot_file_retry";

    AppendLog ( "$func: $msg","",\@aCustomerLog );
    print "ERROR: $msg\n";
    exit(1);
}

# we can tell who is using autodnld by looking at GET in log file
DropMessageViaHTTP("Autodnld_version_".$release_version."_".$release_date);

### successful_log_file

my $szSuccessLogFile = $hCrntEnv{'successful_log_file'} ;
open ( SUCCESS, $szSuccessLogFile ) ;
my @aSuccess = <SUCCESS> ;
close SUCCESS  ;

open ( SUCCESS, ">$szSuccessLogFile" ) ;

my ( $bRetryEntered, $iRetryNumLimit )  ;
if ( defined ( $hIniFile{'redownload_count'} ) && $hIniFile{'redownload_count'} =~ /^\d+$/ )
   {
   $iRetryNumLimit = $hIniFile{'redownload_count'} ;
   }
elsif ( defined ( $hIniFile{'redownload_count'} ) && uc ( $hIniFile{'redownload_count'} ) eq "N"  )
   {
   $iRetryNumLimit = 9999 ;
   }
else
   {
   $iRetryNumLimit  = 9999 ;
   }

foreach my $szOneLine ( @aSuccess )
   {
   if ( $szOneLine =~ /RETRY\=(\d+)/ )
      {
      my $szRetryNum = $1 ;
      if ( $szRetryNum > $iRetryNumLimit   )
          {
          print  "Hit max retry count, will download files if already downloaded. To override can set redownload_count=N in the ini file\n"  ;
          AppendLog (  "main(): hit max retry count, will download files if already downloaded (for safety). To override can set redownload_count=N in the ini file " ) ;
          $szRetryNum = 1 ;
          }
      else
          {
          $szRetryNum ++ ;
          }
      $bRetryEntered = 1;
      print SUCCESS "RETRY=$szRetryNum\n" ;
      next ;
      }
   print SUCCESS $szOneLine  ;
   }
print SUCCESS "RETRY=1\n" if ( ! $bRetryEntered ) ;

close SUCCESS ;


if ( $hIniFile{'temp_download_subdir'} ne "" && ! $is_unix && $hIniFile{'skip_file_in_use_process'} ne 'Y' )
   {
    my @aMsg =
        (
         "You have some file(s) in your database that were in use when trying to update.",
         "These files were saved in your temp_download_subdir.",
         "Below you will find FILE1 ===> FILE2.",
         "",
         "To become up to date, you can run autodnld with the command line option \"-in_use\"\n(i.e. open a command window change to the autodnld\/scripts directory and type \"autodnld -in_use\"",
         "Autodnld will also try to copy these files, each time it is run until it is successful.",
         "Or for each line below copy FILE1 to FILE2 when FILE2 is not in use anymore.",
         "To make it easier to copy, each line is followed by a command that if run in a DOS prompt will copy the files.",
         "========================  Begin List of Files In Use =======================================================",
          );
    my ( $bAllFiles, $paLinesBack, $bNoneFound ) = CheckForInUseFiles ( ) ;
    if ( $bNoneFound )
       {
       AppendLog (  "CheckForInUseFiles(): We did not find any files to copy in the in_use directory" ) ;
       }
    elsif ( scalar ( @$paLinesBack ) )
       {
       if ( scalar ( @$paLinesBack ) > 0 )
          {
          foreach my $szOneLine ( @$paLinesBack )
             {
             my ( $szJunkJunk, $szFileToCopy, $szDestFile ) = split ( / +/, $szOneLine ) ;

             push ( @aMsg, "$szFileToCopy ===> $szDestFile" ) ;
             push ( @aMsg, "COMMAND TO RUN:\"$szOneLine\"\n" ) ;
             }
          push ( @aMsg, "========================  End List of Files In Use =======================================================\n\n" ) ;
          my ( $szStringToLog ) = join ( "\n", @aMsg ) ;
          AppendLog ( "CheckForInUseFiles() returned errors: We had unpack errors from files in use files were saved in temp directory. \n\n $szStringToLog", "", \@aMsg ) ;
          }
       }
    }

# check for all types of shipments that this customer gets
# If one type fails, return to caller; do not plow ahead

TryToDownloadAllDataTypes();

# We may have post processor: post_process.bat
my $szScript = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."post_process.bat";

if ( -e $szScript )
{
   system ( "$com_spec $szScript" );
}

# We may have post processor: post_process.pl
$szScript = $hIniFile{'autodnld_home'} . $slash . "scripts$slash"."post_process.pl";

if ( -e $szScript )
{
   system ( "perl $szScript" );
}

if ( $hIniFile{'temp_download_subdir'} ne "" && ! $is_unix && $hIniFile{'skip_file_in_use_process'} ne 'Y' )
   {
    my @aMsg =
        (
         "You have some file(s) in your database that were in use when trying to update.",
         "These files were saved in your temp_download_subdir.",
         "Below you will find FILE1 ===> FILE2.",
         "",
         "To become up to date, you can run autodnld with the command line option \"-in_use\"\n(i.e. open a command window change to the autodnld\/scripts directory and type \"autodnld -in_use\"",
         "Autodnld will also try to copy these files, each time it is run until it is successful.",
         "Or for each line below copy FILE1 to FILE2 when FILE2 is not in use anymore.",
         "To make it easier to copy, each line is followed by a command that if run in a DOS prompt will copy the files.",
         "========================  Begin List of Files In Use =======================================================",
          );
    my ( $bAllFiles, $paLinesBack, $bNoneFound ) = CheckForInUseFiles ( ) ;

    if ( defined ( $paLinesBack ) && scalar ( @$paLinesBack ) && ! $bNoneFound )
       {
       if ( scalar ( @$paLinesBack ) > 0 )
          {
          foreach my $szOneLine ( @$paLinesBack )
             {
             my ( $szJunkJunk, $szFileToCopy, $szDestFile ) = split ( / +/, $szOneLine ) ;

             push ( @aMsg, "$szFileToCopy ===> $szDestFile" ) ;
             push ( @aMsg, "COMMAND TO RUN:\"$szOneLine\"\n" ) ;
             }
          push ( @aMsg, "========================  End List of Files In Use =======================================================\n\n" ) ;
          ComposeAndSendEmail( 'e__', "ERROR: File(s) in use, please follow instuctions in email.", \@aMsg ) if ( scalar ( @$paLinesBack ) > 0 );
          AppendLog ( "uncompress_zip_under_win(): We had unpack errors from files in use files were saved in temp directory.  Email was sent and detail can be found in $hCrntEnv{'error_log_file'}", "", \@aMsg ) ;
          #print "\n\nERROR was from decompressing and some files were in use.  Please see email (or email.log) for details." ;
          }
       }
    }
# if non-unix, let go of the lock file
if ( !$is_unix )
{
    AppendLog ( "main(): close and unlink lock file; fn=$lock_fn" );
    close(INPROC);
    unlink ( $lock_fn );
}

AppendLog ( "main(): normal end of autodnld\n" );
AppendLog ( "--------------------------- END; version=$release_version ($release_date); pid=$$"."\n\n" );
print "Normal end of autodnld\n";

exit(0);
