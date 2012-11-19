package DragonFlyJob::Controller::Query;

use strict;
use warnings;
use base 'Catalyst::Controller';


my ($dsn,$dbuser,$dbpass);


sub xml : Path('/xml' ) {
  my ($self, $c, $id) = @_;
  use XML::Smart;
  
  my $jobdb	= DBIx::SimplePerl->new;
  my ($hash,$x);
  $jobdb->{debug}	= 1;
  $c->log->debug('Query::xml '.$c->config->{jobdb}->{dsn});
  $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		

                );

  
  if ($id) 
   {
    $jobdb->db_search('table'  => 'jobs', 'search' => { id => $id } );
   }
   else
   {
    $jobdb->db_search('table'  => 'jobs' );
   }
  
  my $count=0;
  while ($x = $jobdb->db_next) { push @{$hash},$x; }
  $jobdb->db_close;
  
  $c->stash->{hash} = $hash;
  
  $c->stash->{template}       = '/query/xml.html';
}

sub status : Path('/status' ) {
  my ($self, $c, $id) = @_;
  use XML::Smart;
  
  my $jobdb	= DBIx::SimplePerl->new;
  my ($status,$heartbeat,$x);
  $jobdb->{debug}	= 1;
  $c->log->debug('Query::xml '.$c->config->{jobdb}->{dsn});
  $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		

                );

  
  if ($id) 
   {
    $jobdb->db_search(
    		      'table'  => 'jobs', 
		      'search' => { id => $id }, 
		      'columns'=> "status,heartbeat"
		      );
   }
 
  
  
  $x 		= $jobdb->db_next;
  $status 	= $x->{'status'}; 
  $heartbeat 	= $x->{'heartbeat'};
  $jobdb->db_close;
  
  $c->stash->{status} 		= $status;
  $c->stash->{id} 		= $id;
  $c->stash->{heartbeat} 	= $heartbeat;
 
  $c->stash->{template}       = '/query/status.html';
}


sub appxml : Path('/appxml' ) {
  my ($self, $c ) = @_;
  use XML::Smart;
  use Data::Dumper;
  my (%hash,$x,@fields,$search_term,$index_current_version);
  my (%results,$count,$current_version);
  $c->log->debug('Query::appxml '.$c->config->{appdb}->{dsn});
  my $appsdb = DBIx::SimplePerl->new;
  $appsdb->{debug}=1;
  $appsdb->db_open( 
    		   'dsn'	=> $c->config->{appdb}->{dsn},
		   'dbuser'	=> $c->config->{appdb}->{dbuser},
		   'dbpass'	=> $c->config->{appdb}->{dbpass}		
                 );
  @fields = @{$c->req->args};
  foreach $search_term (@fields)
   {
      $c->log->debug('Query::appxml: search_term= '.$search_term);
      if ($search_term =~ /(.*)=(.*)/)
       {
          $hash{$1} = $2;
          $c->log->debug('Query::appxml: search term= '.$1.' value = '.$2);
       }
   }
  $c->log->debug('apps/xml: hash = '.Dumper(\%hash));
  $appsdb->db_search('table'  => 'apps', 'search' => \%hash );
# now search for the highest version number in the returned results
  # will be only one returned row for a specific version or serial number
  $count=0;
  $index_current_version  = 0;
  while ($results{$count}  = $appsdb->db_next)
   {
      if ($count == 0)
       {
          $current_version = $results{$count}->{version};
       }
      else
       {
          if ($current_version < $results{$count}->{version})
            {
              $current_version = $results{$count}->{version};
              $index_current_version = $count;
            }
       }
      $count++;
   }
  $appsdb->db_close;

  $c->stash->{xml} = $results{$index_current_version};
  
  $c->stash->{template}       = '/query/appxml.html';

}

sub default : Private {
  my ( $self, $c ) = @_;
  use XML::Smart;
  my $hash;
  my $jobdb	= DBIx::SimplePerl->new;
  
  $jobdb->{debug}	= 1;
  $c->log->debug('Query::xml '.$c->config->{jobdb}->{dsn});
  $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		

                );
  my $xml	= XML::Smart->new;
  
  
  $jobdb->db_search('table'  => 'jobs' );
   
  
  my $count=0;
  while ($hash->{$count}=$jobdb->db_next) { $count++; }
  $jobdb->db_close;
  
  $c->stash->{hash} = $hash;
  $c->stash->{template}       = '/query/jobs.html';

    
}

=head1 NAME

DragonFlyJob::Controller::Query - Catalyst Controller

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
#sub default : Private {
#    my ( $self, $c ) = @_;
#
#    # Hello World
#    $c->response->body('DragonFlyJob::Controller::Query is on Catalyst!');
#}

=back


=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
