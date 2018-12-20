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

1;
