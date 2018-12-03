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

1;
