
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DragonFlyJob' );
use_ok('DragonFlyJob::Controller::Update');

ok( request('update')->is_success );

