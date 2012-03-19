#!/usr/bin/env perl
use 5.014;
use strict;

use Encode qw(encode);
use Tkx;
use Tkx::LabEntry;

use RNCAnalyzer;

our $PROGNAME = 'RNC Extractor';
our $VERSION  = '0.12';

my $main_window = Tkx::widget->new( '.' );
$main_window->g_wm_title( 'Main Window' );
$main_window->configure( -menu => make_menu( $main_window ) );

my $b = $main_window->new_ttk__button(
    -text => "Choose directory",
    -command => \&files_dir,
);
$b->g_pack;

my $attr = 2; # default is 'sem'
my $rb_1 = $main_window->new_ttk__radiobutton(
    -text     => 'sem',
    -value    => 2,
    -variable => \$attr,
);
my $rb_2 = $main_window->new_ttk__radiobutton(
    -text     => 'lex',
    -value    => 1,
    -variable => \$attr,
);
my $rb_3 = $main_window->new_ttk__radiobutton(
    -text     => 'gr',
    -value    => 0,
    -variable => \$attr,
);
$rb_1->g_pack(-side => 'left');
$rb_2->g_pack(-side => 'left');
$rb_3->g_pack(-side => 'left');

sub files_dir {
    my $dir = Tkx::tk___chooseDirectory(
        -parent => $main_window,
        -mustexist => 1,
    );
    if ($dir) {
        chdir $dir;
        open my $fh, '>', "result.txt";
        say $fh encode('utf8', RNCAnalyzer::analyze_file($_, $attr))
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
