package DragonFlyGUI::Controller::Root;

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

=head1 NAME

DragonFlyGUI::Controller::Root - Root Controller for DragonFlyGUI

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body("404 - Not Found");
    $c->response->status(404);
}

=head2 index

=cut

sub index : Private {
    my ( $self, $c ) = @_;    
    $c->stash->{template}="/index.html";

}


# Note that 'auto' runs after 'begin' but before your actions and that
    # 'auto' "chain" (all from application path to most specific class are run)
    # See the 'Actions' section of 'Catalyst::Manual::Intro' for more info.
sub auto : Private {
        my ($self, $c) = @_;
    
        # Allow unauthenticated users to reach the login page.  This
        # allows anauthenticated users to reach any action in the Login
        # controller.  To lock it down to a single action, we could use:
        #   if ($c->action eq $c->controller('Login')->action_for('index'))
        # to only allow unauthenticated access to the C<index> action we
        # added above.
        if ($c->controller eq $c->controller('Login')) {
            return 1;
        }

	# let jobs/xml metadata through for the scripting
	# Note:  this could be a security information leak
	# so we will need a way to enforce than only
	# some clients can request this without login ...
	# for the moment, we are leaking XML on how we run
	# the job.
	if ($c->request->path =~ m|jobs/xml|) {
	 return 1;
	}

	# let apps/xml metadata through for the scripting
	# Note:  this could be a security information leak
	# so we will need a way to enforce than only
	# some clients can request this without login ...
	# for the moment, we are leaking XML on how we run
	# the job.
	if ($c->request->path =~ m|apps/xml|) {
	 return 1;
	}        
	
	# let /ping  through for the scripting
	# Note:  this could be a security information leak
	# so we will need a way to enforce than only
	# some clients can request this without login ...
	# for the moment, we are leaking XML on how we run
	# the job.
	if ($c->request->path =~ m|^ping|) {
	 return 1;
	}        
	
	# let js/css through ...
	#if ($c->path =~ /(js|css)$/) {
        #    # Dump a log message to the development server debug output
        #    $c->log->debug('***js/css requested ='.$c->path);
        #    return 1;
        #}
	
        # If a user doesn't exist, force login
        if (!$c->user_exists) {
            # Dump a log message to the development server debug output
            $c->log->debug('***Root::auto User not found, forwarding to /login');
            # Redirect the user to the login page
            $c->response->redirect($c->uri_for('/login'));
            # Return 0 to cancel 'post-auto' processing and prevent use of application
            return 0;
        }
    
        # User found, so return 1 to continue with processing after this 'auto'
        return 1;
    }

=head2 end

Attempt to render a view, if needed.

=cut 
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

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Joe Landman,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
