package VPNManager::Schema::Result::VPNUser;

use v5.38.2;

use strict;
use warnings;

use feature 'signatures';

use parent 'DBIx::Class::Core';

__PACKAGE__->table('vpn_users');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'INTEGER',
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'TEXT',
        is_nullable => 0,
    },
    publickey => {
        data_type   => 'TEXT',
        is_nullable => 0,
    },
    is_enabled => {
        data_type   => 'INTEGER',
        is_nullable => 1,
    },
    is_protected => {
        data_type   => 'INTEGER',
        is_nullable => 1,
    },
    is_deleted => {
        data_type   => 'INTEGER',
        is_nullable => 1,
    },
    ip => {
        data_type   => 'INTEGER',
        is_nullable => 0,
    },
);

sub ip_to_text($self) {
    my @octets;
    for my $i (0..3) {
        push @octets, ($self->ip >> (abs(3-$i) * 8)) & 0xff;
    }
    return join '.', @octets;
}

sub ip_from_text($self, $ip) {
    my @octets = split /\./, $ip;
    my $raw_ip = 0;
    for my $i (0..3) {
        $raw_ip |= (($octets[$i] & 0xff) << (abs(3-$i) * 8));
    }
    $self->ip($raw_ip);
}
__PACKAGE__->set_primary_key('id');
1;
