package WS::Model::History;

use strict;
use warnings;

use Date::Manip;

sub new { bless {}, shift }

sub entries {
    my ($self, %args) = @_;

    my $db = delete $args{db};

    my $sql = 'SELECT * FROM history';

    my $entries;

    if ( keys %args ) {
        my $start = delete $args{when_start};
        my $end   = delete $args{when_end};

        if ( $start || $end ) {
            if ( $start ) {
                $start = ParseDate($start);
                $start = join '-', UnixDate( $start, '%Y', '%m', '%d', '%T' );
            }
            else {
                $start = '1970-01-01';
            }
            if ( $end ) {
                $end = ParseDate($end);
                $end = join '-', UnixDate( $end, '%Y', '%m', '%d', '%T' );
            }
            else {
                $end = '2032-12-31';
            }
        }

        my @params;
        for my $param ( sort keys %args ) {
            next unless $args{$param};
            push @params, "$param LIKE ?";
        }

        if ( @params || $start ) {
            $sql .= ' WHERE ';

            my @dates = ();
            if ( $start ) {
                $sql .= '`when` BETWEEN ? AND ?';
                $sql .= ' AND ' if @params;
                @dates = ( $start, $end );
            }

            $sql .= join ' AND ', @params;

            $sql .= ' ORDER BY `when` DESC';

            $entries = $db->query($sql, @dates, map { '%' . $args{$_} . '%' } grep { $args{$_} } sort keys %args);
        }
        else {
            $sql .= ' ORDER BY `when` DESC';

            $entries = $db->query($sql);
        }
    }
    else {
        $sql .= ' ORDER BY `when` DESC';

        $entries = $db->query($sql);
    }


    my @entries;
    if ( $entries ) {
        while (my $next = $entries->hash) {
            push @entries, {
                id          => $next->{id},
                who         => $next->{who},
                what        => $next->{what},
                when        => $next->{when},
                remote_addr => $next->{remote_addr},
            };
        }
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
