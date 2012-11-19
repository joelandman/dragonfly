#!/usr/bin/perl

use strict;
use DBIx::SimplePerl;

my $dsn = "dbi:SQLite:dbname=/home/dragonfly/DragonFlyGUI/db/users.db";
my ($rc,$q);

my $sice = DBIx::SimplePerl->new;

$sice->db_open(
               'dsn' => $dsn,
               'dbuser' => "",
               'dbpass' => ""
              );

$rc = $sice->db_add( table => "projects",
                     columns => {
                                 id => 3,
                                 project_name => 'Project 3',
                                 project_id => 'p9abc',
                                 project_start => 'Sept 14, 2007',
                                 project_status => 'pending',
                                 project_uri => 'http://www.test.com/proj3',
                                 project_description => 'A description of project 3',
                                 project_documentation => 'Any supporting docs for this project',
                                 active => 3,
                                 locked => 4
                                }
);

if (defined($rc->{failed}))
   {
      printf "WARNING: the add did not succeed.\n
              DB returned the following error:\n\n%s\n\n",
              $rc->{failed};
   }
$sice->db_close;
