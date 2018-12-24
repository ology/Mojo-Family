use Test::More;
use Test::Mojo;
use Mojo::File qw( path );

my $t = Test::Mojo->new( path('ws.pl') );

# Allow 302 redirect responses
$t->ua->max_redirects(1);

$t->get_ok('/echo');
#    ->send_ok('Is this thing on?')
#    ->message_ok
#    ->message_is('Is this thing on?')
#    ->finish_ok;

done_testing();
