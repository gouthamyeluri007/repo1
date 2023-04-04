# autodnld_config.pl, used to install Intex autodnld.pl; may be re-run as needed this way: autodnld -config

# use strict
use Cwd;

my $question_separator = "-------------------------------\n";
my $done_with_input = 0;

# verbose ?
my $verbose_config = 0;

if ( defined($ENV{'COMPUTERNAME'})  &&  $ENV{'COMPUTERNAME'} eq 'TEDH'  &&  -d "h:\\fips\\scripts" )
{
    print "verbose_config = 1 because COMPUTERNAME=TEDH etc\n";
    $verbose_config = 1;
}

my $new_ini_file;  # set to 0/1 fairly early; if 1, this is a new ini file (probably the first time autodnld has been run)

# shared with autodnld.pl
use vars ( qw
           (
            $slash
            $is_unix
            $com_spec
            $ship_server_password
            $this_script_is_compiled
            %hIniFile
            $release_version
            $release_date
            %hCmoState
            %hCrntEnv
            ));

# list of possible ini file values (for all OS)
use vars ( qw (  @aAllPossibleIniKey ) );
# table of contents
# ================
# figure_out_os
# zap_key_if_val_is_default
# FYI: ReadIniFile is in autodnld.pl
# DeleteUnexpectedIniKeys ... use @aAllPossibleIniKey
# WriteIniFile
# CopyDistFile
# PromptAndGetWorker
# PromptAndEditUsingHashKey
# PromptAndGetYnWithDefault (try to avoid ... use PromptAndEditYnUsingHashKey() instead)
# PromptAndEditYnUsingHashKey
# FindOrCreateIniFile
# Encrypt
# PossiblyGetPassword
# RecordUserAndPassword
# RecordCdiCduSubdirs
# RecordEmailStuff
# EditCduPurgeDepth
# EditMailBin
# CleanUpScriptsSubdir
# EditHashValues
# edit_ini_file   <<< ENTRY



# ------------------ figure_out_os
# make guess; possibly have user verify
# e.g. $hIniFile{'operating_system'} = "nt";
sub figure_out_os
{
# we can detect win32 os's
if ( lc($^O) eq 'mswin32' )
{
    $hIniFile{'operating_system'} = "nt";
    return;
}

# we can detect solaris
if ( $^O =~ /solaris/i )
{
    $hIniFile{'operating_system'} = "unix";
    return;
}

# make a guess
$hIniFile{'operating_system'} = "unix";

# got this far; verify OS
while (1)
{
   PromptAndGetWorker
       (
        "\nWhat operating system are you running under: \"unix\" or  \"nt\"
(Use \"nt\" for Windows NT/2000/XP) (NOTE: Windows 95 is not supported)",                 # # prompt ... we emit dotted line, then this prompt, then new line; may be undef
        $hIniFile{'operating_system'},    # default value ... we emit this inside angle brackets
        \$hIniFile{'operating_system'},   # pointer to dst for edited value
        );

   if ( $hIniFile{'operating_system'} =~ /^unix$|^nt$/ )
   {
      last;
   }

   print "ERROR: invalid value; please try again...\n";
}

} # figure_out_os


# ---------------------------------- zap_key_if_val_is_default
# remove configuration file parameter if val is same as default
sub zap_key_if_val_is_default
{
my
    (
     $key,
     $default_val
     ) = @_;

if ( defined($hIniFile{$key}) && $hIniFile{$key} eq $default_val )
     {
     print "We have removed a configuration file parameter because val is same as default:
  key=$key
  old val=$hIniFile{$key}
  default val=$default_val\n";
     delete ( $hIniFile{$key} );
     }

} # zap_key_if_val_is_default


# ------------- DeleteUnexpectedIniKeys
# have just read ini file as part of the -config process; clean out old and unused keys
# we have defined in autodnld.pl: list of possible ini file values (for all OS): @aAllPossibleIniKey
sub DeleteUnexpectedIniKeys
{
my ( @aKey, $szKey );

# go thru the keys; if unexpected, delete it
foreach $szKey ( sort(keys(%hIniFile )))
    {
    # if in second section (extra cmo downloads), leave it
    if ( $szKey =~ /\[/ )
        {
        next;
        }

    # if in our ref list, OK
    if ( scalar(grep(/^$szKey$/,@aAllPossibleIniKey)))
        {
        next;
        }
    delete ($hIniFile{$szKey} );
    print "\nDeleteUnexpectedIniKeys(): we have removed the parameter \"$szKey\" from the ini file
We did this because we don't recognize the parameter name\n";
    }

zap_key_if_val_is_default ( 'bond_data_months_back',   "2" );
zap_key_if_val_is_default ( 'cdu_check_n_months_back', "2" );
zap_key_if_val_is_default ( 'dbstatus_check',          'strict' );
zap_key_if_val_is_default ( 'minimal_email',           'N'                                   );

} # DeleteUnexpectedIniKeys


# ----------------------------- WriteIniFile
# write %hIniFile to .ini file

# if we have paragraphs at the bottom of the ini file, they are a little irregular to encode
# sample lines
# -----------------------------
# [flash]=y
# tgt_cdi_dir=c:\intex\cmo_cdi
# tgt_cdu_dir=c:\intex\cmo_cdu
# -----------------------------

# sample single value hash key: email_to
# sample paragraph hash keys: [flash]y [flash]tgt_cdi_dir [flash]tgt_cdu_dir)

sub WriteIniFile
{
# say hello
my $fn = "$hIniFile{'autodnld_home'}$slash" . "scripts$slash" . 'autodnld.ini';
print "Writing ini file: $fn\n";

my @aTime = localtime();
my $stamp = sprintf ( "%04d%02d%02d_%02d%02d%02d", $aTime[5] + 1900, $aTime[4] + 1, $aTime[3],   $aTime[2], $aTime[1], $aTime[0] );  # #yyyymmdd_hhmmss
my $szBackupFile = "$fn." . $stamp;

my ( $szLine, $szKey, @aKey, %hPara, %hIni, $szVal, $szCmd );

# if exists, make a backup
if ( -e $fn )
    {
    if ( $hIniFile{'operating_system'} ne "unix" ) # unix/nt
        {
        $szCmd = "$com_spec copy $fn $szBackupFile";
        }
    else
        {
        $szCmd = "cp -p $fn $szBackupFile";
        }

    my @aLine = `$szCmd`;
    }

# open file
if(!open(PARAMS,">$fn"))
    {
    print "ERROR: counld not open file=$fn for output\n";
    PressAnyKeyPriorExit();
    exit(1);
    }

# split the hashes into "ini" (tgt_cdu_dir,c:\\intex\\cmo_cdi) and "para" arrays ([flash]tgt_cdu_dir,c:\\intex\\cmo_cdi)
foreach $szKey ( keys ( %hIniFile ) )
    {
    if ($szKey =~ /^\[/ )
        {
        $hPara{$szKey} = $hIniFile{$szKey};
        }
    else
        {
        $hIni{$szKey} = $hIniFile{$szKey};
        }
    }

# put comments on top; always the same
print PARAMS "# Last update: " . scalar(localtime()) . "\n";
print PARAMS "# Specifies parameters used by Intex autodnld\n";
print PARAMS "# This file was written by version $release_version of autodnld\n";

# print ini hash keys
@aKey = sort(keys(%hIni));

foreach $szKey ( @aKey )
    {
    print PARAMS "$szKey=$hIniFile{$szKey}\n";
    }

# print para hash keys, if any
# a little irregular; if length of value gt 1, must be cdi/cdu keys, must xlat it
# Example: key=[flash]tgt_cdi_dir, change to key=tgt_cdi_dir
@aKey = sort(keys(%hPara));

foreach $szKey ( @aKey )
    {
    $szVal = $hIniFile{$szKey};
    $szKey =~ /\[(\S+)\](\S+)/; # token in square brackets right next to 2nd token

    if ( length($szVal) > 1 )
        {
        print PARAMS "$2=$szVal\n";
        }
    else
        {
        print PARAMS "$szKey=$szVal\n";
        }
    }

close(PARAMS);

} # WriteIniFile


# --------------------------- CopyDistFile
# Translate slashes; do it; check for dest when done.
# If source missing but have dest, this is OK
# Must be sitting in the install subdir
sub CopyDistFile
{
    my(
       $szSrc,
       $szDst,
       ) = @_;

    my( $szCmd, $iDiff );

    # xlat slashes
    if($is_unix)
    {
       $szSrc =~ s/\\/\//g;   # back to forward
       $szDst =~ s/\\/\//g;
    }
    else
    {
       $szSrc =~ s/\//\\/g;   # forward to back
       $szDst =~ s/\//\\/g;   # forward to back
    }

    # If source missing but have dest, this is OK
    if ( -e $szDst && ! ( -e $szSrc ) )
    {
        return 0;
    }

    # if you are running install in the scripts subdir, skip file
    if ( $szSrc eq $szDst )
    {
        return 0;
    }

    # exit if files are the same
    if ( -e $szDst &&  -e $szSrc )
    {
       $iDiff = abs ( (stat($szSrc))[9]- (stat($szDst))[9] );

       if ( $iDiff <= 2 )
       {
          return 0;
       }
    }

    # create command
    if($is_unix)
    {
       $szCmd = "cp -p $szSrc $szDst";
    }
    else
    {
       my($shell) = $hIniFile{'operating_system'} eq "nt" ? "cmd /c" : "command /c";
       $szCmd = "$shell copy $szSrc $szDst";
    }

    # run copy
    print( "\n$szCmd\n");
    system( $szCmd );

    if ( -e $szDst )
    {
       return 0;
    }

    print "WARNING: file copy failed; src=$szSrc  dst=$szDst; press return > ";
    <STDIN>;

    return 1;

} # CopyDistFile


# ---------------------------- PromptAndGetWorker
# optional announcement; show default; get value; ...

sub PromptAndGetWorker
{
my( $szAnnounce,   # prompt ... we emit dotted line, then this prompt, then new line; may be undef
        $szDefault,    # default value ... we emit this inside angle brackets ... if user enters just nothing or white space, return this value
        $refszTarget,  # place edited value here ... always trim any trailing backslashes; always left and right trim
        ) = @_;

my( $szTemp );

# optional announcement
if ( defined($szAnnounce))
    {
       print $question_separator;
       print("$szAnnounce\n");
    }

# show default and get value
print("<$szDefault>:  ");
$szTemp = <STDIN>;
$szTemp =~ s/[\n\r]//g;

# if just pressed return, use default
if ( $szTemp eq "" )
    {
    $$refszTarget = $szDefault;
    return 0;
    }

# if value is only white space, clear the old value
if ( $szTemp =~ /^\s{1,}$/ )
    {
    $$refszTarget = '';
    return 0;
    }

# all trim input
$szTemp =~ s/^\s+//;
$szTemp =~ s/\s+$//;

# if magic value
if ( $szTemp eq "DONE" )
    {
    $done_with_input = 1;
    return;
    }

# got this far; no default used
$$refszTarget = $szTemp;

my $sznewslash = "\\" . $slash ;
# clear any trailing slash
if( defined($slash) &&  $$refszTarget =~ /$sznewslash$/)
    {
    chop($$refszTarget);
    }

return 0;

} # PromptAndGetWorker


# ----------------------------- PromptAndEditUsingHashKey
# This function is used a whole lot
# It calls worker function: PromptAndGetWorker()

sub PromptAndEditUsingHashKey
{
my (
    $szPrompt,       # may be undef
    $szKey,          # key into %hIniFile
    %hArg,           # example of caller's code: opt1 => "option a val"
                   ## 'default_val_if_no_existing' ...  even if defined, only used if we cannot find existing value using $szKey
                   ## 'default_val_always' .... force this as the default choice withing the angle brackets
                   ## 'no_space_in_val_flag' ... if embedded spaces, prompt user to try again
                   ## 'slash_required_flag'
                   ## 'lower_case_required'
    ) = @_;

my ( $szEdited, $szDefault );

# decide on what default value to show user
if ( defined ( $hArg{'default_val_always'} ))
     {
     $szDefault = $hArg{default_val_always};
     }
elsif ( defined ( $hIniFile{$szKey} ) )
    {
    $szDefault = $hIniFile{$szKey};
    }
elsif (defined($hArg{'default_val_if_no_existing'}))
    {
    $szDefault = $hArg{'default_val_if_no_existing'};
    }
else
    {
    $szDefault = "";
    }

# loop to get input (because may fail QA test)
while ( 1 )
    {
    PromptAndGetWorker
        (
         $szPrompt,             # ok if undef
         $szDefault,
         \$szEdited,
         );

    $hIniFile{$szKey} = $szEdited;

    # may not allow spaces
    if ( defined($hArg{'no_space_in_val_flag'}) )
         {
         if ( index($szEdited,' ') >= 0 )
             {
             print "ERROR: spaces are not allowed, press return key > ";
             <STDIN>;
             next;
             }
         }

    # may require slash
    if ( defined($hArg{'slash_required_flag'}) )
         {
         if (  index($szEdited, $slash) < 0 )
             {
             print "ERROR: slash character is required in value, press return key > ";
             <STDIN>;
             next;
             }
         }

    # may force L.C.
    if ( defined($hArg{lower_case_required})  &&  lc($szEdited) ne $szEdited )
         {
         print "ERROR: must be all lowercase, press return key > ";
         <STDIN>;
         next;
         }

    # got this far; all is OK
    last;

    } # forever

} # PromptAndEditUsingHashKey


# ---------------------------- PromptAndGetYnWithDefault (try to avoid ... use PromptAndEditYnUsingHashKey() instead)
# prompt for yes/nodata; also default value; return value of Y or N; reprompt if bad data

sub PromptAndGetYnWithDefault
{
    my( $szAnnounce ) = $_[0];   # prompt
    my( $szDefault ) = $_[1];    # default value
    my( $refszTarget ) = $_[2];   # put response here

    my( $szTemp );

    # clean up incoming y/n
    $szDefault = uc($szDefault);

    if ( $szDefault ne "Y" && $szDefault ne "N" )
    {
        $szDefault = "N";  # arbitrary choice
    }

    while ( 1 )
    {
       print $question_separator;
       print("$szAnnounce\n");
       print("<$szDefault>:  ");

        # get user input
        $szTemp = <STDIN>;
        $szTemp =~ s/[\n\r]//g;

        # if pressed enter, use default
        if ( $szTemp eq "" )
        {
            $$refszTarget = $szDefault;
            return 0;
        }

        # got this far; no default used
        # clean up incoming y/n
        $szTemp = uc($szTemp);

        if ( $szTemp eq "Y" || $szTemp eq "N" )
        {
            $$refszTarget = $szTemp;
            return 0;
        }

        print "\n Invalid input, try again...\n";

    } # forever

} # PromptAndGetYnWithDefault


# ----------------------------- PromptAndEditYnUsingHashKey
sub PromptAndEditYnUsingHashKey
{
    my ( $szPrompt, $szKey ) = @_;

    my ( $szEdited );

    PromptAndGetYnWithDefault ( $szPrompt, $hIniFile{$szKey}, \$szEdited );
    $hIniFile{$szKey} = $szEdited;
    return 0;

} # PromptAndEditYnUsingHashKey


# ------------------ encrypt_password
# passed in plain text, update $hIniFile{'password'}
sub encrypt_password
{
my (
    $plain,
    ) = @_;
$ship_server_password=$plain; #this could be used for later testing after config is done, instead of reading ini file twice.
$hIniFile{'password'} = 'aknmzn' . reverse($plain);

} # encrypt_password


# ---------------- PossiblyGetPassword
# possibly edit this value: $hIniFile{'password'} <<< this is the encrypted string
# called by RecordUserAndPassword()
sub PossiblyGetPassword
{
# if none, default to blank
if ( ! defined ( $hIniFile{'password'} ) )
    {
    $hIniFile{'password'} = "";
    }

my $iMustEnter = 0;

# if no password, must enter it
if( $hIniFile{'password'} eq "" )
    {
    $iMustEnter = 1;
    }
# else, ask user
else
    {
    print "Do you want to re-enter your password y/n? > ";
    my $szYesNo = scalar(<STDIN>);

    if ( lc($szYesNo) =~ /^y/ )
        {
        $iMustEnter = 1;
        }
    }

# exit early?
if ( $iMustEnter == 0 )
    {
    return 0;
    }

# got this far, need password
print ( "Please enter password for user=$hIniFile{'user'}\n");
my $szPassword = <STDIN>;
$szPassword =~ s/[\n\r]//g;
encrypt_password ( $szPassword );  # passed in plain text, update $hIniFile{'password'}

} # PossiblyGetPassword


# ---------------------- RecordUserAndPassword
# ship machine; user name; user password

sub RecordUserAndPassword
{
# edit user name
PromptAndEditUsingHashKey
    (
     "Enter your user name on the Intex shipment server",
     'user',
     no_space_in_val_flag => 1,
     );

# possibly get password
PossiblyGetPassword();

} # RecordUserAndPassword


# ---------------------------------------- RecordCdiCduSubdirs
# edit and record cdi/cdu paths
# keys are tgt_cdi_dir and tgt_cdu_dir

sub RecordCdiCduSubdirs
{
my ( $szBaseDir, $szCurrent, $szTgtCdiDir, $szTgtCduDir, $szPath );

my $mkdir_retry_cnt = 1;

# if don't have, use default
if ( !defined ($hIniFile{'tgt_cdi_dir'}))
    {
    $hIniFile{'tgt_cdi_dir'} = ($is_unix) ? "/home/intex/cmo_cdi" : "c:\\intex\\cmo_cdi";
    }

# loop for cdi
while (1 )
    {
    if ( $is_unix )
        {
        PromptAndEditUsingHashKey
            (
             "Enter the directory you wish to have cdi data downloaded to", # prompt
             'tgt_cdi_dir',     # key
             slash_required_flag => 1,
             no_space_in_val_flag => 1,
             lower_case_required => 1,  # else dbstatus will fail
             );
        }
    else
        {
        PromptAndEditUsingHashKey
            (
             "Enter the directory you wish to have cdi data downloaded to", # prompt
             'tgt_cdi_dir',     # key
             slash_required_flag => 1,
             no_space_in_val_flag => 1,
             );
        }

    # mkdir the cdi subdir as needed
    if ( MkdirAsReq ( $hIniFile{'tgt_cdi_dir'},undef,$mkdir_retry_cnt ) ne '' )
        {
        print "WARNING: Unable to create directory=$hIniFile{'tgt_cdi_dir'} press return key > ";
        <STDIN>;
        }
    else
        {
        last;
        }
    }

# cdu is always derived from cdi
my $default_cdu_dir = $hIniFile{'tgt_cdi_dir'};
$default_cdu_dir =~ s/cdi/cdu/i;

# loop for cdu
while (1)
    {
    if ( $is_unix )
        {
        PromptAndEditUsingHashKey
            (
             "Enter the directory you wish to have cdu data downloaded to", # prompt
             'tgt_cdu_dir',     # key
             default_val_always => $default_cdu_dir,
             slash_required_flag => 1,
             no_space_in_val_flag => 1,
             lower_case_required => 1,
             );
        }
    else
        {
        PromptAndEditUsingHashKey
            (
             "Enter the directory you wish to have cdu data downloaded to", # prompt
             'tgt_cdu_dir',     # key
             default_val_always => $default_cdu_dir,
             slash_required_flag => 1,
             no_space_in_val_flag => 1,
             );
        }

    if ( MkdirAsReq ( $hIniFile{'tgt_cdu_dir'},undef,$mkdir_retry_cnt ) ne '' )
        {
        print "WARNING: Unable to create directory=$hIniFile{'tgt_cdu_dir'}, press return key > ";
        <STDIN>;
        }
    else
        {
        last;
        }
    }

} # RecordCdiCduSubdirs


# ---------------------------------------------- RecordEmailStuff
# NOTE: when running autodnld.pl under NT: use blat.exe
#    -t (to)        supplied on command line; key=email_to
#    -s (subject)   supplied on command line ... decide at run time
#    -server        before 11/97, put in registry; key=mail_server
#    -f             sender ... must be known to SMTP daemon; key=mail_sender
#    -i             sender as appears on email; same as -f

sub RecordEmailStuff
{
# mail to
PromptAndEditUsingHashKey
    (
     "Enter the email address(s) you would like to send notifications to.
Enter one or more names separated by commas.
If you enter a single space, this will clear the email list,
and no emails will be sent at all", # prompt
     'email_to',                #key
     no_space_in_val_flag => 1,
     );

# if blank email list, return now
if ( $hIniFile{'email_to'} eq "" )
    {
    return 0;
    }


############ got this far; we want email

# if this is a new .ini file, and if this is Win32, fill in "mail_sender" using first item from "email_to"
# this is because some SMTP services care who is sending the mail
# NOTE: on the email itself, the user will still see "mail_from" setting (default value is "Intex_auto_download")
# Linux sendEmail requires legit mail_sender field to work

if ( !$is_unix ) {
    if ($new_ini_file )
        {
        my @aToken = split(",",$hIniFile{'email_to'});
        $hIniFile{'mail_sender'} = $aToken[0];
        }
    }
else
    {
    PromptAndEditUsingHashKey
        (
         "Enter ONE email address you would like to use as the sender of email notifications. This is often a required field
         for mailserver. Please use properly formatted email addresss,e.g.,username\@mailservername.com", # prompt
         'mail_sender',                #key
         no_space_in_val_flag => 1,
         );
     }


PromptAndEditUsingHashKey
    (
     "We need to know the network name of your mail server
(You can get this from your network administrator)
In technical terms, this is the name of your \"SMTP server\"

Enter the name of your mail server", # prompt
     "mail_server",         # key
     no_space_in_val_flag => 1,
    );



} # RecordEmailStuff

# ---------------------------------------------- RecordDbstatusUploadInfo
# NOTE: y means will upload dbstatus files.

sub RecordDbstatusUploadInfo
{
# mail to
PromptAndEditUsingHashKey
    (
     "Autodnld contains a feature where if there is a problem with your database,
Autodnld will upload a file to Intex to make a fix-up shipment.
Some firewalls do not allow data to be uploaded, so this feature is not activated by default.
If you are unsure if this is allowed on your server, set this to \"n\", it can be changed later.
To enable this feature, please enter \"y\",
To dis-able this feature, please enter \"n\",", # prompt
     'upload_dbstatus',                #key
     default_val_always => "n",
     default_val_if_no_existing => "n",
     no_space_in_val_flag => 1,
     );

} # RecordDbstatusUploadInfo


sub RecordUpdateExeInfo
{
# mail to

return if ( $hIniFile{'operating_system'} eq 'unix' );
PromptAndEditUsingHashKey
    (
     "Autodnld contains a feature where it tries to update to the latest version available.
Autodnld will download a renamed exe from Intex to update the version.
Some firewalls do not allow exe's to be downloaded.
If you are unsure if this is allowed on your server, set this to \"y\", it can be changed later.
To skip updating the exe, please enter \"y\",
To enable updating the exe, please enter \"n\",", # prompt
     'skip_update_exe',                #key
     default_val_always => "n",
     default_val_if_no_existing => "n",
     no_space_in_val_flag => 1,
     );

} # RecordDbstatusUploadInfo


# -------------------------------- EditCduPurgeDepth
# if monthly value is entered, we run the purge code: autodnld_prune.pl
# Per CS request and Matt, GZ, purge is default to 0 in initial config.20120524
#Chris request 20140115, cdu_purge_depth no longer a required, this sub is bypassed
sub EditCduPurgeDepth
{
# if no value, default is 0 (no purge)
if ( !defined ( $hIniFile{'cdu_purge_depth'} ) )
   {
      $hIniFile{'cdu_purge_depth'} = 0;
   }

#PromptAndEditUsingHashKey
#    (
#        "After autodnld downloads CMO data,
#autodnld can optionally remove (\"prune\") older \"CDU\" files
#from your Intex database.
#
#FYI: For most deals, Intex generates one CDU file per deal
#per month by rolling forward the mathematical model for the deal
#based on the latest data from the trustee for the deal.
#You only need older CDU files if you are settling in the past.
#
#You can control this pruning process by setting the
#\"prune depth\".  If you specify a depth of 0, no
#pruning will be done at all.
#
#Example: if you set the prune depth to 12, autodnld will
#walk backwards thru the CDU files, and once the CDU file count
#for any deal exceeds 12, it will erase any older CDU files.
#
#Please enter the CDU prune depth",   # prompt
#     "cdu_purge_depth",  # key
#     default_val_if_no_existing => 0,
#     no_space_in_val_flag => 1,
#     );
#
} # EditCduPurgeDepth


# ------------------------- EditMailBin
# unix only
sub EditMailBin
{
    print "\nTo provide maximum flexibility, you must provide a Perl expression for sending email.\n";
    print "\nThis expression will be eval'ed to produce a UNIX command,\n";
    print "which we will then \"system()\" to mail the message.\n";
    print "\n";
    print "There are three variables that you should use in your Perl expression:\n";
    print "  \$szEmailFile: contains lines to be emailed\n";
    print "  \$szSubject: subject of email\n";
    print "  \$szEmailTo: list of one or more people to email to\n";
    print "\n";
    print "For example, suppose we typically send email with a command like this: \n";
    print "  cat temp.txt | /usr/ucb/mail -s 'this is the subject' tedh\n";
    print "\n";
    print "We would then supply the following Perl expression:\n";
    print "  cat \$szEmailFile | /usr/ucb/mail -s '\$szSubject' \$szEmailTo\n";


    print "\n";
    PromptAndEditUsingHashKey ( "Please enter Perl expression", "mail_bin" );

} # EditMailBin


# ------------------ EditHashValues
# this value is known: $hIniFile{'operating_system'} ... /^unix$|^nt$/
# note that user can enter DONE for quick exit
sub EditHashValues
{
# get user name etc
RecordUserAndPassword();

if ( $done_with_input )
    {
    return;
    }

# for connection, we want the connection string to be present in the .ini file always
# If first time, default to ship.intex.com
# Else, must be editing an existing file, show the value and let them edit it
if ($new_ini_file)
    {
    $hIniFile{'connection'} = "ship.intex.com";
    $hIniFile{'try_alternate_server'}='N'; #We will not try alternate server, intex will redirect
    }
else
    {
    $hIniFile{'connection'} = "ship.intex.com" if ( !defined ($hIniFile{'connection'}) );

    my $prompt = "Please enter the Intex shipment server that you wish to pull data from (default ship.intex.com):";

    PromptAndEditUsingHashKey
        (
         $prompt,
         'connection', # key into hash
         no_space_in_val_flag => 1,     # if embedded spaces, prompt user to try again
         );
    }

# ask for cdi/cdu home dir e.g. c:\\intex, then prompt for cdi and cdu dirs
RecordCdiCduSubdirs();

if ( $done_with_input )
    {
    return;
    }

# figure out email stuff
RecordEmailStuff();

RecordDbstatusUploadInfo();
RecordUpdateExeInfo();

if ( $done_with_input )
    {
    return;
    }

# we like to have a 'temp_download_subdir', # if none defined, silently add one
if (   !defined ( $hIniFile{'temp_download_subdir'}) )

{
        my $prompt = "Enter a temp subdirectory that autodnld can use. This is where autodnld places temporary files (and then erases them later on). This subdirectory should be located on a local hard disk if possible.
Make sure autodnld has read/write access and be able to create the temp directory after entering this.";

        PromptAndEditUsingHashKey
            (
             $prompt,
             'temp_download_subdir', # key into hash
             default_val_if_no_existing => "$hIniFile{'autodnld_home'}$slash" . "temp",
             no_space_in_val_flag => 1,
             );
       if (!-d $hIniFile{'temp_download_subdir'}) {#needed for https test later
          MkdirAsReq ( $hIniFile{'temp_download_subdir'}, 0 ); # 0 = subdir only
       }
}

# edit parameter: possible purge of older cdu files
#
#Chris request 20140115, cdu_purge_depth no longer a required, but still default =0
#EditCduPurgeDepth();

} # EditHashValues


# ---------------------------- edit_ini_file   <<< ENTRY
# called because -config switch
# careful: if installing via pkzip32se, will be in autodnld, not scripts subdir
sub edit_ini_file
{
# say hello (may be initial installation, may be re-installation)
print "\n==== Configuration program for Intex autodnld ====
Version: $release_version

Do you want to continue y/n? > ";

my $yn = scalar(<STDIN>);

if ($yn !~ /[yY]/)
{
    print "Exit program\n";
    exit(1);
}

# tell about default values
print "
NOTE: when you are asked to enter a value, a default value
is often shown within the angle brackets.

To accept this default value, just press the enter key.
Otherwise, enter your own value and press the enter key.

Press the enter key to start the configuration process > ";
<STDIN>;

# figure out OS
# try to figure it out; if not sure, make guess; may have user verify
# e.g. $hIniFile{'operating_system'} = "nt";
figure_out_os();
print "verbose_config set: operating_system=$hIniFile{'operating_system'}\n" if ( $verbose_config );

# set various globals (normally done by code in autodnld.pl)
if($hIniFile{'operating_system'} eq "unix")
{
   $is_unix = 1;
   $slash = "/";
}
else
{
   $is_unix = 0;
   $slash = "\\";
   $com_spec = $hIniFile{'operating_system'} eq "nt" ? "cmd.exe /c" : "command /c";
}

# figure out $hIniFile{'autodnld_home'}, since we must be in the autodnld or the script subdir
my $subdir = cwd();  # if win32, will have forward slashes
print "*** cwd=$subdir\n" if ( $verbose_config );

if ( $subdir !~ /scripts$/ )
{
    print "*** chdir to $subdir//scripts\n" if ( $verbose_config );
    chdir ( "$subdir//scripts" );
    $subdir = cwd();
}

if ( $subdir !~ /scripts$/ )
{
    print "ERROR: cannot find the autodnld scripts subdir\n";
    return;
}

my $ix = rindex ( $subdir, "/" );
$hIniFile{'autodnld_home'} = substr($subdir,0,$ix);

if ( $is_unix == 0 )
{
    $hIniFile{'autodnld_home'} =~ s/\//\\/g;
    $hIniFile{'autodnld_home'} = lc($hIniFile{'autodnld_home'});
}

print "Autodnld home subdir=$hIniFile{'autodnld_home'}\n";

# figure out the log subdir; make it if necessary
$subdir = "$hIniFile{'autodnld_home'}$slash" . "log";
my $mkdir_retry_cnt = 1;

if ( MkdirAsReq ($subdir,undef,$mkdir_retry_cnt) ne '' )
    {
    print("ERROR: Unable to create log directory: $subdir\n");
    PressAnyKeyPriorExit();
    exit(1);
    }

# figure out the scripts dir; make it if necessary
$subdir = "$hIniFile{'autodnld_home'}$slash" . "scripts";

if ( MkdirAsReq ($subdir,undef,$mkdir_retry_cnt) ne '' )
    {
        print("ERROR: Unable to create scripts directory: $subdir\n");
        PressAnyKeyPriorExit();
        exit(1);
    }

# if we already have an ini file, read it in and clean it up; also, offer to just change the password
if ( -e "$hIniFile{'autodnld_home'}$slash" . "scripts$slash" . 'autodnld.ini' )
{
    $new_ini_file = 0;
    print "\nWe found an existing autodnld.ini file: ($hIniFile{'autodnld_home'}$slash" . "scripts$slash" . "autodnld.ini)\n";
    ReadIniFile( "$hIniFile{'autodnld_home'}$slash" . "scripts$slash" . 'autodnld.ini' );

##    if ( $verbose_config )
##        {
##        print " just read config file\nconfig:\n" . Dumper(\%hIniFile) . "\n";
##        }

    # delete any unexpected keys ... NOTE: we don't check for missing keys at this time
    DeleteUnexpectedIniKeys();

##    if ( $verbose_config )
##        {
##        print " just ran DeleteUnexpectedIniKeys()\nconfig:\n" . Dumper(\%hIniFile) . "\n";
##        }

    print "\nDo you want to re-enter your password only,
and then exit the configuration program y/n? > ";
    my $yn = scalar(<STDIN>);

    if ( lc($yn) =~ /^y/ )
        {
        # empty password not allowed
        my $szPassword;

        while ( 1 )
            {
            print ( "Please enter password for user=$hIniFile{'user'}\n");
            $szPassword = <STDIN>;
            $szPassword =~ s/[\n\r]//g;

            if ( $szPassword eq "" )
                {
                print "Sorry, you must enter a password\n";
                }
            else
                {
                last;
                }
            }

        $hIniFile{https}=1;
        encrypt_password ( $szPassword );  # passed in plain text, update $hIniFile{'password'}
        WriteIniFile();
        print "Normal end of configuration program\n";
        PressAnyKeyPriorExit();
        exit(0);
        }
}
else
{
    $hIniFile{https}=1;
    $new_ini_file = 1;
    print "*** new ini file\n" if ($verbose_config);
}

# ask for all kinds of info
EditHashValues();

# save the parameter file (save hash data etc), we write prior to test in case test failure.
WriteIniFile();

# make dbstatus exe if unix etc
if ( $is_unix )
    {
    my($szCmd) = "chmod a+x $hIniFile{'autodnld_home'}$slash" . "scripts$slash" . "dbstatus";
    system ( $szCmd );

    # all done with ini
    print "

    Intex Auto Download has been successfully configured.

    NOTE: Your settings are kept in the following file:
    $hIniFile{'autodnld_home'}$slash" . "scripts$slash" . "autodnld.ini";

    print "\nDo you want to test access to the Intex shipment server?\n";
    print "Please enter y/n and press enter, y will start test, n will exit the program > ";
    my $szYesNo = <STDIN>;
    system("perl autodnld.pl -t") if ( $szYesNo =~ /^y/i );
    exit(0);
    }


print "-------------------------------\n";
print "If you connect to Internet through a proxy server, you can configure it here. \nIf you are not sure, please check with your network engineer.\n";
print "Do you want to add or reconfigure a https proxy server setting?\n(y/n,then press enter. Select n if you don't use proxy.)\n";
my $szYesNo=<STDIN>;
if ($szYesNo=~/^y/)
   {
   my $bWinInet = 0;
   if ( $hIniFile{operating_system} eq 'nt' )
       {
       print "-------------------------------\n";
       print "Since you are using Windows, Autodnld has the ability to connect using the Windows built-in proxy later used by your browser (called WinInet).  Would you like Autodnld to try using that connection?\n(y/n,then press enter. Select n if you want to configure your own Proxy settings.)\n";
       my $szYesNo=<STDIN>;
       if ($szYesNo=~/^y/)
           {
           $hIniFile{win_https_wininet} = 1;
           $bWinInet = 1;
           }
       }
   if ( ! $bWinInet )
       {
       my ($sPort,$sServerIPPort,$sProxyUserName,$sProxyPwd);
       my $sFormerVal=$ENV{HTTPS_PROXY} if (defined $ENV{HTTPS_PROXY});
       print "Please enter your proxy,in hostname:port format(e.g., 192.168.0.30:80), then press enter(<$sFormerVal>):";
       while (!defined $sPort) {
          $sServerIPPort=<stdin>;
          chomp($sServerIPPort);
          $sServerIPPort=$sFormerVal if ($sServerIPPort eq ''); # taking default value
          my @aTokens=split(/:/,$sServerIPPort);
          if (scalar(@aTokens)==2){
             $sPort=$aTokens[1] ;
          }
          else {
             print "Incorrect format. Please enter your proxy,in hostname:port format, then press enter:";
          }
       }
       $ENV{HTTPS_PROXY} = $sServerIPPort; #prepare it for test
       #not give previous value since return key is ambiguous here
       #$sFormerVal=$ENV{HTTPS_PROXY_USERNAME} if (defined $ENV{HTTPS_PROXY_USERNAME});
       print "Please enter your proxy username and press enter:";
       $sProxyUserName=<STDIN>;
       chomp($sProxyUserName);
       $ENV{HTTPS_PROXY_USERNAME} = $sProxyUserName; #prepare it for test
       print "Please enter your proxy password and press enter:";
       $sProxyPwd=<stdin>;
       chomp($sProxyPwd);
       $ENV{HTTPS_PROXY_PASSWORD} = $sProxyPwd; #prepare it for test
       $sProxyPwd=password_encoding($sProxyPwd);
       $hIniFile{http_session_header}="HTTPS_PROXY=${sServerIPPort}|HTTPS_PROXY_USERNAME=${sProxyUserName}|HTTPS_PROXY_PASSWORD=ENCODE\"${sProxyPwd}\"";

       my $fn = "$hIniFile{'autodnld_home'}$slash" . "scripts$slash" . 'autodnld.ini';
       print "Adding http_session_header to $fn ...\n";
       }
   WriteIniFile();

   }

print "

Intex Auto Download has been successfully configured.

NOTE: Your settings are kept in the following file:
$hIniFile{'autodnld_home'}$slash" . "scripts$slash" . "autodnld.ini";

print "\nDo you want to test access to the Intex server?\n";
print "Please enter y/n and press enter, y will start test, n will exit the program > ";
my $szYesNo = <STDIN>;
exit(0) if ( $szYesNo =~ /^n/i );
my $sTestResult=OneHttpTest();
if ($sTestResult==0) {
   print "\nIntex server access test success. Exit";
   PressAnyKeyPriorExit();
   exit(0);
}
else {
   print "\nIntex server access test failed. Please check your firewall configuration to enable connections to *.intex.com:443";
   PressAnyKeyPriorExit();
   exit(1);
}

PressAnyKeyPriorExit();
exit(0);

} # edit_ini_file
##----------------------PressAnyKeyPriorExit-----------------
# config program could end abruptly without the user reading last message, create a promt so user can digest the message
sub PressAnyKeyPriorExit {

   print "\nPress any key to end configration >";
   <STDIN>;
}
1;
