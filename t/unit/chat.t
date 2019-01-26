use Test::More;

use Mojo::Base -strict;
use Test::Mojo;
use Mojo::File qw( path );

use_ok 'WS::Model::Chat';

my $t = Test::Mojo->new( path('ws.pl') );

my $chat = new_ok('WS::Model::Chat');

my $lines = $chat->lines('chat.txt');
my $n = scalar @$lines;
ok defined($n), "$n lines seen";

my $text = $chat->format('Tester', 'local', 'Mary had a little lamb.');

like $text, qr|<b>Tester</b> <span class="smallstamp">|, 'format';

$chat->add('chat.txt', 'Tester', 'local', 'Mary had a little lamb.');

$lines = $chat->lines('chat.txt', 1);
like $lines->[0], qr/Mary had a little lamb/, 'add';

done_testing();
