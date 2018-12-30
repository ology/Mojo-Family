package WS::Model::History;

use strict;
use warnings;

sub new { bless {}, shift }

sub entries {
    my ($self, %args) = @_;

    my $db = delete $args{db};

    my $sql = 'SELECT * FROM history';

    my $entries;

    if ( keys %args ) {
        my $start = delete $args{when_start};
        my $end   = delete $args{when_end};

        if ( $start && $end ) {
        }

        my @params;
        for my $param ( sort keys %args ) {
            next unless $args{$param};
            push @params, "$param LIKE ?";
        }

        if ( @params ) {
            $sql .= ' WHERE ';
            $sql .= join ' AND ', @params;

            $entries = $db->query($sql, map { '%' . $args{$_} . '%' } grep { $args{$_} } sort keys %args);
        }
        else {
            $entries = $db->query($sql);
        }
    }


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
