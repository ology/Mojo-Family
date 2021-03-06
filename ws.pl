#!/usr/bin/env perl

use Cwd;
use Locale::US;
use Mojolicious::Lite;
use Mojo::mysql;

use lib 'lib';
use WS::Model::Users;
use WS::Model::Chat;
use WS::Model::Calendar;
use WS::Model::Address;
use WS::Model::Messages;
use WS::Model::Album;
use WS::Model::Bans;
use WS::Model::History;

#plugin NYTProf => { nytprof => {} };

plugin 'Config';

my $CWD = cwd();

# Locate the chat file
my $CHATFILE = $CWD . '/chat.txt';

# Establish a database connection
my $DB = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', app->config->{dbuser}, app->config->{dbpass}, app->config->{dbhost}, app->config->{dbname}
)->db;

# Make signed cookies tamper resistant
app->secrets(['I am the walrus']);

# Fix static paths
push @{app->static->paths}, $CWD . '/public',
                            $CWD . '/public/css';

# Helpers to lazy initialize and store model objects
helper messages => sub { state $messages = WS::Model::Messages->new };
helper users => sub { state $users = WS::Model::Users->new };
helper chat => sub { state $chat = WS::Model::Chat->new };
helper calendar => sub { state $calendar = WS::Model::Calendar->new };
helper address => sub { state $address = WS::Model::Address->new };
helper album => sub { state $album = WS::Model::Album->new };
helper bans => sub { state $bans = WS::Model::Bans->new };
helper history => sub { state $history = WS::Model::History->new };
 
# Connected websocket clients
my $clients = {};

websocket '/echo' => sub {
    my $c = shift;

    # Set a long timeout
    $c->inactivity_timeout(86400);

    # Get this client id
    my $id = sprintf '%s', $c->tx;
    $clients->{$id} = $c->tx;

    $c->on(json => sub {
        my ($c, $hash) = @_;

        # Add the new message to the chat file
        $c->chat->add(
            $CHATFILE, $c->session('user'), app->config->{timezone}, $hash->{msg}
        );

        # HTML format the message text
        $hash->{msg} = $c->chat->format(
            $c->session('user'), app->config->{timezone}, $hash->{msg}
        );

        # Send the message to the connected clients
        for (keys %$clients) {
            $clients->{$_}->send({json => $hash});
        }
    });
};
 
any '/' => sub {
    my $c = shift;

    if ( $c->bans->is_banned(db => $DB, ip => $c->tx->remote_address) ) {
        return $c->render(text => 'Forbidden', status => 403);
    }

    # Query parameters
    my $user = $c->param('user') || '';
    my $pass = $c->param('pass') || '';

    # Check password
    my ($allowed, $active) = $c->users->check($DB, $user, $pass);
    return $c->render unless $allowed;

    # Store username in session
    $c->session(user => $user);

    # Render the password reset form if not yet active
    return $c->render('password') unless $active;

    # Store admin in session for username
    my $entries = $c->users->active($DB);
    for my $entry ( @$entries ) {
        if ( $user = $entry->{username} ) {
            $c->session(admin => $entry->{admin});
            last;
        }
    }

    # Log the presence of the user
    $c->users->track(db => $DB, user => $user, tz => app->config->{timezone});

    # Redirect to protected page with a 302 response
    $c->redirect_to('chat');
} => 'index';
 
# Make sure user is logged in for actions in this group
group {
    under sub {
        my $c = shift;

        # We are authorized to proceed
        return 1 if $c->session('user');

        # Redirect to main page with a 302 response if user is not logged in
        $c->redirect_to('index');

        return undef;
    };

    get '/history' => sub {
        my $c = shift;
        my $entries;
        $c->stash(entries => $entries);
    };

    post '/history' => sub {
        my $c = shift;
        my $entries = $c->history->entries(
            db          => $DB,
            who         => $c->param('who'),
            what        => $c->param('what'),
            remote_addr => $c->param('remote_addr'),
            when_start  => $c->param('when_start'),
            when_end    => $c->param('when_end'),
        );
        $c->stash(entries => $entries);
        $c->render('history');
    };

    get '/bans' => sub {
        my $c = shift;
        my $entries = $c->bans->entries($DB);
        $c->stash(entries => $entries);
    };

    post '/bans' => sub {
        my $c = shift;

        my $method = $c->param('Ban') || $c->param('Delete');

        if ( $method eq 'Ban' ) {
            $c->bans->add(db => $DB, ip => $c->param('ip'));

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Add ban for ip: ' . $c->param('ip'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Delete' ) {
            $c->bans->delete(db => $DB, id => $c->param('id'));

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Delete ban for id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );
        }

        $c->redirect_to('bans');
    };

    get '/log' => sub {
        my $c = shift;
        my $entries = $c->users->active($DB);
        $c->stash(entries => $entries);
    };

    get '/password' => sub {};

    post '/password' => sub {
        my $c = shift;

        my $pass1 = $c->param('new_password');
        my $pass2 = $c->param('password_again');

        if ( $pass1 eq $pass2 && length($pass1) >= $c->users->pwsize() ) {
            $c->users->activate(
                db       => $DB,
                user     => $c->session('user'),
                password => $pass1,
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Reset password for: ' . $c->session('user'),
                remote_addr => $c->tx->remote_address,
            );
            $c->redirect_to('chat');
        }
        else {
            $c->flash(message => 'Passwords must match and be at least ' . $c->users->pwsize() . ' characters long.');
            $c->redirect_to('password');
        }
    };

    get '/messages' => sub {
        my $c = shift;
        my $messages = $c->messages->entries($DB);
        $c->stash(entries => $messages);
    };

    post '/messages' => sub {
        my $c = shift;

        my $method = $c->param('Grant') || $c->param('Deny');

        if ( $method eq 'Grant' ) {
            my $user = $c->param('username') || $c->param('first_name');
            my (undef, $pass) = $c->users->grant(
                db       => $DB,
                username => $user,
            );

            $c->album->add($user);

            $c->address->add(
                db         => $DB,
                first_name => $c->param('first_name'),
                last_name  => $c->param('last_name'),
                email      => $c->param('email'),
            );

            if ( $c->param('month') && $c->param('day') ) {
                $c->calendar->add(
                    db    => $DB,
                    title => $user,
                    month => $c->param('month'),
                    day   => $c->param('day'),
                );
            }

            $c->messages->delete(db => $DB, id => $c->param('id'));

            $c->stash(name => $c->param('first_name'));
            $c->stash(username => $user);
            $c->stash(password => $pass);
            $c->stash(email => $c->param('email'));
            $c->stash(database => app->config->{dbname});
            $c->stash(website => app->config->{website});

            $c->render('email');
        }
        else {
            $c->messages->delete(db => $DB, id => $c->param('id'));
            $c->redirect_to('messages');
        }
    };

    get '/email' => sub {};

    get '/users' => sub {
        my $c = shift;
        my $entries = $c->users->entries($DB);
        $c->stash(entries => $entries);
    };

    post '/users' => sub {
        my $c = shift;

        my $method = $c->param('Reset') || $c->param('Delete');

        if ( $method eq 'Delete' ) {
            $c->users->delete(
                db => $DB,
                id => $c->param('id'),
            );

            $c->album->delete($c->param('username'));

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Delete user id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Reset' ) {
            my $pass = $c->users->reset(
                db => $DB,
                id => $c->param('id'),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Reset password for id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );

            $c->flash(message => 'User: ' . $c->param('username') . ", Temporary password: $pass");
        }

        $c->redirect_to('users');
    };

    get '/chat' => sub {
        my $c = shift;

        my $lines = $c->chat->lines($CHATFILE);
        $c->stash(lines => $lines);

        my $events = $c->calendar->events($DB, app->config->{timezone});
        $c->stash(events => $events);

        my $important = $c->calendar->important($DB, app->config->{timezone});
        $c->stash(important => $important);
    };

    get '/calendar' => sub {
        my $c = shift;

        my $id = $c->param('id');
        my $month = $c->param('month');
        my $year = $c->param('year');

        my $event;
        if ( $id ) {
            $c->stash(method => 'Update');
            my $events = $c->calendar->events($DB, app->config->{timezone}, $id);
            $event = $events->[0] if $events;
        }
        else {
            $c->stash(method => 'Add');
            $event = {};
        }
        $c->stash(event => $event);

        $c->stash(month => $month);

        my $cal = $c->calendar->cal($DB, app->config->{timezone}, $year, $month);
        $c->stash(cal => $cal);
    };

    post '/calendar' => sub {
        my $c = shift;

        my $method = $c->param('Add') || $c->param('Update') || $c->param('Delete');

        if ( $method eq 'Add' ) {
            $c->calendar->add(
                db     => $DB,
                title  => defang( $c->param('event_title') ),
                month  => $c->param('event_month'),
                day    => $c->param('event_day'),
                note   => defang( $c->param('event_note') ),
                sticky => $c->param('event_sticky'),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Add calendar event: ' . $c->param('event_title'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Update' ) {
            $c->calendar->update(
                db     => $DB,
                id     => $c->param('id'),
                title  => defang( $c->param('event_title') ),
                month  => $c->param('event_month'),
                day    => $c->param('event_day'),
                note   => defang( $c->param('event_note') ),
                sticky => $c->param('event_sticky'),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Update calendar event id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Delete' ) {
            $c->calendar->delete(
                db => $DB,
                id => $c->param('id'),
            );
        }

        $c->redirect_to('/calendar?month=' . $c->param('event_month'));
    };

    get '/address' => sub {
        my $c = shift;

        my $id = $c->param('id');

        my $addr;
        if ( $id ) {
            $c->stash(method => 'Update');
            my $addrs = $c->address->addrs($DB, $id);
            $addr = $addrs->[0] if $addrs;
        }
        else {
            $c->stash(method => 'Add');
            $addr = {};
        }
        $c->stash(addr => $addr);

        my $addrs = $c->address->addrs($DB);
        $c->stash(addrs => $addrs);

        my $us = Locale::US->new;
        my @code = $us->all_state_codes;
        $c->stash(states => \@code);
    };

    post '/address' => sub {
        my $c = shift;

        my $method = $c->param('Add') || $c->param('Update') || $c->param('Delete');

        if ( $method eq 'Add' ) {
            $c->address->add(
                db         => $DB,
                first_name => defang( $c->param('first_name') ),
                last_name  => defang( $c->param('last_name') ),
                street     => defang( $c->param('street') ),
                city       => defang( $c->param('city') ),
                state      => $c->param('state'),
                zip        => $c->param('zip'),
                phone      => defang( $c->param('phone') ),
                phone2     => defang( $c->param('phone2') ),
                email      => defang( $c->param('email') ),
                notes      => defang( $c->param('notes') ),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Add address for: ' . $c->param('first_name') . ' ' . $c->param('last_name'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Update' ) {
            $c->address->update(
                db         => $DB,
                id         => $c->param('id'),
                first_name => defang( $c->param('first_name') ),
                last_name  => defang( $c->param('last_name') ),
                street     => defang( $c->param('street') ),
                city       => defang( $c->param('city') ),
                state      => $c->param('state'),
                zip        => $c->param('zip'),
                phone      => defang( $c->param('phone') ),
                phone2     => defang( $c->param('phone2') ),
                email      => defang( $c->param('email') ),
                notes      => defang( $c->param('notes') ),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Update address id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );
        }
        elsif ( $method eq 'Delete' ) {
            $c->address->delete(
                db => $DB,
                id => $c->param('id'),
            );

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Delete address id: ' . $c->param('id'),
                remote_addr => $c->tx->remote_address,
            );
        }

        $c->redirect_to('/address');
    };

    get '/album' => sub {
        my $c = shift;

        my $user;
        $user = $c->param('user');
        $c->stash(user => $user);

        my $users = $c->users->active($DB);
        unshift @$users, { username => 'Family' };
        my $files;
        for my $u ( @$users ) {
            my $name = $u->{username};
            my $f = $c->album->files($name);
            $files->{$name} = $f;
            $u->{pic} = $f->[0];
        }

        my $entries;

        if ( $user ) {
            $entries = $files->{$user};
        }
        else {
            $entries = $users;
        }

        $c->stash(entries => $entries);
    };

    post '/album' => sub {
        my $c = shift;

        return $c->render(text => 'File is too big.', status => 200)
            if $c->req->is_limit_exceeded;

        my $target = $c->param('target');

        my $upload = $c->param('filename');
        if ( $upload ) {
            my $size = $upload->size;
            my $name = $upload->filename;

            $upload->move_to("public/album/$target/$name");

            $c->history->add(
                db          => $DB,
                who         => $c->session('user'),
                what        => 'Upload file: ' . $name,
                remote_addr => $c->tx->remote_address,
            );

            $c->flash(message => "Uploaded $size byte file: $name");
        }

        $c->redirect_to("/album?user=$target");
    };

    get '/cookbook' => sub {};
};

get '/request' => sub {};

post '/request' => sub {
    my $c = shift;

    ( my $first = $c->param('first_name') ) =~ s/[\s'"]/_/g;

    $c->messages->add(
        db         => $DB,
        first_name => defang( $c->param('first_name') ),
        last_name  => defang( $c->param('last_name') ),
        email      => defang( $c->param('email') ),
        username   => defang( $c->param('username') ),
        $c->param('month') ? ( month => $c->param('month') ) : (),
        $c->param('day') ? ( day => $c->param('day') ) : (),
        message    => defang( $c->param('message') ),
    );

    $c->redirect_to('index');
};

get '/logout' => sub {
    my $c = shift;

    # Expire and in turn clear session automatically
    $c->session(expires => 1);

    # Redirect to main page with a 302 response
    $c->redirect_to('index');
};

sub defang {
    my ($string) = @_;
    return '' unless $string;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    return $string;
}

app->start;

__END__

=head1 AUTHOR
 
Gene Boggs <gene@cpan.org>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2019 by Gene Boggs.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut
