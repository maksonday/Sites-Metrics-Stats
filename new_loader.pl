#!/usr/bin/perl

use Mojolicious::Lite -signatures;
use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::Promise;
use Mojo::URL;
use Fetcher;

get '/sites' => sub {
    my $c = shift;
    $c->render_later;
    run();
    Mojo::IOLoop->timer(2 => sub { $c->render('info'), \%sites });
};
app->start();

__DATA__

@@ info.html.ep
% use Time::Piece;
% my $now = localtime;
%my $sites = shift;
<!DOCTYPE html>
<html>
  <head><title>Time</title></head>
  <body>
  <% for (keys %$sites) {%>
    <li>
      <%== "$_ : $sites->{$_}->[0]" %>
    </li>
  <% } %>
  </body>
</html>