use Test::More;

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw( path );

use_ok 'WS::Model::Calendar';

my $t = Test::Mojo->new( path('ws.pl') );

use lib 't';
use DB;
my $db = DB::connect($t);

my $cal = new_ok('WS::Model::Calendar');

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
