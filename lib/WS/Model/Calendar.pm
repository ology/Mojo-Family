package WS::Model::Calendar;

use strict;
use warnings;

sub new { bless {}, shift }

sub events {
    my ( $self, $db, $tz ) = @_;

    my $month = DateTime->now( time_zone => $tz )->month;

    my $entries = $db->query('SELECT * FROM calendar WHERE month = ?', $month);

    my @events;
    while ( my $next = $entries->hash ) {
        push @events, {
            month => $next->{month},
            day   => $next->{day},
            title => $next->{title},
            note  => $next->{note},
        };
    }

    return \@events;
}

sub important {
    my ( $self, $db, $tz ) = @_;

    my $month = DateTime->now( time_zone => $tz )->month;

    my $entries = $db->query('SELECT * FROM calendar WHERE month != ? AND important = 1', $month);

    my @events;
    while ( my $next = $entries->hash ) {
        push @events, {
            month => $next->{month},
            day   => $next->{day},
            title => $next->{title},
            note  => $next->{note},
        };
    }

    return \@events;
}

1;
