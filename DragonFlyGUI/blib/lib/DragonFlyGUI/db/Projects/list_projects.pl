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

printf "Entries in the project table\n" ;
$rc = $sice->db_search( table => "projects");
if (defined($rc->{success}))
   {
      $q=($sice->{_sth}->fetchall_hashref('id'));
      foreach (sort keys %{$q})
       {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\n", $_,
                               $q->{$_}->{project_name},
                               $q->{$_}->{project_id},
                               $q->{$_}->{project_start},
                               $q->{$_}->{project_status},
                               $q->{$_}->{project_uri},
                               $q->{$_}->{project_description},
                               $q->{$_}->{project_documentation},
                               $q->{$_}->{active},
                               $q->{$_}->{locked};
       }
   }
  else
   {
      printf "WARNING: the search did not succeed.\n
              DB returned the following error:\n\n%s\n\n",
              $rc->{failed};
   }
$sice->db_close;
