package VPNManager::Schema::Result::Admin;

use v5.38.2;

use strict;
use warnings;

use feature 'signatures';

use parent 'DBIx::Class::Core';

__PACKAGE__->table('admins');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'INTEGER',
        is_auto_increment => 1,
    },
    username => {
        data_type   => 'TEXT',
        is_nullable => 0,
    },
    password => {
        data_type   => 'TEXT',
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key('id');
1;
