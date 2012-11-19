use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DragonFlyGUI';
use DragonFlyGUI::Controller::Config;

ok( request('/config')->is_success, 'Request should succeed' );
done_testing();
