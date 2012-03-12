#!/usr/bin/perl
use strict;
use Tkx;

our $PROGNAME = 'MyProgram';
our $VERSION  = '0.1';

# создаем главное окно
my $main_window = Tkx::widget->new( '.' );

# устанавливаем заголовок
$main_window->g_wm_title( 'Main Window' );

# создаем и прикрепляем меню
$main_window->configure( -menu => make_menu( $main_window ) );


# подпрограмма создания главного меню
sub make_menu {
    my $mw = shift;
    
    # отключаем режим открепления меню (подобно в GIMP)
    Tkx::option_add( '*tearOff', 0 );
    
    # в зависимости от ОС, идентификатор кнопки Ctrl/Control может меняться
    my $control = ($^O eq "darwin") ? "Command"  : "Control";
    my $ctrl    = ($^O eq "darwin") ? "Command-" : "Ctrl+";
    
    # верхние уровни
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
    
    # Добавляем элементы в меню File
    $menu_file->add_command(
        -label => 'Quit',
        -command => sub { $mw->g_destroy(); },
    );
    
    # меню Help
    $menu_help->add_command(
        -label => 'About...',
        -command => sub {
            Tkx::tk___messageBox(
                -title => 'About...',
                -message => "$PROGNAME $VERSION",
            );
        },
    );
    
    # возвращаем меню
    return $menu;    
}

# запускаем основной цикл
Tkx::MainLoop();
