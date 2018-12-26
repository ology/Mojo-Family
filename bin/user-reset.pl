use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use WS::Model::Users;

my $user = shift || die "Usage: perl $0 username\n";

my $t = Test::Mojo->new( path('ws.pl') );

my $config = $t->app->plugin('Config');

my $mysql = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
);
my $db = $mysql->db;

my $users = WS::Model::Users->new;

my $entries = $users->entries($db);

my $id;
for my $entry ( @$entries ) {
    $id = $entry->{id}
        if $user eq $entry->{username};
}

my $pass = $users->reset(db => $db, id => $id);
print "Temporary password: $pass\n";
