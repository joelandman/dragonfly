
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DragonFlyJob' );
use_ok('DragonFlyJob::Controller::Query');

ok( request('query')->is_success );

