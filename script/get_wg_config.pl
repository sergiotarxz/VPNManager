#!/usr/bin/env perl
use v5.38.2;

use strict;
use warnings;

use Moo;
use File::Basename qw/dirname/;
use lib dirname(dirname(__FILE__)).'/lib';
use VPNManager::Schema;

sub get_vpn_settings($self) {
    require VPNManager;
    my $config     = VPNManager->new->config;
    my $vpn_config = <<"EOF";
[Interface]
Address = @{[$config->{vpn}{host}]}/@{[$config->{vpn}{submask}]}
MTU = @{[$config->{vpn}{mtu}]} 
SaveConfig = false
ListenPort = @{[$config->{vpnclients}{server_port}]}
PrivateKey = @{[$config->{vpn}{privkey}]}
EOF
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my @users     = $resultset->search( {} );

    for my $user (@users) {
        next if !$user->is_enabled;

        $vpn_config .= <<"EOF";

[Peer]
PublicKey = @{[$user->publickey]}
AllowedIPs = @{[$user->ip_to_text]}/32
Endpoint = @{[$config->{vpn}{endpoint}]}:@{[$config->{vpnclients}{server_port}]}
EOF
    }
    say $vpn_config;
}
__PACKAGE__->new->get_vpn_settings;
