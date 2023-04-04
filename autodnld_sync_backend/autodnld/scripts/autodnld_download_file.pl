# h:/fips/scripts/autodnld/autodnld_download_file.pl

# use strict

use vars ( qw
           (
            $com_spec
            $ship_server_password
            $is_unix
            $release_date
            $release_version
            $slash
            %hCrntEnv
            %hIniFile
             ));

my $intex_debug = ( $ENV{CVSROOT} eq ':local:\\\\dbserver\\d_drive\\cvs\\src' ) ? 1 : 0;


# AppendSumLog
# DownloadFileWorker
# DownloadFile   <<< ENTRY

# ---------------- AppendSumLog
# append info to summary log file

# ... pull .inf file e.g. aacc.inf
# ... pull version file e.g. autodnld.version.2.47.txt
# cmo shipment data files: .zip, .Z (shipinfo.* are boring; pull eot* every time)
# pooldata level0 data files: .hsp, .hdr, .inf (pull mbsstat.qa every time)
# pooldata level1 data files: .dat
# pooldata level1 data files: .arm, .geo
# perfdata: .txt ... pull perfstat.qa every time
# remitdata: remit.eq.200110 ... (pull remitstat.qa every time)

sub AppendSumLog
{
my (
    $src,
    $szDestIn,
    $sze,
    $min,
    ) = @_;

return if  ( $src =~ /\.inf/i );
return if  ( $src =~ /autodnld\.version/i );
return if  ( $src =~ /shipinfo/i );
return if  ( $src =~ /eot/i );
return if  ( $src =~ /mbsstat\.qa/i );
return if  ( $src =~ /perfstat\.qa/i );
return if  ( $src =~ /remitstat\.qa/i );
return if  ( $src =~ /rmtdstat\.qa/i );

# may have mixed slashes ... clean them up
FixSlashes
    (
     \$src,
     'unix',
     );

if (  open ( LOGOUT, ">>$hCrntEnv{'sum_log_file'}" ) == 1 )
    {
    print LOGOUT scalar(localtime()) . " $src $szDestIn $sze $min\n";
    close ( LOGOUT );
    }

} # AppendSumLog


# ----------------------------- DownloadFileWorker
# download a file

# If we have a temp_download_subdir defined:
#     if no psz arguments, use the temp subdir and copy file to final subdir
#     else, leave the file in the temp subdir

# If file has an interesting extension, add a line to the summation log file

# Always use binary mode.

# typical log file lines:
##  11:24 DownloadFileWorker: start: we are about to download a file
##    here is more infomation about the download:
##      file on Intex server=/cigna/distrib/last4/cmo_cdu.000118.zip
##      file on the client's hard disk (may be placed in a temp subdir)=d:\temp\autodnld\cmo_cdu\cmo_cdu.000118.zip
##      we will check the file size after we attempt to download; bytes=7883318
##      before downloading, we will check disk space on client's computer; we require bytes=7883318 bytes
##      special option is set: after download, do not copy file to final subdir; we will unzip it in place

## WARNING on log file: put stamp in line, so we can match on lines in log file

# Return () if no errors; else, list of error lines

sub DownloadFileWorker
{
my(
   $src,
                             # always start with slash plus user name
                             # examples:
                             #      /xmaspool/distribution/eot.txt
                             #      /xmaspool/../pooldata/shipping/199902280934
                             #      /xmaspool/../public/xxx.xx
                             # can have jumbled slashes ... we will fix them

   $dst,         # local file name (destination name) e.g. c:/autodnld/log/end_rate.eot
                             # can have jumbled slashes ... we will fix them
                         # if you use subdir=$hIniFile{'temp_download_subdir'}, will xfer remote->local and just leave it there

   $verify_file_size,    #  0=don't check for anything; 1=check for file existence only; else, check exact size per arg
                         # FYI: "0" used for pulling this: autodnld.version.2.55.txt

   ## optional args .................

   $chk_disk_room_flag,  # if defined, check for disk room before downloading (NOTE: $verify_file_size arg must be GT 1 so we can compute size needed)

   $phExtraArg,         # optional:
                        ##  {p_raw_dst_fn => "c:\foo.log"}

                           # if defined: special instructions: download to temp file subdir; leave it there; pass the name back
                           # NOTE: this parameter makes no sense unless we have defined $hIniFile{'temp_download_subdir'}
                           # pass back name of temp file to user
                           # the user will then uncompress directly from the temp file, and then unlink it, or whatever

                        ##  {retry_cnt => 3}     # default is 0; acceptable range is 0..2; may force retries lower based on ini file setting
                        ##  {p_raw_dst_file_size => ...}

   )= @_;

my $func = "DownloadFileWorker";

# arg. checking
$chk_disk_room_flag = 0 if ( !defined ( $chk_disk_room_flag ));

if ( $chk_disk_room_flag && $verify_file_size <= 1 )
    {
    AppendLog ( "$func: WARNING: set flag to check disk file before download, but didn't pass in a file size to use; thus, force flag back to 0" );
    $chk_disk_room_flag = 0;
    };

FixSlashes ( \$src, "unix" );
FixSlashes ( \$dst, "native" );

$src =~ s/\/\.\//\// ;

# compose info for log
my $slash_ix = rindex ( $src, "/" );

my $suffix = ( defined($phExtraArg)  &&  defined($phExtraArg->{retry_cnt}) ) ? "(retry count: $phExtraArg->{retry_cnt})" : "";
my $msg = "$func: " . stamp_as_yyyymmdd_hhmm() . ": start: we are about to download a file: " . substr($src,$slash_ix+1) . "$suffix
  here is more infomation about the download:
    file on Intex server=$src
    file on the client's hard disk (may be placed in a temp subdir)=$dst\n";

if ( $verify_file_size == 0 )
    {
    $msg .= "    no file existence nor file size checking will be done after we attempt to download";
    }
elsif ( $verify_file_size == 1 )
    {
    $msg .= "    we will check for file existence but will not check the file size after we attempt to download";
    }
else
    {
    $msg .= "    we will check the file size after we attempt to download; bytes=$verify_file_size";
    }

if ( $chk_disk_room_flag )
{
    $msg .= "\n    before downloading, we will check disk space on client's computer; we require bytes=$verify_file_size bytes";
}

if ( defined($phExtraArg)  &&  defined($phExtraArg->{p_raw_dst_fn}) )
{
    $msg .= "\n    special option is set: after downloading raw_dst_file, let caller know its name and done (we may unzip it in place)";
}

# add big block of info to log file: autodnld.log
AppendLog ( $msg );

# illegal coding?
if ( defined($phExtraArg)  &&  defined($phExtraArg->{p_raw_dst_fn})  &&  !defined ( $hIniFile{'temp_download_subdir'} ))
    {
    return ( "$func: internal error: must have temp subdir if p_raw_dst_fn arg used" );
    }

# just in case, try to make the subdir if missing
my $err_line = MkdirAsReq ( $dst, 1 );  # 1=we are passing in path+file

if ( $err_line ne '' )
{
    return ( "DownloadFileWorker: we could not make subdir: error traceback: $err_line" );
}


# decide on raw_dst_file; hopefully will use temp subdir
my $raw_dst_file;

if ( defined ( $hIniFile{'temp_download_subdir'} ) )      # e.g. c:\\intex\\autodnld\\temp
    {
    my $ix = rindex($dst,$slash);
    $raw_dst_file = "$hIniFile{'temp_download_subdir'}$slash" . substr($dst,$ix+1);
    }
else
{
    $raw_dst_file = "$dst.tmp";
}

# if user has autodnld temp subdir, may mkdir, may check disk room
if ( defined($hIniFile{'temp_download_subdir'}))
    {
    MkdirAsReq ( $hIniFile{'temp_download_subdir'}, 0 ); # 0 = subdir only

    if ( $chk_disk_room_flag)
        {
        my @aTraceBack = ();
        my $iFree = DiskSpaceAvailable ( $hIniFile{'temp_download_subdir'}, \@aTraceBack );

        if ( $iFree < $verify_file_size )
            {
            return (
                    "$func: not enough disk room in autodnld temp subdir for file",
                    "Remote file: $src",
                    "Local file: $raw_dst_file",
                    "Subdir we checked: $hIniFile{'temp_download_subdir'}",
                    "Actual bytes free: $iFree",
                    "Bytes required: $verify_file_size",
                    "Debug info from DiskSpaceAvailable():",
                    "----------------",
                    @aTraceBack,
                    "----------------",
                    );
            }
        }
    }


# zap existing raw file, if any
unlink ( $raw_dst_file );

if ( -e $raw_dst_file )
    {
       my @aMsg = ("$func: " . stamp_as_yyyymmdd_hhmm() . ": could not delete temp file=$raw_dst_file");
       push ( @aMsg, "We were going to download file=$src to this temp file" );
       return @aMsg;
    }

# have optional retry count; default is 2; acceptable range is 0..2
my $file_download_retry_count = 2;
$file_download_retry_count = $phExtraArg->{retry_cnt} if ( defined($phExtraArg)  &&  defined($phExtraArg->{retry_cnt}) );

if ( $file_download_retry_count  &&  $verify_file_size > 200_000_000 )
{
    AppendLog ( "$func: retry count set to zero, because file size GT 200,000,000 bytes" );
    $file_download_retry_count = 0 ;
}

# can use ini file to force retry lower (we checked for valid range of ini-file value as autodnld started up)
if ( $file_download_retry_count
     &&  defined($hIniFile{file_download_retry_count})
     &&  $file_download_retry_count > $hIniFile{file_download_retry_count} )
{
    AppendLog ( "$func: file_download_retry_count set to lower value per ini file: $file_download_retry_count" );
    $file_download_retry_count = $hIniFile{file_download_retry_count};

    if ( $file_download_retry_count > 2 )
        {
        return
            ( "ERROR: you have an illegal value in autodnld.ini",
              "The line starts with this: file_download_retry_count",
              "The permitted values are 0, 1 or 2" );
        }
}

AppendLog ( "$func: we have a retry count: $file_download_retry_count" ) if ( $file_download_retry_count );
my @aStatRawDstFile = ();
my $retry_tries_left = $file_download_retry_count;



############################# get file; may have retry GT 0
while(1)
{
    AppendLog ( "$func: at top of get-file loop: retries left: $retry_tries_left" ) if ($retry_tries_left > 0);
    my @aDownloadFileErr = ();

    $retry_tries_left--;
    @aDownloadFileErr=DownloadFileViaHTTP
    (
       $src,
       $raw_dst_file,
    );


    # if had error from worker, done (FYI: we still have NOT checked for file existence or size yet)
    if ( scalar(@aDownloadFileErr)  ){
       #return if exhausted retry counts
       return ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": error returned by DownloadFileViaXXX", "Debug info:", @aDownloadFileErr ) if ( $retry_tries_left==0);
       AppendLog("$func:error returned by DownloadFileViaXXX:".join("...",@aDownloadFileErr)."...We will retry after 1 minute......","1",\@aDownloadFileErr);
       sleep(60);
       next;
    }

    # if not checking for raw dst file at all...
    @aStatRawDstFile = stat($raw_dst_file);
    last if ( $verify_file_size == 0 );

##    # debug only
##    if ( $intex_debug && $retry_tries_left > 0 )
##        {
##        print "DEBUG: zap: $raw_dst_file\n";
##        unlink($raw_dst_file);
##        }

    ############ must at least have existence



    # if check for existence/size AND missing AND have retry...
    if ( scalar(@aStatRawDstFile) == 0  &&  $retry_tries_left > 0 )
        {
        AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": WARNING: will retry; after download no file found at all" );
        next;
        }

    # if check for existence/size AND missing AND no retry...
    if ( scalar(@aStatRawDstFile) == 0 )
        {
        # note: in log; want to be able to filter all lines w/ this function name
        AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": ERROR: pulling file from Intex server; after xfer, dst file does not exist
  dst file: $raw_dst_file
  src file: $src" );

        return ( "ERROR: we were trying to download file from Intex server: dest. file does not exist at all",
                 "src file: $src",
                 "  dest. file: $raw_dst_file",
                 "!!!!!!!!!!!!!!!!!!!!!!! POSSIBLE SOLUTION !!!!!!!!!!!!!!!!!!!!!: This may be a one time glitch.  Re-Running autodnld might be successful",
                                               );
        }

    # if check for existence/size AND zero len AND have retry...
    if ( $aStatRawDstFile[7] == 0  &&  $retry_tries_left > 0 )
        {
        AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": WARNING: will retry; after download have zero len file" );
        next;
        }

    # if check for existence/size AND zero len AND no retry...
    if ( $aStatRawDstFile[7] == 0  )
        {
        # note: in log; want to be able to filter all lines w/ this function name
        AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": ERROR: dest. file is zero length
  src file: $src
  dst file: $raw_dst_file\n" );

        # this is a common error: speak english to the end user
        return ( "$func: ERROR: pulling file from Intex server: after xfer, dst file is zero length",
                 "  src file: $src",
                 "  dst file: $raw_dst_file",
                 "!!!!!!!!!!!!!!!!!!!!!!! POSSIBLE SOLUTION !!!!!!!!!!!!!!!!!!!!!: This may be a one time glitch of a dropped connection.  Re-running autodnld might be successful",
                                            );
        }

    # got this far; we at least have existence; if that's all we need we are done
    AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": raw_dst file exists" );
    last if ( $verify_file_size == 1 );


    ################ must check file size in bytes


    # if mismatch...
    if ( $aStatRawDstFile[7] != $verify_file_size )
        {
        if ( $hIniFile{'ignore_size_check'} == 1 )
            {
            AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": after download have size mismatch.  Ignoring b/c of ignore_size_check=1 in ini file." );
            }
        else
            {
            # if file with len > 0 AND must check file size AND retry
            if ( $retry_tries_left > 0 )
                {
                # note: in log; want to be able to filter all lines w/ this function name
                AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": WARNING: will retry; after download have size mismatch; probably an incomplete download" );
                next;
                }

            # if file with len > 0 AND must check file size AND no retry
            my @aMsg = ( "ERROR: we were attempting to pull a file from the Intex server" );
            push ( @aMsg, "Src file: $src" );
            push ( @aMsg, "Dst file: $raw_dst_file" );
            push ( @aMsg, "However, the final file size is incorrect" );
            push ( @aMsg, "Expected size=$verify_file_size bytes; actual size: $aStatRawDstFile[7] bytes" );
            push ( @aMsg, "!!!!!!!!!!!!!!!!!!!!!!! POSSIBLE SOLUTION !!!!!!!!!!!!!!!!!!!!!: May be a one time glitch. Try re-running autodnld" );

            # note: in log; want to be able to filter all lines w/ this function name
            AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": ERROR: debug info:\n" . join("\n",@aMsg) );

            # (this is a common error; want good error reporting)
            return @aMsg;
            }
        }

    # got this far; all is OK
    last;
}
######### end retry

# got this far; have done any file existence or size checking per function arg
AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": done with retry loop (retry count may have been 0)" );

# caller may want raw file size (this is silly: why don't they check themselves?)
${$phExtraArg->{p_raw_dst_file_size}} = $aStatRawDstFile[7] if ( defined($phExtraArg)
                                                         &&  defined($phExtraArg->{p_raw_dst_file_size})
                                                         &&  scalar(@aStatRawDstFile) );

# caller may want name of raw file (also a signal: tell caller fn and done)
if ( defined($phExtraArg)  &&  defined($phExtraArg->{p_raw_dst_fn}) )
{
    ${$phExtraArg->{p_raw_dst_fn}} = $raw_dst_file;
    AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": OK: tell caller name of raw_dst_file and done" );
    return ();  # no error
}

# if caller asked for file to be downloaded to the temp subdir (done implicitly, not explicitly), we are done
if ( $raw_dst_file eq $dst )
    {
    AppendLog ("$func: " . stamp_as_yyyymmdd_hhmm() . ": OK: all done; caller wants raw_dst_file as is" );
    return ();  # no error
    }

# if don't check for dst at all AND no raw_dst_file, exit now (don't try to copy)
if ( $verify_file_size == 0  &&  scalar(@aStatRawDstFile) == 0 )
{
    AppendLog ("$func: " . stamp_as_yyyymmdd_hhmm() . ": OK: all done; no raw dest file at all, but caller doesn't care" );
    return ();
}



###################### ok, got this far, raw_dst file exists and is OK, but caller wants final file elsewhere
AppendLog ("$func: " . stamp_as_yyyymmdd_hhmm() . ": caller wants raw_dst_file copied somewhere else; onwards..." );

# zap dst...
unlink ( $dst );

if ( -e $dst )
    {
    my @aMsg = (  );

    # speak english to the end user
    my @aMsgReturn = (
            "ERROR:",
            "We were able to download file from ship server: $raw_dst_file",
            "However, we could not overwrite the final dest. file: $dst",
            "Please make sure the file is not in use: file: $dst",
            );
    AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm(). ": ERROR: unable to delete final output file: $dst", "", \@aMsgReturn );
    return ( @aMsgReturn ) ;
    }

# optional check for disk room (we figure out dst path on the fly)
if ( $chk_disk_room_flag)
{
    my $ix = rindex ( $dst, $slash );   # figure out local dir
    my $szDstSubdir = substr($dst,0,$ix);

    my @aTraceBack = ();
    my $iFree = DiskSpaceAvailable ( $szDstSubdir, \@aTraceBack );

    if ( $iFree < $verify_file_size )
        {
        AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": ERROR
  Remote file=$src
  Local file=$dst
  Bytes free for subdir=$szDstSubdir: $iFree
  Bytes required: $verify_file_size
  Debug info from DiskSpaceAvailable():
  =====
" . join("\n",@aTraceBack ) );

        # speak English to end user
        return (
                "ERROR: not enough disk room in for file that we just downloaded",
                "File on Intex server: $src",
                "Where file needs to be copied to: $dst",
                "Subdir we checked: $szDstSubdir",
                "Bytes free: $iFree",
                "Bytes required: $verify_file_size",
                "Debug info from DiskSpaceAvailable():",
                "--------------",
                @aTraceBack,
                "--------------",
                );
        }
}

# copy the file (rarely done in Win32 for zip files, since we should be using a temp subdir, and we unzip in place)
my $szCmd;

if ( $is_unix )
{
    $szCmd = "cp $raw_dst_file $dst";
}
else
{
    my $dstx = $dst;
    quote_if_has_spaces ( \$dstx );
    $szCmd = "$com_spec copy $raw_dst_file $dstx";
}

my @aIgnore = `$szCmd`;

# copy may have failed
my ( @aDst ) = stat($dst);

if ( scalar(@aDst) == 0 )
{
    my @aMsg = ( "ERROR copying file that we downloaded from temp. area to final dest. area" );
    push ( @aMsg, "src file: $raw_dst_file");
    push ( @aMsg, "dst file is missing: $dst");
    push ( @aMsg, "NOTE: If you were copying to a network drive, you may not" );
    push ( @aMsg, "      have write rights on that drive" );
    AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm(). ": ERROR: debug info:\n" . join("\n",@aMsg) );
    return @aMsg;
}
elsif ( $aStatRawDstFile[7] != $aDst[7] )
{
    my @aMsg = ( "ERROR copying file that we downloaded from temp. area to final dest. area" );
    push ( @aMsg, "The file sizes do not match" );
    push ( @aMsg, "  src file: $raw_dst_file");
    push ( @aMsg, "  src size=$aStatRawDstFile[7]" );
    push ( @aMsg, "  dst file: $dst");
    push ( @aMsg, "  dst size=$aDst[7]" );
    push ( @aMsg, "" );
    push ( @aMsg, "NOTE: If you were copying to a network drive, you may not" );
    push ( @aMsg, "      have the proper write rights on that drive" );
    AppendLog ( "$func: " . stamp_as_yyyymmdd_hhmm() . ": ERROR: debug info:\n" . join("\n",@aMsg) );
    return @aMsg;
}

# copy was ok, zap source
unlink ( $raw_dst_file );

# all done
AppendLog ("$func: " . stamp_as_yyyymmdd_hhmm() . ": raw_dst_file was copied to $dst; all done with no problems" );
return ();  # return () for no errors

} # DownloadFileWorker


# --------------------- DownloadFile  <<< ENTRY
# all file downloads come thru this entry point: this code is just a wrapper around DownloadFileWorker() so we can log some succesfull downloads
# Return () if no errors; else, return list of error lines

sub DownloadFile
{
my(
   $src,                # see DownloadFileWorker() for explanation of arg
   $dst,                # see DownloadFileWorker() for explanation of arg
   $verify_file_size,   #  0=don't check for anything; 1=check for file existence only; else, check exact size per arg
   $chk_disk_room_flag, # optional: if defined: check for disk room before downloading (NOTE: $verify_file_size arg must be GT 1)

   $phExtraArg,         # optional:
                        ##  {p_raw_dst_fn => "c:\foo.log"}
                        ##  {retry_cnt => 3}
   )= @_;

my $func = "DownloadFile";
my $start_time = time();

return ( "$func: internal errors: line: " . __LINE__ ) if ( defined($phExtraArg) && ref($phExtraArg) ne 'HASH' );


# call worker; return () if no errors; else, list of error lines
my $xfer_size = 0;
$phExtraArg->{p_raw_dst_file_size} = \$xfer_size;

my @aErr = DownloadFileWorker
    (
     $src,
     $dst,
     $verify_file_size,
     $chk_disk_room_flag,

   $phExtraArg,         # optional: e.g.
                        ##  {p_raw_dst_fn => ..."}
                        ##  {retry_cnt => 3}
                        ##  {p_raw_dst_file_size => ...}

     );

# if no errors, log the xfer
if (scalar(@aErr) == 0 )
    {
    my $min = sprintf ( "%.1f", ( time() - $start_time ) / 60 );

    AppendSumLog  # note: AppendSumLog will skip uninteresting files
    (
     $src,
     $dst,
     $xfer_size,
     $min,
     );
    }

return @aErr;

} # DownloadFile

1;
