package WS::Model::Users;

use strict;
use warnings;

use Crypt::SaltedHash;
use Mojo::mysql;

sub new { bless {}, shift }

sub check {
    my ($self, $user, $pass) = @_;

    my $mysql = Mojo::mysql->strict_mode('mysql://root:abc123@localhost/example_family');
    my $db = $mysql->db;
    my $entry = $db->query('SELECT * FROM user WHERE username = ?', $user);

    my $password;
    while (my $next = $entry->hash) {
        $password = $next->{password};
    }

    return Crypt::SaltedHash->validate($password, $pass);
}

1;
