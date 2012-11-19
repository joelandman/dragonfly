package DragonFlyJob::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use YAML;
use POSIX qw(getcwd);
use File::Spec;
#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

#
=head1 NAME

DragonFlyJob::Controller::Root - Root Controller for DragonFlyJob

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body( "DragonFly Job Manager" );
}

sub ping : Path('/ping') {
    my ( $self, $c ) = @_;
    use POSIX qw(strftime);
    $c->response->body( 
     sprintf(
      '<alive client="%s" date="%s"/>',
      $c->req->hostname, (strftime "%c",gmtime)
            )
	              );
}
=head2 end

Attempt to render a view, if needed.

=cut 

sub index : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template}="/index.html";

}


sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
