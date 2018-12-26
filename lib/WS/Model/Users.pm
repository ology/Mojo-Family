package WS::Model::Users;

use strict;
use warnings;

use Crypt::SaltedHash;
use Text::Password::Pronounceable;

my $PWSIZE = 6;

sub new { bless {}, shift }

sub pwsize {
    my ($self) = @_;
    return $PWSIZE;
}

sub check {
    my ($self, $db, $user, $pass) = @_;

    my $entry = $db->query('SELECT * FROM user WHERE username = ?', $user);

    my $password;
    my $active;
    while (my $next = $entry->hash) {
        $password = $next->{password};
        $active = $next->{active};
    }

    return Crypt::SaltedHash->validate($password, $pass), $active;
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

sub grant {
    my ($self, %args) = @_;

    die "Invalid entry\n" unless $args{db} && $args{username};

    my $pass = Text::Password::Pronounceable->generate( $PWSIZE, $PWSIZE );

    my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
    $csh->add($pass);
    my $encrypted = $csh->generate;

    $args{db}->query(
        'INSERT INTO user (username,password) VALUES (?,?)',
        $args{username}, $encrypted
    );

    my $results = $args{db}->query('SELECT LAST_INSERT_ID() AS id');

    my $id;
    while ( my $next = $results->hash ) {
        $id = $next->{id};
        last;
    }

    return $id, $pass;
}

sub entries {
    my ($self, $db) = @_;

    my $entries = $db->query('SELECT * FROM user WHERE admin != 1 ORDER BY created');

    my @entries;
    while (my $next = $entries->hash) {
        push @entries, {
            id       => $next->{id},
            username => $next->{username},
            active   => $next->{active},
            admin    => $next->{admin},
        };
    }

    return \@entries;
}

sub delete {
    my ( $self, %args ) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    $args{db}->query( 'DELETE FROM user WHERE id = ?', $args{id} );
}

sub reset {
    my ($self, %args) = @_;

    die "Invalid entry\n" unless $args{db} && $args{id};

    my $pass = Text::Password::Pronounceable->generate( $PWSIZE, $PWSIZE );

    my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
    $csh->add($pass);
    my $encrypted = $csh->generate;

    $args{db}->query(
        'UPDATE user SET password=?, active=0 WHERE id = ?',
        $encrypted, $args{id}
    );

    return $pass;
}

sub activate {
    my ($self, %args) = @_;

    die "Invalid entry\n" unless $args{db} && $args{user} && $args{password};

    my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
    $csh->add($args{password});
    my $encrypted = $csh->generate;

    $args{db}->query(
        'UPDATE user SET password=?, active=1 WHERE username = ?',
        $encrypted, $args{user}
    );
}

1;
