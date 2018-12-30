package WS::Model::History;

use strict;
use warnings;

sub new { bless {}, shift }

sub entries {
    my ($self, %args) = @_;

    my $entries = $args{db}->query('SELECT * FROM history');

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id          => $next->{id},
            who         => $next->{who},
            what        => $next->{what},
            when        => $next->{when},
            remote_addr => $next->{remote_addr},
        };
    }

    return \@entries;
}

sub add {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db};

    $args{db}->query(
        'INSERT INTO history (who,what,remote_addr) VALUES (?,?,?)',
        $args{who}, $args{what}, $args{remote_addr}
    );

    my $db = WS::Model::DB->new;
    my $id = $db->last_insert_id($args{db});

    return $id;
}

1;
