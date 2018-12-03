package WS::Model::Chat;

use strict;
use warnings;

sub new { bless {}, shift }

sub lines {
    my ($self) = @_;

    my @lines = ('1. I like pie.', '2. I want a pony!');

    return \@lines;
}

1;
