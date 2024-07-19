#!/usr/bin/env perl
use v5.38.2;

use strict;
use warnings;

use Moo;
use File::Basename qw/dirname/;
use lib dirname(dirname(__FILE__)).'/lib';
use VPNManager::Schema;
use JSON::PP;

sub get_json($self) {
    require VPNManager;
    my $config     = VPNManager->new->config;
    my $resultset = VPNManager::Schema->Schema->resultset('WhitelistConsole');
    my @users     = map { $_->username } $resultset->search( {} );
    my $json = JSON::PP->new;
    $json->canonical([1]);
    $json->pretty([1]);
    print $json->encode([@users]);
}
__PACKAGE__->new->get_json;
