#!/usr/bin/perl

use strict;
use DBIx::SimplePerl;
use XML::Smart;
use Data::Dumper;

my ($appsdb,$xml,$appsdsn,$retc);

$appsdsn = "dbi:SQLite:dbname=apps.db";
$appsdb = DBIx::SimplePerl->new;
$appsdb	-> {debug} = 1;
$appsdb->db_open( 'dsn' => $appsdsn, 'dbuser' => "", 'dbpass' => "");
$retc = $appsdb->db_search
                        ('table'  => 'apps',
                          search =>
                            {
                                'appname' => 'ptb',
                                'version' => "1"
                            }
                        );
my $x    = $appsdb->db_next;
printf "Dump: %s\n",Dumper($x);

$xml	= XML::Smart->new($x->{app_xml});

foreach my $param (@{$xml->{program}{exec}{param}})
 {
   printf "param: %s\n",$param->{label}->content;
   printf "param: %s\n",$param->{name}->content;
   printf "param: %s\n",$param->{required}->content;
   printf "param: %s\n",$param->{default_value}->content;
 }
