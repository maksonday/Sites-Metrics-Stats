package Config;

use Moo;
use Config::Tiny;

has ini_file => (
    is => 'ro',
    default => sub {
        Config::Tiny->read('config/config.ini');
    }
);

sub get_dsn_data
{
    my $self = shift;

    my ($username, $password, $host, $port, $driver, $dbname);
    my $config = $self->ini_file;

    if ($config->{db}){
        ($username, $password, $host, $port, $driver, $dbname) = @{$config->{db}}{qw(username password host port driver dbname)};
    }

    $username //= $ENV{DB_USERNAME};
    $password //= $ENV{DB_PASSWORD};
    $host //= $ENV{DB_POST};
    $port //= $ENV{DB_PORT};
    $driver //= $ENV{DB_DRIVER};
    $dbname //= $ENV{DB_NAME};

    my $dsn = sprintf('DBI:%s:dbname=%s', $driver, $dbname);
    $dsn .= sprintf(';host=%s', $host) if $host;
	$dsn .= sprintf(';port=%s', $port) if $port;

    return ($dsn, $username, $password);
}

sub get_api_link
{
    my $self = shift;

    my $config = $self->ini_file;
    my $link = '';
    if ($config->{similarweb}){
        $link = sprintf $config->{similarweb}->{link}, $config->{similarweb}->{apikey};
    }

    return $link;
}

1;
