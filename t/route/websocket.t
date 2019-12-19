use Test::More;
use Test::Mojo;
use Mojo::File qw( path );

my $t = Test::Mojo->new( path('ws.pl') );

# Allow 302 redirect responses
$t->ua->max_redirects(1);

$t->get_ok('/echo')
#    ->send_ok({json => {msg => 'I ♥ Mojolicious!'}})
#    ->message_ok
#    ->json_message_is('echo' => 'I ♥ Mojolicious!')
#    ->finish_ok
;

done_testing();
