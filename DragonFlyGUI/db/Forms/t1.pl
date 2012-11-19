#!/usr/bin/perl
#
use strict;
use warnings;
use DBIx::SimplePerl;

    my $dsn = "dbi:SQLite:dbname=/home/dragonfly/DragonFlyGUI/db/users.db";
    my $sice = DBIx::SimplePerl->new;
    
    $sice->db_open(
                   'dsn' => $dsn,
                   'dbuser' => "",
                   'dbpass' => ""
                  );
    
    $sice->db_add(
              table => "projects",
              columns => {
                          id => 4,
                          project_name => 'New project',
                          project_id => 'pnew',
                          project_start => 'today',
                          project_status => 'Completed',
                          project_uri => 'http://www.test.com/docs',
                          project_description => 'This is Project Four',
                          project_documentation => 'No docs available',
                          active => 'yes',
                          locked => 'No'
                         }
              );

    $sice->db_close;
