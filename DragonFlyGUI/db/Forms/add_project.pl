#!/usr/bin/perl

use CGI::FormBuilder;
use strict;
use warnings;

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

    print $form->confirm(header => 1);
} else {
    print $form->render(header => 1);
}
