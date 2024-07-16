package VPNManager::Controller::Main;

use v5.38.2;

use strict;
use warnings;

use Crypt::Bcrypt qw/bcrypt_check/;
use VPNManager::Schema;
use Capture::Tiny qw/capture_stdout/;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Path::Tiny;

sub main($self) {
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my @users     = $resultset->search( {} );
    $self->stash( users => \@users );
    $self->render( template => 'main/index' );
}

sub login($self) {
    $self->render( template => 'main/login' );
}

sub login_post($self) {
    my $password = $self->param('password');
    my $username = $self->param('username');
    my ($user)   = VPNManager::Schema->Schema->resultset('Admin')->search(
        {
            username => $username
        }
    );
    if ( !defined $user ) {
        return $self->_invalid_login;
    }
    if ( !bcrypt_check $password, $user->password ) {
        return $self->_invalid_login;
    }
    $self->session->{user} = $username;
    return $self->redirect_to('/');
}

sub _invalid_login($self) {
    $self->render( text => 'Invalid login', status => 401 );
}

sub create_vpn_user($self) {
    $self->render( template => 'vpn/create-user' );
}

sub create_vpn_user_post($self) {
    my $name           = $self->param('name');
    my $config         = $self->config;
    my $starting_ip    = $config->{vpnclients}{starting_ip};
    my $resultset      = VPNManager::Schema->Schema->resultset('VPNUser');
    my ($last_ip_user) = $resultset->search(
        {},
        {
            order_by => { -desc => 'ip' },
            rows     => 1,
        }
    );
    my $ip                     = $starting_ip;
    my $there_is_previous_user = 0;
    if ( defined $last_ip_user ) {
        $ip                     = $last_ip_user->ip_to_text;
        $there_is_previous_user = 1;
    }
    my $new_user = $resultset->new(
        { name => $name, publickey => '', ip => '', is_enabled => 0 } );
    $new_user->ip_from_text($ip);
    $new_user->ip( $new_user->ip + 1 ) if $there_is_previous_user;
    $ip = $new_user->ip_to_text;
    $new_user->insert;
    $new_user = $new_user->get_from_storage;
    my $id  = $new_user->id;
    my $url = Mojo::URL->new("/vpn/user/$id/details");
    return $self->redirect_to($url);
}

sub download_file($self) {
    my $id        = $self->param('id');
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my ($user)    = $resultset->search( { id => $id } );
    if ( !defined $user ) {
        return $self->render( text => 'No such user', status => 400 );
    }
    my $private_key = `wg genkey`;
    my $public_key  = capture_stdout sub {
        open my $fh, '|-', 'wg', 'pubkey';
        print $fh $private_key;
    };
    chomp $private_key;
    $user->update( { publickey => $public_key } );
    my $config   = $self->config;
    my $ip       = $user->ip_to_text;
    my $vpn_file = <<"EOF";
[Interface]
PrivateKey = $private_key
Address = $ip/32
DNS = @{[$config->{vpn}{host}]}

[Peer]
PublicKey = @{[$config->{vpn}{privkey}]}
AllowedIPs = @{[$config->{vpnclients}{allowedips}]}
Endpoint = @{[$config->{vpnclients}{endpoint}]}:@{[$config->{vpnclients}{server_port}]}
EOF
    my $filename = $user->name . '-vpn.conf';
    $self->res->headers->add( 'Content-Type',
        'application/x-download;name=' . $filename );
    $self->res->headers->add( 'Content-Disposition',
        'attachment;filename=' . $filename );
    $self->render( data => $vpn_file );
}

sub show_user_details($self) {
    my $id        = $self->param('id');
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my ($user)    = $resultset->search( { id => $id } );
    if ( !defined $user ) {
        return $self->render( text => 'No such user', status => 400 );
    }
    $self->stash( details_user => $user );
    return $self->render( template => 'vpn/user-details' );
}

sub enable_user($self) {
    my $id        = $self->param('id');
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my ($user)    = $resultset->search( { id => $id } );
    if ( !defined $user ) {
        return $self->render( text => 'No such user', status => 400 );
    }
    if ( $user->publickey eq '' ) {
        return $self->render(
            text   => 'You must first download the vpn file',
            status => 400
        );
    }
    $user->update( { is_enabled => 1 } );
    return $self->redirect_to('/');
}

sub disable_user($self) {
    my $id        = $self->param('id');
    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
    my ($user)    = $resultset->search( { id => $id } );
    if ( !defined $user ) {
        return $self->render( text => 'No such user', status => 400 );
    }
    return $self->render( text => 'This user is protected', status => 400 )
      if $user->is_protected;
    $user->update( { is_enabled => 0 } );
    return $self->redirect_to('/');
}

#sub save_vpn_settings($self) {
#    my $out_dir = path(__FILE__)->parent->parent->parent->parent->child('out');
#    $out_dir->mkpath;
#    system 'chmod', '700', $out_dir;
#    my $config     = $self->config;
#    my $vpn_config = <<"EOF";
#[Interface]
#Address = @{[$config->{vpn}{host}]}/@{[$config->{vpn}{submask}]}
#MTU = @{[$config->{vpn}{mtu}]} 
#SaveConfig = false
#ListenPort = @{[$config->{vpnclients}{server_port}]}
#PrivateKey = @{[$config->{vpn}{privkey}]}
#EOF
#    my $resultset = VPNManager::Schema->Schema->resultset('VPNUser');
#    my @users     = $resultset->search( {} );
#
#    for my $user (@users) {
#        next if !$user->is_enabled;
#
#        $vpn_config .= <<"EOF";
#
#[Peer]
#PublicKey = @{[$user->publickey]}
#AllowedIPs = @{[$user->ip_to_text]}/32
#Endpoint = @{[$config->{vpn}{endpoint}]}:@{[$config->{vpnclients}{server_port}]}
#EOF
#    }
#    $out_dir->child('wg0.conf')->spew_raw($vpn_config);
#    return $self->redirect_to('/');
#}
1;
