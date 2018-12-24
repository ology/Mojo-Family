#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'WS::Model::Album';

my $album = WS::Model::Album->new;

my $files = $album->files('Family');

my $expected = [qw(
    /album/Family/example_family.jpg
)];

is_deeply $files, $expected, 'Family files';

done_testing();
