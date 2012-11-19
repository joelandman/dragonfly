package DragonFlyGUI::Controller::Help;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyGUI::Controller::Help - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    
    $c->response->body('Matched DragonFlyGUI::Controller::Help in Help.');
}

sub feedback : Local {
    my ( $self, $c ) = @_;
    
    $c->response->body('Matched DragonFlyGUI::Controller::Help::Feedback in Help.');
}


sub howto : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Help::HowTo in Help.');
}

sub rfe : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Help::RFE in Help.');
}

sub contactme : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Help::ContactMe in Help.');
}

sub bug : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Help::Bug in Help.');
}

sub search : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Help::Search in Help.');
}


=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
