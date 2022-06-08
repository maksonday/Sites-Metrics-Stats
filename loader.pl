#!/usr/bin/perl
use strict;
use warnings;
use Mojo::UserAgent;
use Data::Dumper;
# Request a resource and make sure there were no connection errors
my $ua = Mojo::UserAgent->new;
my $tx = $ua->get('https://api.similarweb.com/v1/similar-rank/top-sites?api_key=b37ba7d2dd8d4c479977e63fc145438b&limit=50' => {Accept => 'application/json'});
my $res = $tx->result->json;
for (@{$res->{top_sites}}){
    #print $_->{domain}."\n";
}
my $ans = $ua->get('https://youtube.com')->result;
if ($ans->code == 301){
    $ans = $ua->get($ans->headers->location)->result;
}
my @tmp = split "\n", $ans->body;
my $metrics;
my @scripts;
my $analytics_pattern = '(google-analytics\.com|mc\.yandex\.ru)';
my $script_pattern = '<script\s+src\s*=\s*"([^"]+)"';
for (@tmp){
    if ( $metrics = ($_ =~ m/$analytics_pattern/g)[0] ){
        $metrics = $1;
        last;
    }
}
push @scripts, ($ans->body =~ m/$script_pattern/g);
unless ($metrics){
    for (@scripts){
        warn $_;
        my $script_ans = $ua->get($_)->result;
        if ( $metrics = ($script_ans->body =~ m/$analytics_pattern/g)[0] ){
            last;
        }
    }
}
warn Dumper $metrics;
