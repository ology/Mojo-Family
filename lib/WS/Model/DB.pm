package WS::Model::DB;

use strict;
use warnings;

sub new { bless {}, shift }

sub last_insert_id {
    my ( $self, $db ) = @_;

    my $results = $db->query('SELECT LAST_INSERT_ID() AS id');

    my $id;
    while ( my $next = $results->hash ) {
        $id = $next->{id};
        last;
    }

    return $id;
}

1;
