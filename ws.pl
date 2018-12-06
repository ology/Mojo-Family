#!/usr/bin/env perl

use Cwd;
use Mojolicious::Lite;
use Mojo::mysql;

use lib 'lib';
use WS::Model::Users;
use WS::Model::Chat;
use WS::Model::Calendar;

plugin 'Config';

my $CWD = cwd();

my $CHATFILE = $CWD . '/chat.txt';

my $DB = Mojo::mysql->strict_mode(
    sprintf 'mysql://%s:%s@%s/%s', app->config->{dbuser}, app->config->{dbpass}, app->config->{dbhost}, app->config->{dbname}
)->db;

# Make signed cookies tamper resistant
app->secrets(['I am the walrus']);

# Fix static paths
push @{app->static->paths}, $CWD . '/public',
                            $CWD . '/public/css';

# Helpers to lazy initialize and store model objects
helper users => sub { state $users = WS::Model::Users->new };
helper chat => sub { state $chat = WS::Model::Chat->new };
helper calendar => sub { state $calendar = WS::Model::Calendar->new };
 
my $clients = {};

websocket '/echo' => sub {
    my $c = shift;

    $c->inactivity_timeout(86400);

    my $id = sprintf '%s', $c->tx;
    $clients->{$id} = $c->tx;

    $c->on(json => sub {
        my ($ctrl, $hash) = @_;

        $ctrl->chat->add(
            $CHATFILE, $ctrl->session('user'), app->config->{timezone}, $hash->{msg}
        );

        $hash->{msg} = $ctrl->chat->format(
            $ctrl->session('user'), app->config->{timezone}, $hash->{msg}
        );

        for (keys %$clients) {
            $clients->{$_}->send({json => $hash});
        }
    });
};
 
any '/' => sub {
    my $c = shift;

    # Query parameters
    my $user = $c->param('user') || '';
    my $pass = $c->param('pass') || '';

    # Check password
    return $c->render
        unless $c->users->check($DB, $user, $pass);

    # Store username in session
    $c->session(user => $user);

    # Redirect to protected page with a 302 response
    $c->redirect_to('chat');
} => 'index';
 
# Make sure user is logged in for actions in this group
group {
    under sub {
        my $c = shift;
        # Redirect to main page with a 302 response if user is not logged in
        return 1 if $c->session('user');
        $c->redirect_to('index');
        return undef;
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

        my $events = $c->calendar->events($DB, app->config->{timezone}, undef, $month);
        $c->stash(events => $events);
        $c->stash(month => $month);
    };

    post '/calendar' => sub {
        my $c = shift;

        my $method = $c->param('Add') || $c->param('Update') || $c->param('Delete');

        if ( $method eq 'Add' ) {
            $c->calendar->add(
                db     => $DB,
                title  => $c->param('event_title'),
                month  => $c->param('event_month'),
                day    => $c->param('event_day'),
                note   => $c->param('event_note'),
                sticky => $c->param('event_sticky'),
            );
        }
        elsif ( $method eq 'Update' ) {
            $c->calendar->update(
                db     => $DB,
                id     => $c->param('id'),
                title  => $c->param('event_title'),
                month  => $c->param('event_month'),
                day    => $c->param('event_day'),
                note   => $c->param('event_note'),
                sticky => $c->param('event_sticky'),
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
};

get '/logout' => sub {
    my $c = shift;

    # Expire and in turn clear session automatically
    $c->session(expires => 1);

    # Redirect to main page with a 302 response
    $c->redirect_to('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default', title => 'Login';
<div class="container">
<h1><%= title %></h1>
%= form_for index => begin
    % if (param 'user') {
        <b>Wrong name or password, please try again.</b><br>
    % }
    %= text_field 'user', placeholder => 'Name'
    %= tag 'br'
    %= password_field 'pass', placeholder => 'Password'
    %= tag 'br'
    %= submit_button 'Login'
% end
</div>

@@ chat.html.ep
% my $placeholder = "What's on your mind, " . $c->session('user') . '?';
% layout 'default', title => 'Family Chat';
<div class="container">
%= include 'header', title => 'Family Chat', month => 1;
%= text_area 'chat', name => 'text', class => 'chat', id => 'chat', placeholder => $placeholder
%= tag 'br'
%= submit_button 'Chat', name => 'submit', id => 'submit', class => 'button-primary'
%= tag 'br'
<div class="row">
    <div class="nine columns">
        <div name="data" id="data">
% for my $line ( @$lines ) {
            <p><%== $line %></p>
% }
        </div>
    </div>
    <div class="three columns">
        <b>This month:</b>
%= tag 'br'
        <ul class="event">
% for my $event ( @$events ) {
            <li><%= $event->{month} %>/<%= $event->{day} %> - <%= $event->{title} %>
%       if ( $event->{note} ) {
%= tag 'br'
                &nbsp;&nbsp;&nbsp;&nbsp; <span class="event_note"><%= $event->{note} %></span>
%       }
                </li>
% }
        </ul>
% if ( @$important ) {
        <b>This year:</b>
%= tag 'br'
        <ul class="event">
%   for my $event ( @$important ) {
            <li><%= $event->{month} %>/<%= $event->{day} %> - <%= $event->{title} %>
%       if ( $event->{note} ) {
%= tag 'br'
                &nbsp;&nbsp;&nbsp;&nbsp; <span class="event_note"><%= $event->{note} %></span>
%       }
                </li>
%   }
        </ul>
% }
    </div>
</div>
<script>
    var ws = new WebSocket('<%= url_for('echo')->to_abs %>');
    ws.onmessage = function (event) {
        $('#data').prepend('<p>' + JSON.parse(event.data).msg + '</p>');
    };
    ws.onopen = function (event) {
        console.log('ws.onopen');
    };
    $('#submit').click(function (e) {
        if ($('#chat').val()) {
            ws.send(JSON.stringify({msg: $('#chat').val()}));
            $('#chat').val('');
        }
    });
</script>
</div>


@@ calendar.html.ep
% layout 'default', title => 'Calendar';
<div class="container">
%= include 'header', title => 'Calendar';
<div class="row">
    <div class="eight columns">
%= form_for calendar => (method => 'POST') => begin
    %= text_field 'event_title' => $event->{title}, size => 20, maxlength => 20, placeholder => 'Title'
    Month:
    <select name="event_month">
% for my $i ( 1 .. 12 ) {
        <option value="<%= $i %>"
%   if ( $event->{month} && $i == $event->{month} ) {
            selected
%   }
><%= $i %></option>
% }
    </select>
    Day:
    <select name="event_day">
% for my $i ( 1 .. 31 ) {
        <option value="<%= $i %>"
%   if ( $event->{day} && $i == $event->{day} ) {
            selected
%   }
><%= $i %></option>
% }
    </select>
    %= tag 'br'
    %= text_field 'event_note' => $event->{note}, size => 50, maxlength => 90, placeholder => 'Notes'
    &nbsp;&nbsp;Sticky:
    %= check_box 'event_sticky' => $event->{sticky}
% if ( $method eq 'Add' ) {
    &nbsp;&nbsp;Notify chat:
    %= check_box 'event_notify'
    %= tag 'br'
    %= submit_button $method, name => $method, id => $method, class => 'button-primary'
    <input type="reset" name="reset" value="reset" class="button" />
% } else {
    %= tag 'br'
    %= hidden_field 'id' => $event->{id}
    %= hidden_field 'month' => $event->{month}
    %= submit_button $method, name => $method, id => $method, class => 'button-primary'
    &nbsp;
    <input type="submit" name="Delete" value="Delete" id="Delete" class="button-primary" onclick="return confirm('Delete <%= $event->{title} %>?')" />
    &nbsp;
    %= link_to Cancel => 'calendar', class => 'button'
% }
% end
    </div>
    <div class="four columns rightpad">
%= form_for calendar => (method => 'GET') => begin
    Goto:
    <select name="month" onchange="this.form.submit()">
% for my $i ( 1 .. 12 ) {
        <option value="<%= $i %>"
%   if ( $month && $i == $month ) {
            selected
%   }
><%= $i %></option>
% }
    </select>
%= end
<p>Prev: <%= $prev_month %>, Next: <%= $next_month %></p>
    </div>
</div>
<ol>
% for my $event ( @$events ) {
            <li>
                <a href="/calendar?id=<%= $event->{id} %>&month=<%= $event->{month} %>"><%= $event->{month} %>/<%= $event->{day} %></a> - <%= $event->{title} %>
%       if ( $event->{note} ) {
%= tag 'br'
                &nbsp;&nbsp;&nbsp;&nbsp; <span class="event_note"><%= $event->{note} %></span>
%       }
                </li>
% }
</ol>
</div>


@@ header.html.ep
<div class="row">
    <div class="three columns">
        <h4><b><i><%= title %>!</i></b></h4>
    </div>
    <div class="nine columns btnright">
        <b><a class="button" href="/addressbook">Addresses</a></b>
        <b><a class="button" href="/album">Album</a></b>
        <b><a class="button" href="/calendar">Calendar</a></b>
        <b><a class="button" href="/">Chat</a></b>
        <b><a class="button" href="/cookbook">Cookbook</a></b>
% if ( title eq 'History' || title eq 'Ban' || title eq 'Email' || title eq 'Log' || title eq 'Users' || title eq 'Messages' ) {
        <b><a class="button" href="/ban">Bans</a></b>
        <b><a class="button" href="/history">History</a></b>
        <b><a class="button" href="/log">Log</a></b>
        <b><a class="button" href="/messages">Messages</a></b>
        <b><a class="button" href="/users">Users</a></b>
% }
        <b><a class="button" href="/logout">Logout</a></b>
    </div>
</div>


@@ exception.development.html.ep
% layout 'default', title => 'Error';
<div class="container">
%= include 'header', title => 'Error';
<p><%= $exception->message %></p>
</div>


@@ layouts/default.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title><%= title %></title>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="google" content="notranslate">
    <link rel="stylesheet" type="text/css" href="<%= url_for 'normalize.css' %>">
    <link rel="stylesheet" type="text/css" href="<%= url_for 'skeleton.css' %>">
    <link rel="stylesheet" type="text/css" href="<%= url_for 'style.css' %>">
    <script src="//ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
</head>
<body>
<%= content %>
<div class="row brown">
<div class="four columns leftpad">
<%= link_to '/privacy.html' => begin %>Privacy policy<% end %>
</div>
<div class="four columns centerpad">
<%= link_to '/help.html' => begin %>Help<% end %>
</div>
<div class="four columns rightpad">
    Built by <a href="http://gene.ology.net/">Gene Boggs</a>
</div>
</div>
</body>
</html>
