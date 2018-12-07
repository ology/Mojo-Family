use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../ws.pl";

# Allow 302 redirect responses
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

$t->get_ok('/echo');
#    ->send_ok('Is this thing on?')
#    ->message_ok
#    ->message_is('Is this thing on?')
#    ->finish_ok;

done_testing();
