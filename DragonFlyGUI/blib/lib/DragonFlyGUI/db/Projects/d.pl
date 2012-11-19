#!/usr/bin/perl

use strict;
use DBIx::SimplePerl;

my ($rc,$q, $x);

my $dsn = "dbi:SQLite:dbname=/home/dragonfly/DragonFlyGUI/db/users.db";
my $sice = DBIx::SimplePerl->new;
$x = shift;

$sice->db_open(
               'dsn' => $dsn,
               'dbuser' => "",
               'dbpass' => ""
              );

$sice->{debug}=1;
$rc = $sice->db_delete( table => "projects",
                     search => { project_id => $x }
);

if (defined($rc->{success}))
   { }
else   
   {
      printf "WARNING: the delete did not succeed.\n
              DB returned the following error:\n\n%s\n\n",
              $rc->{failed};
   }
$sice->db_close;
