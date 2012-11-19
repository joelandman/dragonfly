use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DragonFlyFM' }
BEGIN { use_ok 'DragonFlyFM::Controller::Dir' }

ok( request('/dir')->is_success, 'Request should succeed' );


