#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'WS::Model::Album';

my $album = WS::Model::Album->new;

my $files = $album->files('Family');

my $expected = [qw(
    /album/Family/example_family.jpg
)];

is_deeply $files, $expected, 'Family files';

my $user = 'test_' . time;

$album->add($user);
ok -d "public/album/$user", "$user created";
throws_ok { $album->add($user) } qr/File exists/, "$user re-create error";

$album->delete($user);
ok !-d "public/album/$user", "$user deleted";

done_testing();
