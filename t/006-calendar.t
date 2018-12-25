use Test::More;

use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use_ok 'WS::Model::Calendar';

my $t = Test::Mojo->new( path('ws.pl') );

my $config = $t->app->plugin('Config');

my $mysql = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
);
my $db = $mysql->db;

my $cal = WS::Model::Calendar->new;

my $events = $cal->events($db, 'local', undef, 1);
my $n = scalar @$events;

my $id = $cal->add(
    db    => $db,
    title => 'testing',
    month => 1,
    day   => 1,
);

$events = $cal->events($db, 'local', undef, 1);
is $n, scalar(@$events) - 1, 'new events';

$cal->delete(db => $db, id => $id);

$events = $cal->events($db, 'local', undef, 1);
is $n, scalar(@$events), 'old events';

done_testing();
