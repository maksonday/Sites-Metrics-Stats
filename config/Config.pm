package Config;

use Config::Tiny;

sub get_dsn_data
{
    my ($username, $password, $host, $port, $driver, $dbname);
    my $config = Config::Tiny->read('config/config.ini');

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

1;
