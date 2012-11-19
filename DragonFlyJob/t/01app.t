use Test::More tests => 2;
use_ok( Catalyst::Test, 'DragonFlyJob' );

ok( request('/')->is_success );
