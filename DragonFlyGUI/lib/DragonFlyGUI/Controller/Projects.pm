package DragonFlyGUI::Controller::Projects;

use strict;
use warnings;
use base 'Catalyst::Controller::FormBuilder';

__PACKAGE__->config(
        'Controller::FormBuilder' => {
            template_type => 'Mason',    # default is 'TT' (e.g. TT2)
            debug   => 0
        }
    );


=head1 NAME

DragonFlyGUI::Controller::Projects - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Projects in Projects.');
}

=head2 list

Fetch all project objects and pass in stash to be displayed

=cut

sub listxxx : Local {

    use DBIx::SimplePerl;

    my ($self,$c) = @_;
    my $dsn = "dbi:SQLite:dbname=db/dfgui.db";
    my $sice = DBIx::SimplePerl->new;

    $sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
    $sice->db_search( table => "projects");
    $c->stash->{projects} = [@{$sice->db_array}]; 
    $c->stash->{template} = 'projects/list3.html';
    $sice->db_close;

}

sub list : Local {
        my ($self, $c) = @_;
	my (@projects,$x,$rc);
        my $projectdb=DBIx::SimplePerl->new;
        $projectdb->{debug}=1;
        #$c->stash->{projects} = [$c->model('DragonFlyGUIDB::Project')->all];
        #$c->stash->{template} = 'projects/list3.html';
        $projectdb->db_open(
			    'dsn'      => $c->config->{projectdb}->{dsn},
                            'dbuser'   => $c->config->{projectdb}->{dbuser},
                            'dbpass'   => $c->config->{projectdb}->{dbpass} 
			   );
	$rc=$projectdb->db_search('table' => 'projects');
	$c->log->debug('projects/list: dump of projectdb rc = '.Dumper($rc));
	while ($x = $projectdb->db_next) 
	   { 
	     push @projects,$x; 
	     $c->log->debug('projects/list: dump of projectdb query x = '.Dumper($x));

	   }
	$c->stash->{projects} = \@projects;
	$c->stash->{template} = 'projects/list3.html';
}

sub form_create : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'projects/form_create.html';
}

sub form_create_do : Local {
    my ($self, $c) = @_;
 
    # Retrieve the values from the form
    my $projid   = $c->request->params->{project_id}            || 'N/A';
    my $pname    = $c->request->params->{project_name}          || 'N/A';
    my $pstart   = $c->request->params->{project_start}         || 'N/A';
    my $pstatus  = $c->request->params->{project_status}        || 'N/A';
    my $puri     = $c->request->params->{project_uri}           || 'N/A';
    my $pdescr   = $c->request->params->{project_description}   || 'N/A';
    my $pdocs    = $c->request->params->{project_documentation} || 'N/A';
    my $pactive  = $c->request->params->{active}                || 'Yes';
    my $plocked  = $c->request->params->{locked}                || 'No';
   
    # Create the project
    my $project = $c->model('DragonFlyGUIDB::Project')->create({
            project_name          => $pname,
            project_id            => $projid,
            project_start         => $pstart,
            project_status        => $pstatus,
            project_uri           => $puri,
            project_description   => $pdescr,
            project_documentation => $pdocs,
            active                => $pactive,
            locked                => $plocked,
    });
  
    # Store new model object in stash
    $c->stash->{project} = $project;
 
    # Avoid Data::Dumper issue mentioned earlier
    # You can probably omit this    
    #$Data::Dumper::Useperl = 1;

    # Set the TT template to use
    $c->stash->{template} = 'projects/create_done.html';
}

sub delete : Local {
    # $id = primary key of project to delete
    my ($self, $c, $id) = @_;
   
    # Search for the project and then delete it
    $c->model('DragonFlyGUIDB::Project')->search({id => $id})->delete_all;
  
    # Forward to the list action/method in this controller
    $c->response->redirect($c->uri_for('/projects/list',
    {status_msg => "Project deleted."}));
}

sub modify : Local Form {
    use DBIx::SimplePerl; 
    use POSIX;
    use Data::Dumper;
    my ($self, $c, $id) = @_;
    my $time    = POSIX::strftime "%F %T %z",localtime;

    my ($hash,$x,$sice,$each_user);   
    my $form = $self->formbuilder;
    $form->debug(0);    
    $form->stylesheet(1);
    
    
    # insert default current local server date and time for project_start field
    $form->field(
                 name   => 'project_start',
                 value  => $time
                );
    
    # make sure locked is a check box
    $form->field(
                 name   => 'locked',
                 type    => 'checkbox',
                 required => 0,
                 options => ['Yes','No'],
                 value  => ['No']
                );
    
    # make sure active is a check box
    $form->field(
                 name   => 'active',
                 type    => 'checkbox',
                 required => 0,
                 options => ['Yes','No'],
                 value      => ['Yes']
                );
  

    #my $dsn = "dbi:SQLite:dbname=db/dfgui.db";
    #$self->config->{userdb_dsn};
    my $projectdb=DBIx::SimplePerl->new;
    $projectdb->{debug}=1;
    $projectdb->db_open(
                            'dsn'      => $c->config->{projectdb}->{dsn},
                            'dbuser'   => $c->config->{projectdb}->{dbuser},
                            'dbpass'   => $c->config->{projectdb}->{dbpass}
                       );
    $projectdb->db_search('table'  => 'projects', 'search' => { id => $id } );
    $hash = $projectdb->db_next;
    
    $c->stash->{projects}   = $hash;
    $c->stash->{forms}      = $form;
    $c->stash->{id}         = $id;

    $c->stash->{template} = 'projects/modify.html';
     
    if ($form->submitted eq 'Return to Project List') {
      $c->response->redirect($c->uri_for('list'));
    }
    elsif ($form->submitted eq 'Delete This Project') {
      $c->response->redirect($c->uri_for('delete/') . $id);
    }
    elsif ($form->submitted eq 'Update This Project' && $form->validate)
    {
      my $field = $form->fields;

      my @project_users;
      my $rc;
      $c->log->debug('Project users: '.join(":",@project_users));
     
      $projectdb->{debug}=1;
      $rc=$projectdb->db_update( table => "projects", search => { id => $id },
           columns => { 
                     project_id => $field->{project_id},
                     project_name => $field->{project_name},
                     project_description => $field->{project_description},
                     project_status => $field->{project_status},
                     project_start => $field->{project_start},
                     project_documentation => $field->{project_documentation},
                     project_uri => $field->{project_uri},
                     active => $field->{active},
                     locked => $field->{locked}
                     } );

      $c->log->debug('project dump ='.Dumper($rc));
      $c->response->redirect($c->uri_for('list'));
    }
   
}

sub users : Local Form('/projects/users') {
    my ($self, $c, $id) = @_;
    use Data::Dumper;
    my $form = $self->formbuilder;
    $form->debug(0);
    my ($sice,$x,$each_user,@project_users,$rc,$t,@c,@add,@del);
    my ($uid,@_t);
    
    my $dsn = "dbi:SQLite:dbname=db/dfgui.db";
    #$self->config->{userdb_dsn};
    $c->log->debug('DSN = '.$dsn);
    $sice = DBIx::SimplePerl->new;
    $sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");

    # find all users  
    $sice->db_search('table'  => 'users' );
    my (@users,%user_hash,@ids,@in_project,%id_hash,%project_user_list,@values);
    while ($x=$sice->db_next )
     {
        $user_hash{$x->{username}} = $x->{id};
        $id_hash{$x->{id}} = $x->{username};    # store mapping
        $project_user_list{$x->{username}}  = ['No'];
      }
    @users   = sort keys %user_hash;
    map {push @ids,$user_hash{$_} } @users;
    map { $c->log->debug(' ID: key ='.$_.' value = '.$id_hash{$_}) } keys %id_hash;
    # map all users to 'No' first ...
    foreach (@users)
     {
        $project_user_list{$_} = 'No';
     }
    #
     
    # find users associated with project and set them to 'Yes'
    $sice->db_search(
                     'table'  => 'project_users',
                     'search' => { 'project' => $id }                     
                     );
    
    while ($x=$sice->db_next )
     {
       $uid = $id_hash{$x->{user}};
       $project_user_list{$uid} = 'Yes';        
       $c->log->debug(' x->user ='.$x->{user});
     }
     
    map { $c->log->debug(' P ='.$project_user_list{$_}) } keys %user_hash;
     
   # now this is a fun one  
   # CGI::FormBuilder can't build large selection blocks of radio buttons
   # so we are going to force the issue, by having one input per user  
   
   foreach $each_user (sort keys %user_hash)
    {
        $uid    = $user_hash{$each_user};
        $t      = $project_user_list{$each_user};
        undef @_t;
        push @_t,$t;
        
        $c->log->debug(
                       ' project user list for user ='.$each_user.
                       ' with id = '.$uid.
                       ' is '.$t
                      );
        
         # make sure active is a check box
        $form->field(
                 name       => (sprintf 'user:%s',$each_user),
                 label      => $each_user,
                 type       => 'radio',
                 options    => ['No','Yes'],
                 value      => $t,
                 
                );
    }
    
    $c->stash->{forms}      = $form;                                 
    $c->stash->{template} = 'projects/modifyuser.html';

    if ($form->submitted eq "Update users")
     {
    # grab the user:(\d+) field pattern and map them into users
    my $field_hash    = $form->fields;
    my ($retc,$count);
    map {
          if ($_ =~ /user:(.*)/)
           {
              push @project_users,$1;
              if ($field_hash->{$_} eq "Yes")
                {
                    push @add,$1 ;
                }
               else
                {
                    push @del,$1;
                }
           }
        } keys %{$field_hash};
    
    # now that I have the list of users to update from the fields, work
    # through the updates.  Add if not in the list, otherwise update
    foreach my $project_user (@add)
     {
      $c->log->debug('adding user = '.$project_user);
      $c->log->debug('         id = '.$user_hash{$project_user});
      $c->log->debug(' project id = '.$id);

      $rc=$sice->db_search(
                       'table'   => 'project_users',
                       'search'  => {'user' => $user_hash{$project_user}},
                       'count'   => 'user'
                      );
      
      $c->log->debug(' dump of sice ='.Dumper($sice));
      $t      = $sice->db_next;
      @c      = values %{$t};
      $count  = $c[0];
      $c->log->debug(' dump of t ='.Dumper($t));
      # get the count, if >=1, do an update, otherwise do an add
      $c->log->debug(' count of user='.$project_user.' = '.$count);
      
      if ($count >0 )
       {
        $rc=$sice->db_update(
           'table' => 'project_users',
           search  => {'user' => $user_hash{$project_user}},
           columns => {
                       'user' => $user_hash{$project_user},
                       'project'   => $id,
                       'active'    => 'Yes',
                       'access_type'    => 'rw',
                       'access'    => 'Yes',
                       'role'      => '1'
                      }


           );
       }
       else
       {
         $rc=$sice->db_add(
         'table' => 'project_users',
         columns => {
                     'user' => $user_hash{$project_user},
                     'project'   => $id,
                     'active'    => 'Yes',
                     'access_type'    => 'rw',
                     'access'    => 'Yes',
                     'role'      => '1'
                     }

         );            
       }
    }
    foreach my $project_user (@del)
     {
      $c->log->debug('deleting user = '.$project_user);
      $c->log->debug('           id = '.$user_hash{$project_user});
      $c->log->debug('   project id = '.$id);
      $rc=$sice->db_delete(
         'table' => 'proje  ct_users',
          search => {
                     'user' => $user_hash{$project_user}
                     } 
      );
     }
 }
   if ($form->submitted) { $c->response->redirect($c->uri_for('modify/'.$id)); }
}

sub dumper : Local Form('/projects/list_one') {

    my ($self, $c, $id) = @_;
    my $form = $self->formbuilder;
    $form->debug(0);
    my $project = [$c->model('DragonFlyGUIDB::Project')->search( id => $id )];

    $c->stash->{projects}  = $project;
    $c->stash->{forms}  = $form;
    $c->stash->{template} = 'projects/dumper.html';

}

sub add_project : Local Form {
    use POSIX;
    use DBIx::SimplePerl;
    my ( $self, $c ) = @_;
    my $time    = POSIX::strftime "%F %T %z",localtime;
    my $form = $self->formbuilder;
    my $projectdb=DBIx::SimplePerl->new;
    $projectdb->{debug}=1;
    $form->debug(0);    
    $form->stylesheet(1);
    
    # insert default current local server date and time for project_start field
    $form->field(
                 name   => 'project_start',
                 value  => $time
                );
    
    # make sure locked is a radio button
    $form->field(
                 name   => 'locked',
                 options => ['Locked','Unlocked'],
                 value => ['Unlocked'],
                 type   => 'radio'
                );
    
    # make sure active is a radio button
    $form->field(
                 name   => 'active',
                 options => ['Active', 'Inactive'],
                 value      => ['Active'],
                 type   => 'radio'
                );
    #$form->field(name => 'answer', options => ['Yes','No'], value => ['Yes']);
    $c->stash->{forms}  = $form;
    $c->stash->{template}	= '/projects/manage.html';

    if ( $form->submitted ) {
        if ( $form->validate ) {
           my $field = $form->fields;

           #my ($self,$c) = @_;
           #my $dsn = "dbi:SQLite:dbname=db/dfgui.db";
           #my $sice = DBIx::SimplePerl->new;
	   $projectdb->db_open(
                            'dsn'      => $c->config->{projectdb}->{dsn},
                            'dbuser'   => $c->config->{projectdb}->{dbuser},
                            'dbpass'   => $c->config->{projectdb}->{dbpass}
                           );
           #$sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
           my $rc = $projectdb->db_add( table => "projects", columns => {
                     project_id => $field->{project_id},
                     project_name => $field->{project_name},
                     project_description => $field->{project_description},
                     project_status => $field->{project_status},
                     project_start => $field->{project_start},
                     project_documentation => $field->{project_documentation},
                     project_uri => $field->{project_uri},
                     active => $field->{active},
                     locked => $field->{locked}
                     }
           ); 
	   $c->log->debug('projects/add_project: dump of projectdb rc = '.Dumper($rc));
           # Forward to the list action/method in this controller
           $c->response->redirect($c->uri_for('list',
           {status_msg => "Project Successfully Added"}));
        }
        else {
            $c->stash->{ERROR}          = "INVALID FORM";
            $c->stash->{invalid_fields} =
              [ grep { !$_->validate } $form->fields ];
        }
    }
}

sub close : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Projects::Close in Projects.');
}

sub switch : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Projects::Switch in Projects.');
}

sub accounting : Local {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Projects::Accounting in Projects.');
}

sub xml : Local {
    use DBIx::SimplePerl;

    my ($self, $c, $id) = @_;
    my $hash;
  
    my $dsn 		= "dbi:SQLite:dbname=db/dfgui.db";
    my $projectsdb 	= DBIx::SimplePerl->new;

    $projectsdb->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");

    $projectsdb->db_search('table'  => 'projects', 'search' => { id => $id } );
    $hash=$projectsdb->db_next;
    $projectsdb->db_close;
    $c->stash->{xml} = $hash;
    $c->stash->{template}       = '/projects/xml.html';
   }   

=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
