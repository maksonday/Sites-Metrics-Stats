package Fetcher;

use Moo;
use Mojo::Promise;
use List::Util qw (uniq);
use Mojo::UserAgent;
use Cwd qw( abs_path );

use Module::Find;
useall 'db';
useall 'config';

use Log::Log4perl;

has logger => (
    is => 'ro',
    default => sub {
        Log::Log4perl::init(abs_path().'/log.conf');
        Log::Log4perl->get_logger();
    }
);

has ua => (
    is => 'ro',
    default => sub {
        Mojo::UserAgent->new;
    }
);

sub log
{
    my ($self, $message) = @_;
    $self->logger->error($message);
}

sub fetch
{
    my ($self, $sites_list) = @_;
    
    my (@promises, @ref_promises, @ref_promises_indexes);
    my %sites_info;
    my @sites_info;

    for (@$sites_list){
        push(@promises, $self->ua->get_p($_));
    }

    my $analytics_pattern = '(google-analytics\.com|mc\.yandex\.ru)';

    Mojo::Promise->all_settled(@promises)->then(sub {
        my @promises = @_;
        my $cnt = 0;

        for my $tx(@promises){
            if ($tx->{status} eq 'fulfilled'){
                my $res = $tx->{value}->[0]->res;
                my $location = $res->headers->location || '';

                my @arr = uniq ( ($res->body) =~ m/$analytics_pattern/g );
                push(@sites_info, @arr ? \@arr : []);

                if ($location){
                    push(@ref_promises, $self->ua->get_p($location));
                    push(@ref_promises_indexes, @sites_info - 1);
                }
            }
            else{
                push(@sites_info, $tx->{reason}->[0]);
            }
            $cnt++;
        } 
    })->catch(sub {
        my $err = shift;
        $self->log($err);
    })->wait;

    
    Mojo::Promise->all_settled(@ref_promises)->then(sub {
        my @promises = @_;
        my $cnt = 0;
 
        for my $tx(@promises){
            if ($tx->{status} eq 'fulfilled'){
                my $res = $tx->{value}->[0]->res;
                my @arr = uniq ( ($res->body) =~ m/$analytics_pattern/g );
                $sites_info[$ref_promises_indexes[$cnt]] = @arr ? \@arr : [];
            }
            else{
                $sites_info[$ref_promises_indexes[$cnt]] = $tx->{reason}->[0];
            }
            $cnt++;
        }
        
    })->catch(sub {
        my $err = shift;
        $self->log($err);
    })->wait;

    for (0..@$sites_list - 1){
        $sites_info{$sites_list->[$_]} = $sites_info[$_];
    }

    return \%sites_info;
}

sub get_top_sites
{
    my ($self, $link) = @_;
    my @sites;

    my $res = $self->ua->get_p($link => {Accept => 'application/json'})->then(sub {
        my $tx = shift;
        my $res = $tx->result;
        if ($res->is_success){ 
            for (@{$res->json->{top_sites}}){
                push(@sites, $_->{domain});
            }
        }
    })->catch(sub {
        my $err = shift;
        $self->log("Connection error: $err");
    })->wait;
    
    return \@sites;
}

1;