#!/usr/bin/perl

use Getopt::Long;
use POSIX 	qw(strftime getcwd);
use IPC::Cmd  ;
use Data::Dumper;
use XML::Smart;
use IO::File;
use File::Temp;
use File::Spec;
use DBIx::SimplePerl;

use constant true 	=> (1==1);
use constant false	=> (1==0);
use constant INFINITY   => 256*256*256*128-1;

my $rc;

my ($cmd,$debug,$job);
my ($dryrun,$jobid);
my ($dbuser,$dsn,$dbpass,$jobdb,$jobdb_updated,$job);

$jobdb 		= DBIx::SimplePerl->new;
$jobdb_updated	= DBIx::SimplePerl->new;

# initial and default values
$debug		= false;
$dsn		= 'dbi:SQLite:dbname=/home/dragonfly/DragonFlyGUI/db/dfgui.db';
$dryrun		= false;

$rc	= GetOptions(
			"db=s"		=> \$job,
			"debug"		=> \$debug,		
			"dryrun"	=> \$dryrun
		    );

$debug	= true if ($dryrun);

### look at DB for all the entries that are "submitted==1"
### and assign them to a cluster
printf STDERR "D[%i]: dsn\t\t = '%s'\n",$$,$dsn if ($debug);

$jobdb->db_open(
		'dsn'	=> $dsn,
		'dbuser'=> "",
		'dbpass'=> "",
		
		);
		
$jobdb_updated->db_open(
		'dsn'	=> $dsn,
		'dbuser'=> "",
		'dbpass'=> "",
		AutoCommit => 0
		);
		
$jobdb->{debug}		= 1 if ($debug);
$jobdb_updated->{debug}	= 1 if ($debug);

$jobdb->db_search(
		  'table'	=> 'jobs',
		  'search'	=> {
		  		    'submitted' => '0'
		  		   }
		 );
		 
# assignment loop
# This is where the business logic will go!
# right now, it simply assigns the job to the local cluster 		
while ($job=$jobdb->db_next )
 {
  #map { printf "key = %s, value ='%s'\n",$_,$job->{$_} } keys %{$job};
  $jobid	= $job->{'id'};
  $jobdb_updated->db_update(
	    		    'table'	=> 'jobs',
		  	    'search'	=> {
		  		    	    'id' => $jobid
					   },
			    'columns'	=> {
				      	    'assigned_to_cluster' => 'localhost'
				      	   }
			   );	   
 }
	    		   

$jobdb->db_close;
$jobdb_updated->db_commit;
$jobdb_updated->db_close;
