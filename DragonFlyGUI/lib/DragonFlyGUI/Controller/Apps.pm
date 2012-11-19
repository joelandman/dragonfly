package DragonFlyGUI::Controller::Apps;

use strict;
use warnings;
use base 'Catalyst::Controller::FormBuilder';

=head1 NAME

DragonFlyGUI::Controller::Apps - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect('/apps/list');
 
}

sub default : Private {
    my ( $self, $c ) = @_;
    my ($array_ref,$ret);
    
    $c->response->redirect('/apps/list');
}

sub list : Path('list') {
    my ( $self, $c ) = @_;
    my ($array_ref,$ret);
    
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );
    
    $appsdb->db_search('table'  => 'apps', order => 'id');
    while ($ret = $appsdb->db_next)
     {
      push @{$array_ref},$ret;
     }
    
    $c->stash->{apps} = $array_ref;
    $c->stash->{template} = 'apps/list.html';   
}

sub xml : Local {
    use DBIx::SimplePerl;
    use Data::Dumper;
    my ($self, $c, $field) = @_;
    my (%hash,$search_term,%outgoing,%results,$count,$current_version);
    my ($index_current_version,@fields);
    
    #my $dsn = "dbi:SQLite:dbname=db/apps.db";
    @fields = @{$c->req->args};
    #$c->log->debug('apps/xml: dsn   = '.$dsn);
    $c->log->debug('apps/xml: args  = '.join(":",@fields));
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );
    
    foreach $search_term (@fields)
     {
        $c->log->debug('apps/xml: search_term= '.$search_term);
        if ($search_term =~ /(.*)=(.*)/)
         {
            $hash{$1} = $2;
            $c->log->debug('apps/xml: search term= '.$1.' value = '.$2);
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
    $c->stash->{template}       = '/apps/xml.html';
   }

sub add : Local Form {
    my ( $self, $c, $page ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
     
    
    $c->log->debug('apps/add: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    if (!$form->submitted)
       {
         undef $c->session->{appdata};
         $form->field(
        	      name      => "Meta: [appname]",
        	      label     => "Name of application",        	      
        	      size 	=> "80",
		      value	=> $c->session->{appdata}->{meta}->{appname} || ""	     
	             ); 
         $form->field(
        	      name     	=> "Meta: [appdesc]",
        	      label    	=> "description of application",        	      
        	      size 	=> "80",
		      type	=> "textarea",
		      value	=> $c->session->{appdata}->{meta}->{appdesc} || ""
	             ); 
         $form->field(
        	      name     	=> "Meta: [appdoc]",
        	      label    	=> "documentation for application",        	      
        	      size 	=> "80"	,
		      value	=> $c->session->{appdata}->{meta}->{appdoc} || ""	      
	             ); 
         $form->field(
        	      name     	=> "page",
		      type	=> "hidden",
		      value	=> 1 		     
	             ); 
         $form->field(
        	      name     	=> "nextpage",
		      type	=> "hidden",
		      value	=> 2 		     
	             ); 
	 $form->submit(['Cancel', 'Next']);
	 $c->stash->{page}	= "Application name and information";	 
	 $c->stash->{form}	= $form;
         	 
       }
    
    if ($form->submitted eq "Previous")
       {
         if ($c->session->{appdata}->{page} > 1)
	  {
	    $c->session->{appdata}->{page}--;	    
	  } 	 
	 $c->stash->{page}	= $c->session->{appdata}->{page};
	 $c->stash->{form}	= $form;
	 $c->redirect('/jobs/add',[$page]);
       }

    if ($form->submitted eq "Next")
       {
        $c->log->debug('apps/add: meta = '.Dumper($c->request->parameters));         
        foreach my $meta ( grep { /Meta/ } keys %{$c->request->parameters})
	 {
	   if ($meta =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/add: named metadata= '.$1.
	      '  value ='.$c->request->parameters->{$meta});
	      $c->session->{appdata}->{meta}->{$1}=$c->request->parameters->{$meta};
	    }	   
	 }
	$c->redirect('/apps/addparam');  # next page  add parameters.
       }
     
      
    $c->stash->{template}	= '/apps/add.html'
}

sub addparam : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addparam: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 
    $form->field(
        	 name      => "Parameter: [name]",
        	 label     => "Name of parameter",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "Parameter: [label]",
        	 label     => "label of parameter (on input form)",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name     	=> "Parameter: [value]",
        	 label    	=> "default value of parameter",        	      
        	 size 	=> "80",		      
		 value	=> ""
	        ); 
    $form->field(
        	 name     	=> "Parameter: [desc]",
        	 label    	=> "description of parameter",        	      
        	 size 	=> "80",
		 type	=> "textarea",
		 value	=> ""
	        );  

    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application parameters";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/add');
       }

    if ($form->submitted eq "Finished")
       {
       	 $c->redirect('/apps/addarg');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addparam: parameter = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $parameter ( grep { /Parameter/ } keys %{$c->request->parameters})
	 {
	   if ($parameter =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addparam: named parameter= '.$1.
	      '  value ='.$c->request->parameters->{$parameter});
	      $h{$1} = $c->request->parameters->{$parameter};
	    }	   
           $c->log->debug('apps/addparam: dump of minihash = '.Dumper(\%h)); 
	 }
	 $c->session->{appdata}->{parameter}->{$h{name}}=\%h;
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addparam');  # next page  add parameters.
       }
     
    
    $c->stash->{template}	= '/apps/add.html'
}

sub addarg : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addarg: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 
    $form->field(
        	 name      => "Argument: [name]",
        	 label     => "Name of argument",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name     	=> "Argument: [value]",
        	 label    	=> "default value of argument",        	      
        	 size 	=> "80",		      
		 value	=> ""
	        ); 
    $form->field(
        	 name     	=> "Argument: [desc]",
        	 label    	=> "description of argument",        	      
        	 size 	=> "80",
		 type	=> "textarea",
		 value	=> ""
	        );  
    $form->field(
        	 name     	=> "Argument: [label]",
        	 label    	=> "argument label",        	      
        	 size 	=> "80",
		 value	=> ""
	        );  
    $form->field(
        	 name     	=> "Argument: [mandatory]",
        	 label    	=> "Is this an mandatory",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  
    $form->field(
        	 name     	=> "Argument: [input_file]",
        	 label    	=> "Is this an input file",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  
    $form->field(
        	 name     	=> "Argument: [output_file]",
        	 label    	=> "Is this an output file",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  

    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application arguments";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/addparam');
       }

    if ($form->submitted eq "Finished")
       {
       	 $c->redirect('/apps/addenvcopy');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addarg: argument = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $argument ( grep { /Argument/ } keys %{$c->request->parameters})
	 {
	   if ($argument =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addarg: named argument= '.$1.
	      '  value ='.$c->request->parameters->{$argument});
	      $h{$1} = $c->request->parameters->{$argument};
	    }	   
           $c->log->debug('apps/addarg: dump of minihash = '.Dumper(\%h)); 
	 }
	 $c->session->{appdata}->{argument}->{$h{name}}=\%h;
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addarg');  # next page  add parameters.
       }
     
    
    $c->stash->{template}	= '/apps/add.html'
}   

sub addenvcopy : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addenvcopy: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 

    $form->field(
        	 name     	=> "Env: [copy]",
        	 label    	=> "copy in default environment",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "Yes"
	        );  
    

    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application default environment";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/addarg');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addenvcopy: argument = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $e ( grep { /Env/ } keys %{$c->request->parameters})
	 {
	   if ($e =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addenvcopy: named argument= '.$1.
	      '  value ='.$c->request->parameters->{$e});
	      $h{$1} = $c->request->parameters->{$e};
	    }	   
           $c->log->debug('apps/addenvcopy: dump of minihash = '.Dumper(\%h)); 
	 }
	 $c->session->{appdata}->{environment}->{copy}={'copy'=>{name=>'copy',value=>$h{copy}}};
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addenv');  # next page  add parameters.
       }
     
    
    $c->stash->{template}	= '/apps/add.html'
}

sub addenv : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addenvadd: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 
    $form->field(
        	 name      => "Env: [name]",
        	 label     => "Name of environment variable",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name     	=> "Env: [value]",
        	 label    	=> "value of environment variable",        	      
        	 size 	=> "80",		      
		 value	=> ""
	        ); 
    $form->field(
        	 name     	=> "Env: [desc]",
        	 label    	=> "description of environment variable",        	      
        	 size 	=> "80",
		 type	=> "textarea",
		 value	=> ""
	        );  
    $form->field(
        	 name     	=> "Env: [append]",
        	 label    	=> "append to end of existing environment variable (e.g. such as a path)",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  
    $form->field(
        	 name     	=> "Env: [insert]",
        	 label    	=> "insert at beginning of existing environment variable (e.g. such as a path)",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  
    $form->field(
        	 name     	=> "Env: [delete]",
        	 label    	=> "remove this environment variable from environment",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "No"
	        );  
    $form->field(
        	 name     	=> "Env: [add]",
        	 label    	=> "add this environment variable to environment (will overwrite environment variable of same name)",        	              	  
		 options	=> ['Yes','No'],
		 value		=> "Yes"
	        );  

    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application environment";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/addenvcopy');
       }

    if ($form->submitted eq "Finished")
       {
       	 $c->redirect('/apps/addexecutable');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addenv: argument = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $e ( grep { /Env/ } keys %{$c->request->parameters})
	 {
	   if ($e =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addenv: named argument= '.$1.
	      '  value ='.$c->request->parameters->{$e});
	      $h{$1} = $c->request->parameters->{$e};
	    }	   
           $c->log->debug('apps/addenv: dump of minihash = '.Dumper(\%h)); 	 
	 }
	 $c->session->{appdata}->{environment}->{$h{name}}=\%h;
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addenv');  # next page  add parameters.
       }
         
    $c->stash->{template}	= '/apps/add.html'
} 

sub addexecutable : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addexecutable: App db entry builder');
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 
    $form->field(
        	 name      => "Executable: [name]",
        	 label     => "Name of Executable",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "Executable: [path]",
        	 label     => "path to executable",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "Executable: [version]",
        	 label     => "version of executable (integer)",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "Executable: [extra_end]",
        	 label     => "extra command line parameters at end of command line",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        );     
    $form->field(
        	 name      => "Executable: [extra_begin]",
        	 label     => "extra command line parameters at beginning of command line",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        );     
    $form->field(
        	 name      => "Executable: [smp_parallel]",
        	 label     => "Does this program run in parallel on a single machine",        	      
        	 options	=> ['Yes','No'],
		 value		=> "Yes"	     
	        );     
    $form->field(
        	 name      => "Executable: [use_mpi]",
        	 label     => "Does this program use mpi",        	      
        	 options	=> ['Yes','No'],
		 value		=> "No"	     
	        );     


    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application executable";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/addenv');
       }

    if ($form->submitted eq "Finished")
       {
       	 $c->redirect('/apps/addmpi');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addexecutable: argument = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $e ( grep { /Executable/ } keys %{$c->request->parameters})
	 {
	   if ($e =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addenv: named argument= '.$1.
	      '  value ='.$c->request->parameters->{$e});
	      $h{$1} = $c->request->parameters->{$e};
	    }	   
           $c->log->debug('apps/addenv: dump of minihash = '.Dumper(\%h)); 	 
	 }
	 $c->session->{appdata}->{executable}->{$h{name}}=\%h;
	 $c->session->{usempi}	= $h{use_mpi};
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addmpi');  # next page  add parameters.
       }
         
    $c->stash->{template}	= '/apps/add.html'
} 

sub addmpi : Local Form {
    my ( $self, $c ) = @_;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);
    
    $appsdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 
    
    
    $c->log->debug('apps/addmpi: App db entry builder');
    if ($c->session->{usempi} eq "No") { $c->redirect('/apps/addreview'); }
    
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    
    $c->stash->{appdata}	= \%{$c->session->{appdata}};
 
    $form->field(
        	 name      => "MPI: [name]",
        	 label     => "Name of MPI stack",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "MPI: [path]",
        	 label     => "path to MPI bin directory",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "MPI: [version]",
        	 label     => "version of MPI",        	      
        	 size 	=> "80",
		 value	=> ""	     
	        ); 
    $form->field(
        	 name      => "MPI: [mpirun]",
        	 label     => "name of mpirun or mpiexec binary",        	      
        	 size 	=> "80",
		 value	=> "mpirun"	     
	        );     
    $form->field(
        	 name      => "MPI: [ncpus]",
        	 label     => "argument and parameter to mpirun/mpiexec to pass in number of CPUs",        	      
        	 size 	=> "80",
		 value	=> "-np __NCPUS__"	     
	        );     
    $form->field(
        	 name      => "MPI: [machinefile]",
        	 label     => "argument and parameter to mpirun/mpiexec to pass in machine file",        	      
        	 size 	=> "80",
		 value	=> "-machinefile __MACHINEFILE__"	     
	        );     
    $form->field(
        	 name      => "MPI: [verbose]",
        	 label     => "argument to mpirun/mpiexec to run verbosely",        	      
        	 size 	=> "80",
		 value	=> "-v"	     
	        );     


    $form->submit(['Previous','Cancel','Add','Finished']);

    $c->stash->{page}	= "Application usempi";	 
    $c->stash->{form}	= $form;
    

    if ($form->submitted eq "Previous")
       {
       	 $c->redirect('/apps/addexecutable');
       }

    if ($form->submitted eq "Finished")
       {
       	 $c->redirect('/apps/addreview');
       }

    if (($form->submitted eq "Add"))
       {
        $c->log->debug('apps/addexecutable: argument = '.Dumper($c->request->parameters)); 
	my %h;        
        foreach my $e ( grep { /MPI/ } keys %{$c->request->parameters})
	 {
	   if ($e =~ /\[(.*)\]/)
	    {
	      $c->log->debug('apps/addenv: named argument= '.$1.
	      '  value ='.$c->request->parameters->{$e});
	      $h{$1} = $c->request->parameters->{$e};
	    }	   
           $c->log->debug('apps/addenv: dump of minihash = '.Dumper(\%h)); 	 
	 }
	 $c->session->{appdata}->{MPI}->{$h{name}}=\%h;
	 $c->stash->{appdata}	= \%{$c->session->{appdata}};
	 $c->redirect('/apps/addreview');  # next page  add parameters.
       }
         
    $c->stash->{template}	= '/apps/add.html'
} 

sub addreview : Local {
    my ( $self, $c ) = @_;
    my ($retc,$x,$ret,$k,%apps,$xml,$appdata,$nextpage);

    $c->stash->{appdata}	= \%{$c->session->{appdata}};
    
    $c->forward('generate_appxml');
    # return the application XML in appxml stash
    $c->log->debug('apps/addreview: Appxml='.$c->stash->{appxml});             
    $appdata	= \%{$c->session->{appdata}};
    
    my $appsdb  = DBIx::SimplePerl->new;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                    );
    
    $appsdb->db_add( 
    		    'table' 	=> 'apps',
		    'columns'	=> {
		    		     'appname'	=> $appdata->{meta}->{appname},
				     'serial'	=> 1,
				     'version'	=> $appdata->{meta}->{appversion} || 1,
				     'owner_id'	=> 1,
				     'changable'=> 'FALSE',
				     'date_added'	=> "now()",
				     'derived_from'	=> 0,
				     'app_xml'	=> $c->stash->{appxml}
		    		   }
		   );
    $appsdb->db_close		     ;
    undef  $c->session->{appdata};
    $c->response->redirect($c->uri_for('/apps/list'));
} 

sub generate_appxml : Private {
    my ( $self, $c ) = @_;    
    my $nl	= "\n";
    my $appdata	= $c->stash->{appdata};
    my $xml;
    my $use_mpi=(1==0);  # start out with it being false
     
    
    $xml	= sprintf '<program name="%s" index="%s" version="%s">'.$nl,
		  $appdata->{meta}->{appname},
   		  "",  		  
		  $appdata->{meta}->{version} || "1";
 
    # environment section
    $xml	.= ' <env>'.$nl;
    
    if ( lc($appdata->{environment}->{copy}) eq "yes") 
       {
        $xml	.= '  <var_copy value="1" />'.$nl;
       }
     elsif ( lc($appdata->{environment}->{copy}) eq "no") 
       {
        $xml	.= '  <var_copy value="0" />'.$nl;
       }
    
    foreach my $e (sort keys %{$appdata->{environment}})
     {
       next if ($e eq 'copy');
       if (lc($appdata->{environment}->{$e}->{add}) eq "yes")
        {
	  $xml	.= sprintf '  <var_add name="%s" value="%s" />'.$nl,
	  	$appdata->{environment}->{$e}->{name},
		$appdata->{environment}->{$e}->{value};
	}
       if (lc($appdata->{environment}->{$e}->{append}) eq "yes")
        {
	  $xml	.= sprintf '  <var_append name="%s" value="%s" join="%s" />'.$nl,
	  	$appdata->{environment}->{$e}->{name},
		$appdata->{environment}->{$e}->{value},
		$appdata->{environment}->{$e}->{join} || ":";
	}
       if (lc($appdata->{environment}->{$e}->{insert}) eq "yes")
        {
	  $xml	.= sprintf '  <var_insert name="%s" value="%s" join="%s" />'.$nl,
	  	$appdata->{environment}->{$e}->{name},
		$appdata->{environment}->{$e}->{value},
		$appdata->{environment}->{$e}->{join} || ":";
	}
       if (lc($appdata->{environment}->{$e}->{delete}) eq "yes")
        {
	  $xml	.= sprintf '  <var_del name="%s" value="%s"   />'.$nl,
	  	$appdata->{environment}->{$e}->{name},
		$appdata->{environment}->{$e}->{value} ;
	}       
     }    
    $xml	.= ' </env>'.$nl;

    # exec section
    $xml	.= ' <exec>'.$nl;
    foreach my $exe (keys %{$appdata->{executable}})
     {
       $xml	.= sprintf '  <executable path="%s" version="%s" name="%s" smp="%s" extra_end="%s" extra_begin="%s" />'.$nl,
       			$appdata->{executable}->{$exe}->{path},
			$appdata->{executable}->{$exe}->{version} || 1,
			$appdata->{executable}->{$exe}->{name} || "",
			$appdata->{executable}->{$exe}->{smp_parallel} ,
			$appdata->{executable}->{$exe}->{extra_end} ,
			$appdata->{executable}->{$exe}->{extra_begin};
			
       $use_mpi = (1==1) if (lc($appdata->{executable}->{$exe}->{use_mpi}) eq "yes");          
     }
    
    if ($use_mpi) 
     { 
      foreach my $mpi (keys %{$appdata->{MPI}})
       {
         $xml	.= sprintf '  <run use_mpi_stack="%s" version="%s" />'.$nl,
       			$appdata->{MPI}->{$mpi}->{name},
			$appdata->{MPI}->{$mpi}->{version};	 
       }
     }

     # param sub-section
      foreach my $param (keys %{$appdata->{parameter}})
       {
         $xml	.= sprintf '  <param label="%s" name="%s" comment="%s" default_value="%s" />'.$nl,
       			$appdata->{parameter}->{$param}->{label},
       			$appdata->{parameter}->{$param}->{name},
			$appdata->{parameter}->{$param}->{desc},	 
			$appdata->{parameter}->{$param}->{value} || "";	 
       }

     # argument sub-section
      foreach my $arg (keys %{$appdata->{argument}})
       {
         $xml	.= sprintf '  <arg label="%s" name="%s" comment="%s" required="%s" input_file="%s" output_file="%s" />'.$nl,
       			$appdata->{argument}->{$arg}->{label},
       			$appdata->{argument}->{$arg}->{name},
			$appdata->{argument}->{$arg}->{desc},
			$appdata->{argument}->{$arg}->{mandatory},	 
			$appdata->{argument}->{$arg}->{input_file} ,	 
			$appdata->{argument}->{$arg}->{output_file}  ;	 
       }
          
    $xml	.= ' </exec>'.$nl;

    # mpi stack section    
    if ($use_mpi) 
     { 
      foreach my $mpi (keys %{$appdata->{MPI}})
       {
	 $xml	.= '  <mpi>'.$nl;
	 $xml	.= sprintf '   <stack name="%s" version="%s">'.$nl,
       			$appdata->{MPI}->{$mpi}->{name},
			$appdata->{MPI}->{$mpi}->{version};
	 $xml	.= sprintf '    <path>%s</path>'.$nl,
       			$appdata->{MPI}->{$mpi}->{path};
	 $xml	.= sprintf '    <mpi_init name="%s" args="%s" />'.$nl,
       			$appdata->{MPI}->{$mpi}->{init_name},
			$appdata->{MPI}->{$mpi}->{init_args};
	 $xml	.= sprintf '    <mpirun name="%s" args="%s" />'.$nl,
       			$appdata->{MPI}->{$mpi}->{mpirun},
			join(" ",
				 $appdata->{MPI}->{$mpi}->{ncpus},
				 $appdata->{MPI}->{$mpi}->{machinefile},
				 $appdata->{MPI}->{$mpi}->{verbose}
			    ) ; 	 
	 $xml	.= '   </stack>'.$nl;
	 $xml	.= '  </mpi>'.$nl;
	}
      }
    
    $xml	.= '</program>'.$nl;
    $c->stash->{appxml}	= $xml;
}

sub newapp : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    # short circuit for submitted forms
    if (($form->submitted eq 'Next') && $form->validate)
    {
      $c->session->{appname_value}=$c->req->params->{'appname'} ;
      $c->session->{appname_label}= 'Application Name';
      push @{ $c->session->{appfields} }, 'appname';
      $c->session->{appversion_value}=$c->req->params->{'appversion'} ;
      $c->session->{appversion_label}='Version Number';
      push @{ $c->session->{appfields} }, 'appversion';
      $c->session->{binpath_value}=$c->req->params->{'binpath'}  ;
      $c->session->{binpath_label}='Executable Location';
      push @{ $c->session->{appfields} }, 'binpath';
      $c->session->{derived_value}=$c->req->params->{'derived'}  ;
      $c->session->{derived_label}='Derived From';
      push @{ $c->session->{appfields} }, 'derived';
      $c->session->{changeable_value}=$c->req->params->{'changeable'}  ;
      $c->session->{changeable_label}='Changeable';
      push @{ $c->session->{appfields} }, 'changeable';
      $c->session->{usempi_value}=$c->req->params->{'usempi'}  ;
      $c->session->{usempi_label}='Use MPI';
      push @{ $c->session->{appfields} }, 'usempi';

      $c->response->redirect($c->uri_for('getparms'));
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->response->redirect($c->uri_for('/main'));
    }

    # get application/version data
    my ($ret,%apps,$k);
    my $appsdsn = "dbi:SQLite:dbname=db/apps.db";
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );

    $appsdb->db_search('table'  => 'apps');
    while ($ret = $appsdb->db_next)
     {
      if ($ret->{version})
       {
        $k      = sprintf "%s [v%s]",$ret->{appname},$ret->{version};
       }
       else
       {
        $k      = $ret->{appname};
        
       }
      $apps{$k} = $k;
     }
    $appsdb->db_close;
    
    $self->formbuilder->field(
        name    => 'appname',
        label   => 'Enter Application Name',
        required => 1
    );

    $self->formbuilder->field(
        name    => 'appversion',
        label   => 'Enter Version Number',
        required => 1
    );
    
    $self->formbuilder->field(
        name    => 'binpath',
        label   => 'Executable Location',
        type    => "file",
        required => 1
    );

    $self->formbuilder->field(
        name    => 'derived',
        label   => 'Derived From',        
        options => \%apps,
	type	=> "select",
        required => 0
    );

    $form->field(           
        name   => 'changeable',
        label   => 'Changeable',
        options => ['Yes','No'],
        value => ['Yes'],
        type   => 'radio'
    );
                
    $form->field(
        name   => 'usempi',
        label   => 'Use MPI',
        options => ['Yes','No'],
        value => ['Yes'],
        type   => 'radio'
    );

    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/apps/newapp.html';

}

sub getparms : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0); 

    my @app_data = @{ $c->session->{appfields} };
    my ($tlabel, $tfield, $tvalue, $tcomm);
    
    # get and display application data from sub newapp
    while ( @app_data ) {
       $tfield = shift( @app_data );
       $tlabel = $tfield . "_label";
       $tvalue = $tfield . "_value";
       # display data from previous page
       $form->field(
           name     => $tfield,
           label    => $c->session->{$tlabel},
           disabled => 1,
           value    => $c->session->{$tvalue}
       );
    }

    if ( defined($c->session->{appparms}->[0]) ){
       my @app_parms = @{ $c->session->{appparms} };
       # get and display parameter data from sub getparms
       while ( @app_parms ) {
          $tfield = shift( @app_parms );
          $tlabel = $tfield . "_name";
          $tcomm  = $tfield . "_comm";
          $tvalue = $tfield . "_value";
          $form->field(
             name     => $tfield,
             label    => $c->session->{$tlabel},
             comment  => $c->session->{$tcomm},
             disabled => 1,
             value    => $c->session->{$tvalue}
          );
       }    
    }

    #get data for one parameter

    $self->formbuilder->field(
        name    => 'parmname',
        label   => 'Parameter Name',
        comment => 'ex. NCPUS MEMORY -n',
        required => 0
    );
    
    $self->formbuilder->field(
        name    => 'parmcomm',
        label   => 'Parameter Description',
        comment => 'ex. Number of Steps',
        required => 0
    );

    $self->formbuilder->field(
        name    => 'parmdf',
        label   => 'Default Value',        
        required => 0
    );
    
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/apps/getparms.html';
    
    if ($form->submitted eq 'Add this Parameter' && $form->validate) {
      my ($pnum, $tparm, $tpname, $tpcomm, $tpvalue);
      if ( ! defined($c->session->{appparms}->[0]) ){
         $pnum = 1;
      }
      else {
         $pnum = scalar( @{ $c->session->{appparms} } ) + 1;
      }    
      
      $tparm  = "parm" . $pnum;
      $tpname = $tparm . "_name";
      $tpcomm = $tparm . "_comm";
      $tpvalue = $tparm . "_value";
      $c->session->{$tpname} =$c->req->params->{'parmname'} ;
      $c->session->{$tpcomm} =$c->req->params->{'parmcomm'}  ;
      $c->session->{$tpvalue}=$c->req->params->{'parmdf'}  ;
      push @{ $c->session->{appparms} }, $tparm;
      
      $c->response->redirect($c->uri_for('getparms'));
    }
    elsif ($form->submitted eq 'Done with Parameters') {
      $c->response->redirect($c->uri_for('getargs'));
    }
    elsif ($form->submitted eq 'Previous') {
      $c->response->redirect($c->uri_for('newapp'));
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->response->redirect($c->uri_for('/main'));
    }
}

sub getargs : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0);
    
    my @app_data = @{ $c->session->{appfields} };
    my ($tlabel, $tfield, $tvalue, $tcomm, $tvals);
    # get and display application data from sub newapp
    while ( @app_data ) {
       $tfield = shift( @app_data );
       $tlabel = $tfield . "_label";
       $tvalue = $tfield . "_value";
       $form->field(
           name     => $tfield,
           label    => $c->session->{$tlabel},
           disabled => 1,
           value    => $c->session->{$tvalue}
       );
    }

    if ( defined($c->session->{appparms}->[0]) ){
       my @app_parms = @{ $c->session->{appparms} };
       # get and display parameter data from sub getparms
       while ( @app_parms ) {
          $tfield = shift( @app_parms );
          $tlabel = $tfield . "_name";
          $tcomm  = $tfield . "_comm";
          $tvalue = $tfield . "_value";
          $form->field(
             name     => $tfield,
             label    => $c->session->{$tlabel},
             comment  => $c->session->{$tcomm},
             disabled => 1,
             value    => $c->session->{$tvalue}
          );
       }    
    }
    
    if ( defined($c->session->{appargs}->[0]) ){
       my @app_args = @{ $c->session->{appargs} };
       # get and display argument data from sub getargs
       while ( @app_args ) {
          $tfield = shift( @app_args );
          $tlabel = $tfield . "_name";
          $tcomm  = $tfield . "_comm";
          $tvalue = $tfield . "_value";
          $tvals  = $tfield . "_vals";
          $form->field(
             name     => $tfield,
             label    => $c->session->{$tlabel},
             comment  => $c->session->{$tcomm},
             disabled => 1,
             value    => $c->session->{$tvalue}
          );
          $form->field(
             name     => $tvals,
             label    => $c->session->{$tlabel},
             comment  => 'options selected',
             disabled => 1,
             value    => $c->session->{$tvals}
          );
       }
    }  
    
    #get data for one argument
    $self->formbuilder->field(
        name    => 'argname',
        label   => 'Argument Name',
        comment => "ex. -n",
        required => 0
    );   
    $self->formbuilder->field(
        name    => 'argcomm',
        label   => 'Argument Description',
        comment  => "ex. number of steps",
        required => 0
    );
    $self->formbuilder->field(
        name    => 'argvalue',
        label   => 'Argument Value',
        comment  => 'enter value if needed',        
        required => 0
    );
    $form->field(
        name   => 'argreq',
        label   => 'Required',
        options => ['Yes','No'],
        value => ['No'],
        type   => 'radio'
    );
        $form->field(
        name   => 'arginfile',
        label   => 'Input File',
        options => ['Yes','No'],
        value => ['No'],
        type   => 'radio'
    );
    $form->field(
        name   => 'argoutfile',
        label   => 'Output File',
        options => ['Yes','No'],
        value => ['No'],
        type   => 'radio'
    );
    
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/apps/getargs.html';
    
    if ($form->submitted eq 'Add this Argument' && $form->validate) {
      my ($anum, $targ, $taname, $tacomm, $tavalue, $tavals);
      my ($tareq, $taifile, $taofile);
      if ( ! defined($c->session->{appargs}->[0]) ){
         $anum = 1;
      }
      else {
         $anum = scalar( @{ $c->session->{appargs} } ) + 1;
      }    
      
      $targ    = "arg" . $anum;
      $taname  = $targ . "_name";
      $tacomm  = $targ . "_comm";
      $tavalue = $targ . "_value";
      $tareq   = $targ . "_req";
      $taifile = $targ . "_ifile";
      $taofile = $targ . "_ofile";
      $tavals  = $targ . "_vals";
      $c->session->{$taname}  =$c->req->params->{'argname'} ;
      $c->session->{$tacomm}  =$c->req->params->{'argcomm'}  ;
      $c->session->{$tavalue} =$c->req->params->{'argvalue'}  ;
      $c->session->{$tareq}   =$c->req->params->{'argreq'}  ;
      $c->session->{$taifile} =$c->req->params->{'arginfile'}  ;
      $c->session->{$taofile} =$c->req->params->{'argoutfile'}  ;
      $c->session->{$tavals}  =sprintf("req=%s ifile=%s ofile=%s",
                                      $c->req->params->{'argreq'},
                                      $c->req->params->{'arginfile'},
                                      $c->req->params->{'argoutfile'} );
      push @{ $c->session->{appargs} }, $targ;
       
      $c->response->redirect($c->uri_for('getargs'));
            
    }
    elsif ($form->submitted eq 'Done with Arguments') {
      $c->response->redirect($c->uri_for('review'));
    }
    elsif ($form->submitted eq 'Previous') {
      $c->response->redirect($c->uri_for('getparms'));
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->response->redirect($c->uri_for('/main'));
    }
}

sub review : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    use Date::Format;
    $form->stylesheet(1);
    $form->debug(0); 
    
    my @app_data = @{ $c->session->{appfields} };
    my ($tlabel, $tfield, $tvalue, $tcomm, $tvals, $i, $tval);
    my ($targ, $tareq, $taifile, $taofile);
    # get and display application data from sub newapp
    while ( @app_data ) {
       $tfield = shift( @app_data );
       $tlabel = $tfield . "_label";
       $tvalue = $tfield . "_value";
       if ( $tfield eq 'changeable' || $tfield eq 'usempi' ) {
         $form->field(
             name     => $tfield,
             label    => $c->session->{$tlabel},
             options => ['Yes','No'],
             type   => 'radio',
             disabled => 0,
             value    => $c->session->{$tvalue}
         );
       }
       else {       
         $form->field(
             name     => $tfield,
             label    => $c->session->{$tlabel},
             disabled => 0,
             value    => $c->session->{$tvalue}
         );
       }
    }

    my @app_parms = @{ $c->session->{appparms} };
    # get and display parameter data from sub getparms
    $i = 0;
    while ( @app_parms ) {
       $tfield = shift( @app_parms );
       $tlabel = $tfield . "_name";
       $tcomm  = $tfield . "_comm";
       $tvalue = $tfield . "_value";
       $form->field(
          name     => "parmname[$i]",
          label    => "Parameter[$i] Name",
          value    => $c->session->{$tlabel},
          disabled => 0
       );
       $form->field(
          name     => "parmcomm[$i]",
          label    => "Description",
          value    => $c->session->{$tcomm},
          disabled => 0
       );
       $form->field(
          name     => "parmvalue[$i]",
          label    => "Default Value",
          value    => $c->session->{$tvalue},
          disabled => 0
       );
       $i++;
    }

    my @app_args = @{ $c->session->{appargs} };
    # get and display argument data from sub getargs
    $i = 0;
    while ( @app_args ) {
       $tfield = shift( @app_args );
       $tlabel = $tfield . "_name";
       $tcomm  = $tfield . "_comm";
       $tvalue = $tfield . "_value";
       $tareq   = $tfield . "_req";
       $taifile = $tfield . "_ifile";
       $taofile = $tfield . "_ofile";
       $form->field(
          name     => "argname[$i]",
          label    => "Argument[$i] Name",
          value    => $c->session->{$tlabel},
          disabled => 0
       );
       $form->field(
          name     => "argcomm[$i]",
          label    => "Description",
          value    => $c->session->{$tcomm},
          disabled => 0
       ); 
       $form->field(
          name     => "argvalue[$i]",
          label    => "Value",
          value    => $c->session->{$tvalue},
          disabled => 0
       );         
       if ( $c->session->{$tareq} == 1 ) { $tval = "Yes"; }
       else { $tval = "No"; }
       $form->field(
          name     => "argreq[$i]",
          label    => "Required",
          options => ['Yes','No'],
          value    => $tval,
          type   => 'radio',
          disabled => 0
       );       
       $form->field(
          name     => "arginfile[$i]",
          label    => "Input File",
          options => ['Yes','No'],
          value    => $c->session->{$taifile},
          type   => 'radio',
          disabled => 0
       );
       $form->field(
          name     => "argoutfile[$i]",
          label    => "Output File",
          options => ['Yes','No'],
          value    => $c->session->{$taofile},
          type   => 'radio',
          disabled => 0
       );                  
       $i++
    }  
    
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/apps/review.html';
    
    if ($form->submitted eq 'Yes' && $form->validate) {
      my $appxml = "";
      
      $appxml .= sprintf("<program name=\"%s\" index=\"1\" version=\"%s\" >\n",
                 $c->session->{appname_value},
                 $c->session->{appversion_value},
      );
      $appxml .= sprintf(" <env>\n");
      $appxml .= sprintf("  <var_copy                 value=\"1\" />\n");
      
      $appxml .= sprintf(" </env>\n");
      $appxml .= sprintf(" <exec>\n");
      #$appxml .= sprintf("  <run use_mpi_stack=\"openmpi\" version=\"1.2.4\" />\n");
      
      # if there are any parameters, print one line for each one
      if ( defined($c->session->{appparms}->[0]) ) {
         @app_parms = @{ $c->session->{appparms} };
         while ( @app_parms ) {
           $tfield = shift( @app_parms );
           $tlabel = $tfield . "_name";
           $tcomm  = $tfield . "_comm";
           $tvalue = $tfield . "_value";
           $appxml .= sprintf("  <param label=\"%s\" name=\"%s\" comment=\"%s\" default_value=\"%s\" />\n",
                 $tfield,
                 $c->session->{$tlabel},
                 $c->session->{$tcomm},
                 $c->session->{$tvalue} );
         }
      }
      # if there are any arguments, print one line for each one
      if ( defined($c->session->{appargs}->[0]) ) {
         @app_args = @{ $c->session->{appargs} };
         while ( @app_args ) {
           $tfield  = shift( @app_args );
           $tlabel  = $tfield . "_name";
           $tcomm   = $tfield . "_comm";
           $tvalue  = $tfield . "_value";
           $tareq   = $tfield . "_req";
           $taifile = $tfield . "_ifile";
           $taofile = $tfield . "_ofile";
           $appxml .= sprintf("  <arg label=\"%s\" name=\"%s\" comment=\"%s\" required=\"%s\" input_file=\"%s\" output_file=\"%s\" />\n",
                 $tfield,
                 $c->session->{$tlabel},
                 $c->session->{$tcomm},
                 $c->session->{$tareq},
                 $c->session->{$taifile},
                 $c->session->{$taofile}
           );
         }
      }
     
      $appxml .= sprintf(" </exec>\n");
      $appxml .= sprintf(" <mpi>\n");
      $appxml .= sprintf("  <stack name=\"openmpi\" version=\"1.2.4\">\n");
      $appxml .= sprintf("   <path>/opt/openmpi124/bin</path>\n");
      $appxml .= sprintf("   <mpi_init name=\"\" args=\"\" />\n");
      $appxml .= sprintf("   <mpirun name=\"mpirun\" args=\"-np _NCPUS_\" />\n");
      $appxml .= sprintf("  </stack>\n");
      $appxml .= sprintf(" </mpi>\n");
      $appxml .= sprintf(" <data_motion>\n");
      $appxml .= sprintf(" </data_motion>\n");
      $appxml .= sprintf("</program>\n");
      
      $appxml =~ s/\"/\"\"/g;
      
      my $app_creation_date = time2str("%c", time);
      my $app_owner_uid = getpwnam($c->user->get("username"));
      my $dsn = "dbi:SQLite:dbname=db/apps.db";
      my $sice = DBIx::SimplePerl->new;
      $sice->{debug} = 1;
      $sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");      
      
      my $rc = $sice->db_add( table => "apps", 
          columns => { appname      => $c->session->{appname_value},
                       serial       => 1,
                       version      => $c->session->{appversion_value},
                       owner_id     => $app_owner_uid,
                       changable    => $c->session->{changeable_value},
                       date_added   => $app_creation_date,
                       derived_from => $c->session->{derived_value},
                       app_xml      => $appxml
                     }    
      );
            
      $sice->db_close; 

      $c->response->redirect($c->uri_for('list'));
    }
    elsif ($form->submitted eq 'No') {
      $c->response->redirect($c->uri_for('getargs'));
    }
}

sub appdata : Local Form {
    my ($self, $c, $field) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0);
    use DBIx::SimplePerl;
    use Data::Dumper; 

    my (%hash,$search_term,%outgoing,%results,$rt,$count,$current_version);
    my ($index_current_version,@fields,$appid);
    
    
    @fields = @{$c->req->args};
    $c->log->debug('apps/appdata: args  = '.join(":",@fields));
    my $appsdb = DBIx::SimplePerl->new;

     
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );
    foreach $search_term (@fields)
     {
        $c->log->debug('apps/appdata: search_term= '.$search_term);
        if ($search_term =~ /(.*)=(.*)/)
         {
            $hash{$1} = $2;
            $appid = $2;
            $c->log->debug('apps/appdata: search term= '.$1.' value = '.$2);
         }
     }
    $c->log->debug('apps/appdata: hash = '.Dumper(\%hash));
    $appsdb->db_search('table'  => 'apps', 'search' => \%hash );
    
    $rt = $appsdb->db_next;
    $appsdb->db_close;
    
    my $axml = $rt->{'app_xml'};
    my $xml = new XML::Smart($axml);
    my ($i, $tlabel, $tval);

    # get application information

    my @appdata = qw(appname version owner_id changable date_added derived_from);

    foreach (@appdata) {
      $tlabel = $_;
      $tlabel =~ tr/\_/ /;
      $form->field(
         name     => $_,
         label    => $tlabel,
         disabled => 0,
         fieldset => "appinfo",
         value    => $rt->{$_}
      );
    }

    # get all the application params

    my ($paramname, @paramdata);
    $i = 0;
    $paramname = $xml->{program}{exec}{param}[ $i ]{name};

    while ( $paramname ne "" ) {
      @paramdata = qw(name value);
      foreach (@paramdata) {
         $tval = "".$xml->{program}{exec}{param}[ $i ]{name};
         $form->field(
            name     => "parmname[$i]",
            label    => "Parameter[$i] Name",
            value    => $tval,
            fieldset => "parm",
            disabled => 0
         );
         $tval = "".$xml->{program}{exec}{param}[ $i ]{comment}; 
         $form->field(
            name     => "parmcomm[$i]",
            label    => "Description",
            value    => $tval,
            fieldset => "parm",
            disabled => 0
         );
         $tval = "".$xml->{program}{exec}{param}[ $i ]{default_value}; 
         $form->field(
            name     => "parmvalue[$i]",
            label    => "Default Value",
            value    => $tval,
            fieldset => "parm",
            disabled => 0
         );
      }
      $i++;
      $paramname = $xml->{program}{exec}{param}[ $i ]{name};
    }

   # get all the application args

    my ($argname, @argdata);
    $i = 0;
    $argname = $xml->{program}{exec}{arg}[ $i ]{name};

    while ( $argname ne "" ) {
         $tval = "".$xml->{program}{exec}{arg}[ $i ]{name};
         $form->field(
            name     => "argname[$i]",
            label    => "Argument[$i] Name",
            value    => $tval,
            fieldset => "arg",
            disabled => 0
         );
         $tval = "".$xml->{program}{exec}{arg}[ $i ]{comment};
         $form->field(
            name     => "argcomm[$i]",
            label    => "Description",
            value    => $tval,
            fieldset => "arg",
            disabled => 0
         ); 
         $form->field(
            name     => "argvalue[$i]",
            label    => "Value",
            value    => "",
            fieldset => "arg",
            disabled => 0
         );
         if ( $xml->{program}{exec}{arg}[ $i ]{required} == 1 ) { $tval = "Yes"; }
         else { $tval = "No"; }
         $form->field(
            name     => "argreq[$i]",
            label    => "Required",
            options => ['Yes','No'],
            value    => $tval,
            fieldset => "arg",
            type   => 'radio',
            disabled => 0
         );
         $tval = "".$xml->{program}{exec}{arg}[ $i ]{input_file}; 
         $form->field(
            name     => "arginfile[$i]",
            label    => "Input File",
            options => ['Yes','No'],
            value    => $tval,
            fieldset => "arg",
            type   => 'radio',
            disabled => 0
         );
         $tval = "".$xml->{program}{exec}{arg}[ $i ]{output_file};
         $form->field(
            name     => "argoutfile[$i]",
            label    => "Output File",
            options => ['Yes','No'],
            value    => $tval,
            fieldset => "arg",
            type   => 'radio',
            disabled => 0
         );                                       
      $i++;
      $argname = $xml->{program}{exec}{arg}[ $i ]{name};
    }

    $c->stash->{app}  = $rt->{appname};
    $c->stash->{vers}  = $rt->{version};
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/apps/appdata.html';
    
    if ($form->submitted eq 'Return to Application List')
    {
      $c->response->redirect($c->uri_for('modify'));
    }
    elsif ($form->submitted eq 'Update This Application') {
      $c->session->{appname}=$c->req->params->{'appname'};
      $c->session->{appversion}=$c->req->params->{'version'};
      $c->session->{appowner}=$c->req->params->{'owner_id'};
      $c->session->{appchange}=$c->req->params->{'changable'};
      $c->session->{appdateadd}=$c->req->params->{'date_added'};
      $c->session->{appderived}=$c->req->params->{'derived_from'};
      # get parameters
      $i = 0;
      $paramname = $c->req->params->{"parmname[$i]"};
      while ( $paramname ne "" ) {
         $c->session->{"parmname[$i]"}=$paramname;
         $c->session->{"parmcomm[$i]"}=$c->req->params->{"parmcomm[$i]"};
         $c->session->{"parmvalue[$i]"}=$c->req->params->{"parmvalue[$i]"};
         $i++;
         $paramname = $c->req->params->{"parmname[$i]"};
      }
      # get arguments
      $i = 0;
      $argname = $c->req->params->{"argname[$i]"};
      while ( $argname ne "" ) {
         $c->session->{"argname[$i]"}=$argname;
         $c->session->{"argcomm[$i]"}=$c->req->params->{"argcomm[$i]"};
         $c->session->{"argvalue[$i]"}=$c->req->params->{"argvalue[$i]"};
         $c->session->{"argreq[$i]"}=$c->req->params->{"argreq[$i]"};
         $c->session->{"arginfile[$i]"}=$c->req->params->{"arginfile[$i]"};
         $c->session->{"argoutfile[$i]"}=$c->req->params->{"argoutfile[$i]"};
         $i++;
         $argname = $c->req->params->{"argname[$i]"};
      }
      $self->_appxml( $c );
      #$c->response->redirect($c->uri_for('appxml'));
      $c->response->redirect($c->uri_for('appupdate/'.$appid));
    }
}

sub _appxml : Private {
    my ($self, $c) = @_;
    use Data::Dumper;
    my ($label, $i);
    my $appxml = "";
    my $nl = "\n";
    $appxml .= sprintf('<program name="%s" index="12345" version="%s" >'.$nl,
                 $c->session->{appname},
                 $c->session->{appversion},
    );
    $appxml .= sprintf(" <env>\n");
    $appxml .= sprintf("  <var_copy                 value=\"1\" />\n");
    $appxml .= sprintf("  <var_add     name=\"alpha\"     value=\"5\" />\n");     
    $appxml .= sprintf("  <var_add     name=\"beta\"     value=\"4\" />\n");
    $appxml .= sprintf("  <var_add     name=\"gamma\"     value=\"1\" />\n");
    $appxml .= sprintf("  <var_append     name=\"PATH\"     value=\"/usr/strange/bin\" join=\":\" />\n");
    $appxml .= sprintf("  <var_insert     name=\"PATH\"     value=\"/opt/bin\" join=\":\" />\n");
    $appxml .= sprintf("  <var_del       name=\"PGI_BITS\" />\n");
    $appxml .= sprintf(" </env>\n");
    $appxml .= sprintf(" <exec>\n");
    $appxml .= sprintf("  <run use_mpi_stack=\"openmpi\" version=\"1.2.4\" />\n");
      
    # if there are any parameters, print one line for each one
    $i = 0;
    while ( defined($c->session->{"parmname[$i]"}) ) {
       $label = "parm".$i;
       $appxml .= sprintf("  <param label=\"%s\" name=\"%s\" comment=\"%s\" default_value=\"%s\" />\n",
          $label,
          $c->session->{"parmname[$i]"},
          $c->session->{"parmcomm[$i]"},
          $c->session->{"parmvalue[$i]"} );
       $i++;
    }
    # if there are any arguments, print one line for each one
    $i = 0;
    while ( defined($c->session->{"argname[$i]"}) ) {
       $label = "arg".$i;
       $appxml .= sprintf("  <arg label=\"%s\" name=\"%s\" comment=\"%s\" required=\"%s\" input_file=\"%s\" output_file=\"%s\" />\n",
          $label,
          $c->session->{"argname[$i]"},
          $c->session->{"argcomm[$i]"},
          $c->session->{"argreq[$i]"},
          $c->session->{"arginfile[$i]"},
          $c->session->{"argoutfile[$i]"} );
       $i++;
    }
     
    $appxml .= sprintf(" </exec>\n");
    $appxml .= sprintf(" <mpi>\n");
    $appxml .= sprintf("  <stack name=\"openmpi\" version=\"1.2.4\">\n");
    $appxml .= sprintf("   <path>/opt/openmpi124/bin</path>\n");
    $appxml .= sprintf("   <mpi_init name=\"\" args=\"\" />\n");
    $appxml .= sprintf("   <mpirun name=\"mpirun\" args=\"-np _NCPUS_\" />\n");
    $appxml .= sprintf("  </stack>\n");
    $appxml .= sprintf(" </mpi>\n");
    $appxml .= sprintf(" <data_motion>\n");
    $appxml .= sprintf(" </data_motion>\n");
    $appxml .= sprintf("</program>\n");
      
    #$appxml =~ s/\"/\"\"/g;
    $c->log->debug('apps/appxml: appxml = '.Dumper($appxml)); 
    $c->session->{appxml} = $appxml;     
}

sub appupdate : Local {
    my ($self, $c, $id) = @_;
    
    use DBIx::SimplePerl;
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->{debug}=1;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );
    
    $appsdb->db_update( table => "apps", search => { id => $id },
         columns => { appname      => $c->session->{appname},
                      version      => $c->session->{appversion},
                      owner_id     => $c->session->{appowner},
                      changable    => $c->session->{appchange},
                      date_added   => $c->session->{appdateadd},
                      derived_from => $c->session->{appderived} | 0,
                      app_xml      => $c->session->{appxml} 
         }
    );

    $appsdb->db_close;
    
    $c->response->redirect($c->uri_for('list'));
}
=head1 AUTHOR

Joe Landman,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
