use Test::More;

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw( path );

use_ok 'WS::Model::Messages';

my $t = Test::Mojo->new( path('ws.pl') );

use lib 't';
use DB;
my $db = DB::connect($t);

my $msg = new_ok('WS::Model::Messages');

my $entries = $msg->entries($db);
my $n = scalar @$entries;

my ($id) = $msg->add(
    db         => $db,
    first_name => 'Tester',
    last_name  => 'Testing',
    email      => 'tester@example.com',
);

$entries = $msg->entries($db);
is $n, scalar(@$entries) - 1, 'new entries';

$msg->delete(db => $db, id => $id);

$entries = $msg->entries($db);
is $n, scalar(@$entries), 'old entries';

done_testing();
