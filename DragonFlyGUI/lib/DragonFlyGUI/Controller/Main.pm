package DragonFlyGUI::Controller::Main;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyGUI::Controller::Main - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    my ($navbar);
    $c->stash->{template}="/index.html";
    #$c->response->body('Matched DragonFlyGUI::Controller::Main in Main.');
}


=head1 AUTHOR

Joe Landman,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
