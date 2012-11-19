package DragonFlyGUI::Controller::DragonFlyGUI::Configuration;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

DragonFlyGUI::Controller::DragonFlyGUI::Configuration - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::DragonFlyGUI::Configuration in DragonFlyGUI::Configuration.');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
