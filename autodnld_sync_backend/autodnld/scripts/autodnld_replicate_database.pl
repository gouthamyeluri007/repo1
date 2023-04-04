# h:/fips/scripts/autodnld/autodnld_replicate_database.pl

# use strict

use DirHandle;
use File::Copy;
use IO::File;


# set in autodnld.pl
use vars ( qw (
               $slash
               %hIniFile
               %hCrntEnv
               ));


# table of contents
## ------------------------ possibly_shrink_replicate_log_file
## append_replicate_session_log
## replicate_db_copy
## replicate_db_scan_to_copy   <<<< RECURSES
## replicate_db_scan_to_prune   <<<< RECURSES
## intex_db_subdir_replication
## possibly_replicate  <<< ENTRY


# verbose_for_replication: bigger log file, lots more logging
my $verbose_for_replication;

# for internal use
my $skip_cda_etc = 0;
$skip_cda_etc = 1 if ( defined($ENV{'COMPUTERNAME'})  &&  $ENV{'COMPUTERNAME'} eq 'AUTODNLD'  &&  $ENV{'LOGONSERVER'} eq '\\\\AUTODNLD');
print "FYI: special flag set: skip_cda_etc\n" if ( $skip_cda_etc );


# --------------------------- is_there_any_replication
# look at ini hash values like xxx, and return 0 or 1=yes
sub is_there_any_replication
{
return 1 if ( defined ( $hIniFile{'extra_cdi_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_cdu_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_perfdata_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_remitdata_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_deal_remit_data_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_tranche_remit_data_dirs'} ) );
return 1 if ( defined ( $hIniFile{'extra_rmtddata_dirs'} ) );
return 0;

} # is_there_any_replication


# ------------------------ possibly_shrink_replicate_log_file
sub possibly_shrink_replicate_log_file
{
my ( $szLogFile ) = @_;

my ( $max_cnt );
my ( $rollback_cnt );

if ( $verbose_for_replication )
    {
    $max_cnt = 100000;
    $rollback_cnt = 80000;
    }
else
    {
    $max_cnt = 8000;
    $rollback_cnt = 5000;
    }

return if ( ! ( open ( LOG, $szLogFile )));
my @aLine = <LOG>;
close(LOG);
my $cnt = scalar(@aLine);

if ( $cnt > $max_cnt )
    {
    AppendLog ( "possibly_shrink_replicate_log_file(): shrink log file=$szLogFile from $cnt to $rollback_cnt" );
    @aLine = @aLine[($cnt - $rollback_cnt)..($cnt-1)];
    unlink ( $szLogFile );
    open ( LOG, ">$szLogFile" );
    print LOG join("",@aLine);
    close(LOG);
    }

} # possibly_shrink_replicate_log_file


# ---------------- append_replicate_session_log
# append info to summary log file (NOTE that no stamp is prepended and no crlf appended)
# this routine called a lot if $verbose_for_replication is true; only called a few times otherwise

sub append_replicate_session_log
{
my($szInfo) = @_; #iPrint is a print-to-screen flag
print($szInfo); #client like to see it
my @aTime = localtime();
my $stamp = sprintf ( "%02d:%02d:%02d", $aTime[2], $aTime[1], $aTime[0] );  # hh:mm:ss

if ( open ( LOGOUT, ">>$hCrntEnv{'replicate_session_log_file'}" ) )
    {
    if ( substr($szInfo,0,1) eq "\n" )
        {
        print LOGOUT "$szInfo";
        }
    else
        {
        print LOGOUT "$stamp: $szInfo";
        }

    close ( LOGOUT );
    }

} # append_replicate_session_log


# -------------------------- replicate_db_copy
# copy one file

# screen output:
##  copy d:\temp\autodnld\cmo_cdu\0112\gtmh9503.cdu --> d:\temp\cmo_cdu\0112\gtmh9503.cdu
##  copy d:\temp\autodnld\cmo_cdu\0112\gtmh9504.cdu --> d:\temp\cmo_cdu\0112\gtmh9504.cdu
##  copy d:\temp\autodnld\cmo_cdu\0112\gtmh9505.cdu --> d:\temp\cmo_cdu\0112\gtmh9505.cdu; bytes=1642496; seconds=-2
##  copy d:\temp\autodnld\cmo_cdu\0112\gtmh9506.cdu --> d:\temp\cmo_cdu\0112\gtmh9506.cdu
sub replicate_db_copy
{
my (
    $src_fn,
    $dst_fn,
    $p_dst_exists,
    $p_err,  # if error, fill this in
    ) = @_;

my @aSrc = stat($src_fn);
my @aDst = stat($dst_fn);

# have special skip flag
if ( $skip_cda_etc  &&  $src_fn =~ /cmo_cdu\\\d\d\d\d\\.#/ )   # e.g. d:\\source\\cmo_cdu\\0202\\g#304292.cdu
     {
     append_replicate_session_log "replicate_db_copy(): skip file=$src_fn because skip_cda_etc flag is set\n";
     return;
     }

# return if timestamp more or less matches (allowing for daylight saving time shift)
if ( scalar(@aDst) )
    {
    $$p_dst_exists = 1;
    my $sec = abs($aSrc[9] - $aDst[9]);
    return if ( $sec < 2 ||  $sec >= 3599 && $sec <= 3601 );
    }
else
    {
    $$p_dst_exists = 0;
    }

################  got this far, copy file

print "\cM" . "copy $src_fn --> $dst_fn     ";

# decide on tmp dest
my $dst_fn_tmp = "$dst_fn.tmp";
unlink ( $dst_fn_tmp ) if ( -e $dst_fn_tmp );

if ( -e $dst_fn_tmp )
    {
    $$p_err = "Cannot delete temp. output file=$dst_fn_tmp";
    return;
    }

# open tmp out
my $dst_fh_tmp = new IO::File ">$dst_fn_tmp";

if ( ! $dst_fh_tmp )
    {
    $$p_err = "Cannot open temp. output file=$dst_fn_tmp";
    return;
    }

# open input fh
my $src_fh = new IO::File $src_fn;

if ( ! $src_fn )
    {
    $$p_err = "Cannot open $src_fn. temp output file=$dst_fn_tmp";
    $dst_fh_tmp->close();
    return;
    }

# block copy
binmode($src_fh);
binmode($dst_fh_tmp);
my $buf;
my $last_screen_update = time() - 999;
my $total_byte = 0;
my $start_time = time();

while ( 1 )
    {
    my $stat = sysread ( $src_fh,$buf,0x1000 );

    # bad read?
    if ( !defined($stat))
        {
        $$p_err = "Error reading src file=$src_fn";
        $dst_fh_tmp->close();
        unlink($dst_fn_tmp);
        return;
        }

    # no data left?
    last if ( $stat == 0 );

    # ok, got some data, write it out
    $total_byte += $stat;
    my $wr_stat = syswrite ( $dst_fh_tmp,$buf,$stat );

    # bad write?
    if ( !defined($wr_stat) || $wr_stat != $stat )
        {
        $$p_err = "Error writing to temp. dest. file=$dst_fn_tmp";
        $dst_fh_tmp->close();
        unlink($dst_fn_tmp);
        return;
        }

    # possible screen update
    # if small file, will update once because last_time_update was initted to time() - 999, and will update once more when we drop out of the loop
    if ( time() - $last_screen_update > 1 )
        {
        $last_screen_update = time();
        print "\cM" . "copy $src_fn --> $dst_fn; bytes=$total_byte; seconds=" . (time() - $start_time);
        }
    }

# we had odometer, finish it off
print "\cM" . "copy $src_fn --> $dst_fn; bytes=$total_byte; seconds=" . (time() - $start_time);
print "\n";
$dst_fh_tmp->close();

# ok, copied to temp, utime it and then move the file
utime ( $aSrc[9], $aSrc[9], $dst_fn_tmp );

if ( !move ( $dst_fn_tmp, $dst_fn ))
    {
    $$p_err = "Error renaming tmp dest. file to final file
  temp=$dst_fn_tmp
  final=$dst_fn";
    return;
    }

append_replicate_session_log "replicate_db_copy(): copy_file: $src_fn -> $dst_fn\n" if ( $verbose_for_replication );
$$p_dst_exists = 1;

} # replicate_db_copy


# --------------------- replicate_db_scan_to_copy   <<<< RECURSES
# called for starting subdirs, and we then recurse down
sub replicate_db_scan_to_copy
{
my (
    $src_subdir,
    $dst_subdir,
    $p_err,
    ) = @_;

# say hello
# NOTE: when we kick off the recursive copy, we say this: "Recursively scan subdir=$src_subdir looking for files to copy to subdir=$dst_subdir...\n";
print "... scan subdir=$src_subdir looking for files to copy to subdir=$dst_subdir...\n";

append_replicate_session_log "replicate_db_scan_to_copy(): start: src=$src_subdir  dst=$dst_subdir\n" if ( $verbose_for_replication );

# make dst subdir if needed
my $err = MkdirAsReq ( $dst_subdir );

if ( $err ne '' )
    {
    $$p_err = "cannot make subdir=$dst_subdir";
    return;
    }

# scan subdir; save subdirs for recursion later on
my $dh = new DirHandle $src_subdir;
return if ( !$dh );
my @aRecurseRoot = ();
my $subdir_file_cnt = 0;

while ( defined ( my $root = $dh->read() ) )
    {
    next if ( substr($root,0,1) eq '.' );
    my $file = "$src_subdir$slash$root";

    if ( -d $file )
        {
        # have special skip flag
        if ( $skip_cda_etc  &&  $file =~ /\\cmo_cdu\\history$/ )  # actually a subdir...
            {
            append_replicate_session_log "replicate_db_scan_to_copy(): skip subdir=$file because skip_cda_etc flag is set\n";
            next;
            }

        push ( @aRecurseRoot, $root );
        next;
        }

    my $dst_exists = 0;

    replicate_db_copy  # will quick return if stat's are close
        (
         "$src_subdir$slash$root",
         "$dst_subdir$slash$root",
         \$dst_exists,
         $p_err,
         );

    $subdir_file_cnt++ if ( $dst_exists);
    return if ( $$p_err ne '' );
    }

$dh->close();

append_replicate_session_log "replicate_db_scan_to_copy(): subdir_file_cnt=$subdir_file_cnt for subdir=$dst_subdir\n" if ( $verbose_for_replication );

# now recurse into subdirs
foreach my $root ( reverse ( sort ( @aRecurseRoot ))  )
    {
    replicate_db_scan_to_copy    # <<<<<<<< RECURSE
        (
         "$src_subdir$slash$root",
         "$dst_subdir$slash$root",
         $p_err,
         );

    return if ( $$p_err ne '' );
    }

} # replicate_db_scan_to_copy


# --------------------- replicate_db_zap_subdir   <<<< RECURSES
# zap subdir, and all subdir's under it
# we call this because we found an orphan subdir

sub replicate_db_zap_subdir
{
my (
    $subdir,
    $p_err,
    ) = @_;

print "\n... zap subdir=$subdir\n";
append_replicate_session_log "--- replicate_db_zap_subdir(): start: subdir=$subdir\n" if ( $verbose_for_replication );

# get ready to scan dst subdir
my $dh = new DirHandle $subdir;
return if ( !$dh );
my @aZapFile = ();
my @aZapSubdir = ();

# scan subdir...
while ( defined ( my $root = $dh->read() ) )
    {
    # skip dot files
    next if ( substr($root,0,1) eq '.' );

    # if dst item is a subdir, recurse down, and then add to rmdir list
    if ( -d "$subdir$slash$root" )
        {
        replicate_db_zap_subdir
            (
             "$subdir$slash$root",
             $p_err,
             );

        return if ( $$p_err ne '' );
        append_replicate_session_log ("replicate_db_zap_subdir(): push subdir onto zap list: $subdir$slash$root\n" ) if ( $verbose_for_replication );
        push ( @aZapSubdir, $root );
        next;
        }

    # got this far; the dst item must be a file; add to unlink list
    append_replicate_session_log ("replicate_db_zap_subdir(): push file onto zap list: $subdir$slash$root\n") if ( $verbose_for_replication );
    push ( @aZapFile, $root );
    }

# done scanning subdir
$dh->close();



############### done scanning this subdir; we recursed down into any subdir, and we built  2 zap lists: now we can act on the zap lists


## # debug only...
## if ( scalar(@aZapFile) )
##     {
##     print " replicate_db_zap_subdir(): about to unlink files ... see log file for list .. press enter > ";
##     <STDIN>;
##     }

# tell user
if ( scalar(@aZapFile) )
    {
    print "... removing files in subdir=$subdir\n";
    }

# zap files
foreach my $root ( @aZapFile )
    {
    append_replicate_session_log ("replicate_db_zap_subdir(): unlink file=$subdir$slash$root\n") if ( $verbose_for_replication );
    unlink ( "$subdir$slash$root" );
    }

## # debug only...
## if ( scalar(@aZapSubdir) )
##     {
##     print " replicate_db_zap_subdir(): about to remove subdir ... see log file for list .. press enter > ";
##     <STDIN>;
##     }

# tell user
if ( scalar(@aZapSubdir) )
    {
    print "... removing subdir under subdir=$subdir\n";
    }

# zap child subdir
foreach my $root ( @aZapSubdir )
    {
    append_replicate_session_log ("replicate_db_zap_subdir(): rmdir subdir=$subdir$slash$root\n") if ( $verbose_for_replication );
    rmdir ( "$subdir$slash$root" );
    }

# and finally, remove the parent subdir itself
append_replicate_session_log ("replicate_db_zap_subdir(): rmdir subdir=$subdir\n") if ( $verbose_for_replication );
rmdir ( $subdir );

} # replicate_db_zap_subdir


# --------------------- replicate_db_scan_to_prune   <<<< RECURSES
# called for starting subdirs, and we then recurse down

# example
## ini file has this: tgt_cdu_dir=y:\cmo_cdu,\\matt\d_drive\source\cmo_cdu,\\jim\d_drive\cmo_cdu,\\johnm\d_drive\source\cmo_cdu
## we are called with:
##   src=y:\cmo_cdu
##   dst=\\matt\d_drive\source\cmo_cdu

sub replicate_db_scan_to_prune
{
my (
    $src_subdir,   # compare with this one
    $dst_subdir,   # scan this one
    $p_err,
    ) = @_;

# say hello
# NOTE: when we start the whole recursive scan, we say this: "Recursively scan subdir=$dst_subdir looking for files to prune...\n";
print "... scan subdir=$dst_subdir looking for files to prune...\n";

append_replicate_session_log "--- replicate_db_scan_to_prune(): src=$src_subdir  dst=$dst_subdir\n" if ( $verbose_for_replication );

# scan dst subdir ... (we are removing orphans)
my $dh = new DirHandle $dst_subdir;
return if ( !$dh );
my @aZapFile = ();
my @aZapSubdir = ();

while ( defined ( my $root = $dh->read() ) )
    {
    # skip dot files
    next if ( substr($root,0,1) eq '.' );

    # if dst item is a subdir, and there is no corresponding src subdir, add to subdir zap list and done
    if ( -d "$dst_subdir$slash$root"  &&  (! -d "$src_subdir$slash$root" )  )
        {
        print "...soon will delete subdir=$dst_subdir$slash$root because src_subdir=$src_subdir$slash$root is missing\n";
        append_replicate_session_log "replicate_db_scan_to_prune(): push onto subdir zap list: $dst_subdir$slash$root\n" if ( $verbose_for_replication );
        push ( @aZapSubdir, $root );
        next;
        }

    # if dst item is a subdir, and we got this far, there must also be a src subdir, so we can recurse and done
    if ( -d "$dst_subdir$slash$root" )
        {
        replicate_db_scan_to_prune
            (
             "$src_subdir$slash$root",
             "$dst_subdir$slash$root",
             $p_err,
             );

        return if ( $$p_err ne '' );
        next;
        }

    # got this far; the dst item must be a file; if no src file add to zap list
    if ( ! -e "$src_subdir$slash$root" )
        {
        print "...soon will delete file=$dst_subdir$slash$root because there is no corresponding file in src_subdir=$src_subdir\n";
        append_replicate_session_log "replicate_db_scan_to_prune(): push onto file zap list: $dst_subdir$slash$root\n" if ( $verbose_for_replication );
        push ( @aZapFile, $root );
        next;
        }
    }

# done scanning subdir
$dh->close();


########################  done scanning subdir and done recursing down; now we can zap orphan files and/or subdir

## # debug only...
## if ( scalar(@aZapFile) )
##     {
##     print " replicate_db_scan_to_prune(): about to unlink files ... see log file for list .. press enter > ";
##     <STDIN>;
##     }

# tell user
if ( scalar(@aZapFile) )
    {
    print "... removing files in subdir=$dst_subdir\n";
    }

# zap files
foreach my $root ( @aZapFile )
    {
    append_replicate_session_log ("replicate_db_scan_to_prune(): unlink orphan file=$dst_subdir$slash$root\n") if ( $verbose_for_replication );
    unlink ( "$dst_subdir$slash$root" );
    }

### debug only
##if ( scalar(@aZapSubdir) )
##    {
##    print " replicate_db_scan_to_prune(): about to unlink subdir ... see log file for list .. press enter > ";
##    <STDIN>;
##    }

# tell user
if ( scalar(@aZapSubdir) )
    {
    print "... removing subdir under subdir=$dst_subdir\n";
    }

# zap subdir
foreach my $root ( @aZapSubdir )
    {
    # call worker routine
    append_replicate_session_log ("replicate_db_scan_to_prune(): call worker routine to remove subdir=$dst_subdir$slash$root\n" );
    replicate_db_zap_subdir ( "$dst_subdir$slash$root", $p_err );
    }

} # replicate_db_scan_to_prune


# ---------------------------- intex_db_subdir_replication
# e.g. source is c:\\intex\\cmo_cdi, dst is x:\\intex\\cmo_cdi
# chatter to log as you work
# if error, put that in the log file, and also return the error string
sub intex_db_subdir_replication
{
my (
    $src_subdir,   # source subdir
    $paDstSubdir,  # one or more dst subdir(s)
    $p_err,
    ) = @_;


# NOTE: errors are soft .. .keep going ... if matt fails, try jim, for example
my $local_err = '';

foreach my $dst_subdir ( @$paDstSubdir )
    {
    print "\nRecursively scan subdir=$src_subdir looking for files to copy to subdir=$dst_subdir...\n";
    next if ( $dst_subdir eq '' );  # protect against double comma in ini file
    append_replicate_session_log ( "Start recursive scan of subdirectory for possible file copy; src_subdir=$src_subdir; dst_subdir=$dst_subdir\n" );

    my $PruneEnabled=1;
    if (defined $hIniFile{replicate_cmd}) #&&($hIniFile{operating_system} eq 'nt'))
       {
       my $sCmd=$hIniFile{replicate_cmd}." $src_subdir $dst_subdir";
       append_replicate_session_log ( "We have a customized replicate command to use: cmd=$sCmd\n" );
       $local_err=system($sCmd);
      }
    else {
       my $sRoboString="Robust\\s+File\\s+Copy\\s+for\\s+windows";
       my @aRoboResult=`robocopy /?`;
       if ((grep(/$sRoboString/i,@aRoboResult))&&($skip_cda_etc==0)) {
          my $sCmd="robocopy $src_subdir $dst_subdir /S /E /PURGE /R:10 /W:10 /V";
          append_replicate_session_log ( "We replicate by using command: cmd=$sCmd\n" );
          #robocopy return code shifted up by 8 bits from perl system call. here is the return code copied from
          # http://support.microsoft.com/kb/954404/en-us, code above 6 should tell user
          my %hRoboReturn=(
                           0 =>"No files were copied. No failure was encountered. No files were mismatched. The files already exist in the destination directory; therefore, the copy operation was skipped",
                           1 =>"All files were copied successfully",
                           2 =>"There are some additional files in the destination directory that are not present in the source directory. No files were copied",
                           3 =>"Some files were copied. Additional files were present. No failure was encountered",
                           5 =>"Some files were copied. Some files were mismatched. No failure was encountered",
                           6 =>"Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory",
                           7 =>"Files were copied, a file mismatch was present, and additional files were present",
                           8 =>"Several files did not copy",
          );
          my @aCopyScreen=`$sCmd`;
          append_replicate_session_log ( "Robocopy screen dump:\n".join("",@aCopyScreen));
          if ( $?>= 6<<8)
              {
              append_replicate_session_log ( "We had an error code".$?."from robocopy during repllicate; we will stop. ".$hRoboReturn{$?>>8}."\n");
              $$p_err .= " Replicate error: ".$?.":".$hRoboReturn{$?>>8};
              }
          else
              {
              append_replicate_session_log ( "All done with robocopy. Status:".$?.":".$hRoboReturn{$?>>8}."\n" );
              }
          $PruneEnabled=0;
          append_replicate_session_log ( "We disable prune to $dst_subdir since it is implied in robocopy command\n" );
       }
       else {
          #stuck with traditional method, including $skip_cda_etc=1 case

          append_replicate_session_log ( "We replicate by using autodnld built in process\n" );
          replicate_db_scan_to_copy  # will recurse
              (
               $src_subdir,
               $dst_subdir,
               \$local_err,
               );

          if ( $local_err ne '' )
              {
              append_replicate_session_log ( "We had an error during the replicate; we will stop; here is the error: $local_err\n" );
              $$p_err .= " copy_error=$local_err";
              $local_err = '';
              }
          else
              {
              append_replicate_session_log ( "All done with recursive scan of subdirectory for possible file copy; there were no errors\n" );
              }
       }
       # we are looking
    }


    #
    print "\nRecursively scan subdir=$dst_subdir looking for files to prune...\n";
    if (($PruneEnabled==1)&&((!defined $hIniFile{skipreplicateprune}) || ($hIniFile{skipreplicateprune}==0)))
       {

       append_replicate_session_log ( "Start recursive scan of subdirectory for possible prune; src_subdir=$src_subdir; dst_subdir=$dst_subdir\n" );

       replicate_db_scan_to_prune
           (
            $src_subdir,       # compare against this one
            $dst_subdir,       # scan this one
            \$local_err,
            );


       if ( $local_err ne '' )
           {
           append_replicate_session_log ( "We had an error during the subdirectory scan; we will stop scanning this subdirectory; here is the error: $local_err\n" );
           $$p_err .= " pruning_error=$local_err";
           $local_err = '';
           }
           else
               {
               append_replicate_session_log ( "End recursive scan of subdirectory for possible prune; there were no errors" );
               }
    }

    } # dst subdir e.g. matt, jim ...

} # intex_db_subdir_replication


# ------------------------------ possibly_replicate  <<< ENTRY
# for each data type: if the download count is GT 0, and if we have replicate subdirs, do the replication

##  1685:$hCrntEnv{'gets_cmo_data'} = 1 if  ( scalar(grep(/^cmo=1/,     @aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_cmo$/i,      @ARGV ) == 0 ) );
##  1686:$hCrntEnv{'gets_pool_data'} = 1 if ( scalar(grep(/^pooldata=1/,@aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_pooldata$/i, @ARGV ) == 0 ) );
##  1687:$hCrntEnv{'gets_bond_data'} = 1 if ( scalar(grep(/^bonddata=1/,@aLine)) > 0  &&  scalar(grep( /^\-suppress_inf_bonddata$/i, @ARGV ) == 0 ) );
##  1711:if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_perfdata$/i, @ARGV ) == 0 ) )
##  1741:if ( scalar(@aMatch) &&  scalar(grep( /^\-suppress_inf_remitdata$/i, @ARGV ) == 0 ) )

sub possibly_replicate
{
my (
    $download_cmo_pool_bond_cnt,
    $perf_download_cnt,
    $remit_download_cnt,
    $remit_diff_download_cnt,
    $hist_download_cnt,
    $tranche_remit_download_cnt,
    $deal_remit_download_cnt,
    $tranche_remit_diff_download_cnt,
    $deal_remit_diff_download_cnt,
    ) = @_;

# if no data download, return now
return if ( $download_cmo_pool_bond_cnt == 0 && $perf_download_cnt == 0 && $remit_download_cnt == 0 && $hist_download_cnt == 0 && $remit_diff_download_cnt == 0 && $deal_remit_download_cnt == 0 && $tranche_remit_download_cnt == 0 && $tranche_remit_diff_download_cnt == 0 && $deal_remit_diff_download_cnt == 0 );

# look at ini hash values like xxx, and return 0 or 1=yes
return if ( is_there_any_replication() == 0 );

# the verbose flag can be turned on by the command arg -replicate_verbose
$verbose_for_replication = ( scalar(grep( /^\-replicate_verbose$/i, @ARGV ) == 1 ) ) ? 1 : 0;
print "FYI: The \"verbose_for_replication\" flag has been turned on by the command arg -replicate_verbose\n" if ( $verbose_for_replication );

AppendLog ( "possibly_replicate(): start
  Incoming args:
    download_cmo_pool_bond_cnt=$download_cmo_pool_bond_cnt
    perf_download_cnt=$perf_download_cnt
    remit_download_cnt=$remit_download_cnt
    remit_diff_download_cnt=$remit_diff_download_cnt
    hist_download_cnt=$hist_download_cnt
    tranche_remit_download_cnt=$tranche_remit_download_cnt
    deal_remit_download_cnt=$deal_remit_download_cnt
    tranche_remit_diff_download_cnt=$tranche_remit_diff_download_cnt
    deal_remit_diff_download_cnt=$deal_remit_diff_download_cnt" );

# shrink log file; keep it bigger if QA machine
possibly_shrink_replicate_log_file ( $hCrntEnv{'replicate_session_log_file'} );

if ( $verbose_for_replication )
    {
    AppendLog ( "possibly_replicate(): verbose_for_replication is TRUE" );
    append_replicate_session_log ( "\n\nSTART: We are running on a QA machine; this log will be verbose and will be bigger than usual
" . scalar(localtime()) . "
Useful keywords to search for: copy_file unlink rmdir subdir_file_cnt\n\n" ) ;
    }
else
    {
    append_replicate_session_log ( "\n\nSTART: begin the replication process at " . scalar(localtime()) . "\n\n
Incoming args:
  download_cmo_pool_bond_cnt=$download_cmo_pool_bond_cnt
  perf_download_cnt=$perf_download_cnt
  remit_download_cnt=$remit_download_cnt
  hist_download_cnt=$hist_download_cnt
  tranche_remit_download_cnt=$tranche_remit_download_cnt
  deal_remit_download_cnt=$deal_remit_download_cnt
  remit_diff_download_cnt=$remit_diff_download_cnt
  tranche_remit_diff_download_cnt=$tranche_remit_diff_download_cnt
  deal_remit_diff_download_cnt=$deal_remit_diff_download_cnt" );
    }

my $err = '';
my $p_err = \$err;
my $replicate_error_cnt = 0;    # my email if errors
my $replicate_attempt_cnt = 0;  # no email if we don't even try
my $have_announced_name_of_replication_log_file = 0;

# cmo?
if ( $download_cmo_pool_bond_cnt )
    {

    # cdi replication? (errors go to log and are ignored, since we may have multiple replications to be done)
    if ( defined ( $hIniFile{'extra_cdi_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate CMO data (cmo_cdi)\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_cdi_dir'}; dst=" . join(",",@{$hIniFile{'extra_cdi_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_cdi_dir'}, # src_subdir,
             $hIniFile{'extra_cdi_dirs'}, # paDstSubdir,
             $p_err,
             );

        # keep track of errors ... we want to send a final, summary email
        if ( $$p_err ne '' )
            {
            $replicate_error_cnt++;
            $$p_err = '';
            }
        }

    # cdu replication? (errors go to log and are ignored, since we may have multiple replications to be done)
    if ( defined ( $hIniFile{'extra_cdu_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate CMO data (cmo_cdu)\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_cdu_dir'}; dst=" . join(",",@{$hIniFile{'extra_cdu_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_cdu_dir'}, # src_subdir,
             $hIniFile{'extra_cdu_dirs'}, # paDstSubdir,
             $p_err,
             );

        # keep track of errors ... we want to send a final, summary email
        if ( $$p_err ne '' )
            {
            $replicate_error_cnt++;
            $$p_err = '';
            }
        }
    } # cmo


# perfdata replication?  (errors go to log and are ignored, since we may have multiple replications to be done)
if ( $perf_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_perfdata_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate performance data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_perfdata_dir'}; dst=" . join(",",@{$hIniFile{'extra_perfdata_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_perfdata_dir'}, # src_subdir,
             $hIniFile{'extra_perfdata_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

        # keep track of errors ... we want to send a final, summary email
        if ( $$p_err ne '' )
            {
            $replicate_error_cnt++;
            $$p_err = '';
            }
    } # perf

# remitdata replication?  (errors go to log and are ignored, since we may have multiple replications to be done)
if ( $remit_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_remitdata_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate remit data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_remitdata_dir'}; dst=" . join(",",@{$hIniFile{'extra_remitdata_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_remitdata_dir'}, # src_subdir,
             $hIniFile{'extra_remitdata_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # remit
# deal_remit_download_cnt  $tranche_remit_download_cnt,
if ( $deal_remit_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_deal_remit_data_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate deal remit data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_deal_remit_data_dir'}; dst=" . join(",",@{$hIniFile{'extra_deal_remit_data_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_deal_remit_data_dir'}, # src_subdir,
             $hIniFile{'extra_deal_remit_data_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # deal remit

if ( $tranche_remit_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_tranche_remit_data_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate tranche remit data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_tranche_remit_data_dir'}; dst=" . join(",",@{$hIniFile{'extra_tranche_remit_data_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_tranche_remit_data_dir'}, # src_subdir,
             $hIniFile{'extra_tranche_remit_data_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # deal remit

if ( $hist_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_histdata_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate hist data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_histdata_dir'}; dst=" . join(",",@{$hIniFile{'extra_remitdata_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_histdata_dir'}, # src_subdir,
             $hIniFile{'extra_histdata_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # hist

if ( $remit_diff_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_rmtddata_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate remit diff data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_rmtddata_dir'}; dst=" . join(",",@{$hIniFile{'extra_rmtddata_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_rmtddata_dir'}, # src_subdir,
             $hIniFile{'extra_rmtddata_dirs'}, # paDstSubdir,
             $p_err,
             );
        }
    elsif ( defined ( $hIniFile{'extra_remit_data_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate remit diff data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_remit_data_dir'}; dst=" . join(",",@{$hIniFile{'extra_remit_data_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_remit_data_dir'}, # src_subdir,
             $hIniFile{'extra_remit_data_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # remit
if ( $deal_remit_diff_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_deal_remit_data_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate remit diff data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_deal_remit_data_dir'}; dst=" . join(",",@{$hIniFile{'extra_deal_remit_data_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_deal_remit_data_dir'}, # src_subdir,
             $hIniFile{'extra_deal_remit_data_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # deal remit diff

if ( $tranche_remit_diff_download_cnt )
    {
    if ( defined ( $hIniFile{'extra_tranche_remit_data_dirs'} ) )
        {
        # if have not announced name of replication file, do so now
        if ( $have_announced_name_of_replication_log_file == 0 )
            {
            print "Replication log file: $hCrntEnv{'replicate_session_log_file'}\n";
            $have_announced_name_of_replication_log_file = 1;
            }

        $replicate_attempt_cnt++;
        append_replicate_session_log ( "\n---- replicate remit diff data\n" );
        AppendLog ( "possibly_replicate(): replicate subdir(s): src=$hIniFile{'tgt_tranche_remit_data_dir'}; dst=" . join(",",@{$hIniFile{'extra_tranche_remit_data_dirs'}} ) );

        intex_db_subdir_replication
            (
             $hIniFile{'tgt_tranche_remit_data_dir'}, # src_subdir,
             $hIniFile{'extra_tranche_remit_data_dirs'}, # paDstSubdir,
             $p_err,
             );
        }

    # keep track of errors ... we want to send a final, summary email
    if ( $$p_err ne '' )
        {
        $replicate_error_cnt++;
        $$p_err = '';
        }
    } # tranche remit diff


##################### email?

# qa only
if ( $verbose_for_replication )
    {
    append_replicate_session_log ( "Possibly email:
  replicate_attempt_cnt=$replicate_attempt_cnt
  replicate_error_cnt=$replicate_error_cnt\n" );
    }

# start to think about email; if no attempts were made to replicate, we are done
# the attempt count was bumped if we saw extra-paths defined
return if ( $replicate_attempt_cnt == 0 );

# got this far; did attempt to replicate; if no errors, email and done
if ( $replicate_error_cnt == 0 )
    {
    ComposeAndSendEmail
        (
         'idX',
         "Successful replication of Intex data",
         [
          "For details, please refer to the session log file: $hCrntEnv{'replicate_session_log_file'}",
          ],
         );
    return;
    }

# got this far; have replication error, but if QA machine, ignore (because we are replicating to docked laptops)
if ( $verbose_for_replication )
    {
    print "ERROR in replication
However, no email sent because this is a QA machine\n";
    return;
    }

# got this far; report error
ComposeAndSendEmail
    (
     'idX',
     "Error replicating Intex data",
     [
      "For details, please refer to the session log file: $hCrntEnv{'replicate_session_log_file'}",
      ],
     );

} # possibly_replicate


1;
