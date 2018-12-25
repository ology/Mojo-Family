use Test::More;

use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use_ok 'WS::Model::Messages';

my $t = Test::Mojo->new( path('ws.pl') );

my $config = $t->app->plugin('Config');

my $mysql = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
);
my $db = $mysql->db;

my $msg = WS::Model::Messages->new;

my $entries = $msg->entries($db);
my $n = scalar @$entries;

my $user = 'Test_' . time;

my ($id) = $msg->add(
    db         => $db,
    first_name => $user,
    last_name  => 'Test',
    email      => 'tester@example.com',
);

$entries = $msg->entries($db);
is $n, scalar(@$entries) - 1, 'new entries';

$msg->delete(db => $db, id => $id);

$entries = $msg->entries($db);
is $n, scalar(@$entries), 'old entries';

done_testing();
