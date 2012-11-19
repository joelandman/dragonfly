package DragonFlyJob;

use strict;
use warnings;
use DBIx::SimplePerl;
use YAML;
use POSIX qw(getcwd);

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the applications root directory
#
use Catalyst qw/
		-Debug 
		Static::Simple
		ConfigLoader
                StackTrace

	      /;

our $VERSION = '0.01';

#
# Configure the application
#
__PACKAGE__->config( name => 'DragonFlyJob' );

  # application setup
__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'jobdb.yml') ) );
__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'appdb.yml') ) );



#
# Start the application
#
__PACKAGE__->setup;

=head1 NAME

DragonFlyJob - Catalyst based application

=head1 SYNOPSIS

    script/dragonflyjob_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=over 4

=item default

=cut

#
# Output a friendly welcome message
#
#sub default : Private {
#    my ( $self, $c ) = @_;
#
#    # Hello World
#    $c->response->body( $c->welcome_message );
#}



#
# Uncomment and modify this end action after adding a View component
#
#=item end
#
#=cut
#
#sub end : Private {
#    my ( $self, $c ) = @_;
#
#    # Forward to View unless response body is already defined
#    $c->forward('View::') unless $c->response->body;
#}

=back

=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
