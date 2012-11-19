#!/opt/dragonfly/bin/perl


#$ -S /opt/dragonfly/bin/perl

use Getopt::Long;
use POSIX 	qw(strftime getcwd fflush);
use IPC::Run qw( start finish timeout ) ;
use Data::Dumper;
use XML::Smart;
use IO::File;
use URI;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use IPC::Run qw( start ) ;
use IPC::Cmd qw( run );

use LWP::UserAgent;
use HTTP::Request::Common;
use Sys::Hostname;
use File::Iterator;

use constant true 	=> (1==1);
use constant false	=> (1==0);
use constant INFINITY   => 256*256*256*128-1;

# we need to catch signals, pass them along to all the children
$SIG{CHLD} = \&REAPER;
$SIG{ALRM} = sub { die "Operation timed out\n" } ;

my $rc;
my $termination_error;
my ($date,$time,$xml,$xml_job,$program,$var);
my ($cmd,$debug,$job,$os,$script_fh,$tmp_script,$path);
my ($in,$out,$err,@all,$dryrun,$str);
my ($usempi, $mpibin, $mpirun, $scriptdebug, $mpiargs);
my ($which_mpi,$mpi_startup,$mpi_shutdown,$exec);
my ($mpi_startup_args,$mpi_shutdown_args,$tmp,$mpincpus);
my ($executable,$pre,$param_name,$param,$param_value);
my ($fullpath,@cmd,$run_handle);
my ( $update_jobserver );
my ( $output_name, $output_fh );
my ( $error_name, $error_fh );
my ( $input_name, $input_fh );
my (@input_files,@output_files,$errors,$logserver,$downloads_ok,$jobserver);
my ($jobname,$jobid,$joburi);
my ($dl_command,$full_buffer,$error_code,$stdout_buffer,$stderr_buffer,$success);
my ($notemp,$tempdir,$tdir,$return_uri,$return_path,@file_array,$curl_binary);
my $ua = LWP::UserAgent->new;

my ($lwp_download,$stdout_file,$stderr_file,$stdout_fh,$stderr_fh,$run_harness);

# initial and default values
$batch		= false;
$debug		= false;
$os		= "linux";
$path		= "";
$dryrun		= false;
$scriptdebug	= false;
$pre		= "";
$exec		= false;
$notemp		= false;
$tempdir	= "";
$lwp_download   = "/usr/bin/lwp-download";
$curl_binary	= "/usr/bin/curl";

$ua->agent("Build_job/0.3 ");
$ua->timeout(10);
$ua->env_proxy;

$rc	= GetOptions(
			"job=s"		=> \$job,					
			"program=s"	=> \$program,					
			"debug"		=> \$debug,
			"scriptdebug"	=> \$scriptdebug,
                        "errors=s"      => \$errors,
                        "logs=s"        => \$logserver,
                        "jobserver=s"   => \$jobserver,
                        "jobid=s"       => \$jobid,
                        "jobname=s"     => \$jobname,
			"os=s"		=> \$os,			
			"path=s"	=> \$path,
			"dryrun"	=> \$dryrun,
			"execute"	=> \$exec
		    );

$debug	= true if ($dryrun);

$tdir	= (strftime "%Y%m%d_%H%M%S",localtime);
mkdir File::Spec->catfile(getcwd,$tdir);
$path 	= File::Spec->catfile(getcwd,$tdir) if (!$path);
# now make a small run directory below this one


die "FATAL ERROR: no input job specification using --job=xml_file.xml\n" if (!$job);
die "FATAL ERROR: no input program specification using --program=xml_file.xml\n" if (!$program);

$joburi = URI->new($job);
if (!$jobid)
 {
  my @jobpath = split(/\//,$joburi->path);
  $jobid  = pop @jobpath;
 }
printf STDERR "D[%i]: jobid\t\t = '%s'\n",$$,$jobid if ($debug);
if (!$jobserver)
 {  
  $jobserver  = sprintf "%s://%s/",$joburi->scheme,$joburi->authority;
 }
printf STDERR "D[%i]: jobserver\t\t = '%s'\n",$$,$jobserver if ($debug);

&update_job_record('status',"Running [Building job]",$jobid,$jobserver);

### tell the job server which node, directory, and so forth we are started on
if (&update_job_record('started',"now()",$jobid,$jobserver))
 {
  printf STDERR "D[%i]: jobserver updated in field started with current time\n",$$ if ($debug);
 }

### these are SGE specific ... need PBS and others ...
if (exists($ENV{'JOB_ID'}))
 {
  if (&update_job_record('queue_jobid',"now()",$ENV{'JOB_ID'},$jobserver))
  {
   printf STDERR "D[%i]: jobserver updated in queue_jobid=\'%s\'\n",$$,$ENV{'JOB_ID'} if ($debug);
  }
 }
if (exists($ENV{'JOB_NAME'}))
 {
  if (&update_job_record('queue_jobname',"now()",$ENV{'JOB_NAME'},$jobserver))
  {
   printf STDERR "D[%i]: jobserver updated in queue_jobname=\'%s\'\n",$$,$ENV{'JOB_NAME'} if ($debug);
  } 
 }
if (&update_job_record('running_on_node',hostname,$jobid,$jobserver))
 {
  printf STDERR "D[%i]: jobserver updated with running_on_node='%s'\n",$$,hostname if ($debug);

 }
if (&update_job_record('compute_node_run_directory',getcwd,$jobid,$jobserver))
 {
  printf STDERR "D[%i]: jobserver updated with compute_node_run_directory='%s'\n",$$,getcwd if ($debug);
 }
 
### parse XML to start
printf STDERR "D[%i]: os\t\t = '%s'\n",$$,$os if ($debug);
printf STDERR "D[%i]: directory\t = '%s'\n",$$,$path if ($debug);
printf STDERR "D[%i]: opening temp file in directory ....\n",$$ if ($debug);
$File::Temp::DEBUG = 1 if ($debug);
($script_fh, $temp_script) = File::Temp::tempfile( "batchXXXXXXX", DIR => $path, UNLINK => 0) if (!$dryrun);

printf STDERR "D[%i]: parsing XML from job='%s'\n",$$,$job if ($debug);
$xml_job	= XML::Smart->new($job);
printf STDERR "D[%i]: parsing XML from program='%s'\n",$$,$program if ($debug);
$xml		= XML::Smart->new($program);


printf STDERR "D[%i]: project='%s'\n",$$,$xml_job->{'jobs'}{'job'}{'project'}->content if ($debug);

printf STDERR "D[%i]: data return uri ='%s'\n",$$,$xml_job->{'jobs'}{'job'}{'project_output_directory'}->content if ($debug);

$return_uri	= URI->new($xml_job->{'jobs'}{'job'}{'project_output_directory'}->content);
$return_path	= $return_uri->path;
$return_path	=~ s/^\/data_return/\/upload/g;
$return_uri->path($return_path);
printf STDERR "D[%i]: data upload uri ='%s'\n",$$,$return_uri->as_string if ($debug);


# pull environmental changes from <var* tags ...
#
# process in the following order:
# 	1) copyin (default is to delete environment)
#	2) remove variables
#	3) add variables
#	4) append to variables
#	5) inserts to variables (append to front)
#

#    1) copyin
if (($xml->{'program'}{'env'}{'var_copy'}{'value'}->content) == 0)
 {
   printf "D[%i]: removing default environment \n",$$ if ($debug);
   undef %ENV;
 }
 else
 {
   printf "D[%i]: keeping default environment \n",$$ if ($debug); 
 }

#   2) removes

foreach $var ($xml->{'program'}{'env'}{'var_del'}('[@]'))
 {
  printf "D[%i]: delete environmental variable '%s' [current value = '%s']\n",$$,
  	$var->{'name'}->content,$ENV{$var->{'name'}->content}  if ($debug);
  delete $ENV{$var->{'name'}->content} if ($ENV{$var->{'name'}->content});
 }

#   3) adds

foreach $var ($xml->{'program'}{'env'}{'var_add'}('[@]'))
 {
  printf  STDERR "D[%i]: add environmental variable '%s' [current value = '%s']\n",$$,
  	$var->{'name'}->content,$ENV{$var->{'name'}->content}  if ($debug);
  
  $ENV{$var->{'name'}->content}	= $var->{'value'}->content;
 }

#   4) appends

foreach $var ($xml->{'program'}{'env'}{'var_append'}('[@]'))
 {
  printf  STDERR "D[%i]: append environmental variable '%s' [current value = '%s'] with value = '%s'\n",$$,
  	$var->{'name'}->content,
	$ENV{$var->{'name'}->content},
	$var->{'value'}->content  if ($debug);
  
  $ENV{$var->{'name'}->content}	.= (sprintf "%s%s",
  		($var->{'join'}->content | ":"),
		$var->{'value'}->content);
 }

#   5) inserts

foreach $var ($xml->{'program'}{'env'}{'var_insert'}('[@]'))
 {
  printf  STDERR "D[%i]: insert environmental variable '%s' [current value = '%s'] with value = '%s'\n",$$,
  	$var->{'name'}->content,
	$ENV{$var->{'name'}->content},
	$var->{'value'}->content  if ($debug);
  
        $ENV{$var->{'name'}->content}	= 
		(sprintf "%s%s%s",  		
		$var->{'value'}->content,
		($var->{'join'}->content | ":"),
		$ENV{$var->{'name'}->content});
 }

# now generate this in the batch script
 
  # temp hardwire for SGE, fix later.
$str	= &_generate_script_header($os,$scriptdebug,"sge",$temp_script);
printf $script_fh "%s",$str if (!$dryrun);

$str	= &_generate_script_environment($os,\%ENV);
printf $script_fh "%s",$str if (!$dryrun);

# see how to start the job:  
#
# 	Do we us MPI, and if so, how do we initialize and launch the run?

if ($xml->{'program'}{'exec'}{'run'}{'use_mpi_stack'}->content)
 {
  $usempi	= true;
 
  #exit;
  $which_mpi	= $xml->{'program'}{'exec'}{'run'}{'use_mpi_stack'}->content;
  $mpibin	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'path'}->content;
  $mpirun	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpirun'}{'name'}->content;
  $mpiargs	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpirun'}{'args'}->content;
  $mpincpus	= $xml_job->{'jobs'}{'job'}{'jobxml'}{'job'}{'program'}{'exec'}{'param'}('name','eq','NCPUS'){'value'}->content;
  if ($mpincpus == 0)
   {
    $mpincpus = $xml_job->{'jobs'}{'job'}{'jobxml'}{'job'}{'program'}{'exec'}{'param'}('name','eq','NCPU'){'value'}->content;
   }
  $mpi_startup	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpi_init'}{'name'}->content;
  $mpi_startup_args	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpi_init'}{'args'}->content;
  $mpi_shutdown	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpi_shutdown'}{'name'}->content;
  $mpi_shutdown_args	= $xml->{'program'}{'mpi'}{'stack'}('name','eq',$which_mpi){'mpi_shutdown'}{'args'}->content;
  
  # look at MPIARGS, and make sure any parameters (such as_NAME_) are 
  # replaced with values from the job_entry.xml.  Some like _MACHINEFILE_
  # come from the environment, and not the job_entry.xml.  Do a second pass
  # to handle those.
  $pre		= sprintf ("%s %s ",(File::Spec->catfile($mpibin,$mpirun)),$mpiargs);
  foreach $param_name ($xml_job->{'jobs'}{'job'}{'jobxml'}{'job'}{'program'}{'exec'}{'param'}('[@]'))
   {
    $param	= sprintf("_%s_",$param_name->{'name'}->content);
    $param_value= $param_name->{'value'}->content;
    printf  STDERR "D[%i]: param substitution: Parameter '%s' = '%s'\n",$$,$param,$param_value if ($debug);
    $pre	=~ s/$param/$param_value/g; 
   }
  
  # another hardwire for SGE, will fix asap
  my $machine_file  = '$TMPDIR/machines';
  $pre      =~ s/_MACHINEFILE_/$machine_file/;
  
  printf  STDERR "D[%i]: Using MPI: stack = '%s'\n",$$,$which_mpi if ($debug);
  printf  STDERR "D[%i]:  - MPI mpibin = '%s'\n",$$,$mpibin if ($debug);
  printf  STDERR "D[%i]:  - MPI mpirun = '%s'\n",$$,$mpirun if ($debug);
  printf  STDERR "D[%i]:  - MPI mpiargs= '%s'\n",$$,$mpiargs if ($debug);      
  printf  STDERR "D[%i]:  - MPI runcmd = '%s'\n",$$,$pre if ($debug);
 }
 
$executable	= $xml->{'program'}{'exec'}{'executable'}{'path'}->content;
if (!$executable)
 {
  if (&update_job_record('status',"Failed",$jobid,$jobserver)) 
   {
    printf STDERR "D[%i]: jobserver status updated as job as failed due to lack of an executable in application xml\n",$$ if ($debug);
   }
 }
die "FATAL ERROR: no executable specified in application XML\n"  if (!$executable);
printf "D[%i]: executable = '%s'\n",$$,$executable if ($debug);

if ($usempi)
 {
  $str	= &_generate_script_mpi_initialize($os,$mpibin,$mpi_startup,$mpi_startup_args)  if ($mpi_startup);
  printf $script_fh "%s",$str if (($mpi_startup) && (!$dryrun));   
 }

# assemble the command line
$cmd	= $pre if ($pre);	# start out with any pre-existing stuff (mpi ...)
$cmd	.= $executable . " ";	# add in the executable and a little white space
				# at end, 
foreach $var ($xml_job->{'jobs'}{'job'}{'jobxml'}{'job'}{'program'}{'arg'}('[@]'))
 {
  $tmp	= $var->{'value'}->content;
  if (lc($var->{'input_file'}->content) eq "yes")
   {
    push @input_files,$tmp;   # queue it up for download
    my $input_uri = URI->new($tmp);
    my $uri_path  = $input_uri->path;
    my @full_path =  File::Spec->splitpath( $uri_path );  # remove all but the file name part
    $tmp          = $full_path[2]; 
   }
  
  $cmd	.= sprintf ( "%s %s ",$var->{'name'}->content,$tmp);

 }
printf $script_fh "%s",$cmd if  (!$dryrun); 

if ($usempi)
 {
  $str	= &_generate_script_mpi_shutdown($os,$mpibin,$mpi_shutown,$mpi_shutdown_args)  if ($mpi_shutdown);
  printf $script_fh "%s",$str if (($mpi_shutdown) && (!$dryrun));   
 }
close($script_fh);
chmod 0755,$temp_script;

### update the job server with the current hostname, directory, etc.



$update   = sprintf("%s/update/%s/queued?value=now()",$jobserver,$jobid);

### script is generated, now download the input files
$downloads_ok = true;
chdir $path;

my $wd=getcwd;
&update_job_record('status',"Running [Downloading files]",$jobid,$jobserver);

my @failed_downloads;
foreach my $file (@input_files)
 {
   $file    =~ s#///#//#;
   printf "D[%s] downloading file=\'%s\' ... \n",$$,$file if ($debug); 
   $dl_command  = sprintf "%s %s",$lwp_download,$file;
   my $retc	= &runcmd($dl_command);
   $success	= $retc->{rc} ? $retc->{rc} : false;
   $stdout_buffer	= $retc->{stdout} ? $retc->{stdout} : false;
   #( $success, $error_code, $full_buffer, $stdout_buffer, $stderr_buffer ) =
   #                run( command => $dl_command, verbose => 1 );
   if ( $success)
     {
      printf STDERR "D[%s] download complete\n",$$ if ($debug);
      printf STDERR "D[%s] download output: %s\n",$$,$stdout_buffer if ($debug);
     printf STDERR "D[%s] download output: %s\n",$$,$stderr_buffer if ($debug);
     }
    else
     {
      # update log server with the problem
      $downloads_ok = false;
      printf STDERR "D[%s] download failed\n",$$ if ($debug);
      printf STDERR "D[%s] download output: %s\n",$$,$stdout_buffer if ($debug);
      printf STDERR "D[%s] download error: %s\n",$$,$stderr_buffer if ($debug);
      push @failed_downloads,$file;
      
     }
 }

# only execute it if we have all the input
if ($downloads_ok)
 {
### finally, if we are to execute it, then, execute it.
  if ($exec) 
   {   
     ### create std[out|err] files
     $stdout_file	= sprintf "STDOUT.%s",$jobid;
     $stderr_file	= sprintf "STDERR.%s",$jobid;
     $stdout_fh	= IO::File->new;
     $stderr_fh	= IO::File->new;
     if (!($stdout_fh->open($stdout_file,"w")) )
	{
         # update log server with the problem
         printf STDERR "D[%s] could not create stdout file = %s \n",$$,$stdout_file if ($debug);
         &update_job_record('status',"Failed",$jobid,$jobserver);
	 &update_job_record('job_stderr',"could not create stdout file = ".$stdout_file,$jobid,$jobserver);      
	}
     if (!($stderr_fh->open($stderr_file,"w")) )
	{
         # update log server with the problem
         printf STDERR "D[%s] could not create stderr file = %s \n",$$,$stderr_file if ($debug);
         &update_job_record('status',"Failed",$jobid,$jobserver);
	 &update_job_record('job_stderr',"could not create stderr file = ".$stderr_file,$jobid,$jobserver);      
	}
     
    ### Now create command array
    my @command_array	;
    push @command_array,$temp_script;
    
    ### tell job server about our pid
    &update_job_record('pid_on_compute_node',$$,$jobid,$jobserver);
    &update_job_record('status',"Running",$jobid,$jobserver);
    my $terminated = false;
    
    ### ... and create run run_harness
    eval {
           printf STDERR "D[%s] attaching run harness\n",$$ if ($debug);
           $run_harness		= start 
	   				\@command_array, 
					\undef, 
					$stdout_fh, 
					$stderr_fh,
					'debug'=>3;
           printf STDERR "D[%s] ... attached\n",$$ if ($debug);
         };
    if ( $@ )
       {
         $termination_error = $@;
         printf STDERR "D[%s] execution failed after harness attached: %s\n",$$,$termination_error if ($debug);
         &update_job_record('status',"Failed",$jobid,$jobserver);
         &update_job_record('job_stderr',$stderr_buf,$jobid,$jobserver);
         $terminated    = true;
       }

    # loop if not terminated  AND the run_harness can be pumped AND we pump the
    # run_harness without blocking ... (e.g. as long as we can pump it, we do
    # and don't block waiting for input)
    printf STDERR "D[%s] beginning main loop ... \n",$$ if ($debug);
    while ((!$terminated) && ($run_harness->pumpable) && ($run_harness->pump_nb))
     {
       # see if we have been stopped
       if (&job_stopped($jobid,$jobserver))
          {
            # if so, stop this run            
            $terminated = true;            
            # and exit the loop
            printf STDERR "D[%s] job has been terminated from external sources\n",$$ if ($debug);
            &update_job_record('status',"Stopped",$jobid,$jobserver);
            last;
          }
       
       # otherwise update the job server that we are still alive
       &update_job_record('heartbeat',"now()",$jobid,$jobserver);
       printf STDERR "D[%s] execution in progress\n",$$ if ($debug);
       
       # this may be too short ... might need to sleep for 60 seconds
       # or the job server will be too loaded down to process other requests
       sleep 15;
     }
    printf STDERR "D[%s] ending main loop ... \n",$$ if ($debug);
    
    ### close run run_harness
    &stop_run($run_harness,$jobid,$jobserver); 
     
    # now we have STD[OUT|ERR].jobid files, so we don't need to return the
    # stdout/stderr into the db.  This could potentially be huge output ...
    # so we may need an alternative method of transfer.  Note we *might* have
    # a 2 or 4 GB limit lurking in some of the intervening code.  Usually you
    # find this in 32 bit systems, and code built for them.  This could cause
    # aborted transfers.  We need an alternative method (like scp), but as
    # we cannot guarantee a Linux/Unix machine as the file server, this
    # may be problematic.
    
    # get run_harness return code.  Might not be application return code ...
    my $rc=$run_harness->results;
    
    # ok, there is something very strange going on in the IPC::Run code
    # as it won't let me set success directly, but only with the indirect
    # method ... rc=...; success=rc;
    $success=$rc;
    printf STDERR "D[%s] return code: %s\n",$$,Dumper($success) if ($debug);
    if ($success)
     {
      printf STDERR "D[%s] execution complete\n",$$ if ($debug);     
      &update_job_record("status","Succeeded",$jobid,$jobserver);
     }
    else
     {
      # update log server with the problem
      printf STDERR "D[%s] execution failed\n",$$ if ($debug);
      &update_job_record('status',"Failed",$jobid,$jobserver);
     }
    
    &update_job_record("completed","now()",$jobid,$jobserver);
    &update_job_record('job_return_code',$run_harness->results,$jobid,$jobserver);   
   }
 }
 else
 {
  if ((&update_job_record('status',"Failed",$jobid,$jobserver)))
   {
    printf STDERR "D[%i]: jobserver status updated as job as failed due to one or more input file downloads failing\n",$$ if ($debug);
    &update_job_record('job_stderr',"job as failed due to one or more input file downloads failing.  Failed downloads are :",join(", ",@failed_downloads),$jobid,$jobserver);
    
    # nothing left to do, so exit
    exit ;
   }  
 }


#### return to data repository here
# gather list of files ...
my $dir	= new File::Iterator( DIR => $path, RECURSE => 5);
while (my $file = $dir->next()) { push @file_array,$file;  }

foreach my $file (@file_array)
 {
  printf STDERR "D[%i]: uploading file = '%s' to DragonFly File manager\n",$$,$file if ($debug);
  if (&upload_file($file,$return_uri->as_string))
   {
     printf STDERR "D[%i]: uploading file = '%s' succeeded\n",$$,$file if ($debug);     
   }
   else
   {
     printf STDERR "D[%i]: uploading file = '%s' failed\n",$$,$file if ($debug);     
   } 
 }


exit 0;

###  each _generate_* returns a string
sub _generate_script_header
 {
   my $os	= shift;
   my $debug	= shift;
   my $scheduler= shift;
   my $batchname= shift;
   my $return	= "";
   my $top	= "";
   my $nl	= "";
   my $comment	= "";
   
   if (lc($os)	=~ /linux/)
    {
     if (!$debug) 
      {
       $top	= sprintf('#!/bin/bash'."\n");
      }
      else
      {
       $top	= sprintf('#!/bin/bash -x'."\n");
      }
     $nl	= "\n";
     $comment	= '# ';
     if ($scheduler =~ /sge/) 
      {
       # add in SGE metadata for run
       $top	.=sprintf('# SGE metadata for run'."\n");
       $top	.=sprintf('#$ -S /bin/bash'."\n");
       $top	.=sprintf('#$ -cwd '."\n");
        $top	.=sprintf('#$ -b y '."\n");
      $top	.=sprintf('#$ -o %s.STDOUT '."\n",$batchname);
       $top	.=sprintf('#$ -e %s.STDERR '."\n",$batchname);
      }
    }
   elsif (lc($os)	=~ /windows/)
    {
    
    }
   else
    {
    
    }
   
   $return 	= $top;
   $return 	.=sprintf("%s%s",$comment,$nl);
   $return 	.=sprintf("%s autogenerated script on %s %s",
   		   $comment,
		   (strftime "%F %T GMT %z",localtime),
		   $nl);
   $return 	.=sprintf("%s %s",$comment,$nl);	   
   return $return;
 }
 
 sub _generate_script_environment
 {
   my $os	= shift;
   my $env	= shift;
   my $return	= "";
   my $set	= "";
   
   if (lc($os)	=~ /linux/)
    {
     $nl	= "\n";
     $comment	= '# ';
     $set	= "export %s='%s'";
    }
   elsif (lc($os)	=~ /windows/)
    {
    
    }
   else
    {
    
    }
   
   $return	= sprintf("%s Environment variables %s",
   		   $comment,
		   $nl);
		   
   foreach (keys %{$env})
      {
        $return	.= (sprintf $set,$_,$env->{$_}).$nl;
      }
   return $return;
 }

 sub _generate_script_mpi_initialize
 {
   my $os	= shift;
   my $bindir	= shift;
   my $mpistart	= shift;
   my $mpistartargs	= shift;
   my $return	= "";
   my $set	= "";
   
   if (lc($os)	=~ /linux/)
    {
     $nl	= "\n";
     $comment	= '# ';
     $set	= "export %s='%s'";
    }
   elsif (lc($os)	=~ /windows/)
    {
    
    }
   else
    {
    
    }
   
   $return	= sprintf("%s Starting MPI environment initialization %s",
   			$comment, $nl);
			
   $return	.=  sprintf("%s %s %s",
   			(File::Spec->catfile($mpibin,$mpistart)),
			$mpistartargs,
			$nl);
		      
   return $return;
 }

 sub _generate_script_mpi_shutdown
 {
   my $os	= shift;
   my $bindir	= shift;
   my $mpistop	= shift;
   my $mpistopargs	= shift;
   my $return	= "";
   my $set	= "";
   
   if (lc($os)	=~ /linux/)
    {
     $nl	= "\n";
     $comment	= '# ';
    }
   elsif (lc($os)	=~ /windows/)
    {
    
    }
   else
    {
    
    }
   
   $return	= sprintf("%s Stopping MPI environment [teardown phase] %s",
   			$comment, $nl);
			
   $return	.=  sprintf("%s %s %s",
   			(File::Spec->catfile($mpibin,$mpistop)),
			$mpistopargs,
			$nl);
		      
   return $return;
 }

sub update_job_record {
 my $entry	= shift;
 my $value	= shift;
 my $jobid	= shift;
 my $jobserver  = shift;
# printf "entry = %s\n",$entry;
# printf "value = %s\n",$value;
# printf "jobid = %s\n",$jobid;
# printf "jobserver = %s\n",$jobserver;
 
 my $ping   = sprintf("%s/ping",$jobserver);
 my $response;
 my $ret	= false;
 
 $value = "NULL" if (!$value);
 my $form = {
 		'id' => $jobid,
		'field' => $entry,
		'value' => $value 
 	    };
 
 
 
 if (&ping_jobserver($jobserver))
  {
 #   $update   = sprintf("%s/update/%s/%s/%s",
 #    			$jobserver,
#			$jobid,
#			$entry,
#			$value			
#		       );
    $update   = sprintf("%s/update", $jobserver);
    printf  STDERR "D[%s] uri for update = \'%s\'\n",$$,$update;
    printf  STDERR "D[%s] form for update = \'%s\'\n",$$,Dumper($form);
    $response = $ua->post($update, $form);
    if ($response->is_success) 
     {
      printf  STDERR "D[%s] update to DragonFly Job Server worked (field=\'%s\', value=\'%s\'):\n %s\n",
           $$,
	   $entry,
	   $value,
           $response->content,
           if ($debug); 
      $ret = true;
     } 
     else 
     {
      printf  STDERR "D[%s] update to DragonFly Job Server failed (field=\'%s\', value=\'%s\'):\n %s\n",
           $$,
           $entry,
	   $value,
	   $response->content
           if ($debug);  

     }	       
  }
 return $ret;
}

sub upload_file {
 my $filename	= shift;
 my $uploaduri	= shift;

 my $response;
 my $ret	= false;
 my $uri	= URI->new($uploaduri);
 my @uripath	= split(/\//,$uri->path);
 shift(@uripath);
 shift(@uripath);
 my $newpath	= join("/",@uripath);
 my $serveruri	= sprintf "%s://%s/upload",$uri->scheme,$uri->authority;
 my $retc;
 my $cmd	= sprintf '%s -F upload=@%s -F form_submit=yes -F destination_path=%s %s',
 			  $curl_binary,$filename,$newpath, $serveruri;
 printf STDERR "D[%s] curl cmd=\'%s\'\n",$$,$cmd;
 my( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf );
                   $rec = &runcmd($cmd);
 printf STDERR "D[%s] curl stdout for file=\'%s\':\n%s\n",$$,$filename,$retc->{stdout};
 printf STDERR "D[%s] curl stderr for file=\'%s\':\n%s\n",$$,$filename,$retc->{stderr};
 $ret	= $retc->{rc} ? $retc->{rc} : false;;
 return $ret; 
}

sub ping_jobserver {
 my ($jobserver) = @_;
 my $ping   = sprintf("%s/ping",$jobserver);
 my $response;
 my $ret	= false;
 
 $response = $ua->get($ping);
 if ($response->is_success) {
     printf  STDERR "D[%s] ping to DragonFly Job Server worked: %s\n",
        $$,
        $response->content
        if ($debug); 
     $ret = true;
 } 
 else {
     printf  STDERR "D[%s] ping to DragonFly Job Server failed: %s\n",
        $$,
        $response->content
        if ($debug);  
  
 }
 return $ret;
}

sub job_stopped {
 my $jobid	    = shift;
 my $jobserver      = shift;
 my $status   = sprintf("%s/status/%s",$jobserver,$jobid);
 my $response;
 my $ret	= false;
 my $stats;
 
 $response = $ua->get($status);
 if ($response->is_success) {
     printf  STDERR "D[%s] status inquiry to DragonFly Job Server worked for id=%s: %s\n",
        $$,$jobid,
        $response->content
        if ($debug);
     # now check to see if the state is "Stopping"
     $stats = $response->content;
     if ($stats =~ /status\s{0,}=\s{0,}\"(\S+)\"/im)
        {
          if (lc($1) eq "stopping")
          {
            $ret = true;
          }
        }
 } 
 else {
     printf  STDERR "D[%s] status inquiry to DragonFly Job Server failed: %s\n",
        $$,
        $response->content
        if ($debug);  
 }
 return $ret;
}



sub REAPER 
    {
      my $child;
      while (($child = waitpid(-1,WNOHANG)) > 0) 
        {
          $Kid_Status{$child} = $?;
        }
      $SIG{CHLD} = \&REAPER;   
    }
    
sub catch_int
    {
      my $signal=shift;
      local $SIG{HUP} = 'IGNORE';
      if ($signal eq "INT")
         {
	   kill HUP => -$$;
	 }
      if ($run_harness) 
         { 
	   # send the signal to the run_harness and its children
	   $run_harness->signal($signal); 
	 }      
      if ($signal eq "INT")  {die "caught signal ".$signal."\n"; }
      if ($signal eq "DIE")  {die "caught signal ".$signal."\n"; }
      if ($signal eq "STOP")  {die "caught signal ".$signal."\n"; }
      kill DIE => -$$;          
    }

sub stop_run
    {
        my $run_harness = shift;
        my $jobid   = shift;
        my $jobserver = shift;
        my $termination_error;
        eval {
              alarm(60);	# 60 seconds to finish
              if ($run_harness->finish)
                {
                 printf STDERR "D[%s] Gentle stop of jobid = %s complete\n",$$,$jobid if ($debug);
                 &update_job_record('job_stderr',"Job gracefully terminated",$jobid,$jobserver);    
                 &update_job_record("status","Stopped",$jobid,$jobserver);                 
                }
	       alarm(0);
             };
            if ( $@ )
             {              
              $termination_error = $@ ;          ## Preserve $@ in case another exception occurs
              $run_harness->kill_kill ; ## kill it gently, then brutally
              &update_job_record('job_stderr',"Job forcibly terminated: initial stop attempt failed: ".Dumper($termination_error),$jobid,$jobserver);    
              &update_job_record("status","Stopped",$jobid,$jobserver);                 
             }
    }


sub runcmd
    {
     my $cmd = shift;

     my @cmd_array	= split /\s+/,$cmd;	
     my ($local_run,$error,$termination_error,$ret,$terminated);
     my ($stdout_buf,$stderr_buf);
     eval {
           printf STDERR "D[%s] attaching run harness\n",$$ if ($debug);
           $local_run		= start 
	   				\@cmd_array, 
					\undef, 
					\$stdout_buf, 
					\$stderr_buf,
					'debug'=>3;
           printf STDERR "D[%s] ... attached\n",$$ if ($debug);
          };
     if ( $@ )
	{
          $termination_error = $@;
          printf STDERR "D[%s] execution failed after harness attached: %s\n",$$,$termination_error if ($debug);
          $terminated    = true;
	  $ret	= { 'error' => $termination_error, 'stdout' => $stdout_buf, 'stderr' => $stderr_buf };
	}
      while ((!$terminated) && ($local_run->pumpable) && ($local_run->pump_nb))
       {
	 printf STDERR "D[%s] cmd stdout: %s\n",$$,$stdout_buf if ($debug);
	 printf STDERR "D[%s] cmd stderr: %s\n",$$,$stderr_buf if ($debug);
	 $ret->{'stdout'} .= $stdout_buf if ($stdout_buf);
	 $ret->{'stderr'} .= $stderr_buf if ($stderr_buf);
	 $stdout_buf = "" if ($stdout_buf);
	 $stderr_buf = "" if ($stderr_buf);	 
	 sleep 1;
       }
      eval {
            alarm(60);	# 60 seconds to finish
            if ($local_run->finish)
              {
               printf STDERR "D[%s] Gentle stop of command = %s complete\n",$$,$cmd if ($debug);                         
              }
	    alarm(0)
           };
      if ( $@ )
       {              
	$termination_error = $@ ;          ## Preserve $@ in case another exception occurs
	$local_run->kill_kill   ;          ## kill it gently, then brutally
	$ret->{termination_error} = $termination_error;
       }
      my $rc=$local_run->results;
      $ret->{rc}	= $rc;
      return $ret;    
    }
