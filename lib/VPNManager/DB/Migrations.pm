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
        'ALTER TABLE vpn_users rename column is_protected to is_protected_old;',
        'ALTER TABLE vpn_users add is_protected NOT NULL DEFAULT false;',
        'UPDATE vpn_users set is_protected = is_protected_old;',
        'CREATE TABLE whitelist_console (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE
        );',
    );
}
1;
