package WS::Model::Calendar;

use strict;
use warnings;

use DateTime;
use HTML::CalendarMonthSimple;

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

    my $results = $args{db}->query('SELECT LAST_INSERT_ID() AS id');

    my $id;
    while ( my $next = $results->hash ) {
        $id = $next->{id};
        last;
    }

    return $id;
}

sub update {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{month} && $args{day} && $args{title};

    $args{db}->query(
        'UPDATE calendar SET title=?, month=?, day=?, note=? WHERE id = ?',
        $args{title}, $args{month}, $args{day}, $args{note}, $args{id}
    );
}

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM calendar WHERE id = ?', $args{id} );
}

sub cal {
    my ($self, $db, $tz, $year, $month) = @_;

    my $now = DateTime->now( time_zone => $tz );
    $year ||= $now->year;
    $month ||= $now->month;

    my $sql = 'SELECT * FROM calendar WHERE month = ?';
    my $entries = $db->query($sql, $month);

    my $cal = HTML::CalendarMonthSimple->new( month => $month, year => $year );
    $cal->border(0);

    while ( my $next = $entries->hash ) {
        if ( $cal->getcontent( $next->{day} ) ) {
            $cal->addcontent( $next->{day}, '<br/>' );
        }
        $cal->addcontent(
            $next->{day},
            qq|<b><a href="/calendar?year=$year&month=$month&id=$next->{id}">$next->{title}</a></b>|
        );
    }

    return $cal->as_HTML;
}

1;
