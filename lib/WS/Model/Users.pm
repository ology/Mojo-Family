package WS::Model::Users;

use strict;
use warnings;

use Crypt::SaltedHash;

sub new { bless {}, shift }

sub check {
    my ($self, $db, $user, $pass) = @_;

    my $entry = $db->query('SELECT * FROM user WHERE username = ?', $user);

    my $password;
    while (my $next = $entry->hash) {
        $password = $next->{password};
    }

    return Crypt::SaltedHash->validate($password, $pass);
}

sub active {
    my ($self, $db) = @_;

    my $entries = $db->query('SELECT * FROM user WHERE active = 1');

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id          => $next->{id},
            username    => $next->{username}, 
            last_login  => $next->{last_login},
            remote_addr => $next->{remote_addr},
            admin       => $next->{admin},
        };
    }

    return \@entries;
}

1;
