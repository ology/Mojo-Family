package WS::Model::Calendar;

use strict;
use warnings;

use Mojo::mysql;

sub new { bless {}, shift }

sub events {
    my ( $self, $tz ) = @_;

    my $month = DateTime->now( time_zone => $tz )->month;

    my $mysql = Mojo::mysql->strict_mode('mysql://root:abc123@localhost/example_family');
    my $db = $mysql->db;
    my $entries = $db->query('SELECT * FROM calendar WHERE month = ?', $month);

    my @events;
    while ( my $next = $entries->hash ) {
        push @events, {
            month => $next->{month},
            day   => $next->{day},
            title => $next->{title},
        };
    }

    return \@events;
}

1;
