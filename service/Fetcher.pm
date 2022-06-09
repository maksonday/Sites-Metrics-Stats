package Fetcher;

use Mojo::Promise;
use Data::Dumper;
use Try::Tiny;
use List::Util qw (uniq);

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
    'rt.com',
    'mos.ru',
    '2gis.ru',
    'rutube.ru',
    'telegram.org',
    'fandom.com',
    'instagram.com'
);

sub run
{
    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(1);
    my @promises;
    for (@sites_list){
        push @promises, $ua->head_p($_)->timeout(1);
    }
    my @ref_promises;
    my $start_time = Time::HiRes::gettimeofday();
    my $cnt = 0;
    my $ref_cnt = 0;
    Mojo::Promise->all_settled(@promises)->then(sub(@promises){
        for my $tx(@promises){
            try{
                if ($tx->{status} eq 'fulfilled'){
                    my $res = $tx->{value}->[0]->res;
                    my $location = $res->headers->location;
                    $ref_cnt++ if $location;
                    warn $res->code unless $location;
                    $cnt++;
                    push @ref_promises, $ua->get_p($location)->timeout(1);
                }
                else{
                    warn $tx->{reason}->[0];
                }
            }
            catch{
                warn $_;
            }
        }
        
    })->catch(sub{
        my $err = shift;
        warn $err;
    })->wait;

    my %sites;

    my $i = 0;
    Mojo::Promise->all_settled(@ref_promises)->then(sub(@promises){
        for my $tx(@promises){
            try{
                if ($tx->{status} eq 'fulfilled'){
                    my $res = $tx->{value}->[0]->res;
                    my @arr = uniq ( ($res->body) =~ m/google\-analytics|mc\.yandex\.ru/g );
                    $i++;
                    $sites{$sites_list[$i++]} = \@arr;
                }
            }
            catch{
                warn $_;
            }
        }
        
    })->catch(sub{
        my $err = shift;
        warn $err;
    })->wait;
}

1;