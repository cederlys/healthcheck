use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Statweb' }
BEGIN { use_ok 'Statweb::Controller::Domainset' }

ok(request('/domainset')->is_success, 'Request should succeed');

