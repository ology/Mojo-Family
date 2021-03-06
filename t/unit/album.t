#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'WS::Model::Album';

my $album = new_ok('WS::Model::Album');

my $user = 'test_' . time;

$album->add($user);
ok -d "public/album/$user", "$user created";
throws_ok { $album->add($user) } qr/File exists/, "$user re-create error";

$album->delete($user);
ok !-d "public/album/$user", "$user deleted";

done_testing();
