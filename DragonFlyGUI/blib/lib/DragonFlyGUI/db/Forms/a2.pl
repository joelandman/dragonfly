#!/usr/bin/perl

use strict;
use warnings;
use CGI::FormBuilder;
use DBIx::SimplePerl;

my @fields;

my $form = CGI::FormBuilder->new(
             method => 'post',
             reset  => 1,
             fields => \@fields,
        );

$form->field(name => 'pid', label => 'Project ID');
$form->field(name => 'pname', label => 'Project Name');
$form->field(name => 'descrip', label => 'Project Description',
             size => 80, maxsize => 256);
$form->field(name => 'pstatus', label => 'Project Status');
$form->field(name => 'pstart', label => 'Project Start');
$form->field(name => 'pdocs', label => 'Project Documentation');
$form->field(name => 'uri', label => 'Data Repository');
$form->field(name => 'pactive', label => 'Active');
$form->field(name => 'plocked', label => 'Locked');

if ($form->submitted && $form->validate) {
    my $field = $form->fields;
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
                          project_name => $field->{pname},
                          project_id => $field->{pid},
                          project_start => $field->{pstart},
                          project_status => $field->{pstatus},
                          project_uri => $field->{uri},
                          project_description => $field->{descrip},
                          project_documentation => $field->{pdocs},
                          active => $field->{pactive},
                          locked => $field->{plocked}
                         }
              );

    $sice->db_close;

    print $form->confirm(header => 1);
} else {
    print $form->render(header => 1);
}
