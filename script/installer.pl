#!/usr/bin/env perl

use v5.38.2;

use strict;
use warnings;
use File::Basename qw/dirname/;
use Cwd 'abs_path';

if ($> != 0) {
    die 'You must be root.';
}

while (1) {
    eval {
        install_if_new();
        sleep 15;
    };
    if ($@) {
        warn $@;
    }
}

sub install_if_new {
    my $script_get_wg_config = abs_path(dirname(__FILE__).'/get_wg_config.pl');
    my $user = 'vpnmanager';
    open my $fh, '-|', 'sudo', '-i', '-u', $user, 'perl', $script_get_wg_config;
    my $contents = join '', <$fh>;
    my $output_file = '/etc/wireguard/wg0.conf';
    my $output_exists;
    open $fh, '<', $output_file and ($output_exists = 1);
    my $contents_output_file = '';
    $contents_output_file = join '', <$fh> if $output_exists;
    if ($contents ne $contents_output_file) {
        say 'Writting new file';
        open $fh, '>', $output_file;
        print $fh $contents;
        system 'systemctl', 'restart', 'wg-quick@wg0';
        return;
    }
    say 'Files equal';
}
