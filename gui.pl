#!/usr/bin/env perl
use 5.014;
use strict;

use Encode qw(encode decode);
use Tkx;
use Tkx::LabEntry;
use YAML qw(LoadFile);

use RNCAnalyzer;

our $PROGNAME = 'RNC Extractor';
our $VERSION  = '0.13';

my $main_window = Tkx::widget->new( '.' );
$main_window->g_wm_title( 'Main Window' );
$main_window->configure( -menu => make_menu( $main_window ) );

my $b = $main_window->new_ttk__button(
    -text => "Choose directory",
    -command => \&files_dir,
);
$b->g_pack;

my %UI = (
    attr => { sem => 1 },
);

my $cb_1 = $main_window->new_ttk__checkbutton(
    -text     => 'sem',
    -variable => \$UI{'attr'}{'sem'},
    -onvalue  => 1,
);
my $cb_2 = $main_window->new_ttk__checkbutton(
    -text     => 'lex',
    -variable => \$UI{'attr'}{'lex'},
    -onvalue  => 1,
);
my $cb_3 = $main_window->new_ttk__checkbutton(
    -text     => 'gr',
    -variable => \$UI{'attr'}{'gr'},
    -onvalue  => 1,
);

$cb_1->g_pack(-side => 'left');
$cb_2->g_pack(-side => 'left');
$cb_3->g_pack(-side => 'left');

sub files_dir {
    my $dir = Tkx::tk___chooseDirectory(
        -parent => $main_window,
        -mustexist => 1,
    );
    if ($dir) {
        my $dict_file = $dir =~ s{(?<=/)[^/]+$}{translate.yml}r;
        my $dict;
        $dict = LoadFile($dict_file) if -e $dict_file;
        open my $fh, '>', "result.txt";
        chdir $dir;
        for my $fname (glob '*.txt') {
            my $lemma = (split '\.', $fname)[0];
            if ($dict && $dict->{$lemma}) {
                $lemma = $dict->{$lemma};
            }
            else {
                $lemma = decode 'cp1251', $lemma;
            }
            say $fh encode('utf8', RNCAnalyzer::analyze_file($fname, \%UI, $lemma));
        }
        Tkx::tk___messageBox(
            -parent  => $main_window,
            -icon    => "info",
            -title   => "Finished",
            -message => "OK",
        );
        exit;
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
