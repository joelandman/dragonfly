package DragonFlyJob::Controller::Log;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyJob::Controller::Log - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyJob::Controller::Log in Log.');
}

sub update_stdout : Path('/stdout') {
    my ( $self, $c, $id ) = @_;


}

sub update_stderr : Path('/stderr') {
    my ( $self, $c, $id ) = @_;


}


=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
