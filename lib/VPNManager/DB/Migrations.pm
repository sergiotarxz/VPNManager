package VPNManager::DB::Migrations;

use v5.34.1;

use strict;
use warnings;
use utf8;

use feature 'signatures';

sub MIGRATIONS {
    return (
        'CREATE TABLE options (
            name TEXT PRIMARY KEY,
            value TEXT
        );',
        'CREATE TABLE vpn_users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            publickey TEXT NOT NULL,
            is_enabled INTEGER NOT NULL DEFAULT true,
            is_protected INTEGER NOT NULL DEFAULT true,
            is_deleted INTEGER NOT NULL DEFAULT false,
            ip INTEGER NOT NULL
        );',
        'CREATE TABLE admins (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
        );',
    );
}
1;
