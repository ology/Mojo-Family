use Test::More;

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw( path );

use_ok 'WS::Model::Users';

my $t = Test::Mojo->new( path('ws.pl') );

use lib 't';
use DB;
my $db = DB::connect($t);

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

my ($allowed, $active) = $users->check($db, $user, $pass);
ok $allowed, 'known user';
ok !$active, 'not yet active';

$pass = $users->reset(db => $db, id => $id);

($allowed, $active) = $users->check($db, $user, $pass);
ok $allowed, 'reset user';

$users->delete(db => $db, id => $id);

$entries = $users->entries($db);
is $n, scalar(@$entries), 'old entries';

done_testing();
