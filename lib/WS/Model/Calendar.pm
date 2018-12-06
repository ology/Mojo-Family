package WS::Model::Calendar;

use strict;
use warnings;

use DateTime;

sub new { bless {}, shift }

sub events {
    my ( $self, $db, $tz, $id, $month ) = @_;

    $month ||= DateTime->now( time_zone => $tz )->month;

    my $param = $id ? $id : $month;

    my $sql = 'SELECT * FROM calendar WHERE ';
    $sql .= $id ? 'id = ?' : 'month = ?';

    my $entries = $db->query($sql, $param);

    my @events;
    while ( my $next = $entries->hash ) {
        push @events, {
            id    => $next->{id},
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
            id    => $next->{id},
            month => $next->{month},
            day   => $next->{day},
            title => $next->{title},
            note  => $next->{note},
        };
    }

    return \@events;
}

sub add {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{month} && $args{day} && $args{title};

    $args{db}->query(
        'INSERT INTO calendar (title, month, day, note) VALUES (?,?,?,?)',
        $args{title}, $args{month}, $args{day}, $args{note}
    );
}

sub update {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{month} && $args{day} && $args{title};

    $args{db}->query(
        'UPDATE calendar SET title=?, month=?, day=?, note=? WHERE id = ?',
        $args{title}, $args{month}, $args{day}, $args{note}, $args{id}
    );
}

1;