package DragonFlyGUI::Controller::Users;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyGUI::Controller::Users - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Users in Users.');
}

sub list : Local {
 my ( $self, $c ) = @_;
    $c->stash->{template}="/users/list.html";

#    $c->response->body('Matched DragonFlyGUI::Controller::list in Users.');

}

=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
