use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DragonFlyGUI';
use DragonFlyGUI::Controller::DragonFlyGUI::Configuration;

ok( request('/dragonflygui/configuration')->is_success, 'Request should succeed' );
done_testing();
