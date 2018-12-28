package WS::Model::Address;

use strict;
use warnings;

use WS::Model::DB;

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

    die "Invalid entry\n" unless $args{db} && $args{first_name} && $args{last_name};

    $args{db}->query(
        'INSERT INTO address (first_name,last_name,street,city,state,zip,phone,phone2,email,notes) VALUES (?,?,?,?,?,?,?,?,?,?)',
        $args{first_name}, $args{last_name}, $args{street}, $args{city}, $args{state}, $args{zip}, $args{phone}, $args{phone2}, $args{email}, $args{notes}
    );

    my $db = WS::Model::DB->new;
    my $id = $db->last_insert_id($args{db});

    return $id;
}

sub update {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id} && $args{first_name} && $args{last_name};

    $args{db}->query(
        'UPDATE address SET first_name=?, last_name=?, street=?, city=?, state=?, zip=?, phone=?, phone2=?, email=?, notes=? WHERE id = ?',
        $args{first_name}, $args{last_name}, $args{street}, $args{city}, $args{state}, $args{zip}, $args{phone}, $args{phone2}, $args{email}, $args{notes}, $args{id}
    );
}

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM address WHERE id = ?', $args{id} );
}

1;
