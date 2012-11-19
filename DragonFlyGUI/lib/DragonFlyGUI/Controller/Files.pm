package DragonFlyGUI::Controller::Files;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyGUI::Controller::Files - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Local {
    my ( $self, $c ) = @_;
    my ( $projects);
    my $projectdb	= DBIx::SimplePerl->new;
    $c->log->debug('Files/index projectdb dsn'.$c->config->{projectdb}->{dsn});
    $projectdb->db_open(
		    'dsn'	=> $c->config->{projectdb}->{dsn},
		    'dbuser'	=> $c->config->{projectdb}->{dbuser},
		    'dbpass'	=> $c->config->{projectdb}->{dbpass}		
                   );
    $projectdb->db_search( 'table'	=> 'projects' );
    while (my $x = $projectdb->db_next)
     {
       $projects->{$x->{id}} = $x;
     }
    $c->stash->{projects} = $projects;
    $c->stash->{template} = "/files/project.html";
    
}




=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
