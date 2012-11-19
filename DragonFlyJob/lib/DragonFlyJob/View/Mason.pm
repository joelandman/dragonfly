package DragonFlyJob::View::Mason;

use strict;
use warnings;
use base 'Catalyst::View::Mason';
use POSIX qw(getcwd);

__PACKAGE__->config(use_match => 0);
__PACKAGE__->config->{comp_root} = getcwd.'/root';
__PACKAGE__->config->{data_dir} = getcwd.'/masondata';


=head1 NAME

DragonFlyJob::View::Mason - Mason View Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
