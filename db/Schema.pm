package Schema;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(result_namespace => [ '+db::Schema::Result' ],);
__PACKAGE__->load_classes();

1;