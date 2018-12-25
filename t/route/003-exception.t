use Test::More;
use Test::Mojo;
use Mojo::File qw( path );

my $t = Test::Mojo->new( path('ws.pl') );

$t->app->routes->get(
    '/test/exception' => sub { die "Exception" },
);
$t->get_ok( '/test/exception' )->status_is( 500 );

done_testing();
