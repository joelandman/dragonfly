use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DragonFlyGUI' }
BEGIN { use_ok 'DragonFlyGUI::Controller::Login' }

ok( request('/login')->is_success, 'Request should succeed' );


