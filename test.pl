#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path($0));

use Module::Find;
useall 'db';
useall 'config';

my @params = Config->get_dsn_data();

my $schema = Schema->connect(@params);
my @source_names = $schema->sources;
warn Dumper \@source_names;
my $site = $schema->resultset('Site')->search(
    {
        'me.name' => 'xyz.ru'
    }
)->single;