#!/usr/bin/perl
use 5.26.0;

use Mojolicious::Lite -signatures;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path($0));

use Module::Find;
useall 'db';
useall 'config';

my @params = Config->new->get_dsn_data();
my $schema = Schema->connect(@params);

get '/top_sites' => sub {
    my $c = shift;
    my $sites = [ $schema->resultset('Site')->search(
        {},
        {
            order_by => { -asc => 'position' }
        })->all ];
    my @sites_info;
    for (@$sites){
        push(@sites_info, { name => $_->name, metrics => $_->metrics, position => $_->position });
    }
    $c->stash(stuff => \@sites_info);
    $c->render('info');
};

plugin Cron => ( '* * * * *' => sub {
    my $target_epoch = shift;
    {
        my $path = abs_path().'/fetcher.pl';
        do $path;
    }
});

app->start();

__DATA__

@@ info.html.ep
<!DOCTYPE HTML>
<html>
 <head>
  <meta charset="utf-8">
  <title>Таблица метрик топ-50 сайтов России</title>
 </head>
 <body>
    <table width="100%" border="1" cellspacing="0" cellpadding="4">
    <caption>Метрики, используемые топ-50 сайтами России(по версии SimilarWeb)</caption>
    <thead>
    <tr>
        <th>Место</th>
        <th>Имя сайта</th>
        <th>Используемые метрики</th>
    </tr>
    </thead>
    <tbody>
    % for my $item (@$stuff) {
        <tr class="text-nowrap">
        % if ( $item->{metrics} ){
            % if ( my $answer = join ', ', @{$item->{metrics} } ){
                <td><%= $item->{position} %></td>
                <td><%= $item->{name} %></td>
                <td><%= $answer %></td>
            % }
            % else {
                <td><%= $item->{position} %></td>
                <td><%= $item->{name} %></td>
                <td>другое</td>
            % }
        % }
        % else{
            <td><%= $item->{position} %></td>
            <td><%= $item->{name} %></td>
            <td>не удалось получить информацию</td>
        %}
        </tr>
    % }
    </tbody>
    </table>
 </body>
</html>