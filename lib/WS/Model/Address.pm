package WS::Model::Address;

use strict;
use warnings;

sub new { bless {}, shift }

sub addrs {
    my ( $self, $db, $id ) = @_;

    my $entries;

    my $sql = 'SELECT * FROM address';

    if ( $id ) {
        $sql .= ' WHERE id = ?';
        $entries = $db->query($sql, $id);
    }
    else {
        $entries = $db->query($sql);
    }

    my @addrs;
    while ( my $next = $entries->hash ) {
        push @addrs, {
            id         => $next->{id},
            first_name => $next->{first_name} || '',
            last_name  => $next->{last_name} || '',
            street     => $next->{street} || '',
            city       => $next->{city} || '',
            state      => $next->{state} || '',
            zip        => $next->{zip} || '',
            phone      => $next->{phone} || '',
            phone2     => $next->{phone2} || '',
            email      => $next->{email} || '',
            notes      => $next->{notes} || '',
        };
    }

    return \@addrs;
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

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM calendar WHERE id = ?', $args{id} );
}

1;
