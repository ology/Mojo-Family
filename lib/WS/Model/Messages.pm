package WS::Model::Messages;

use strict;
use warnings;

sub new { bless {}, shift }

sub entries {
    my ($self, $db) = @_;

    my $entries = $db->query('SELECT * FROM message');

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id         => $next->{id},
            stamp      => $next->{stamp}, 
            first_name => $next->{first_name},
            last_name  => $next->{last_name},
            username   => $next->{username},
            email      => $next->{email},
            month      => $next->{month},
            day        => $next->{day},
            message    => $next->{message},
        };
    }

    return \@entries;
}

sub add {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{first_name} && $args{last_name} && $args{email};

    $args{db}->query(
        'INSERT INTO message (first_name,last_name,email,username,month,day,message) VALUES (?,?,?,?,?,?,?)',
        $args{first_name}, $args{last_name}, $args{email}, $args{month}, $args{day}, $args{message}
    );
}

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM message WHERE id = ?', $args{id} );
}

1;
