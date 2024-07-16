#!/usr/bin/env perl

use v5.38.2;

use strict;
use warnings;

use File::Basename qw/dirname/;

use lib dirname(dirname(__FILE__)).'/lib';

use Crypt::Bcrypt  qw/bcrypt/;
use Crypt::URandom qw/urandom/;
use VPNManager::Schema;

my $username = $ARGV[0] or die 'No username passed';
my $password = $ARGV[1] or die 'No password passed';

my $new_salt           = urandom(16);
my $encrypted_password = bcrypt $password, '2b', 12, $new_salt;

VPNManager::Schema->Schema->resultset('Admin')->populate(
    [
        {
            username => $username,
            password => $encrypted_password,
        }
    ]
);
