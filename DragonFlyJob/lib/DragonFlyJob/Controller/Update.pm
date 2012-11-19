package DragonFlyJob::Controller::Update;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub xml : Path('/update' ) {
  my ($self, $c, $id,$field,@values) = @_;
  
  my $jobdb	= DBIx::SimplePerl->new;
  my ($hash,$x,$rc,$value);
  my @allowed_fields;
  
  my @fields = @{$c->req->args};
  my @captures = @{ $c->request->captures };
  
  if (!$id)
   {
    $id = $c->request->param('id') if ($c->request->param('id'));
   }
  if (!$field)
   {
    $field = $c->request->param('field') if ($c->request->param('field'));
   }
  if (!$value)
   {
    $value = $c->request->param('value') if ($c->request->param('value'));
   }  
  
  $jobdb->{debug}	= 1;
  $c->log->debug('Query::xml '.$c->config->{jobdb}->{dsn});
  $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		

                );

  $c->stash->{template}       = '/update/xml.html';
  @allowed_fields	= qw(
  				assigned_to_cluster
				completed
				compute_node_run_directory
				hold
				job_directory
				job_return_code
				job_stderr
				job_stdout
				jobid
				queue_jobname
				queued
				running_on_node
				started
				status
				submitted
				wallclock_queued
				wallclock_run
				pid_on_compute_node
				heartbeat
				
			    );
  if (($id) && ($field) && ($value)) 
   {
    # look for the ID we supplied
    $jobdb->db_search('table'  => 'jobs', 'search' => { id => $id } );
    $x	= $jobdb->db_next;
    if ($x)
     {
      # found job ID, now see if we have a valid field
      if ((exists($x->{$field})) && (grep {/^$field$/} @allowed_fields))
       {
        # found updatable field in record
	
	$rc=$jobdb->db_update(
			  'table'   => 'jobs',
                          'search'  => { 'id' => $id    },
                          'columns' => { $field  => $value }
                          );
        $c->stash->{rc} = $rc;
	$c->stash->{template}     = '/update/completed.html';
       }
       else
       {
        # field not found, tell user
        $c->stash->{error}	= 'updatable field='.$field.' was not found in record id='.$id;
        $c->stash->{updatable_fields} = \@allowed_fields;
        $c->stash->{template}     = '/update/error.html';
       }
     }
     else
     {
      # id not found, tell user
      $c->stash->{error}	= 'ID='.$id.' was not found in jobdb.';
      $c->stash->{template}     = '/update/error.html';
     
     }
    
    
   }
   else
   {
    # no id/field/value provided, tell user
    $c->stash->{error}		= sprintf 'id[%s]/field[%s]/value[%s] not provided.  Please provide this.',$id,$field,$value;
    $c->stash->{template}       = '/update/error.html';
   }
  
   
  $jobdb->db_close;
   

}

=head1 NAME

DragonFlyJob::Controller::Update - Catalyst Controller

=head1 SYNOPSIS

See L<DragonFlyJob>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=over 4


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
#    $c->response->body('DragonFlyJob::Controller::Update is on Catalyst!');
#}

=back


=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
