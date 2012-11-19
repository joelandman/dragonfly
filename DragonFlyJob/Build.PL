use strict;
use Catalyst::Build;

my $build = Catalyst::Build->new(
    license            => 'perl',
    module_name        => 'DragonFlyJob',
    requires           => { Catalyst => '5.49' },
    create_makefile_pl => 'passthrough',
    script_files       => [ glob('script/*') ],
    test_files         => [ glob('t/*.t'), glob('t/*/*.t') ]
);
$build->create_build_script;
