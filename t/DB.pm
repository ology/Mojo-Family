package DB;

use Mojo::mysql;
use Mojolicious::Plugin::Config;

sub connect {
    my ($t) = @_;

    my $config = $t->app->plugin('Config');

    my $mysql = Mojo::mysql->strict_mode(
        sprintf 'mysql://%s:%s@%s/%s', $config->{dbuser}, $config->{dbpass}, $config->{dbhost}, $config->{dbname}
    );

    return $mysql->db;
}

1;
