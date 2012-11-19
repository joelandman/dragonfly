package DragonFlyGUI::Controller::Acct;

use strict;
use warnings;
use base 'Catalyst::Controller::FormBuilder';

=head1 NAME

DragonFlyGUI::Controller::Acct - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyGUI::Controller::index in Acct.');
}

sub listall : Local   {
    my ( $self, $c ) = @_;
    use IO::File;
    use File::Temp qw/ tempfile tempdir /; 
    use Spreadsheet::SimpleExcel;
    my $jobs;
    #my $form = $self->formbuilder;
    my $excel = Spreadsheet::SimpleExcel->new();
    my @header = ("Job ID", 
               "Job Name",
               "Job Owner",
               "Application",
               "Job Directory",
               "Queue Job ID",
               "Queue Job Name",
               "Time Submitted",
               "Time Queued",
               "Time Started",
               "Time Completed",
               "Time on Hold",
               "Cluster",
               "Nodes",
               "NCPUs",
               "Wallclock Run Time",
               "Wallclock Queued Time"
               );
    $c->stash->{jha_ref}=\@header;
           
    $excel->set_headers("JobAccounting", @header);       
    #$form->stylesheet(1);
    #$form->debug(0);
    my (%job_hash, @jobs, @job, $ret);

    my $acctdb = DBIx::SimplePerl->new;

    $acctdb->db_open(
    		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                );
           
    $acctdb->db_search('table'  => 'jobs');
    while ($ret = $acctdb->db_next)
     {
      $jobs->{$ret->{id}} = $ret;
     }    
    @jobs = values( %{$jobs} );
    
    #$c->stash->{forms}  = $form;   
    $c->stash->{jobs} = $jobs;
    $c->stash->{template} = 'acct/list.html';
    my ($fh, $filename) = tempfile( SUFFIX => '.xls');
    foreach ( keys(%$jobs) ) {
      @job   = ([$jobs->{$_}->{jobid},
               $jobs->{$_}->{jobname},
               $jobs->{$_}->{job_owner_uid},
               $jobs->{$_}->{application},
               $jobs->{$_}->{job_directory},
               $jobs->{$_}->{queue_jobid},
               $jobs->{$_}->{queue_jobname},
               $jobs->{$_}->{submitted},
               $jobs->{$_}->{queued},
               $jobs->{$_}->{started},
               $jobs->{$_}->{completed},
               $jobs->{$_}->{hold},
               $jobs->{$_}->{assigned_to_cluster},
               $jobs->{$_}->{running_on},
               $jobs->{$_}->{NCPU},
               $jobs->{$_}->{wallclock_run},
               $jobs->{$_}->{wallclock_queued}
              ]); 
      $excel->add_row("JobAccounting", [@job]);
    };
    $excel->output_to_file($filename);
    $c->log->debug('acct/listall: excel file for download='.$filename);
     
    if (0)
    {
      $c->log->debug('acct/listall: Form submitted, beginning download');
       
       $c->response->content_type('application/octet-stream');
       $c->res->header('Content-Disposition', qq[attachment; filename=$filename]);
       $c->response->body($fh);       
          
       
      $c->redirect('/acct/listall');
    }   
}

sub jobdata : Local Form {
    my ($self, $c, $field) = @_;
    my $form = $self->formbuilder;
    $form->stylesheet(1);
    use DBIx::SimplePerl;
    use Data::Dumper; 

    my (%hash,$search_term,%outgoing,%results,$rt, $count,$current_version);
    my ($index_current_version,@fields, $jxml, $jobid);
    
    my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    @fields = @{$c->req->args};
    $c->log->debug('acct/xml: dsn   = '.$dsn);
    $c->log->debug('acct/xml: args  = '.join(":",@fields));
    my $acctdb = DBIx::SimplePerl->new;

    $acctdb->db_open( 'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                ); 
    foreach $search_term (@fields)
     {
        $c->log->debug('acct/xml: search_term= '.$search_term);
        if ($search_term =~ /(.*)=(.*)/)
         {
            $hash{$1} = $2;
            $jobid = $2;
            $c->log->debug('acct/xml: search term= '.$1.' value = '.$2);
         }
     }
    $c->log->debug('acct/xml: hash = '.Dumper(\%hash));
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
         disabled => 1,
         value    => "$xml->{job}{$_}"
      );
    }

    # get program information

    my @programdata = qw(name version);

    foreach (@programdata) {
      $form->field(
         name     => "program$_",
         label    => "program $_",
         disabled => 1,
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
            disabled => 1,
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
            disabled => 1,
            value    => "$xml->{job}{program}{arg}[ $i ]{$_}"
         );
      }
      $i++;
      $argname = $xml->{job}{program}{arg}[ $i ]{name};
    }
    $c->stash->{jid}  = $jobid;
    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/acct/jobdata.html';
    
    if ($form->submitted eq 'Back to Job List')
    {
      $c->response->redirect($c->uri_for('listall'));
    }
}
 
sub xml : Local {
    use DBIx::SimplePerl;
    use Data::Dumper;
    my ($self, $c, $field) = @_;
    my (%hash,$search_term,%outgoing,%results,$rt, $count,$current_version);
    my ($index_current_version,@fields, $jxml, $jobid);
    
    my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    @fields = @{$c->req->args};
    $c->log->debug('acct/xml: dsn   = '.$dsn);
    $c->log->debug('acct/xml: args  = '.join(":",@fields));
    my $acctdb = DBIx::SimplePerl->new;

    $acctdb->db_open( 
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                ); 
    foreach $search_term (@fields)
     {
        $c->log->debug('acct/xml: search_term= '.$search_term);
        if ($search_term =~ /(.*)=(.*)/)
         {
            $hash{$1} = $2;
            $jobid = $2;
            $c->log->debug('acct/xml: search term= '.$1.' value = '.$2);
         }
     }
    $c->log->debug('acct/xml: hash = '.Dumper(\%hash));
    $acctdb->db_search('table'  => 'jobs', 'search' => \%hash );
    
    $rt = $acctdb->db_next;
    $acctdb->db_close;
    
    $jxml = $rt->{'jobxml'};
    $jxml =~ s/</&lt;/g;
    $jxml =~ s/>/><br>/g;
    $c->stash->{xml} = $jxml;
    $c->stash->{jid} = $jobid;
    $c->stash->{template}       = '/acct/xml.html';
}

sub jobs : Local {
 my ( $self, $c ) = @_;
    $c->response->body('Matched DragonFlyGUI::Controller::jobs in Acct.');
}

sub acctinfo : Local Form {
    use Data::Dumper;
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder;
    $form->stylesheet(1); 

    my ($ret,%userids, %apps, %clusters,$k);
    my $appsdsn = "dbi:SQLite:dbname=db/jobs.db";
    my $appsdb = DBIx::SimplePerl->new;
    $appsdb->db_open( 
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                ); 
    
    $appsdb->db_search('table'  => 'jobs');
    while ($ret = $appsdb->db_next)
    {
      $userids{$ret->{job_owner_uid}} = $ret->{job_owner_uid} if ($ret->{job_owner_uid});
      $clusters{$ret->{assigned_to_cluster}} = $ret->{assigned_to_cluster} if ($ret->{assigned_to_cluster});
      $apps{$ret->{application}} = $ret->{application} if ($ret->{application});
    }
 
    $appsdb->db_close;
   
    $self->formbuilder->field(
        name    => 'userids',
        label   => 'Select User ID', 
        type    => 'select',
        multiple => 1,       
        options => \%userids,
        required => 0
    );
    $self->formbuilder->field(
        name    => 'apps',
        label   => 'Select Application', 
        type    => 'select', 
        multiple => 1,      
        options => \%apps,
        required => 0
    );
    $self->formbuilder->field(
        name    => 'clusters',
        label   => 'Select Cluster', 
        type    => 'select',
        multiple => 1,       
        options => \%clusters,
        required => 0
    );

    $c->stash->{forms}  = $form;
    $c->stash->{template}       = '/acct/acctinfo.html';

    if ($form->submitted eq 'Submit')
    {
      @{ $c->session->{userids} } = $c->req->params->{'userids'};
      @{ $c->session->{apps} } = $c->req->params->{'apps'};
      @{ $c->session->{clusters} } = $c->req->params->{'clusters'};
      $c->response->redirect($c->uri_for('listsome'));
    }
}

sub listsome : Local Form{
    use Data::Dumper;    
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder;
    $form->stylesheet(1); 
    my $ret;
    my %job_hash;
    my (@tuids, @tclus, @tapps, ,@job, @jobs, @job_data);

    my $dsn = "dbi:SQLite:dbname=db/jobs.db";
    my $acctdb = DBIx::SimplePerl->new;
    $acctdb->db_open( 
		'dsn'	=> $c->config->{jobdb}->{dsn},
		'dbuser'=> $c->config->{jobdb}->{dbuser},
		'dbpass'=> $c->config->{jobdb}->{dbpass}		
                ); 
    $acctdb->{debug} = 1;
    my $criteria = 0;
    # determine if any user id criteria
    if ( defined($c->session->{userids}->[0]) ){
       @tuids = @{ $c->session->{userids} };
       $acctdb->db_search(table  => 'jobs',
                          search => { job_owner_uid => @tuids });
       while ($ret = $acctdb->db_next){
         $job_hash{$ret->{id}} = $ret;
       }
       $criteria = 1;
    }
    # determine if any cluster criteria
    if ( defined($c->session->{clusters}->[0]) ){
       @tclus = @{ $c->session->{clusters} };
       $acctdb->db_search(table  => 'jobs',
                          search => { assigned_to_cluster => @tclus });
       while ($ret = $acctdb->db_next){
         $job_hash{$ret->{id}} = $ret;
       }
       $criteria = 1;
    }
    # determine if any application criteria
    if ( defined($c->session->{apps}->[0]) ){
       @tapps = @{ $c->session->{apps} };
       $acctdb->db_search(table  => 'jobs',
                          search => { application => @tapps });
       while ($ret = $acctdb->db_next){
         $job_hash{$ret->{id}} = $ret;
       }
       $criteria = 1;
    }
    # if no userid, cluster, or application criteria - show all data
    if ( ! $criteria ){
       $acctdb->db_search(table  => 'jobs');
       while ($ret = $acctdb->db_next){
         $job_hash{$ret->{id}} = $ret;
       }
    }
     
    @jobs = values( %job_hash );
    $self->formbuilder->field(
        name    => 'wrk_sheet',
        label   => 'Work Sheet Name',
        value   => 'Accounting' 
    );
    $self->formbuilder->field(
        name    => 'excel_file',
        label   => 'excel File Path',
        value   => '/tmp/acct.xls'
    );
         
    # display list of selected jobs
    $c->stash->{forms}  = $form;
    $c->stash->{jobs} = \@jobs;
    $c->stash->{template} = 'acct/list.html';
    
    if ($form->submitted)
    {
      # output selected data to excel spreadsheet
      
      my $job_hash_ref = \%job_hash;
      my $wrksheet=$c->req->params->{'wrk_sheet'} ;
      my $xcelpath=$c->req->params->{'excel_file'} ;
      
      $self->_excel_file( $job_hash_ref, $wrksheet, $xcelpath);    
    }
}

sub _excel_file : Private {
    my ( $self, $c, $jobs, $wrksheet, $excelfile ) = @_;
    my ($excel, @header, @job);
    use Spreadsheet::SimpleExcel;
        
 
    $excel = Spreadsheet::SimpleExcel->new();
    $excel->add_worksheet($wrksheet);

    @header = (["Job ID", 
               "Job Name",
               "Job Owner",
               "Application",
               "Job Directory",
               "Queue Job ID",
               "Queue Job Name",
               "Time Submitted",
               "Time Queued",
               "Time Started",
               "Time Completed",
               "Time on Hold",
               "Cluster",
               "Nodes",
               "NCPUs",
               "Wallclock Run Time",
               "Wallclock Queued Time"
               ]);
               
    $excel->set_headers($wrksheet, @header);
    foreach ( keys(%$jobs) ) {
      @job   = ([$jobs->{$_}->{jobid},
               $jobs->{$_}->{jobname},
               $jobs->{$_}->{job_owner_uid},
               $jobs->{$_}->{application},
               $jobs->{$_}->{job_directory},
               $jobs->{$_}->{queue_jobid},
               $jobs->{$_}->{queue_jobname},
               $jobs->{$_}->{submitted},
               $jobs->{$_}->{queued},
               $jobs->{$_}->{started},
               $jobs->{$_}->{completed},
               $jobs->{$_}->{hold},
               $jobs->{$_}->{assigned_to_cluster},
               $jobs->{$_}->{running_on},
               $jobs->{$_}->{NCPU},
               $jobs->{$_}->{wallclock_run},
               $jobs->{$_}->{wallclock_queued}
              ]); 
      $excel->add_row($wrksheet, [@job]);
    };
    # write selected job data to excel file
    $excel->output_to_file($excelfile); 
    $c->log->debug('acct/_excel_file: file='.$excelfile);
    $c->log->debug('acct/_excel_file: error='.$excel->errstr());

}

=head1 AUTHOR

DragonFly,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
