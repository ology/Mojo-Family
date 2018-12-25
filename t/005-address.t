use Test::More;
use Test::Exception;

use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use_ok 'WS::Model::Address';

my $t = Test::Mojo->new( path('ws.pl') );

my $config = $t->app->plugin('Config');

my $mysql = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
);
my $db = $mysql->db;

my $addr = WS::Model::Address->new;

my $addrs = $addr->addrs($db);
my $n = scalar @$addrs;

my $user = 'test_' . time;

my $id = $addr->add(
    db         => $db,
    first_name => $user,
    last_name  => 'Foo',
);

ok $id, "user: $user, id: $id";

$addrs = $addr->addrs($db);
is $n, scalar(@$addrs) - 1, 'new addrs';

$addr->delete(db => $db, id => $id);

$addrs = $addr->addrs($db);
is $n, scalar(@$addrs), 'old addrs';

done_testing();
