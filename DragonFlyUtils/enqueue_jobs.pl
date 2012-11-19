#!/opt/dragonfly/bin/perl

use Getopt::Long;
use POSIX 	qw(strftime getcwd);
use IPC::Cmd   qw[can_run run];
use Data::Dumper;
use XML::Smart;
use IO::File;
use File::Temp;
use File::Spec;
use DBIx::SimplePerl; 
use YAML;
use Sudo;
use LWP::UserAgent;
use File::HomeDir;
use Config::IniFiles;
 

use constant true 	=> (1==1);
use constant false	=> (1==0); 
use constant INFINITY   => 256*256*256*128-1;

my $rc;

my ($cmd,$debug,$job);
my ($dryrun,$jobid);
my ($dbuser,$dsn,$dbpass,$jobdb,$jobdb_updated);

my ($userid,$login,@user);

my ($date,$time,$xml,$xml_job,$program,$var);
my ($os,$script_fh,$tmp_script,$path);
my ($in,$out,$err,@all,$str);
my ($usempi, $mpibin, $mpirun, $scriptdebug, $mpiargs);
my ($which_mpi,$mpi_startup,$mpi_shutdown);
my ($mpi_startup_args,$mpi_shutdown_args,$tmp);
my ($executable,$pre,$param_name,$param,$param_value);
my ($jobxml,$prog,$version,$config,$cfg,$server);
my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf);
my ($response,$query_jobs,$ping,@conf_files,$jxml,$update,$interval);

my ($qsub, $buildjob, $command, $arguments,$jobserver);

my $ua = LWP::UserAgent->new;
$ua->agent("NQJobs/0.2 ");

my $home    = File::HomeDir->my_home;

# initial and default values
$debug		= false;
$dryrun		= false;
$interval	= 0;

$rc	= GetOptions(
			"db=s"		=> \$job,
			"debug"		=> \$debug,		
			"dryrun"	=> \$dryrun,
                        "config=s"      => \$config,
			
		    );

$debug	= true if ($dryrun);

@conf_files = (
                File::Spec->catfile(getcwd,".nq.ini"),
                File::Spec->catfile(getcwd,"nq.ini"),
                File::Spec->catfile($home,".nq.ini"),
                File::Spec->catfile($home,"nq.ini"),
                File::Spec->catfile("opt","dragonfly","etc","nq.ini"),
                File::Spec->catfile("Programs","dragonfly","etc","nq.ini") );


if (($config) && !(-e $config))
 {
    die "FATAL ERROR: config file (".$config.") not found\n"
 }

# first get config file so we know which machine to talk to
if (!$config)
 {
    foreach my $cfile( @conf_files )
     {
      printf 'D[%s] checking for config file = "%s" ... ',$$,$cfile if ($debug);
      $config = $cfile if ((!$config) && (-e $cfile));
      printf " %s ", ($config eq $cfile) ? "found\n" : "not found\n" if ($debug);
      last if ($config);
     }
 }

printf STDERR "D[%s] config file = %s\n", $$, $config if ($debug);
$cfg            = new Config::IniFiles( -file => $config );
$server     = $cfg->val("DragonFlyJob","server");
$server     =~ s/\/$//; # remove a "/" at end of URL if any.
$jobserver	= $server;
$qsub       = $cfg->val("scripts","qsub");
$buildjob   = $cfg->val("scripts","buildjob");
$command    = $cfg->val("enqueue","command");
$arguments  = $cfg->val("enqueue","arguments");


# second, ping the job server to make sure it is alive ... give it 10
# seconds to respond
$ua->timeout(10);
$ua->env_proxy;
$ping   = sprintf("%s/ping",$server);

$response = $ua->get($ping);
if ($response->is_success) {
     printf STDERR "D[%s] ping to DragonFly Job Server worked: %s\n",
        $$,
        $response->content
        if ($debug); 
 }
 else {
     die "FATAL ERROR: Unable to contact DragonFly Job Server at ".$server.
         "\nError message is ".$response->status_line;
 }

# third, query the job server to get all the jobs ... give it 15
# seconds to respond
$ua->timeout(15);
$ua->env_proxy;
$query_jobs   = sprintf("%s/xml",$server);

$response = $ua->get($query_jobs);
if ($response->is_success) {
     printf STDERR "D[%s] query jobs from DragonFly Job Server worked: \n",
        $$,       
        if ($debug); 
 }
 else {
     die "FATAL ERROR: Unable to contact DragonFly Job Server at ".$server.
         "\nError message is ".$response->status_line;
 }

printf STDERR "D[%s] parsing job xml: \n",$$;

$jxml    = XML::Smart->new($response->content);

printf STDERR "D[%s] xml object created: \n",$$;

# enqueing loop
# this is how we submit a batch job that will pull the jobxml from
# the database, and start executing
printf STDERR "D[%s] starting enqueuing loop: \n",$$;
		
foreach $job (@{$jxml->{jobs}{job}})
 {
   printf STDERR "D[%s] jobid=%s: \n",$$,$jobid	= $job->{'id'}->content;;
   next if ($job->{'status'}->content ne "Submit"); 
   # skip jobs that are not in the Submit state 
  $jobid	= $job->{'id'}->content;
  $userid	= $job->{'job_owner_uid'}->content;
  $NCPU		= $job->{'ncpu'}->content;
  
  ### get the mapping between userid (uid) and login name
  ### which for the moment is done via a unix getpwuid call.
   printf STDERR "D[%s] getting user data: \n",$$;
  @user		= getpwuid($userid) | getpwuid($<);
  if (!@user)	# skip processing if the user is not known
   {
    printf STDERR "D[%i]: no valid user id [currently = \'%s\'] for jobid  = '%s'\n",
    		$$,$userid,$jobid if ($debug);
    #next;
   }
  $login	= $user[0];
  printf STDERR "D[%i]: user id  = \'%s\' has login name = \'%s\',  for jobid  = '%s'\n",
    		$$,$userid,$login,$jobid if ($debug);
		
  next if ($login eq "root");  # root can't run jobs, so don't even try.
  
  $jobxml  = $job->('<xml>');
  undef $xml;
  $xml  = XML::Smart->new($jobxml);
  # hardwired for Linux as well for the moment ...  
  # just until we have time to fix it.
 
  $prog	= $xml->{'job'}{'jobxml'}{'job'}{'program'}{'name'}->content;
  if ($prog =~ /\[v(\S+)\]/)
   {
     $version = $1;
     $prog =~ s/\[v\S+\]//g;
   }
   
  #$enqueue	= sprintf "/usr/bin/sudo -u %s /home/dragonfly/bin/qsub.bash -cwd -j y  ./build_job.pl --job=http://dragonfly:3000/jobs/xml/%s --program=http://dragonfly:3000/apps/xml/appname=%s  --exec ",$login,$jobid,$prog;
  $enqueue	= sprintf $command,eval $arguments;
 
  
  printf STDERR "D[%i]: command line to run\n\n\t%s\n\n",$$,$enqueue if ($debug);
  ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) = run( command => $enqueue, verbose => 2 ) if (!$dryrun);
  #$rc	= `$enqueue`;
  if ($success)
   {
    printf STDERR "D[%i]: submission succeeded:\n%s\n",$$,join("",@$full_buf);
   }
   else
   {
    printf STDERR "D[%i]: submission failed:\n%s\n",$$,join("",@$full_buf);   
   }
  
  printf STDERR "D[%i]: rc = \'%s\'\n",$$,$rc if ($debug);
  # update the jobdb to indicate that it has started
  &update_job_record('queued',"now()",$jobid,$server);
  &update_job_record('submitted',"now()",$jobid,$server);
 }  	    		   


###  each _generate_* returns a string
sub _generate_script_header
 {
   my $os	= shift;
   my $debug	= shift;
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
 
sub ping_jobserver {
 my ($jobserver) = @_;
 my $ping   = sprintf("%s/ping",$jobserver);
 my $response;
 my $ret	= false;
 
 printf  STDERR "D[%s] ping = '%s'\n",$$,$ping;
 
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
