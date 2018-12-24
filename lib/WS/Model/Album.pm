package WS::Model::Album;

use strict;
use warnings;

use File::Find::Rule;
use File::Path qw( remove_tree );

my $ALBUM = 'public/album';

sub new { bless {}, shift }

sub files {
    my ($self, $user) = @_;

    my @files = File::Find::Rule->file()->in("$ALBUM/$user");
    my @mtimes = map { { name => $_, mtime => (stat $_)[9] } } @files;
    @files = map { $_->{name} } sort { $b->{mtime} <=> $a->{mtime} } @mtimes;
    @files = map { s/^public(.*)$/$1/r } @files;

    return \@files;
}

sub add {
    my ($self, $user) = @_;

    my $path = "$ALBUM/$user";

    mkdir($path) or die "Can't mkdir $path: $!";

    open( my $fh, '>', "$path/image.caption" ) if -d $path;
}

sub delete {
    my ($self, $user) = @_;

    my $count = 0;

    my $path = "$ALBUM/$user";
    if ( $user && -d $path ) {
        $count = remove_tree($path);
    }

    return $count;
}

1;
