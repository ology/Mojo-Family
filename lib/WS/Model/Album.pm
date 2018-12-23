package WS::Model::Album;

use strict;
use warnings;

use File::Find::Rule;

sub new { bless {}, shift }

sub files {
    my ($self, $user) = @_;

    my @files = File::Find::Rule->file()->in('public/album/' . $user);
    my @mtimes = map { { name => $_, mtime => (stat $_)[9] } } @files;
    @files = map { $_->{name} } sort { $b->{mtime} <=> $a->{mtime} } @mtimes;
    @files = map { s/^public(.*)$/$1/r } @files;

    return \@files;
}

1;
