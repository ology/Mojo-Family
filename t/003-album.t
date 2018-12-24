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

$album->add('foo');

ok -d 'public/album/foo', 'foo created';

throws_ok { $album->add('foo') } qr/File exists/, 'foo re-create error';

$album->delete('foo');

ok !-d 'public/album/foo', 'foo deleted';

done_testing();
