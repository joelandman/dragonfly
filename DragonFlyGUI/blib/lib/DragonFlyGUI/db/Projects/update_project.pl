#!/usr/bin/perl

use strict;
use DBIx::SimplePerl;

my ($rc,$q);

my $dsn = "dbi:SQLite:dbname=/home/dragonfly/DragonFlyGUI/db/users.db";
my $sice = DBIx::SimplePerl->new;

$sice->db_open(
               'dsn' => $dsn,
               'dbuser' => "",
               'dbpass' => ""
              );

$rc = $sice->db_update( table => "projects",
                     search => { project_id => 'p9abc' },
                     columns => { project_status => 'delayed' }
);

if (defined($rc->{failed}))
   {
      printf "WARNING: the update did not succeed.\n
              DB returned the following error:\n\n%s\n\n",
              $rc->{failed};
   }
$sice->db_close;
