#!/usr/bin/env perl
use 5.014;
use strict;

use Encode qw(encode);
use Tkx;
use Tkx::LabEntry;

use RNCAnalyzer;

our $PROGNAME = 'RNC Extractor';
our $VERSION  = '0.1';

my $main_window = Tkx::widget->new( '.' );
$main_window->g_wm_title( 'Main Window' );
$main_window->configure( -menu => make_menu( $main_window ) );

my $b = $main_window->new_ttk__button(
    -text => "Choose directory",
    -command => \&files_dir,
);
$b->g_pack;

sub files_dir {
    my $dir = Tkx::tk___chooseDirectory(
        -parent => $main_window,
        -mustexist => 1,
    );
    if ($dir) {
        chdir $dir;
        open my $fh, '>', "result.txt";
        say $fh encode('utf8', RNCAnalyzer::analyze_file($_))
          for glob '*.txt';
        Tkx::tk___messageBox(
            -parent  => $main_window,
            -icon    => "info",
            -title   => "Finished",
            -message => "OK",
        );
    }
}

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
