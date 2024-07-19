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
#        install_if_new_wireguard();
        install_if_new_whitelist();
        sleep 15;
    };
    if ($@) {
        warn $@;
    }
}

sub install_from_script($script, $output_file) {
    my $script_abs = abs_path(dirname(__FILE__). '/'. $script);
    my $user = 'vpnmanager';
    open my $fh, '-|', 'sudo', '-i', '-u', $user, 'perl', $script_abs;
    my $contents = join '', <$fh>;
    my $output_exists;
    open $fh, '<', $output_file and ($output_exists = 1);
    my $contents_output_file = '';
    $contents_output_file = join '', <$fh> if $output_exists;
    if ($contents ne $contents_output_file) {
        say 'Writting new file';
        say "Writting new file for $script -> $output_file";;
        system 'mkdir', '-p', dirname($output_file);
        open $fh, '>', $output_file;
        print $fh $contents;
        return 1;
    }
    say "Files equal for $script -> $output_file";;
}

sub install_if_new_wireguard {
    system 'systemctl', 'restart', 'wg-quick@wg0' if install_from_script('get_wg_config.pl', '/etc/wireguard/wg5.conf');
}

sub install_if_new_whitelist {
    install_from_script('get_whitelist_json.pl', '/etc/geyser-console/whitelist.json');
}
