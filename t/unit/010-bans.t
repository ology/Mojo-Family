use Test::More;

use Mojo::Base -strict;
use Mojo::mysql;
use Test::Mojo;
use Mojo::File qw( path );
use Mojolicious::Plugin::Config;

use_ok 'WS::Model::Bans';

my $t = Test::Mojo->new( path('ws.pl') );

use lib 't';
use DB;
my $db = DB::connect($t);

my $bans = WS::Model::Bans->new;

my $entries = $bans->entries($db);
my $n = scalar @$entries;

my ($id) = $bans->add(
    db => $db,
    ip => '123.234.345.456',
);

$entries = $bans->entries($db);
is $n, scalar(@$entries) - 1, 'new entries';

ok $bans->is_banned(
    db => $db,
    ip => '123.234.345.456',
), 'is_banned';

$bans->delete(db => $db, id => $id);

$entries = $bans->entries($db);
is $n, scalar(@$entries), 'old entries';

done_testing();
