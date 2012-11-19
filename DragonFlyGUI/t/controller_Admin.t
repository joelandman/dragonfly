use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DragonFlyGUI' }
BEGIN { use_ok 'DragonFlyGUI::Controller::Admin' }

ok( request('/admin')->is_success, 'Request should succeed' );


