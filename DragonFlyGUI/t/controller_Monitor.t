use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DragonFlyGUI';
use DragonFlyGUI::Controller::Monitor;

ok( request('/monitor')->is_success, 'Request should succeed' );
done_testing();
