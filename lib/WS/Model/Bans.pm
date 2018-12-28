package WS::Model::Bans;

use strict;
use warnings;

sub new { bless {}, shift }

sub entries {
    my ($self, $db) = @_;

    my $entries = $db->query('SELECT * FROM ban');

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id        => $next->{id},
            ip        => $next->{ip}, 
            last_seen => $next->{last_seen},
        };
    }

    return \@entries;
}

sub add {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{ip};

    $args{db}->query(
        'INSERT INTO ban (ip) VALUES (?)',
        $args{ip}
    );

    my $results = $args{db}->query('SELECT LAST_INSERT_ID() AS id');

    my $id;
    while ( my $next = $results->hash ) {
        $id = $next->{id};
        last;
    }

    return $id;
}

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM ban WHERE id = ?', $args{id} );
}

sub is_banned {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{ip};

    my $entries = $args{db}->query( 'SELECT * FROM ban WHERE ip = ?', $args{ip} );

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id        => $next->{id},
            ip        => $next->{ip}, 
            last_seen => $next->{last_seen},
        };
    }

    return @entries ? 1 : 0;
}

1;
