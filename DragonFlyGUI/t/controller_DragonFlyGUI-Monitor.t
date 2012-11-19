use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DragonFlyGUI';
use DragonFlyGUI::Controller::DragonFlyGUI::Monitor;

ok( request('/dragonflygui/monitor')->is_success, 'Request should succeed' );
done_testing();
