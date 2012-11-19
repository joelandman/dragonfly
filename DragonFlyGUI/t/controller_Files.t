use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DragonFlyGUI' }
BEGIN { use_ok 'DragonFlyGUI::Controller::Files' }

ok( request('/files')->is_success, 'Request should succeed' );


