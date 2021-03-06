use Test::More;

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw( path );

use_ok 'WS::Model::History';

my $t = Test::Mojo->new( path('ws.pl') );

use lib 't';
use DB;
my $db = DB::connect($t);

my $history = new_ok('WS::Model::History');

my $entries = $history->entries(db => $db);
my $n = scalar @$entries;

$history->add(
    db          => $db,
    who         => 'Tester',
    what        => 'Testing',
    remote_addr => '127.0.0.1',
);

$entries = $history->entries(db => $db);
is $n, scalar(@$entries) - 1, 'new entries';

done_testing();
