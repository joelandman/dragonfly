#!/usr/bin/perl
#

use Getopt::Long;
use IPC::Cmd  qw[can_run run];
use strict;

my ($delay, $command, $fh);
my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf );

my $rc     = GetOptions(
                        "delay=s"	=> \$delay,
			"command=s"	=> \$command         
			);
#exit if ($delay);

while(1)
 {
  ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
	run( command	=> $command, verbose =>0 );
   print join "", @$full_buf;
  sleep($delay);
 }
