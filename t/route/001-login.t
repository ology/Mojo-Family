use Test::More;
use Test::Mojo;
use Mojo::File qw( path );

my $t = Test::Mojo->new( path('ws.pl') );

# Allow 302 redirect responses
$t->ua->max_redirects(1);

# Test if the HTML login form exists
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('form input[name="user"]')
  ->element_exists('form input[name="pass"]')
  ->element_exists('form input[type="submit"]');

# Test login with valid credentials
$t->post_ok('/' => form => {user => 'Gene', pass => 'aisa123'})
  ->status_is(200);

# Test accessing a protected page
$t->get_ok('/chat')
  ->status_is(200)
  ->content_like(qr/Family Chat/);

# Test if HTML login form shows up again after logout
$t->get_ok('/logout')
  ->status_is(200)
  ->element_exists('form input[name="user"]')
  ->element_exists('form input[name="pass"]')
  ->element_exists('form input[type="submit"]');

done_testing();
