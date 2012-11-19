use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DragonFlyJob' }
BEGIN { use_ok 'DragonFlyJob::Controller::Log' }

ok( request('/log')->is_success, 'Request should succeed' );


