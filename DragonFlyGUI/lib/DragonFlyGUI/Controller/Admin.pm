package DragonFlyGUI::Controller::Admin;

use strict;
use warnings;
use base 'Catalyst::Controller::FormBuilder';

=head1 NAME

DragonFlyGUI::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Admin in Admin.');
}


sub adduser : Local Form {
    my ( $self, $c ) = @_;
    use Data::Dumper;
    my ($retc,$x,%h,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    $c->log->debug('admin/adduser: ');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
        $form->field(
        	      name      => "first_name",
        	      label     => "First name for user",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "last_name",
        	      label     => "last name for user",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "username",
        	      label     => "Login name for user",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "password",
        	      label     => "password for user",        	      
        	      size 	=> "80",
		      type	=> "password" 		      
	             ); 
        $form->field(
        	      name     	=> "email_address",
        	      label    	=> "email address",        	      
        	      size 	=> "80"	      
	             ); 
        $form->field(
        	      name     	=> "uid",
        	      label    	=> "numerical UID",        	      
        	      size 	=> "80"	      
	             ); 
        $form->field(
        	      name     	=> "active",
		      label	=> "active",
		      options	=> ['Yes','No'],
		      value	=> 'Yes'     
	             ); 

	 $form->submit(['Cancel', 'Save']);
	 $c->stash->{page}	= "Application name and information";	 
	 $c->stash->{form}	= $form;
         	 
       }
 
   if ($form->submitted)
      {
        my $userdb  = DBIx::SimplePerl->new;
	my $rc;
	$userdb->{debug}=1;
        $userdb->db_open( 
    		     'dsn'	=> $c->config->{userdb}->{dsn},
		     'dbuser'	=> $c->config->{userdb}->{dbuser},
		     'dbpass'	=> $c->config->{userdb}->{dbpass}	
                    );
        foreach my $field ( keys %{$c->request->parameters})
	 {
	  next if (($field eq "_submit") || ($field eq "_submitted"));
	  $h{$field} = $c->request->parameters->{$field};
	 }	   
        $c->log->debug('admin/adduser: dump of minihash = '.Dumper(\%h)); 	 
	  
        $rc=$userdb->db_add( 
    		    'table' 	=> 'users',
		    'columns'	=> \%h
		   );
         $c->log->debug('admin/adduser: dump of useradd return = '.Dumper($rc));
        $userdb->db_close;
	$c->redirect('/main');
      }
   
   $c->stash->{template} = '/admin/adduser.html';   
    
}

sub edituser : Local Form {
    my ( $self, $c, $id ) = @_;
    my $userdb  = DBIx::SimplePerl->new;
    use Data::Dumper;
    my ($retc,$x,%h,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    $userdb->{debug}=1;
    $userdb->db_open( 
    		 'dsn'	=> $c->config->{userdb}->{dsn},
		 'dbuser'	=> $c->config->{userdb}->{dbuser},
		 'dbpass'	=> $c->config->{userdb}->{dbpass}		
                );
    $userdb->db_search('table'  => 'users', 'search' => {'id' => $id});
    $x	= $userdb->db_next;
    
    
    $c->log->debug('admin/edituser: ');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
        $form->field(
        	      name      => "first_name",
        	      label     => "First name for user",        	      
        	      size 	=> "80",
		      value	=> $x->{first_name}     
	             ); 
        $form->field(
        	      name      => "last_name",
        	      label     => "last name for user",        	      
        	      size 	=> "80"   ,
		      value	=> $x->{last_name}     
	             ); 
        $form->field(
        	      name      => "username",
        	      label     => "Login name for user",        	      
        	      size 	=> "80" ,
		      value	=> $x->{username}       
	             ); 
        $form->field(
        	      name      => "password",
        	      label     => "password for user",        	      
        	      size 	=> "80",
		      type	=> "password" 	,
		      value	=> $x->{password}   	      
	             ); 
        $form->field(
        	      name     	=> "email_address",
        	      label    	=> "email address",        	      
        	      size 	=> "80"	      ,
		      value	=> $x->{email_address}   
	             ); 
        $form->field(
        	      name     	=> "uid",
        	      label    	=> "userid",        	      
        	      size 	=> "80"	   ,
		      value	=> $x->{uid}      
	             ); 
        $form->field(
        	      name     	=> "active",
		      label	=> "active",
		      options	=> ['Yes','No'],
		      value	=> $x->{active}    
	             ); 

	 $form->submit(['Cancel', 'Save']);
	 $c->stash->{page}	= "Application name and information";	 
	 $c->stash->{form}	= $form;
         	 
       }
   $userdb->db_close;
   if ($form->submitted)
      {
        my $userdb  = DBIx::SimplePerl->new;
	$userdb->{debug}=1;
        $userdb->db_open( 
    		     'dsn'	=> $c->config->{userdb}->{dsn},
		     'dbuser'	=> $c->config->{userdb}->{dbuser},
		     'dbpass'	=> $c->config->{userdb}->{dbpass}		
                    );
        foreach my $field ( keys %{$c->request->parameters})
	 {
	  next if (($field eq "_submit") || ($field eq "_submitted"));
	  $h{$field} = $c->request->parameters->{$field};
	 }	   
        $c->log->debug('admin/adduser: dump of minihash = '.Dumper(\%h)); 	 
	  
        $userdb->db_add( 
    		    'table' 	=> 'users',
		    'columns'	=> \%h
		   );
        $userdb->db_close;
	$c->redirect('/main');
      }
  
   $c->stash->{template} = '/admin/adduser.html';   
    
}

sub listuser : Local Form {
    my ( $self, $c, $id ) = @_;
    my $userdb  = DBIx::SimplePerl->new;
    use Data::Dumper;
    my ($x, $users);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    $userdb->{debug}=1;
    $userdb->db_open( 
    		 'dsn'	=> $c->config->{userdb}->{dsn},
		 'dbuser'	=> $c->config->{userdb}->{dbuser},
		 'dbpass'	=> $c->config->{userdb}->{dbpass}		
                );
    $userdb->db_search('table'  => 'users');
    while ($x	= $userdb->db_next)
     {
      $users->{$x->{id}}=$x;
     }
    
    $c->stash->{users}	= $users;
    $c->stash->{template} = '/admin/listusers.html';    
}

sub feedback : Local Form {
    my ( $self, $c, $id ) = @_;
    my $feedback  = DBIx::SimplePerl->new;
 
     
    use Data::Dumper;
    my ($retc,$x,%h,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    $c->log->debug('admin/feedback: ');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
        $form->field(
        	      name      => "username",
        	      label     => "Login name for user",        	      
        	      size 	=> "80"  ,
		      required	=> 1	   
	             ); 
        $form->field(
        	      name     	=> "email_address",
        	      label    	=> "email address",        	      
        	      size 	=> "80",
		      required	=> 1	      
	             ); 
        $form->field(
        	      name     	=> "phone",
        	      label    	=> "phone",        	      
        	      size 	=> "80"
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "comment",
        	      label    	=> "comment",        	      
        	      type 	=> "textarea"
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "respond",
		      label	=> "respond",
		      options	=> ['True','False'],
		      value	=> 'False'     
	             ); 

	 $form->submit(['Cancel', 'Save']);
	 $c->stash->{form}	= $form;
         	 
       }
 
   if ($form->submitted)
      {
        my $feedback  = DBIx::SimplePerl->new;
	$feedback->{debug}=1;
        $feedback->db_open( 
    		     'dsn'	=> $c->config->{feedback}->{dsn},
		     'dbuser'	=> $c->config->{feedback}->{dbuser},
		     'dbpass'	=> $c->config->{feedback}->{dbpass}		
                    );
        foreach my $field ( keys %{$c->request->parameters})
	 {
	  next if (($field eq "_submit") || ($field eq "_submitted"));
	  $h{$field} = $c->request->parameters->{$field};
	 }	   
        $c->log->debug('admin/feedback: dump of minihash = '.Dumper(\%h)); 	 
	  
        $feedback->db_add( 
    		    'table' 	=> 'feedback',
		    'columns'	=> \%h
		   );
        $feedback->db_close;
	$c->redirect('/main');
      }
   
   $c->stash->{template} = '/admin/adduser.html';   
    
}

sub rfe : Local Form {
    my ( $self, $c, $id ) = @_;
    my $feedback  = DBIx::SimplePerl->new;
 
     
    use Data::Dumper;
    my ($retc,$x,%h,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    $c->log->debug('admin/rfe: ');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
        $form->field(
        	      name      => "username",
        	      label     => "Login name for user",        	      
        	      size 	=> "80"  ,
		      required	=> 1	   
	             ); 
        $form->field(
        	      name     	=> "email_address",
        	      label    	=> "email address",        	      
        	      size 	=> "80",
		      required	=> 1	      
	             ); 
        $form->field(
        	      name     	=> "phone",
        	      label    	=> "phone",        	      
        	      size 	=> "80"
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "feature",
        	      label    	=> "what feature would you like?",        	      
        	      type 	=> "textarea"
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "respond",
		      label	=> "respond",
		      options	=> ['True','False'],
		      value	=> 'False'     
	             ); 

	 $form->submit(['Cancel', 'Save']);
	 $c->stash->{form}	= $form;
         	 
       }
 
   if ($form->submitted)
      {
        my $feedback  = DBIx::SimplePerl->new;
	$feedback->{debug}=1;
        $feedback->db_open( 
    		     'dsn'	=> $c->config->{feedback}->{dsn},
		     'dbuser'	=> $c->config->{feedback}->{dbuser},
		     'dbpass'	=> $c->config->{feedback}->{dbpass}		
                    );
        foreach my $field ( keys %{$c->request->parameters})
	 {
	  next if (($field eq "_submit") || ($field eq "_submitted"));
	  $h{$field} = $c->request->parameters->{$field};
	 }	   
        $c->log->debug('admin/feedback: dump of minihash = '.Dumper(\%h)); 	 
	  
        $feedback->db_add( 
    		    'table' 	=> 'rfe',
		    'columns'	=> \%h
		   );
        $feedback->db_close;
	$c->redirect('/main');
      }
   
   $c->stash->{template} = '/admin/adduser.html';       
}

sub support_request : Local Form {
    my ( $self, $c, $id ) = @_;
    my $feedback  = DBIx::SimplePerl->new;
 
     
    use Data::Dumper;
    my ($retc,$x,%h,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    $c->log->debug('admin/rfe: ');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
        $form->field(
        	      name      => "first_name",
        	      label     => "What is your first name?",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "last_name",
        	      label     => "What is your last name?",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "username",
        	      label     => "Login name for user",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name      => "best_contact_method",
        	      label     => "What is the best way to respond to you?",        	      
        	      size 	=> "80"     
	             ); 
        $form->field(
        	      name     	=> "email_address",
        	      label    	=> "email address",        	      
        	      size 	=> "80",
		      required	=> 1	      
	             ); 
        $form->field(
        	      name     	=> "phone",
        	      label    	=> "phone",        	      
        	      size 	=> "80",
		      required	=> 1
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "need",
        	      label    	=> "what is the nature of your support request?",        	      
        	      type 	=> "textarea",
		      required	=> 1
		       	  	      
	             ); 
        $form->field(
        	      name     	=> "urgency",
		      label	=> "How urgently do you require a response?",
		      options	=> ['immediately','an hour','a day', 'a week', 'a month', 'a quarter','a year' ],
		      value	=> 'a week',
		      type	=> 'select',
		      required	=> 1     
	             ); 

	 $form->submit(['Cancel', 'Save']);
	 $c->stash->{form}	= $form;
         	 
       }
 
   if ($form->submitted)
      {
        my $feedback  = DBIx::SimplePerl->new;
	$feedback->{debug}=1;
        $feedback->db_open( 
    		     'dsn'	=> $c->config->{feedback}->{dsn},
		     'dbuser'	=> $c->config->{feedback}->{dbuser},
		     'dbpass'	=> $c->config->{feedback}->{dbpass}		
                    );
        foreach my $field ( keys %{$c->request->parameters})
	 {
	  next if (($field eq "_submit") || ($field eq "_submitted"));
	  $h{$field} = $c->request->parameters->{$field};
	 }	   
        $c->log->debug('admin/support: dump of minihash = '.Dumper(\%h)); 	 
	  
        $feedback->db_add( 
    		    'table' 	=> 'support',
		    'columns'	=> \%h
		   );
        $feedback->db_close;
	$c->redirect('/main');
      }
   
   $c->stash->{template} = '/admin/adduser.html';   
    
}
=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
