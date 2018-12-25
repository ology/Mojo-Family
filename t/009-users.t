use Test::More;

use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use_ok 'WS::Model::Users';

my $t = Test::Mojo->new( path('ws.pl') );

my $config = $t->app->plugin('Config');

my $mysql = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
);
my $db = $mysql->db;

my $users = WS::Model::Users->new;

my $user = 'test_' . time;

ok !$users->check($db, $user, 'foo'), 'unknown user';

my $entries = $users->entries($db);
my $n = scalar @$entries;

my ($id, $pass) = $users->grant(
    db       => $db,
    username => $user,
);

$entries = $users->entries($db);
is $n, scalar(@$entries) - 1, 'new entry';

ok $users->check($db, $user, $pass), 'known user';

$pass = $users->reset(db => $db, id => $id);

ok $users->check($db, $user, $pass), 'reset user';

$users->delete(db => $db, id => $id);

$entries = $users->entries($db);
is $n, scalar(@$entries), 'old entries';

done_testing();
