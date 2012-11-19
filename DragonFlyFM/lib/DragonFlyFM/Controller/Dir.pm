package DragonFlyFM::Controller::Dir;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DragonFlyFM::Controller::Dir - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched DragonFlyFM::Controller::Dir in Dir.');
}

sub reset : Private {
    my ( $self, $c ) = @_;
    $c->session->{top_path}="";
    $c->redirect('/list');
}

sub settopdir : Private {
    my ( $self, $c ) = @_;
    my @fields = @{$c->req->args};
    my @captures = @{ $c->request->captures };
    my $top_path = $c->req->param('top_dir');
    $c->forward('/list');
}

sub list : Path('/list')  {
    my ( $self, $c , @relative_path) = @_;
    use XML::Directory::String;
    use File::Spec;
    use Data::Dumper;
    my ($top_path,$uri_path,$path,$rel_path,$real_rel_path);
   
    $top_path  = $c->session->{top_path};
    $top_path = $c->config->{default_dir} if (!$top_path);
#$c->session->{top_path};
      if ((!$top_path) && defined($c->config->{default_dir}))
     	{
          $top_path	= $c->config->{default_dir};
        }
	elsif ((!$top_path) && (!defined($c->config->{default_dir})))
	{
	  $top_path	= $ENV{'HOME'};
	}
        $c->session->{top_path} = $top_path;
	
        $c->log->debug('Dir::list top_path = '.$top_path);
	$c->log->debug('Dir::list rel_path = '.$rel_path);
	$c->log->debug('Dir::list default_dir = '.$c->config->{default_dir});
	$c->log->debug('Dir::list relative_path = '.@relative_path);
	$c->log->debug('Dir::list path = '.$path);
		$c->log->debug('Dir::list relative path = '.join(",",@relative_path));    
    my @fields = @{$c->req->args};
    my @captures = @{ $c->request->captures };
    #my $path = $c->req->param('path');
	
	$uri_path=$rel_path;

    #$path 	=  $top_path if (!$path);
    $rel_path	= "";
    $real_rel_path="";

    # real_rel_path is the path after the home path i.e. after /home/vijay (in this case)
    # need to change the above comment when the code is moved to real server

    if (@relative_path)
      {
        $rel_path = File::Spec->catfile(@relative_path);
	my $i=0;
	
	foreach my $_subdir (File::Spec->splitdir( $rel_path ))
	{
	  $i++;
	  if($i>3)
		{
		  $real_rel_path= File::Spec->catfile( $real_rel_path, $_subdir );
		}
	}

      }
    else{
    		$rel_path = $top_path;
    	}
  
if (!($uri_path))
{
    $path 	= $rel_path;
    #$path	= "/local/projects" if (!$path);
}
else
{
$path 	= $uri_path;
  }   
   $c->log->debug('Dir::list top_path = '.$top_path);
	$c->log->debug('Dir::list rel_path = '.$rel_path);
	$c->log->debug('Dir::list uri_path = '.$uri_path);
        $c->log->debug('Dir::list real_rel_path = '.$real_rel_path);

	$c->log->debug('Dir::list path = '.$path);    

    my $dir = XML::Directory::String->new($path ,3,0);
    $dir->parse_dir;
    my $xml = $dir->get_string;
    $c->stash->{top_path}		= $top_path;
    $c->stash->{xmldir} 		= $xml;
    $c->stash->{download_uri_base}	= $c->uri_for('/');
    $c->stash->{rel_path} 		= $rel_path;
    $c->stash->{real_rel_path} 		= $real_rel_path; 
 #    $c->stash->{real_rel_path}               = $rel_path;
    $c->stash->{is_IE} 			= ($c->request->browser->ie ? 1 : 0 );
    $c->stash->{template} 		= "/list.html";
}

sub listdir : Path('/xmldir')  {
    my ( $self, $c , @relative_path) = @_;
    my @file_array;
    use File::Spec;
    use Data::Dumper;
    use File::Iterator;
    my ($top_path,$uri_path,$path,$rel_path,$xml,$dir);
    $top_path	= $c->session->{top_path};
    $top_path	= $c->config->{default_dir} if (!$top_path);
    $c->log->debug('Dir::listdir top_path = '.$top_path);

    my @fields = @{$c->req->args};
    my @captures = @{ $c->request->captures };
    #my $path = $c->req->param('path');
    
    $path 	=  $top_path if (!$path);
    $rel_path	= "";
    if (@relative_path)
      {
        $rel_path	= File::Spec->catfile(@relative_path);
	$uri_path	= File::Spec->catfile($top_path,$rel_path);
        $c->log->debug('Dir::listdir rel_path = '.$rel_path);
        $c->log->debug('Dir::listdir uri_path = '.$uri_path);
      }    
    
    $path 	= $uri_path if ($uri_path);
    $dir	= new File::Iterator( DIR => $path, RECURSE => 10);
    while (my $file = $dir->next()) { push @file_array,$file;  }
    $c->stash->{top_path}		= $top_path;
    $c->stash->{file_array} 		= \@file_array;
    $c->stash->{rel_path} 		= $rel_path;
    $c->stash->{download_uri_base}	= $c->uri_for('/');
    $c->stash->{is_IE} 			= ($c->request->browser->ie ? 1 : 0 );
    $c->stash->{template} 		= "/listdir.html";
}

sub listabsdir : Path('/xmlabsdir')  {
    my ( $self, $c , @absolute_path) = @_;
    my @file_array;
    use File::Spec;
    use Data::Dumper;
    use File::Iterator;
    my ($top_path,$uri_path,$path,$abs_path,$xml,$dir);
    $top_path	= $c->session->{top_path};

    my @fields = @{$c->req->args};
    my @captures = @{ $c->request->captures };
    #my $path = $c->req->param('path');
    
    $path 	=  $top_path if (!$path);
    if (@absolute_path)
      {
        $abs_path	= File::Spec->catfile(@absolute_path);
        $c->log->debug('Dir::listabsdir abs_path = '.$abs_path);
      }        
    $path 	= $abs_path if ($abs_path);
    $dir	= new File::Iterator( DIR => $path, RECURSE => 10);
    while (my $file = $dir->next()) { push @file_array,$file;  }
    $c->stash->{top_path}		= $top_path;
    $c->stash->{file_array} 		= \@file_array;
    $c->stash->{abs_path} 		= $abs_path;
    $c->stash->{download_uri_base}	= $c->uri_for('/');
    $c->stash->{is_IE} 			= ($c->request->browser->ie ? 1 : 0 );
    $c->stash->{template} 		= "/listabsdir.html";
}

sub list_absolute : Path('/listabs')  {
    my ( $self, $c , @abs_path) = @_;
    use XML::Directory::String;
    use File::Spec;
    use Data::Dumper;
    my ($top_path,$uri_path,$path);
    $top_path	= $c->session->{top_path};
    $c->log->debug('Dir::list top_path = '.$top_path);

    $uri_path	= File::Spec->catfile(@abs_path) if (@abs_path);
    $path 	= $uri_path if ($uri_path);
    
     my $dir = XML::Directory::String->new($path ,3,0);
    $dir->parse_dir;
    my $xml = $dir->get_string;
    $c->stash->{xmldir} = $xml;
    $c->stash->{project_path}	= $top_path;
    $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
    $c->stash->{template} = "/list.html";
}

sub data_return : Path('/data_return')  {
    my ( $self, $c , @abs_path) = @_;
    use XML::Directory::String;
    use File::Spec;
    use Data::Dumper;
    my ($top_path,$uri_path,$path);
    #$top_path	= $c->session->{top_path};
    #$c->log->debug('Dir::list top_path = '.$top_path);

    $uri_path	= File::Spec->catfile(@abs_path) if (@abs_path);
    $path 	= $uri_path if ($uri_path);
    
    my $dir = XML::Directory::String->new($path ,3,0);
    $dir->parse_dir;
    my $xml = $dir->get_string;
    $c->stash->{xmldir} = $xml;
    $c->stash->{project_path}	= $top_path;
    $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
    $c->stash->{template} = "/list.html";
}

sub set_data_repository_top : Path('/path') {
    my ( $self, $c, @top_path) = @_;    
    use File::Spec;
    my @fields = @{$c->req->args};
    my @captures = @{ $c->request->captures };
    my $path = $c->req->param('top');
    
    my ($_tmp_path,$uri_path);
    
    $uri_path	= File::Spec->catfile(@top_path) if (@top_path);
    $path 	= $c->config->{'default_dir'} if (!$path);
    $path 	= $uri_path if ($uri_path);
    $path	= "/local/projects" if (!$path);
    
    $c->session->{top_path}	= $path;
    
    $c->log->debug('Dir::set_data_repository_top set path = '.$path);  
    $c->log->debug('Dir::set_data_repository_top uri_path = '.$uri_path);  
    $c->redirect('/list'); 
}

sub download : Path('/download')  {
    my ( $self, $c,@relative_path ) = @_;
    use File::Spec;
    use Data::Dumper;
    use IO::File;
    use File::Spec;
    use File::Spec::Win32;
 
    my ($volume,$directories,$filename,$path);  
    my @fields 	= @{$c->req->args		};
    my @captures= @{ $c->request->captures 	};
    my $file 	= $c->req->param('file');
    my $fh	= IO::File->new; 
    
    my ($top_path,$uri_path,$rel_path);
    $top_path	= $c->session->{top_path};
    $top_path	= $c->config->{default_dir} if (!$top_path);
    $c->log->debug('Dir::download top_path = '.$top_path);

    $path 	=  $top_path if (!$path);
    $rel_path	= "";
    if (@relative_path)
      {
        $uri_path	= File::Spec->catfile(@relative_path);
      }
    
    $path 	= $uri_path if ($uri_path);
    
    return if (!$path);
    ($volume,$directories,$filename) 	= File::Spec->splitpath( $path );
    
    if ($fh->open("< ".File::Spec->catfile($top_path,$path)))
      {
       $c->response->content_type('application/octet-stream');
       $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
       $c->response->body($fh);
       $c->stash->{template} = "/list.html";
      }
     else
      {
       $c->log->debug('download:error! path ='.File::Spec->catfile($top_path,$path));
       $c->stash->{template} = "/error.html";
       $c->stash->{message}  = (sprintf "file \'%s\' is missing or unable to be opened\n",File::Spec->catfile($top_path,$path)       );
      }
     $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
}

sub downloadabs : Path('/downloadabs')  {
    my ( $self, $c,@absolute_path ) = @_;
    use File::Spec;
    use Data::Dumper;
    use IO::File;
    use File::Spec;
    use File::Spec::Win32;
 
    my ($volume,$directories,$filename,$path);  
    my @fields 	= @{$c->req->args		};
    my @captures= @{ $c->request->captures 	};
    my $file 	= $c->req->param('file');
    my $fh	= IO::File->new; 
    
    my ($top_path,$uri_path,$abs_path);
    $top_path	= $c->session->{top_path};
    $c->log->debug('Dir::download top_path = '.$top_path);

    $path 	=  $top_path if (!$path);
    $abs_path	= "";
    if (@absolute_path)
      {
        $uri_path	= File::Spec->catfile(@absolute_path);
      }
    
    $path 	= $uri_path if ($uri_path);
    
    return if (!$path);
    ($volume,$directories,$filename) 	= File::Spec->splitpath( $path );
    
    if ($fh->open("< ".$path))
      {
       $c->response->content_type('application/octet-stream');
       $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
       $c->response->body($fh);
       $c->stash->{template} = "/list.html";
      }
     else
      {
       $c->stash->{template} = "/error.html";       
      }
     $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
}

sub upload : Global {
  my ($self, $c) = @_;
  my @uploads;
  use File::Spec;
  use Data::Dumper;
  use POSIX qw(strftime);
  use Time::Local;
  # don't overwrite files ... if a file with that same
  # name/path exists, then append the current date/time
  # to it and try again
  my $path 	= $c->req->param('destination_path');
  my $rel_path 	= $c->req->param('rel_path');
  my $timestamp	= timelocal(localtime);
  my ($volume,$directories,$file);
  $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
  $c->log->debug('Dir::upload path = '.$path);
  if ( $c->request->parameters->{form_submit} eq 'yes' ) {

      $c->log->debug('Dir::upload uploading! ');
      for my $field ( $c->request->upload ) {
          $c->log->debug('Dir::upload field  '.$field);
          my $upload   = $c->request->upload($field);
          my $filename = $upload->filename;         
	  if ($c->request->browser->ie ) 
	   {
            # handle the broken-ness of IE for users constrained
	    # to deal with it
	    ($volume,$directories,$file) = File::Spec::Win32->splitpath( $filename );
	   }
	   else
	   {
            ($volume,$directories,$file) = File::Spec->splitpath( $filename );
	   }
	  $filename	= $file;
          $c->log->debug('*********** name   '.$filename);
          my $target   = File::Spec->catfile($path,$filename);
	  if (-e $target) { $target.=$timestamp };
	  $c->log->debug('*********** target '.$target);
          unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
              die( "Failed to copy '$filename' to '$target': $!" );
          }
      }
  }
  my $jump_to	= sprintf "list/%s",$rel_path;
  $c->stash->{template}	= "/list.html";
  #$c->forward($jump_to, [qw/path=$path/]);
  $c->redirect($jump_to);  
}



sub mkdir : Global {
  my ($self, $c) = @_;

  use File::Spec;
  use Data::Dumper;
  use POSIX qw(strftime);
  use Time::Local;
  # don't overwrite directories ... if a file with that same
  # name/path exists, then append the current date/time
  # to it and try again
  my $path 	= $c->req->param('destination_path');
  my $dir   	= $c->req->param('dir');
  my $rel_path	= $c->req->param('rel_path');
  my $target  	= File::Spec->catfile($path,$dir);
  my $timestamp	= timelocal(localtime);
  $c->log->debug('mkdir:	 path = '.$path);
  $c->log->debug('mkdir: 	 dir  = '.$dir); 
  $c->stash->{is_IE} 	= ($c->request->browser->ie ? 1 : 0 );
  if (
      ( $c->req->param('form_submit') eq 'yes' )  &&
      ( $dir )
     )
     {
      if (-e $target) { $target.=$timestamp };
      $c->log->debug('mkdir:		target = '.$target);
      unless ( mkdir $target ) 
       {
        $c->log->debug('mkdir: 	 Failed to make directory '.$target.": $!");
       }
     }
  
  my $jump_to	= sprintf "/list/%s/%s",$rel_path,$dir;
  $c->stash->{template}	= "/list.html";
  $c->redirect($jump_to);   
}

sub mkdatadir : Path('/mkdatadir') {
  my ($self, $c,@data_dir) = @_;

  use File::Spec;
  use Data::Dumper;
  use POSIX qw(strftime);
  use Time::Local;
  # don't overwrite directories ... if a file with that same
  # name/path exists, then append the current date/time
  # to it and try again
  my $path 	= $c->req->param('destination_path');
  my $dir   	= $c->req->param('dir');
  my $rel_path	= $c->req->param('rel_path');
  my $target  	= File::Spec->catfile($path,$dir);
  my $timestamp	= timelocal(localtime);
  
  my $data_path	= "";
  my @fields 	= @{$c->req->args		};
  my @captures	= @{ $c->request->captures 	};
  $data_path 	= $c->req->param('data_path');
  if (@data_dir)
      {
        $data_path	= File::Spec->catfile(@data_dir);
      }
    
  return if (!$data_path);  # return if no arguments specified    
  
  $c->log->debug('Dir::mkdatadir:   	data_path = '.$data_path);
 
  if (-e $data_path) { $data_path	.= $timestamp };
  $c->log->debug('Dir::mkdatadir:	data_path = '.$data_path);
  $c->stash->{mkdatadir} = "succeeded";  
  unless ( mkdir $data_path ) 
   {
    $c->stash->{errormessage} = $!;    
    $c->log->debug('Dir::mkdatadir:  Failed to make directory '.$data_path.": $!");
    $c->stash->{mkdatadir} = "failed";
    
   }
  $c->stash->{datadir} = $data_path;
  $c->stash->{template}	= "/mkdatadir.html";  
}

=head1 AUTHOR

Joe Landman,,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
