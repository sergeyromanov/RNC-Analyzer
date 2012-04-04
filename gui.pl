#!/usr/bin/env perl
use 5.014;

use Encode qw(encode decode);
use Tkx;
use Tkx::LabEntry;
use YAML qw(LoadFile);

use RNCAnalyzer;

our $PROGNAME = 'RNC Extractor';
our $VERSION  = '0.2';

my $main_window = Tkx::widget->new( '.' );
$main_window->g_wm_title( 'Main Window' );
$main_window->configure( -menu => make_menu( $main_window ) );

my $content = $main_window->new_ttk__frame;
$content->g_grid(-row => 0, -column => 0);

my $b = $content->new_ttk__button(
    -text => "Choose directory",
    -command => \&files_dir,
);
$b->g_grid(-row => 0, -column => 0);

my $progress = 0;
my $pbar = $content->new_ttk__progressbar(
    -orient => 'horizontal',
    -length => 100,
    -mode   => 'determinate',
    -value => $progress,
);
$pbar->g_grid(-row => 1, -column => 0);

my %UI = (
    attr       => { sem => 1 },
    top_output => 10,
    window     => { left => 1, right => 1 },
);

my $res_label = $content->new_ttk__label(
    -text => "Number of top results:"
);
$res_label->g_grid(-row => 2, -column => 0);

my $top_output = $content->new_ttk__entry(
    -textvariable => \$UI{'top_output'},
    -width => 7,
);
# $top_output->g_grid(-row => 3, -column => 0);

my $attrs_frame = $content->new_ttk__frame;
$attrs_frame->g_grid(-row => 4, -column => 0);
my $cb_1 = $attrs_frame->new_ttk__checkbutton(
    -text     => 'sem',
    -variable => \$UI{'attr'}{'sem'},
    -onvalue  => 1,
);
my $cb_2 = $attrs_frame->new_ttk__checkbutton(
    -text     => 'lex',
    -variable => \$UI{'attr'}{'lex'},
    -onvalue  => 1,
);
my $cb_3 = $attrs_frame->new_ttk__checkbutton(
    -text     => 'gr',
    -variable => \$UI{'attr'}{'gr'},
    -onvalue  => 1,
);
$cb_1->g_grid(-row => 0, -column => 0);
$cb_2->g_grid(-row => 0, -column => 1);
$cb_3->g_grid(-row => 0, -column => 2);

my $db_l = $content->new_ttk__combobox(
    -textvariable => \$UI{'window'}{'left'},
    -values  => [0, 1, 2, 3, 4],
);
my $db_r = $content->new_ttk__combobox(
    -textvariable => \$UI{'window'}{'right'},
    -values  => [0, 1, 2, 3, 4],
);
my $lw_label = $content->new_ttk__label(
    -text => "Left window:"
);
my $rw_label = $content->new_ttk__label(
    -text => "Right window:"
);
$lw_label->g_grid(-row => 5, -column => 0);
$db_l->g_grid(-row => 6, -column => 0);
$rw_label->g_grid(-row => 7, -column => 0);
$db_r->g_grid(-row => 8, -column => 0);

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
        my @files = glob '*.txt';
        $pbar->configure(-maximum => @files + 1);
        $pbar->start();
        for my $fname (@files) {
            my $lemma = (split '\.', $fname)[0];
            if ($dict && $dict->{$lemma}) {
                $lemma = $dict->{$lemma};
            }
            else {
                $lemma = decode 'cp1251', $lemma;
            }
            say $fh encode('utf8', RNCAnalyzer::analyze_file($fname, \%UI, $lemma));
            $progress++;
            Tkx::update();
        }
        $pbar->stop();
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
