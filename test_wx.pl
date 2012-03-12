#!/usr/bin/perl
use strict;
use Tkx;

our $PROGNAME = 'MyProgram';
our $VERSION  = '0.1';

# ������� ������� ����
my $main_window = Tkx::widget->new( '.' );

# ������������� ���������
$main_window->g_wm_title( 'Main Window' );

# ������� � ����������� ����
$main_window->configure( -menu => make_menu( $main_window ) );


# ������������ �������� �������� ����
sub make_menu {
    my $mw = shift;
    
    # ��������� ����� ����������� ���� (������� � GIMP)
    Tkx::option_add( '*tearOff', 0 );
    
    # � ����������� �� ��, ������������� ������ Ctrl/Control ����� ��������
    my $control = ($^O eq "darwin") ? "Command"  : "Control";
    my $ctrl    = ($^O eq "darwin") ? "Command-" : "Ctrl+";
    
    # ������� ������
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
    
    # ��������� �������� � ���� File
    $menu_file->add_command(
        -label => 'Quit',
        -command => sub { $mw->g_destroy(); },
    );
    
    # ���� Help
    $menu_help->add_command(
        -label => 'About...',
        -command => sub {
            Tkx::tk___messageBox(
                -title => 'About...',
                -message => "$PROGNAME $VERSION",
            );
        },
    );
    
    # ���������� ����
    return $menu;    
}

# ��������� �������� ����
Tkx::MainLoop();
