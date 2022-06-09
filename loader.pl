#!/usr/bin/perl
use Mojo::UserAgent;
use Mojo::Promise;
use Data::Dumper;
use strict;
use warnings;

my $analytics_pattern = '(google-analytics\.com|mc\.yandex\.ru)';
my $script_pattern = '<script\s+src\s*=\s*"https:\/\/([^"]+)"';
my $ua = Mojo::UserAgent->new;
$ua         = $ua->connect_timeout(1);
my @sites_list = (
    'yandex.ru',
    'youtube.com',
    'google.com',
    'vk.com',
    'turbopages.org',
    'mail.ru',
    'ok.ru',
    'avito.ru',
    'wildberries.ru',
    'gismeteo.ru',
    'wikipedia.org',
    'ozon.ru',
    'market.yandex.ru',
    'google.ru',
    'ria.ru',
    'lenta.ru',
    'kinopoisk.ru',
    'news.mail.ru',
    'gosuslugi.ru',
    'rbc.ru',
    'rambler.ru',
    'whatsapp.com',
    'cloud.mail.ru',
    't.me',
    'aliexpress.ru',
    'xvideos.com',
    'music.yandex.ru',
    'drom.ru',
    'rus-tv.su',
    'dns-shop.ru',
    'sberbank.ru',
    'pikabu.ru',
    'ficbook.net',
    'livejournal.com',
    'mk.ru',
    'tsargrad.tv',
    'twitch.tv',
    'hh.ru',
    'vz.ru',
    'kp.ru',
    'drive2.ru',
    'roblox.com',
    'gazeta.ru',
    'instagram.com',
    'rt.com',
    'mos.ru',
    '2gis.ru',
    'rutube.ru',
    'telegram.org',
    'fandom.com'
);

main();

my %sites;
sub main
{
    #my $tx = $ua->get('https://api.similarweb.com/v1/similar-rank/top-sites?api_key=b37ba7d2dd8d4c479977e63fc145438b&limit=50' => {Accept => 'application/json'});
    #my $res = $tx->result->json;
    my $start_time = Time::HiRes::gettimeofday();
    for (@sites_list){
        my $analytics_service = fetch_site('https://'.$_) unless $_ =~ /facebook|instagram|twitter/;
        $sites{$_} = 'google' if ( $analytics_service || '' ) =~ /google/;
        $sites{$_} = 'yandex' if ( $analytics_service || '' ) =~ /yandex/;
    }
    my $stop_time = Time::HiRes::gettimeofday();
    printf("%.2f\n", $stop_time - $start_time);
    print Dumper \%sites;
}

sub fetch_site
{
    my $site = shift;
    my $metrics;
    $ua->get_p($site)->then(sub 
    {
        my $tx = shift;
        my $ans = $tx->result;
        #warn $tx->headers->location; 
        if ($ans->code == 301){
            $ua->get_p($ans->headers->location)->then(sub {
                my $tx = shift;
                $ans = $tx->result;
                my @scripts;
                $metrics = ($ans->body =~ m/$analytics_pattern/g)[0];
                #warn $metrics if $metrics;
                unless ( $metrics ){
                    push @scripts, ($ans->body =~ m/$script_pattern/g);
                    for (@scripts){
                        #warn $_;
                        $ua->get_p($_)->then(sub
                        {
                            my $script_ans = $tx->result;
                            if ( $metrics = ($script_ans->body =~ m/$analytics_pattern/g)[0] ){
                                $sites{$site} = 'google' if ( $metrics || '' ) =~ /google/;
                                $sites{$site} = 'yandex' if ( $metrics || '' ) =~ /yandex/;
                                #warn $metrics if $metrics;
                                last;
                            }
                        })->catch(
                            sub{
                                my $err = shift;
                                warn $err;
                            }
                        )->wait;
                    }
                }
                })->catch(
                            sub{
                                my $err = shift;
                                warn $err;
                            }
                        )->wait;
        }
        else{
            my @scripts;
            
            $metrics = ($ans->body =~ m/$analytics_pattern/g)[0];
            #warn $metrics if $metrics;
            unless ($metrics){
                push @scripts, ($ans->body =~ m/$script_pattern/g);
                for (@scripts){
                    $ua->get_p($_)->then(sub
                    {
                        my $script_ans = $tx->result;
                        if ( $metrics = ($script_ans->body =~ m/$analytics_pattern/g)[0] ){
                            $sites{$site} = 'google' if ( $metrics || '' ) =~ /google/;
                            $sites{$site} = 'yandex' if ( $metrics || '' ) =~ /yandex/;
                            #warn $metrics if $metrics;
                            last;
                        }
                    })->catch(
                            sub{
                                my $err = shift;
                                warn $err;
                            }
                        )->wait;
                }
            }
        }
    })->catch(
                            sub{
                                my $err = shift;
                                warn $err;
                            }
                        )->wait;
}



exit;
use Mojolicious::Lite;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
 
# Normal action
get '/' => {text => 'Hello World!'};
 
# Connect application with web server and start accepting connections
my $daemon = Mojo::Server::Daemon->new(app => app, listen => ['http://*:9000']);
$daemon->start;
 
# Call "one_tick" repeatedly from the alien environment
Mojo::IOLoop->one_tick while 1;