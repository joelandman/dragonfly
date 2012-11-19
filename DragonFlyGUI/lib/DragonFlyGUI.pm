package DragonFlyGUI;

use strict;
use warnings;
use YAML;
use Catalyst::Runtime '5.70';
use POSIX qw(getcwd);

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/
		-Debug 
		ConfigLoader 
		Config::YAML
		Static::Simple
		StackTrace
		Redirect
		Authentication      
	     
		Authorization::Roles
            
		Session
		Session::Store::File
	    Session::State::Cookie
	   /;
	   # Authentication::Store::Htpasswd
our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in DragonFlyGUI.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'DragonFlyGUI' );
__PACKAGE__->config->{static}->{dirs} 
        = [ 'static' ,'js', 'style', 'css', qr/^(images|css)/ ];

#__PACKAGE__->config( 'Plugin::ConfigLoader' );
__PACKAGE__->config( name => 'Controller::FormBuilder' =>
                    {
                     new => { method => 'post', stylesheet =>1 , debug => 0 },
                     debug => 0
                    }
                   );

		  		   
# application setup
#__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'jobdb.yml') ) );
#__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'projectdb.yml') ) );
#__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'appdb.yml') ) );		   
#__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'userdb.yml') ) );	

__PACKAGE__->config(
               authentication => {
		   default_realm => 'scalable',
		    realms => {
			scalable => {
			    credential => {
					    class => 'Password',
					    password_field => 'password',
					    password_type  => 'self_check',
					  },
			    store => {
				       class => 'Htpasswd',
				       file => 'storm_passwd',
				     },
			},
		    },
	       },
		    );
#__PACKAGE__->config->{authentication}{htpasswd} = "storm_passwd";		    
	   
#__PACKAGE__->config( YAML::LoadFile(File::Spec->catfile(getcwd ,'feedbackdb.yml') ) );		   
		   
# Start the application
__PACKAGE__->setup;


=head1 NAME

DragonFlyGUI - Catalyst based application

=head1 SYNOPSIS

    script/dragonflygui_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<DragonFlyGUI::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Joe Landman,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
