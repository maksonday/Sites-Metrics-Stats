#!/usr/bin/perl
use 5.26.0;

use strict;
use warnings;

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path($0));

use Module::Find;
useall 'db';
useall 'config';
useall 'service';

my $config = Config->new();
my @params = $config->get_dsn_data();
my $schema = Schema->connect(@params);
my $sites_rs = $schema->resultset('Site');

my $link = $config->get_api_link();

my $fetcher = Fetcher->new();
my $sites_list = $fetcher->get_top_sites($link);
my $sites_info;
my %sites_positions;

if (scalar @$sites_list){
    $sites_info = $fetcher->fetch($sites_list);
    for my $i(0..@$sites_list - 1){
        $sites_positions{$sites_list->[$i]} = $i + 1;
    }
}
else{
    $fetcher->log('SimilarWeb API is not available');
    #Trying to fetch previously used sites
    my $saved_sites = [ 
        $sites_rs->search(
            {},
            {
                order_by => { -asc => 'position' }
            }
        )->all 
    ];
    for (@$saved_sites){
        push @$sites_list, $_->name;
        $sites_positions{$_->name} = $_->position;
    }
    if (scalar @$sites_list ){
        $sites_info = $fetcher->fetch($sites_list);
    }
    else{
        Fetcher->log('Nothing to fetch');
    }
}

my $sites_to_delete = $sites_rs->search(
    {
        name => {
            'not in' => [ @$sites_list ]
        }
    }
);

$sites_to_delete->delete;

my @sites_to_update = $sites_rs->search(
    {
        name => [ @$sites_list ]
    }
);

for (@sites_to_update){
    my $new_value = delete $sites_info->{$_->name};
    my $new_position = $sites_positions{$_->name};
    if (ref $new_value eq 'ARRAY'){
        $_->update({
            metrics => [ @$new_value ],
            position => $new_position
        });
    }
    elsif ($new_value){
        $_->update({
            comment => $new_value,
            position => $new_position
        });
    }
}

for (keys %$sites_info){
    my $value = $sites_info->{$_};
    my $metrics = (ref $value eq 'ARRAY') ? $value : undef;
    my $comment = ($value && (ref $value ne 'ARRAY')) ? $value : undef;
    my $position = $sites_positions{$_};

    $sites_rs->create({
        name => $_,
        metrics => $metrics,
        comment => $comment,
        position => $position,
    });
}