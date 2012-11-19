package DragonFlyJob::Controller::Add;

use strict;
use warnings;
use base 'Catalyst::Controller';

my ($dsn,$dbuser,$dbpass);


sub _opendb : Path('db' ) {
  my ($self, $c) = @_;
  
  my $jobdb	= DBIx::SimplePerl->new;

  $jobdb->{debug}	= 1;
  $c->log->debug('echo: '.$c->config->{jobdb}->{dsn});
  $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
	       );

}

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body('DragonFlyJob::Controller::Add is on Catalyst!');
}

=head1 NAME

DragonFlyJob::Controller::Add - Catalyst Controller

=head1 SYNOPSIS

See L<DragonFlyJob>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=over 4

#
# Uncomment and modify this or add new actions to fit your needs
#
#=item default
#
#=cut
#


=back


=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
