#!/usr/bin/env perl
use 5.014;
use strict;
use Tkx;
use Tkx::LabEntry;

our $PROGNAME = 'MyProgram';
our $VERSION  = '0.1';

my $main_window = Tkx::widget->new( '.' );
$main_window->g_wm_title( 'Main Window' );
$main_window->configure( -menu => make_menu( $main_window ) );

my $e = $main_window->new_tkx_LabEntry(-label => "Path");
$e->g_pack;
my $b = $main_window->new_button(
    -text => "Done",
    -command => sub {
        say $e->get;
        $main_window->g_destroy;
    },
);
$b->g_pack;

sub make_menu {
    my $mw = shift;

    Tkx::option_add( '*tearOff', 0 );
    my $menu = $mw->new_menu();
    my $menu_file = $menu->new_menu();
    my $menu_help = $menu->new_menu();
    $menu->add_cascade(
        -label => 'File',
        -menu  => $menu_file,
    );
    $menu->add_cascade(
        -label => 'Help',
        -menu  => $menu_help,
    );
    $menu_file->add_command(
        -label => 'Quit',
        -command => sub { $mw->g_destroy(); },
    );
    $menu_help->add_command(
        -label => 'About...',
        -command => sub {
            Tkx::tk___messageBox(
                -title => 'About...',
                -message => "$PROGNAME $VERSION",
            );
        },
    );

    return $menu;
}

Tkx::MainLoop();
