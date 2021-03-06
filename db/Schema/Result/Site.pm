package db::Schema::Result::Site;

use base 'DBIx::Class::Core';

__PACKAGE__->table('sites');
__PACKAGE__->add_columns(qw(
	id
	name
	metrics
	comment
	position
));
__PACKAGE__->set_primary_key('id');

1;