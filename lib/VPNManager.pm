package VPNManager;

use v5.38.2;

use strict;
use warnings;

use Mojo::Base 'Mojolicious', -signatures;

use Path::Tiny;

# This method will run once at server start
sub startup ($self) {

    # Load configuration from config file
    system 'chmod', '600',
      path(__FILE__)->parent->parent->child('v_p_n_manager.yml');
    my $config = $self->plugin('NotYAMLConfig');

    # Configure the application
    $self->secrets( $config->{secrets} );

    # Router
    my $r = $self->routes;

    # Normal route to controller
    my $routes = $r->under(
        '/app',
        sub {
            my $c              = shift;
            my $redirect_login = sub {
                my $c   = shift;
                my $url = Mojo::URL->new('/app/login');
                $url->query( redirect_to => $c->url_for );
                $c->redirect_to($url);
                return 0;
            };

            if ( $c->url_for->path =~ /^\/app\/login\/?$/ ) {
                return 1;
            }
            if ( !defined $c->session->{user} ) {
                return $redirect_login->($c);
            }
            require VPNManager::Schema;
            my $schema           = VPNManager::Schema->Schema;
            my $resultset_admins = $schema->resultset('Admin');
            my ($user)           = $resultset_admins->search(
                {
                    username => $c->session->{user},
                }
            );
            if ( !defined $user ) {
                delete $c->session->{user};
                return $redirect_login->($c);
            }
            return 1;
        }
    );
    my $root = sub {
        my $c     = shift;
        my $extra = $c->param('extra') // '';
        return $c->redirect_to( '/app/' . $extra );
    };
    $r->get( '/',       $root, );
    $r->get( '/*extra', $root, );
    $routes->get('/')->to('Main#main');
    $routes->get('/login')->to('Main#login');
    $routes->post('/login')->to('Main#login_post');
    $routes->get('/vpn/create-user')->to('Main#create_vpn_user');
    $routes->post('/vpn/create-user')->to('Main#create_vpn_user_post');
    $routes->get('/vpn/user/:id/details')->to('Main#show_user_details');
    $routes->post('/vpn/user/:id/download')->to('Main#download_file');
    $routes->post('/vpn/user/:id/enable')->to('Main#enable_user');
    $routes->post('/vpn/user/:id/disable')->to('Main#disable_user');
    $routes->post('/whitelist/add')->to('Main#whitelist_add');
    $routes->post('/whitelist/:id/remove')->to('Main#whitelist_remove');
}
1;
