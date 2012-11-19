
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DragonFlyJob' );
use_ok('DragonFlyJob::Controller::Add');

ok( request('add')->is_success );

