package DragonFlyGUI::Controller::Jobs;

use strict;
use warnings;
use base 'Catalyst::Controller::FormBuilder';

=head1 NAME

DragonFlyGUI::Controller::Jobs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::Jobs in Jobs.');
}

sub xml : Local {
    use DBIx::SimplePerl;

    my ($self, $c, $id) = @_;
    my $hash;

    my $jobsdb	= DBIx::SimplePerl->new;
    
    $jobsdb->{debug}	= 1;
    $c->log->debug('Jobs::xml '.$c->config->{jobdb}->{dsn});
    $jobsdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );

    $jobsdb->db_search('table'  => 'jobs', 'search' => { id => $id } );
    $hash=$jobsdb->db_next;
    $jobsdb->db_close;
    $c->stash->{xml} = $hash;
    $c->stash->{template}       = '/jobs/xml.html';
}

sub list : Local  {
    my ($self, $c) = @_;
    #my $form = $self->formbuilder;
    #$c->stash->{forms}    = $form;
    #$form->stylesheet(1);
    #$form->debug(0);
    use DBIx::SimplePerl;

    my $jobsdb	= DBIx::SimplePerl->new;
    my $hash;
    $jobsdb->{debug}	= 1;
    $c->log->debug('jobs/xml '.$c->config->{jobdb}->{dsn});
    $jobsdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );


    $jobsdb->db_search('table'  => 'jobs');
    my $q = $jobsdb->{_sth}->fetchall_hashref('id');

    $jobsdb->db_close;
    $c->stash->{jobs} = $q;

    $c->stash->{template} = 'jobs/list.html';
}

sub list_one : Local Form {
    use DBIx::SimplePerl;

    my ($self, $c, $id) = @_;
    my $form = $self->formbuilder;
    $c->stash->{forms}    = $form;
    $form->stylesheet(1);
    $form->debug(0);
    my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    my $sice = DBIx::SimplePerl->new;
    $sice->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );


    $sice->db_search('table'  => 'jobs', 'search' => { id => $id } );
    my $hash = $sice->{_sth}->fetchrow_hashref();

    $c->stash->{jobs}     = $hash;
    $c->stash->{template} = 'jobs/list_one.html';

    if ($form->submitted eq 'Return to Job List') {
      $c->response->redirect($c->uri_for('list'));
    }
    elsif ($form->submitted eq 'Delete This Job') {
      $c->response->redirect($c->uri_for('delete/') . $id);
    }
    elsif ($form->submitted eq 'Update This Job' && $form->validate) {
      my $field = $form->fields;
      my $upjob = $field->{jobxml};
      $upjob =~ s/"/""/g;
      $sice->db_update( table => "jobs", search => { id => $id },
                        columns => { jobxml => $upjob }
                      );
      $c->response->redirect($c->uri_for('list'));
    }
    $sice->db_close;
}

sub delete : Private {
    # $id = primary key to delete
    my ($self, $c, $id) = @_;
    my $retc;
    if (!$id) { $c->response->redirect($c->uri_for('/main')); }
    # Search for the record and then delete it
    #$c->model('DragonFlyGUIDB::Job')->search({id => $id})->delete_all;
    my $jobdb   = DBIx::SimplePerl->new;
    $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
    $retc   = $jobdb->db_delete
                        ('table'  => 'jobs',
                          search => { 'id' => $id }
                        );
    $jobdb->db_close;
    # Forward to the list action/method in this controller    
}

sub newjob0 : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder;
    $form->stylesheet(1);
    #$form->debug(0);
    my ($ret,%apps,$k,$x,$projectdb);
    $self->formbuilder->new(debug=>0);
    
    my $appsdb = DBIx::SimplePerl->new;
    
    
    # short circuit for submitted forms
    if (($form->submitted eq 'Next') && $form->validate)
    {      
      $c->session->{project}=$c->req->params->{'project'} ;
      $c->session->{jobname}=$c->req->params->{'jobname'} ;
      $c->session->{application}=$c->req->params->{'application'}  ;
      $c->log->debug('jobs/newjob0: saving form data into session');
      $c->log->debug('jobs/newjob0:  project ='. $c->req->params->{'project'});
      $c->log->debug('jobs/newjob0:  jobname ='. $c->req->params->{'jobname'});
      $c->log->debug('jobs/newjob0:  application ='.$c->req->params->{'application'}  );
      $c->response->redirect($c->uri_for('newjob1'));       
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->response->redirect($c->uri_for('/main'));
    }
     
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
    
    $projectdb	= DBIx::SimplePerl->new;
    $c->log->debug('Jobs::newjob0 projectdb dsn'.$c->config->{projectdb}->{dsn});
    $projectdb->db_open(
		    'dsn'	=> $c->config->{projectdb}->{dsn},
		    'dbuser'	=> $c->config->{projectdb}->{dbuser},
		    'dbpass'	=> $c->config->{projectdb}->{dbpass}		
                   );
    $projectdb->db_search( 'table'	=> 'projects' );
    my @options;
    while ($x = $projectdb->db_next) { push @options,[$x->{project_id} , $x->{project_id}] };
    $projectdb->db_close;
    
    $self->formbuilder->field(
        name    => 'project',
        label   => 'Select Project',
        options => \@options,
	type	=> "select",
        required => 1
    );

    $self->formbuilder->field(
        name    => 'jobname',
        label   => 'Enter Job Name',
        required => 1
    );

    $self->formbuilder->field(
        name    => 'application',
        label   => 'Select Application',
        type    => 'select',
        options => \%apps,
        required => 1
    );
    
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/jobs/newjob0.html';
    
    
}

sub newjob1 : Local Form {
    my ( $self, $c ) = @_;
    my %job_data;
    use DBIx::SimplePerl;
    use Data::Dumper;
    use XML::Smart;
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    my (%input_files);
    $ua->timeout(30);
    $ua->env_proxy;
    
   
    my $sice = DBIx::SimplePerl->new;
    my ($ret,%apps,$k,$app,$ver,$field,$application,$jobname);
    my ($project_name,$retc,$xml,$job_data);
    my (%results,%DF_app,$apploc);
    my ($project_query,$project_data_repository_uri,$response);
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0);
    
    $c->session->{project}=$c->req->params->{'project'} | $c->session->{project} ;
    $c->session->{jobname}=$c->req->params->{'jobname'} | $c->session->{jobname};
    $c->session->{application}=$c->req->params->{'application'}| $c->session->{application}  ;
 
    # get project information from project DB
    my $projectdb	= DBIx::SimplePerl->new;
    $projectdb->{debug}	= 1;
    $c->log->debug('Jobs::newjob1 projectdb dsn'.$c->config->{projectdb}->{dsn});
    $projectdb->db_open(
		    'dsn'	=> $c->config->{projectdb}->{dsn},
		    'dbuser'	=> $c->config->{projectdb}->{dbuser},
		    'dbpass'	=> $c->config->{projectdb}->{dbpass}		
                   );
     
    $c->log->debug('jobs/newjob1: testing for form completion');
    if (($form->submitted eq 'Next' ) && $form->validate)
    {
      $c->log->debug('jobs/newjob1: form is complete, going to newjob2');
       
      foreach my $par (keys %{$c->req->body_params})
       {
        if ($par =~ /\[argument\]\s(.*)/)
         {
          $c->session->{arguments}->{$1} = $c->req->body_params->{$par};
         }
        elsif ($par =~ /\[parameter\]\s(.*)/)
         {
          $c->session->{parameters}->{$1} = $c->req->body_params->{$par};
         }
        else
         {
          $c->session->{$par} = $c->req->body_params->{$par};
         }
       }
      $c->response->redirect('review');
    }
    elsif ($form->submitted eq 'Previous') {
     $c->log->debug('jobs/newjob1: returning to newjob0');
     $c->response->redirect('newjob0');
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->log->debug('jobs/newjob1: returning to main');
      $c->response->redirect($c->uri_for('/main'));
    }
    
    $projectdb->db_search(
    			  'table'	=> 'projects', 
			  'search'	=> { 
			  		    'project_id' => $c->session->{project} 
					   } 
			 );
    # project names are unique, so that the first one is the right one ...
    $project_query	= $projectdb->db_next;
    $project_data_repository_uri	= $project_query->{project_uri_xml};

    $c->log->debug('Jobs::newjob1: project_uri='.$project_data_repository_uri);
  
    $projectdb->db_close;
    $c->session->{project_uri}	= $project_query->{project_uri_xml};
    
    $project_name   = $c->session->{project};
    $jobname        = $c->session->{jobname};
    $application    = $c->session->{application};
    $job_data->{project}    = $project_name ;
    $job_data->{jobname}    = $jobname ;
    $job_data->{application}= $application ;
    $c->log->debug('jobs/newjob1: application = '.$application);
    $c->log->debug('jobs/newjob1:     jobname = '.$jobname);
    $c->log->debug('jobs/newjob1: project name= '.$project_name);
    
    if ( 1 || ($c->session->{appxml} eq ""))
     {
    #my $appsdsn = "dbi:SQLite:dbname=db/apps.db";
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->{debug}=1;
    $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                   );
    
    if ($application =~ /\[v(\S+)\]/)
       {
        $ver    = $1;
        $application =~ s/\[v\S+\]//g;
       }
    $app    = $application;
    $app    =~ s/\s+$//g;  #remove trailing blanks
    $c->log->debug('jobs/newjob1: updated app = '.$app);
    $c->log->debug('jobs/newjob1: updated ver = '.$ver);
    $appsdb->{debug}=1;
    if (defined($ver))
     {
      $retc = $appsdb->db_search
                        ('table'  => 'apps',
                          search =>
                            {
                                'appname' => $app,
                                'version' => $ver
                            }
                        );
      $c->log->debug('jobs/newjob1: (simple) query = '.Dumper($retc));
      my $x    = $appsdb->db_next;     
      $apploc = $x->{app_xml};
     }
    else
     {
       $retc = $appsdb->db_search('table'  => 'apps',
                         search =>
                          {
                            'appname' => $application
                          });
       $c->log->debug('jobs/newjob1: (complex) query = '.Dumper($retc));
       my $count=0;
       my $index_current_version  = 0;
       
        my $current_version;
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
      %DF_app   = %{$results{$index_current_version}} ;
      $c->log->debug('jobs/newjob1: (complex) app = '.$app);
      $c->log->debug('jobs/newjob1: (complex) ver = '.$ver);
      $appsdb->db_close;
      $apploc = $DF_app{app_xml};
      }
      
     }
    else
     { $apploc = $c->session->{appxml} ;}
    
    $c->session->{appxml}=$apploc;
    $c->log->debug('jobs/newjob1: application XML = '.$apploc);
 
   

    $xml = XML::Smart->new($apploc);
 
    my $prog_name =    $xml->{program}{name};
    my $prog_index =   $xml->{program}{index};
    my $prog_version = $xml->{program}{version};

    $job_data->{prog_name} = $xml->{program}{name}->content;
    $job_data->{prog_index} = $xml->{program}{index}->content;
    $job_data->{prog_version} = $xml->{program}{version}->content;

    
    $form->field(
        name    => 'project',
        label   => 'Project',
        disabled => 1,
        value => $project_name
    );
    $form->field(
        name    => 'jobname',
        label   => 'Job Name',
        disabled => 1,
        value => $jobname
    );
    $form->field(
        name    => 'application',
        label   => 'Application',
        disabled => 1,
        value => $application
    );

    # create input form field for each application parameter

    my ($par, $pdefval, $plabel, $pcomment, $pname, $prequired);
    my @app_vals;
    
    # get list of possible input files from data repository
    # uri
    
    $c->log->debug('Jobs:newjob1  data repository uri = '.$c->session->{project_uri});
    $response = $ua->get($c->session->{project_uri});
    
    if ($response->is_success) 
     {	
        my $filelist	= $response->content;
	$c->log->debug('Jobs:newjob1  data repository file list return = '.$filelist);
	my $filexml	= XML::Smart->new($filelist);
	foreach my $file (@{$filexml->{files}{file}} )
         {
	   $c->log->debug('Jobs:newjob1 adding file='.$file->{name}->content.' to data structure');
	   $input_files{$file->{download_abspath}->content} = $file->{name}->content;
	 }
     }
    
    $c->log->debug('Jobs:newjob1  Dump of file list data structure = '.Dumper(\%input_files));
    
    foreach $par (@{$xml->{program}{exec}{param}}  )
    {
         
      $c->log->debug('jobs/newjob1: in parameter parsing ...');
      $c->log->debug('jobs/newjob1:      name  = '.$par->{name}->content);
      $c->log->debug('jobs/newjob1:     value  = '.$par->{default_value}->content);
      $c->log->debug('jobs/newjob1:     label  = '.$par->{label}->content);
      $c->log->debug('jobs/newjob1:   comment  = '.$par->{comment}->content);

      $self->formbuilder->field(
         name     => "[parameter] " . $par->{label}->content,
         label    => "[parameter] " . $par->{name}->content ,
         comment  => $par->{comment}->content, 
         value    => $par->{default_value}->content,
         required => $par->{required}->content 
      );
      $job_data->{$par->{name}->content} = $par->{default_value}->content;       
    }
    
    # create input form field for each application argument

    my ($alabel, $aname, $acomment, $arequired, $ainfile, $aoutfile);
    my $targ;

    $c->log->debug('jobs/newjob1: in argument parsing ...');
    foreach $targ (@{$xml->{program}{exec}{arg}})
     {
      $aname    =  $targ->{name}->content;
      $acomment =  $targ->{comment}->content;
      $alabel   =  $targ->{label}->content;
      $arequired=  (lc($targ->{required}->content) eq "no") ? 0 : 1;
      $ainfile  =  $targ->{input_file}->content;
      $aoutfile =  $targ->{output_file}->content;
      $c->log->debug('jobs/newjob1:      name  = '.$aname);
      $c->log->debug('jobs/newjob1:     label  = '.$alabel);
      $c->log->debug('jobs/newjob1:   comment  = '.$acomment);
      $c->log->debug('jobs/newjob1:   input    = '.$ainfile);
      $c->log->debug('jobs/newjob1:   req      = '.$arequired);

      if ((lc($ainfile) eq "no"))
	 {
	  $c->log->debug('jobs/newjob1: field = '.$aname);
          $self->formbuilder->field(
             name     => "[argument] ".$aname,
             label    => $alabel,      
             comment  => $acomment,      
             required => $arequired
          );
	 }
	 
      if ((lc($ainfile) eq "yes"))
	 {
	   $c->log->debug('jobs/newjob1: inputfile = '.$aname);
           $self->formbuilder->field(
             name     => "[argument] ".$aname,
             label    => $alabel,      
             comment  => $acomment,      
             required => $arequired,
	     options  => \%input_files,
	     type	    => "select"

          );
          $job_data->{$alabel} = "";

	 }
    }
    
    $c->stash->{forms}      = $form;
    $c->stash->{template}   = '/jobs/newjob1.html';
        
}

sub _stub : Private {
    my ( $self, $c );
    
    $c->response->body('Matched DragonFlyGUI::Controller::Jobs::_stub');
}

sub review : Local Form {
    my ( $self, $c, @job_data_array ) = @_;
    my %job_data = @job_data_array;
    use Date::Format;
    use XML::Smart;
    use DBIx::SimplePerl;
    use Time::Local;
    
    my ($xml,$dsn,$apploc);
    
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0);
    
    $c->log->debug('jobs/review: session dump = '.Dumper($c->session));
    $c->log->debug('jobs/review: project = '.Dumper($c->session->{project}));
    $c->log->debug('jobs/review: application = '.Dumper($c->session->{application}));
    $c->log->debug('jobs/review: jobname = '.Dumper($c->session->{jobname}));
    $c->log->debug('jobs/review: ncpus = '.Dumper($c->session->{parameters}->{ncpus}));
    $c->log->debug('jobs/review: n = '.Dumper($c->session->{arguments}->{-n}));
    $c->log->debug('jobs/review: out = '.Dumper($c->session->{arguments}->{-out}));
    $c->log->debug('jobs/review: in = '.Dumper($c->session->{arguments}->{-in}));
    $c->log->debug('jobs/review: debug = '.Dumper($c->session->{arguments}->{-debug}));
    $c->log->debug('jobs/review: params dump = '.Dumper($c->req->body_params));
    $c->session->{project}=$c->req->params->{'project'} | $c->session->{project} ;
    $c->session->{jobname}=$c->req->params->{'jobname'} | $c->session->{jobname};
    $c->session->{application}=$c->req->params->{'application'}| $c->session->{application}  ;
    
    $c->log->debug('jobs/review: testing for form completion');
    
    $xml = new XML::Smart( $c->session->{appxml} );
    
    $form->field(
        name    => 'project',
        label   => 'Project',
        disabled => 1,
        value => $c->session->{project}
    );
    $form->field(
        name    => 'jobname',
        label   => 'Job Name',
        disabled => 1,
        value => $c->session->{jobname}
    );
    $form->field(
        name    => 'application',
        label   => 'Application',
        disabled => 1,
        value => $c->session->{application}
    );
    
    # create a display only form field for all the application params
 
    my ($par, $arg);
    foreach $par (@{$xml->{program}{exec}{param}})
     { 
       $c->log->debug('jobs/review: par **** *** dump = '.Dumper($par));
       $form->field(
          name     => $par->{name}->content,
          label    => $par->{label}->content,
          comment  => $par->{comment}->content,
          value    => $c->session->{parameters}->{$par->{label}->content},
          disabled => 1
       );
    }
    
    # create display only form field for each application argument

    foreach $arg (@{$xml->{program}{exec}{arg}})
    {
         $c->log->debug('jobs/review: name '.$arg->{name}->content);
         $c->log->debug('jobs/review: label '.$arg->{label}->content);
         $c->log->debug('jobs/review: comment '.$arg->{comment}->content);
          
         $form->field(
            name     => $arg->{name}->content,
            label    => $arg->{label}->content,
            comment  => $arg->{comment}->content,
            value    => $c->session->{arguments}->{$arg->{name}->content},
            disabled => 1
         );
    }

    $c->stash->{forms}  =       $form;
    $c->stash->{template}       = '/jobs/review.html';

    if ($form->submitted eq 'No') {
      $c->response->redirect($c->uri_for('newjob1'));
    }
    elsif (($form->submitted eq 'Yes') && $form->validate)
    {
      my $line;
      my $jobxml = "";
      
      my $job_creation_date = time2str("%c", time);     
      $jobxml .= sprintf('<job project="%s" jobname="%s" version="%s" >'."\n",
         $c->session->{project},
         $c->session->{jobname},
         ''
      );
            
      $jobxml  .= sprintf(' <program name="%s" index="%s" version="%s" >'."\n",
         $c->session->{application},
         '',
         ''
      );
            
      $jobxml .= sprintf("  <exec>\n");

      #
      # print all parameter lines here
      #      
      
      #######  HERE   ###########
      foreach $par (@{$xml->{program}{exec}{param}})
       {
        $c->log->debug('jobs/review: parameter  = '.$par->{'label'}->content);                
        $jobxml .= sprintf('   <param name="%s" value="%s" />'."\n",
                           $par->{name}->content,
                           $c->session->{parameters}->{$par->{label}->content}
                          );        
      }
          
      $jobxml  .= sprintf("  </exec>\n");
           
      #
      # print all argument lines here
      #        
      foreach $arg (@{$xml->{program}{exec}{arg}})
       {
        if ( $c->session->{arguments}->{$arg->{name}->content} ne "" )
         {
           $jobxml .= sprintf('<arg name="%s" value="%s" input_file="%s" output_file="%s" />'."\n",
                   $arg->{name}->content,
                   $c->session->{arguments}->{$arg->{name}->content},
		   $arg->{'input_file'}->content,
		   $arg->{'output_file'}->content
           );
        }
      }
    
      $jobxml .=  ' </program>'."\n";
      $jobxml .=  '</job>'."\n";
      
      
      
      my $sice = DBIx::SimplePerl->new;    
      $c->log->debug('Jobs/review '.$c->config->{jobdb}->{dsn});

      $sice->{debug}=1;
      $sice->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
                  
      $sice->db_add( table => "jobs", columns =>
            { jobxml        => $jobxml,
              jobname       => $c->session->{jobname},
              project       => $c->session->{project},
              created       => "now",
              application   => $c->session->{application},
              status        => 'Created',
	      job_owner_uid => getpwnam($c->user->get("username")) | "-1"
            } 
      );
      $sice->db_close;

      $c->response->redirect($c->uri_for('list'));
    }
}

sub submitjob : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    $form->debug(0);
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/jobs/submitjob.html';

    if ($form->submitted eq 'Previous') {
       $c->response->redirect($c->uri_for('review'));
    }
    elsif ($form->submitted eq 'Save' && $form->validate) {
      $c->response->redirect($c->uri_for('savejob'));
    }
    elsif ($form->submitted eq 'Erase' && $form->validate) {
      $c->response->redirect($c->uri_for('erasejob'));
    }
    elsif ($form->submitted eq 'Run' && $form->validate) {
       $c->response->redirect($c->uri_for('runjob'));
    }
    elsif ($form->submitted eq 'Cancel') {
      $c->response->redirect($c->uri_for('/main'));
    }
}

sub editjob : Local Form {
    my ( $self, $c, $id ) = @_;
    my $jobdb   = DBIx::SimplePerl->new;
    my $appsdb  = DBIx::SimplePerl->new;
    
    my ($retc,$x,$ret,$k,%apps,$xml);
    # must have a job id to edit
    if (!$id) { $c->response->redirect($c->uri_for('/main')); }
    $jobdb->{debug}=1;
    my $form = $self->formbuilder->new(debug=>0);
    $c->log->debug('jobs/editjob: id  = '.$id);
    if ($form->submitted eq "Cancel") { $c->response->redirect($c->uri_for('/main')); }
    if ($form->submitted eq "Delete") 
       { 
        $c->forward('delete', [$id]); 
       }
    if (!($form->submitted))
      {
        $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
        $retc   = $jobdb->db_search
                        ('table'  => 'jobs',
                          search => { 'id' => $id }
                        );
        $x      = $jobdb->db_next;
        $appsdb->db_open( 
    		     'dsn'	=> $c->config->{appdb}->{dsn},
		     'dbuser'	=> $c->config->{appdb}->{dbuser},
		     'dbpass'	=> $c->config->{appdb}->{dbpass}		
                    );
    
        $appsdb->db_search('table'  => 'apps');
     $c->log->debug('jobs/editjob: querying appdb '.$id);
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
      $c->log->debug('jobs/editjob: appname '.$k);

      $apps{$k} = $k;
     }
    $appsdb->db_close;
        foreach my $field (
                           qw(
                              jobname
                              ncpu
                              application
                             )
                           )
         {
          if ($field ne "application")
           {
            $form->field(
              name     => "Meta: [".$field."]",
              label    => $field,
              value    => $x->{$field},
              size => "80"        
                        );
           }
           else
           {
            $form->field(
              name     => "Meta: [".$field."]",
              label    => $field,
              options    => \%apps,
	      value	=> $x->{$field},
              type      => "select"
                        );
            
           }
         
         }
       # now for the jobxml bits
       $xml     = XML::Smart->new($x->{jobxml});
       foreach my $param ($xml->{job}{program}{exec}{param})
        {
         $c->log->debug('jobs/editjob: jobxml param name,value= '.
	 		$param->{name}->content." ".$param->{value}->content);         
         $form->field(
              name     => "Parameter: [".$param->{name}->content."]",
              label    => "Parameter: ". ($param->{label}->content | $param->{name}->content) ,
              value    => $param->{value}->content ,
              type     => "textarea",
                        );
        }
       foreach my $arg ($xml->{job}{program}{arg})
        {
         $c->log->debug('jobs/editjob: jobxml arg name,value= '.$arg->{name}->content." ".$arg->{value}->content);         
         $form->field(
              name     => "Argument: [name=".$arg->{name}->content.",value]",
              label    => "Argument name: [". ($arg->{label}->content | $arg->{name}->content) . "]",
              type     => "textarea",
              size     => "80",
              value    => $arg->{value}->content ,           
                        );
        
        $form->field(
              name     => "Argument: [name=".$arg->{name}->content.",input_file]",
              label    => "Argument input file: [" . ($arg->{label}->content | $arg->{name}->content) . "]",
              options  => ['Yes','No'],
              value    => $arg->{input_file}->content ,            
                        );
         $form->field(
              name     => "Argument: [name=".$arg->{name}->content.",output_file]",
              label    => "Argument output file: [" . ($arg->{label}->content | $arg->{name}->content) . "]",
              options  => ['Yes','No'],
              value    => $arg->{output_file}->content ,            
                        );
       }
      }
    else
      {
        # form has been submitted ...rebuild jobxml and update job metadata
        my $jobdata;
	
	$c->log->debug('jobs/editjob: parameters= '.Dumper($c->request->parameters));         
        $jobdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
        $retc   = $jobdb->db_search
                        ('table'  => 'jobs',
                          search => { 'id' => $id }
                        );
        $x      = $jobdb->db_next;
	$jobdata->{entry}	= $x;
	foreach my $arg ( grep { /Argument/ } keys %{$c->request->parameters})
	 {
	   if ($arg =~ /\[name=(.*),(.*)\]/)
	    {
	      $c->log->debug('jobs/editjob: named argument= '.$1.
	      "  label = ".$2."  value = ".$c->request->parameters->{$arg});
	      $jobdata->{arg}->{$1}->{$2}=$c->request->parameters->{$arg};
	    }	   
	 }
	foreach my $param ( grep { /Parameter/ } keys %{$c->request->parameters})
	 {
	   if ($param =~ /\[(.*)\]/)
	    {
	      $c->log->debug('jobs/editjob: named parameter= '.$1.
	      '  value ='.$c->request->parameters->{$param});
	      $jobdata->{parameter}->{$1}=$c->request->parameters->{$param};
	    }	   
	 }
	foreach my $meta ( grep { /Meta/ } keys %{$c->request->parameters})
	 {
	   if ($meta =~ /\[(.*)\]/)
	    {
	      $c->log->debug('jobs/editjob: named metadata= '.$1.
	      '  value ='.$c->request->parameters->{$meta});
	      $jobdata->{meta}->{$1}=$c->request->parameters->{$meta};
	    }	   
	 }
	$c->stash->{jobdata}	= $jobdata;
	$c->forward('build_jobxml');
	$c->log->debug('jobs/editjob: generated jobxml = '.Dumper($c->stash->{jobxml}));
	#
	# upon return from build_jobxml, we will have a correct and updated
	# version of the jobxml, which we can then push into the 
	# database
	
        $retc   = $jobdb->db_update
                        ('table'  => 'jobs',
                          search  => { 'id' => $id },
			  columns => {
			  	      jobxml	=> $c->stash->{jobxml},
				      jobname	=> $c->stash->{jobname}
			  	     }
                        );
        $jobdb->db_close;
	$c->redirect('/jobs/list');
        
      }
    
    
    $form->stylesheet(1);
    $form->debug(0);
    $form->field(name => "id", label=>"id", value=>$id, type=>"hidden");
    $c->stash->{forms}  = $form;
    $c->stash->{id}  = $id;
    $c->stash->{template}       = '/jobs/editjob.html';

}

sub build_jobxml : Private {
   my ( $self, $c ) = @_;
   my $jobdata	= $c->stash->{jobdata};
   my $nl	= "\n";
   # get job data from the stash, and use it to build the jobxml.
   
   my $app	= $jobdata->{meta}->{application} | $jobdata->{entry}->{application};
   my $jobname	= $jobdata->{meta}->{jobname} || $jobdata->{entry}->{jobname};
   my $version="";
   if (
       ($app)  && 
       ($app =~ /(.*)\s\[v(.*)\]/ )
      )
      {
        $app	= $1;
	$version= $2;
      }
   
   my $xml	= sprintf '<job project="%s" jobname="%s" version="%s">'.$nl,
		  $jobdata->{entry}->{project},
   		  $jobname,  		  
		  $jobdata->{meta}->{version} || $jobdata->{entry}->{version} || "";
   $xml		.= sprintf ' <program name="%s" index="%s" version="%s">'.$nl,
   			$app,
   			$jobdata->{meta}->{index} || $jobdata->{entry}->{index} || "",
			$version ;
   
   $xml		.= '  <exec>'.$nl;
   foreach my $param (keys %{$jobdata->{parameter}})
    {
     $xml	.= sprintf '   <param name="%s" value="%s" label="%s" />'.$nl,
     			$param,
			$jobdata->{parameter}->{$param},
			$jobdata->{parameter}->{label} || ""
			;
    }
   $xml		.= '  </exec>'.$nl;
   foreach my $arg (keys %{$jobdata->{arg}})
    {
     $xml	.= sprintf '   <arg name="%s" value="%s" label="%s" input_file="%s" output_file="%s" />'.$nl,
     			$arg,
			$jobdata->{arg}->{$arg}->{value},
			$jobdata->{arg}->{$arg}->{label} || "",
			$jobdata->{arg}->{$arg}->{input_file} ,
			$jobdata->{arg}->{$arg}->{output_file}
			;
    }


   ### close the XML
   $xml		.= ' </program>'.$nl;
   $xml		.= '</job>'.$nl;
   $c->stash->{jobxml}	= $xml;
   $c->stash->{jobname}	= $jobname;
   
}

sub runjob : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->debug(0);
    $form->stylesheet(1);
    use DBIx::SimplePerl;

    #my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    my $sice = DBIx::SimplePerl->new;

    #$sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
    $sice->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
    $sice->db_search(table   => 'jobs',
                     
                     columns => "id,jobname,created,submitted"
                    );
    my $q = $sice->{_sth}->fetchall_hashref('id');

    $sice->db_close;
    $c->stash->{jobs} = $q;

    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/jobs/runjob.html';
}

sub submit : Local {
    use DBIx::SimplePerl;

    my ($self, $c, $id) = @_;
    my $hash;
  
    #my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    my $jobsdb = DBIx::SimplePerl->new;
    $jobsdb->{debug} = 1 ;
    $c->log->debug('Jobs::submit JOB BEING SUBMITTED ');
    $c->log->debug('Jobs::submit  username = '.$c->user->get("username").' ****');
    $c->log->debug('Jobs::submit Initiating on_submit triggered actions ');
    $c->forward('on_submit_triggered_pre', $id);
    $jobsdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );

    # hardwired the user
    $jobsdb->db_update(
    			'table'  => 'jobs', 
			'search' => { id => $id } ,
			'columns'=> { 
					submitted	=> "now()",
			              	status		=> "Submit"			              			              			                
	                  	    } 
	 );
    $jobsdb->db_close;
    $c->response->redirect($c->uri_for('/jobs/list'));       
} 

sub on_submit_triggered_pre : Private {
    # actions triggered before setting the db state to submitted
    # will return on_submit_triggered_pre = true if successful
    my ($self, $c, $id) = @_;
    use DBIx::SimplePerl;
    use LWP::UserAgent;
    use URI;
    use Data::Dumper;
    use XML::Smart;
    use constant true	=> (1==1);
    use constant false	=> (1==0);    
    my ($hash,$jobsdb,$x,$project,$projectdb,$y,$project_return_uri);
    my ($mkdatadir,$datadir_base,$jobname,$uri,$run_dir,$response,$xml);
    my ($actual_data_dir,$rc);
    
    # prepare the web user agent
    my $ua = LWP::UserAgent->new;
    $ua->agent("DragonFlyGUI/0.2 ");
    $ua->timeout(10);
    $ua->env_proxy;
    
    # default to pre-trigger process failing ...
    $c->stash->{on_submit_triggered_pre} = false;
    
    # open jobDB and get specific record of this entry ...
    $jobsdb	= DBIx::SimplePerl->new;
    $jobsdb->{debug}=1;
    $jobsdb->db_open(
		     'dsn'	=> $c->config->{jobdb}->{dsn},
		     'dbuser'	=> $c->config->{jobdb}->{dbuser},
		     'dbpass'	=> $c->config->{jobdb}->{dbpass}		
                    );

    $jobsdb->db_search(
    			'table'  => 'jobs', 
			'search' => { 'id' => $id }			
	              );
    # only one job per id, so this 
    # query should always give 0 or 1 job.  0 means an
    # error, so if we don't have any jobs to report, simply 
    # return with the above stash set, and the job will not be submitted...
    
    $x	= $jobsdb->db_next;
    return if (!$x);
    
    # get the project, and prepare a query to get the project
    # data repository
    $project	= $x->{'project'};
    $c->log->debug('Jobs::on_submit_triggered_pre  	project = '.$project);
    $jobname	= $x->{'jobname'};
    $c->log->debug('Jobs::on_submit_triggered_pre  	jobname = '.$jobname);
    $projectdb	= DBIx::SimplePerl->new;
    $projectdb->{debug}=1;
    $projectdb->db_open(
		     'dsn'	=> $c->config->{projectdb}->{dsn},
		     'dbuser'	=> $c->config->{projectdb}->{dbuser},
		     'dbpass'	=> $c->config->{projectdb}->{dbpass}		
                    );

    $projectdb->db_search(
    			'table'  => 'projects', 
			'search' => { 'project_id' => $project }			
	              );
    
    # only one project per project_id, so this 
    # query should always give 0 or 1 project.  0 means an
    # error, so if we don't have any projects to associate with, simply 
    # return with the above stash set, and the job will not be submitted...
    
    $y	= $projectdb->db_next;
    return if (!$y);
   
    #  THIS SHOULD BE DONE BY THE FILE MANAGER!!!! 
    # create the run directory
    my @lt = localtime(time);
    my $_jobname_=$jobname;
    $_jobname_=~ s/[^\w]/_/;  # fix up the path to remove non
    $_jobname_=~ s/[\s]/_/;   # alphanumberic and other whitespace 
    # this is needed for the return via curl for data transport
    $run_dir	= sprintf "%s_%s_%s",
    		$_jobname_,
		$c->user->get("username"),
		(strftime ("%Y%m%d_%H%M%S",@lt))
		;
    
    $uri	= URI->new( $y->{'project_uri'} );
    $mkdatadir	= $uri->path;
    $c->log->debug('Jobs::on_submit_triggered_pre  	run_dir = '.$run_dir);

    # change the from "path" to "mkdatadir" method
    $mkdatadir	=~ s/^\/path/\/mkdatadir/;
    $datadir_base	= $mkdatadir;
    
    # append the run directory
    $mkdatadir	.= (sprintf "/%s",$run_dir);        
    
    $c->log->debug('Jobs::on_submit_triggered_pre     mkdatadir = '.$mkdatadir);
    
    # rebuild the URI ...
    $uri->path($mkdatadir);
    
    # now hit the file manager with the method
    $response = $ua->get($uri->as_string);
    if ($response->is_success) 
     {
      $c->log->debug('Jobs::on_submit_triggered_pre mkdatadir sent');
      $c->log->debug('Jobs::on_submit_triggered_pre response = '.$response->content);
      $xml	= XML::Smart->new($response->content);
      if ($xml->{'results'}{'mkdatadir'}->content eq "success")
       {
        # we succeeded at making the directory, proceed ...
        $actual_data_dir	= $xml->{'results'}{'dir'}->content;
        $c->log->debug('Jobs::on_submit_triggered_pre     actual_data_dir = '.$actual_data_dir);
       } 
       elsif ($xml->{'results'}{'mkdatadir'}->content eq "failed")
       {
         # we failed to make the dir.  Report the error to the log 
         $c->log->debug('Jobs::on_submit_triggered_pre     failed = '.$xml->{results}->content);
	 $c->stash->{error_message}	= (sprintf "could not make directory=%s on file server, reason = %s",$mkdatadir,$xml->{results}->content);
	 return;       
       }       
     }
     else 
     {
      $c->log->debug('Jobs::on_submit_triggered_pre Unable to contact DragonFly File Manager at '.$uri->as_string);
      $c->log->debug('Jobs::on_submit_triggered_pre  Error message is '.$response->status_line);
      return;
     }
    
    # almost done ... now update the uri to reflect the data return uri for this directory
    # append the run directory
    $datadir_base	= (sprintf "/data_return/%s",$actual_data_dir);
     
    # rebuild the URI ...
    $uri->path($datadir_base);
    $c->log->debug('Jobs::on_submit_triggered_pre data return uri '.$uri->as_string);
    $rc = $jobsdb->db_update(
    			'table'  	=> 'jobs', 
			'search' 	=> { 'id' => $id },
			'columns'	=> {
					    'project_output_directory'=>$uri->as_string
					   }		
	              );
    # set pre-trigger process succeeding if the updated did ...
    $c->stash->{on_submit_triggered_pre} = true if ($rc->{success});	
    $c->log->debug('Jobs::on_submit_triggered_pre commit results '.Dumper($rc));
    
    $projectdb->db_close;
    $jobsdb->db_close;
    
}

sub rerun : Local {    
    my ($self, $c, $id) = @_;
    use DBIx::SimplePerl;
    use Data::Dumper;
    use XML::Smart;
    use constant true	=> (1==1);
    use constant false	=> (1==0);    
    my ($hash,$jobsdb,$x,$project,$projectdb,%y,$project_return_uri);
    my ($mkdatadir,$datadir_base,$jobname,$uri,$run_dir,$response,$xml);
    my ($actual_data_dir,$rc);
    my (@fields,$basename);       
    
    # open jobDB and get specific record of this entry ...
    $jobsdb	= DBIx::SimplePerl->new;
    $jobsdb->{debug}=1;
    $jobsdb->db_open(
		     'dsn'	=> $c->config->{jobdb}->{dsn},
		     'dbuser'	=> $c->config->{jobdb}->{dbuser},
		     'dbpass'	=> $c->config->{jobdb}->{dbpass}		
                    );

    $jobsdb->db_search(
    			'table'  => 'jobs', 
			'search' => { 'id' => $id }			
	              );
    # only one job per id, so this 
    # query should always give 0 or 1 job.  0 means an
    # error, so if we don't have any jobs to report, simply 
    # return with the above stash set, and the job will not be submitted...
    
    $x	= $jobsdb->db_next;
    return if (!$x);
    
    @fields	= qw(
    		     jobname
		     job_owner_uid
		     job_directory
		     hold
		     ncpu
		     jobxml
		     project
		     application		     
    		    );
    # now copy some of the fields over ...
    foreach my $field (@fields)
     {
      $y{$field} = $x->{$field};
     }
    
    # fixes for values that should not be wrong ...
    $y{'ncpu'} = 1 if ($y{'ncpu'} == 0) ;

    # updates for values
    $y{'status'} = "Created" if ($y{'status'} eq "") ;
    $y{'created'} = "now()" ;
    
    # update the jobname to specify that it is a re-reun
    if ($y{'jobname'} =~ /(.*)\.rerun\..*/)
     {
       $basename = $1;
     }
     else
     {
       $basename = $y{'jobname'};
     }
    my @lt = localtime(time);
    $basename	.= (sprintf ".rerun.%s",(strftime ("%Y%m%d_%H%M%S",@lt)));
    $y{'jobname'}	= $basename;
    
    # and put into jobdb ...
    $jobsdb->db_add(
    			'table'  => 'jobs', 
			'columns' => \%y
	              );    
    $jobsdb->db_close;
    $c->redirect('/jobs/list');
    
}

sub stop : Local {    
    my ($self, $c, $id) = @_;
    use DBIx::SimplePerl;
    use Data::Dumper;
    use XML::Smart;
    use constant true	=> (1==1);
    use constant false	=> (1==0);    
    my ($hash,$jobsdb,$x,$project,$projectdb,%y,$project_return_uri);
    my ($mkdatadir,$datadir_base,$jobname,$uri,$run_dir,$response,$xml);
    my ($actual_data_dir,$rc);
    my (@fields,$basename);       
    
    # open jobDB and get specific record of this entry ...
    $jobsdb	= DBIx::SimplePerl->new;
    $jobsdb->{debug}=1;
    $jobsdb->db_open(
		     'dsn'	=> $c->config->{jobdb}->{dsn},
		     'dbuser'	=> $c->config->{jobdb}->{dbuser},
		     'dbpass'	=> $c->config->{jobdb}->{dbpass}		
                    );

    $jobsdb->db_search(
    			'table'  => 'jobs', 
			'search' => { 'id' => $id },				
	              );
    $x=$jobsdb->db_next;
   
    if ($x->{'status'} eq "Running" )
     {
      $jobsdb->db_update(
    			'table'  => 'jobs', 
			'search' => { 'id' => $id },
			'columns'=> { 'status' => "Stopping" }		
	              );
     }  
    if ($x->{'status'} eq "Submit" )
     {
      $jobsdb->db_update(
    			'table'  => 'jobs', 
			'search' => { 'id' => $id },
			'columns'=> { 'status' => "Created" }		
	              );
     }  
    $jobsdb->db_close;
    $c->redirect('/jobs/list');
    
}

sub newjob00 : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);

    # create a unused hidden field so that the forms generator will not complain
    $self->formbuilder->field(
        name    => 'hidden1',
        label   => '',
        type    => 'hidden'
    );
    
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/jobs/newjob00.html';
    
    if ($form->submitted eq 'Create a New Job')
    {          
      $c->response->redirect($c->uri_for('newjob0'));       
    }
    elsif ($form->submitted eq 'Clone an Existing Job') 
    {
      $c->response->redirect($c->uri_for('list2'));
    } 
}

sub list2 : Local Form {
    my ( $self, $c ) = @_;
    my ( %job_hash, $ret, @jobs);
    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1); 
    use DBIx::SimplePerl;
    
    #my $dsn = "dbi:SQLite:dbname=db/jobs.db";    
    my $acctdb = DBIx::SimplePerl->new;
    #$acctdb->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
    $acctdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
    
    $acctdb->db_search('table'  => 'jobs');
    
    undef %job_hash;
    while ($ret = $acctdb->db_next)
     {
      $job_hash{$ret->{id}} = $ret;
     }    
    @jobs = values( %job_hash );
    
    $acctdb->db_close;

    # create a unused hidden field so that the forms generator will not complain
    $self->formbuilder->field(
        name    => 'hidden1',
        label   => '',
        type    => 'hidden'
    );
    
    $c->stash->{forms}  = $form;              
    $c->stash->{jobs} = \@jobs;
    $c->stash->{template} = 'jobs/list2.html';
    
    if ($form->submitted eq 'Previous') {
      $c->response->redirect($c->uri_for('newjob00'));
    }
}
sub clone : Local Form {
    my ($self, $c, $field) = @_;
    use DBIx::SimplePerl;
    use Data::Dumper;
    use XML::Smart;
    my (%hash,$search_term,%outgoing,%results,$rt, $count,$current_version);
    my ($index_current_version,@fields, $jxml, $jobid);

    my $form = $self->formbuilder->new(debug=>0);
    $form->stylesheet(1);
    
    my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    @fields = @{$c->req->args};
    my $acctdb = DBIx::SimplePerl->new;
    $acctdb->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
    #$acctdb->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
    foreach $search_term (@fields)
     {
        if ($search_term =~ /(.*)=(.*)/)
         {
            $hash{$1} = $2;
            $jobid = $2;
         }
     }
    $acctdb->db_search('table'  => 'jobs', 'search' => \%hash );
    
    $rt = $acctdb->db_next;
    $acctdb->db_close;
    
    $jxml = $rt->{'jobxml'};    
    my $xml = new XML::Smart($jxml);
    my $i;

    # get job information

    my @jobdata = qw(project jobname version creation_date start_date status);

    foreach (@jobdata) {
      $form->field(
         name     => "$_",
         label    => "$_",
         value    => "$xml->{job}{$_}"
      );
    }

    # get program information

    my @programdata = qw(name version);

    foreach (@programdata) {
      $form->field(
         name     => "program$_",
         label    => "program $_",
         value    => "$xml->{job}{program}{$_}"
      );
    }

    # get all the application params

    my ($paramname, @paramdata);
    $i = 0;
    $paramname = $xml->{job}{program}{exec}{param}[ $i ]{name};

    while ( $paramname ne "" ) {
      @paramdata = qw(name value);
      foreach (@paramdata) {
         $form->field(
            name     => "param[$i]$_",
            label    => "param[$i] $_",
            value    => "$xml->{job}{program}{exec}{param}[ $i ]{$_}"
         );
      }
      $i++;
      $paramname = $xml->{job}{program}{exec}{param}[ $i ]{name};
    }

    # get all the application args

    my ($argname, @argdata);
    $i = 0;
    $argname = $xml->{job}{program}{arg}[ $i ]{name};

    while ( $argname ne "" ) {
      @argdata = qw(name value);
      foreach (@argdata) {
         $form->field(
            name     => "arg[$i]$_",
            label    => "arg[$i] $_",
            value    => "$xml->{job}{program}{arg}[ $i ]{$_}"
         );
      }
      $i++;
      $argname = $xml->{job}{program}{arg}[ $i ]{name};
    }
    $c->stash->{jid}  = $jobid;
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/jobs/clone.html';
    
    if ($form->submitted eq 'Return to Job List') {
      $c->response->redirect($c->uri_for('list2'));
    }
    elsif ($form->submitted eq 'Submit This Job') {
      my $sproject = $c->req->params->{'project'} ;
      my $sjobname = $c->req->params->{'jobname'} ;
      my $sapp = $c->req->params->{'programname'} ;
      my $jobxml = "";
      my $job_creation_date = time2str("%c", time);
      $jobxml .= sprintf("<job project=\"%s\" jobname=\"%s\" version=\"%s\">\n",
       $sproject, $sjobname, '');
      $jobxml .= sprintf("<program name=\"%s\" index=\"%s\" version=\"%s\">\n",
       $sapp, '', '');
      $jobxml .= sprintf("<exec>\n");
      
      #
      # print all parameter lines here
      # 
      $i = 0;
      $paramname = $c->req->params->{"param[$i]name"} ;

      while ( $paramname ne "" ) {
         $jobxml .= sprintf("<param name=\"%s\" value=\"%s\" />\n",
                 $c->req->params->{"param[$i]name"}, 
                 $c->req->params->{"param[$i]value"} );
          $i++;
          $paramname = $c->req->params->{"param[$i]name"} ;
      }      
      $jobxml  .= sprintf("</exec>\n");
      
      #
      # print all argument lines here
      # 
      $i = 0;
      $argname = $c->req->params->{"arg[$i]name"} ;

      while ( $argname ne "" ) {
         $jobxml .= sprintf("<arg name=\"%s\" value=\"%s\" />\n",
                 $c->req->params->{"arg[$i]name"}, 
                 $c->req->params->{"arg[$i]value"} );
          $i++;
          $argname = $c->req->params->{"arg[$i]name"} ;
      }
       
      $jobxml .= sprintf("</program>\n</job>\n");
      #$jobxml =~ s/"/""/g;
      
      #
      # store jobxml data in jobs table of jobs.db
      #
      #my $dsn = "dbi:SQLite:dbname=db/jobs.db";
      my $sice = DBIx::SimplePerl->new;
      #$sice->db_open( 'dsn' => $dsn, 'dbuser' => "", 'dbpass' => "");
      $sice->db_open(
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
      $sice->{debug} = 1;
      $c->log->debug('*** JOB BEING SUBMITTED ****');
      $c->log->debug('*** jobxml = '.$jobxml.' ****');
      	                
	   $sice->db_add( table => "jobs", columns =>
            { jobxml        => $jobxml,
              jobname       => $sjobname,
              project       => $sproject,
              submitted     => 0,
              application   => $sapp,
              status        => 'Created',
				  job_owner_uid => getpwnam($c->user->get("username"))
            } );

      $sice->db_close;

      $c->response->redirect($c->uri_for('runjob'));
    }
}

=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
