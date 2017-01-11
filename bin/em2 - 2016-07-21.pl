#!/usr/bin/perl
# HHC - 30-03-2016
# HHC - 13-07-2016 - after DCC'16
use warnings;
use strict;
use Tk;
use Tk::Font;
use Tk::Balloon;
#use Alias qw/alias/;

use lib qw/module/;
use Step;

### global variables

my $safe_chars = "a-zA-Z0-9_.-";
our $bar;
our %product;
our ($x_size, $y_size) = (600, 480);
my $r = 2;
my ($x_offset, $y_offset) = ($x_size/2, 5);

our $c;
our $canvas;
our $text;
my $item1;

# Main Window

my $mw = new MainWindow;
$mw -> geometry('-0+0');
$mw -> minsize(500,300);
$mw -> optionAdd('*font', 'Helvetica 10');
my $label = $mw -> Label(-text => "StrEmbed-2")->pack;

# menu bar

my $fm = $mw -> Frame -> pack(-side => 'top', -anchor => 'w', -fill => 'x');

my $menu_1 = $fm -> Menubutton( -text => "File",
    -menuitems => [
        [ 'command' => "Open", -command => sub { load_file() } ],
        [ 'command' => "Test Printing", -command => sub { test_print() } ],
        [ 'command' => "Item 3"],
        "-",
        [ 'command' => "Item 99"],
        [ 'command' => "Exit", -command => sub { exit } ],                      
    ]
) -> pack(
    -anchor => 'nw',
    -side => 'left',
);

my $menu_2 = $fm -> Menubutton( -text => "Edit",
    -menuitems => [
        [ 'command' => "Item 1"],
        [ 'command' => "Item 2"],
        [ 'command' => "Item 3"],
        "-",
        [ 'command' => "Item 99"],
        [ 'command' => "Item 100"],                     
    ]
) -> pack(
    -anchor => 'nw',
    -side => 'left',
);

my $menu_3 = $fm -> Menubutton( 
    -text => "Help",
    -menuitems => [
        [ 'command' => "Item 1"],
        [ 'command' => "Item 2"],
        [ 'command' => "Item 3"],
        "-",
        [ 'command' => "Item 99"],
        [ 'command' => "Item 100"],                     
    ],
) -> pack(
    -anchor => 'ne',
);

# buttons

my $f = $mw -> Frame -> pack(-side => 'left', -anchor => 'n', -fill => 'y');
my $f1 = $f -> Frame -> pack(-side => 'left', -anchor => 'n', -fill => 'y');
my $f2 = $f -> Frame -> pack(-side => 'left', -anchor => 'n', -fill => 'y');

my $b_load = $f1 -> Button(
    -text => "STEP AP214\ndump",
    -command => sub { load_file() },
    -state => 'disabled',
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_read = $f1 -> Button(
    -text => "Step\nread",
    -command => sub { Step::read_step_file() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_embed = $f1 -> Button(
    -text => "embed\nlattice",
    -command => sub { Step::embed_lattice() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_product = $f1 -> Button(
    -text => "Step print\nproduct",
    -command => sub { Step::print_product() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_assy = $f1 -> Button(
    -text => "Step print\nassembly",
    -command => sub { Step::print_assembly() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_element = $f1 -> Button(
    -text => "Step print\nelement",
    -command => sub { Step::print_element() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_sup = $f1 -> Button(
    -text => "Step print\nonly p or c",
    -command => sub { Step::print_only() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_level = $f1 -> Button(
    -text => "print\nlattice",
    -command => [ \&Step::print_lat, $x_size, $y_size ],
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_hyp_read = $f1 -> Button(
   -text => "read\nhypercube",
   -command => [ \&Step::read_hypercube ],
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_hyp_print = $f1 -> Button(
   -text => "print\nhypercube",
   -command => [ \&Step::print_hypercube ],
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

# next row of buttons

my $b_draw = $f2 -> Button(
   -text => "Draw",
   -command => sub { draw_supremum() },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_c1 = $f2 -> Button(
   -text => "arrow",
   -command => sub { $main::canvas -> configure(-cursor => 'arrow') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_c2 = $f2 -> Button(
   -text => "what?",
   -command => sub { $main::canvas -> configure(-cursor => 'question_arrow') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $b_c3 = $f2 -> Button(
   -text => "crosshair",
   -command => sub { $main::canvas -> configure(-cursor => 'crosshair') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $cf1 = $f2 -> Button(
   -text => "red",
   -command => sub { $canvas -> itemconfigure($item1, -fill => 'red') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $cf2 = $f2 -> Button(
   -text => "yellow",
   -command => sub { $canvas -> itemconfigure($item1, -fill => 'yellow') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $cf3 = $f2 -> Button(
   -text => "none",
   -command => sub { $canvas -> itemconfigure($item1, -fill => '') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $f21 = $f2 -> Frame -> pack(-side => 'top', -anchor => 'w', -fill => 'x');

my $cf4 = $f21 -> Button(
   -text => "hidden\nnode",
   -command => sub { $canvas -> itemconfigure("node", -state => 'hidden') },
) -> pack(
    -side => 'left',
    -anchor => 'n',
    -fill => 'y',
);

my $cf5 = $f21 -> Button(
   -text => "show\nnode",
   -command => sub { $canvas -> itemconfigure("node", -state => 'normal') },
) -> pack(
    -side => 'left',
    -anchor => 'n',
    -fill => 'y',
);

my $f22 = $f2 -> Frame -> pack(-side => 'top', -anchor => 'w', -fill => 'x');

my $cf6 = $f22 -> Button(
   -text => "hidden\nlink",
   -command => sub { $canvas -> itemconfigure("link", -state => 'hidden') },
) -> pack(
    -side => 'left',
    -anchor => 'n',
    -fill => 'y',
);

my $cf7 = $f22 -> Button(
   -text => "show\nlink",
   -command => sub { $canvas -> itemconfigure("link", -state => 'normal') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $f23 = $f2 -> Frame -> pack(-side => 'top', -anchor => 'w', -fill => 'x');

my $cf8 = $f23 -> Button(
   -text => "hidden\ntext",
   -command => sub { $canvas -> itemconfigure("text", -state => 'hidden') },
) -> pack(
    -side => 'left',
    -anchor => 'n',
    -fill => 'y',
);

my $cf9 = $f23 -> Button(
   -text => "show\ntext",
   -command => sub { $canvas -> itemconfigure("text", -state => 'normal') },
) -> pack(
    -side => 'top',
    -anchor => 'w',
    -fill => 'x',
);

my $button = $f2 -> Button(
    -text => "Exit", 
    -command => sub { exit },
) -> pack(
    -side => 'bottom',
    -anchor => 'w',
    -fill => 'x',
);

# middle bits

$c = $mw -> Scrolled("Canvas",
    -width => $x_size,
    -height => $y_size,
) -> pack(
    -anchor => 'nw',
);

$canvas = $c -> Subwidget("canvas");

$text = $mw -> Scrolled("Text",
    -height => 4,
) -> pack(
    -side => 'top',
    -anchor => 'nw',
    -fill => 'both',
    -expand => 1,
);

&bind_start();

MainLoop;

### subroutines

sub bind_start {
    #print "binding\n";
}

sub foo_hush {
    $product{"#1"} = "name ONE";
    $product{"#2"} = "name TWO";
    print "... bf In main.\n";
    while (my @list = each %product) {
        my $key = $list[0];
        my $value = $list[1];
        print "$key $value\n"
    }
    print "bf Out main.\n";   

    #Foo::setproduct();
    #%product = %Foo::product;
    print "... In main.\n";
    while (my @list = each %product) {
        my $key = $list[0];
        my $value = $list[1];
        print "$key $value\n"
    }
     print "Out main.\n";   

}

sub foo_test {
    $bar = 23;
    print "1: Out main \$bar is $bar.\n";
    Foo::setbar();
    # $bar = $Foo::bar;
    print "2: Out main \$bar is $bar.\n";
}

sub test_print {
    print "testing ...\n";
}

sub load_file {
    open (FH, "data/step/Robot.STEP") || die "Could not open file";
    while (<FH>) {
        $text -> insert('end', $_);
    }   
    close (FH);
}

sub draw_supremum {
    my ($id, $desp);
    my ($x, $y) = (0, 0);;
    my @list = Step::return_parents();
    while (@list) {
        $desp = pop @list;
        $id = pop @list;
        my $x1 = $x + $x_offset - $r;
        my $x2 = $x + $x_offset + $r;
        my $y1 = $y + $y_offset - $r;
        my $y2 = $y + $y_offset + $r;
        my $item = $canvas -> createOval($x1, $y1, $x2, $y2, -tags => "node");
        
    }   
    $item1 = $canvas -> createRectangle(10,10,50,50, -tags => "other");
    my $item2 = $canvas -> createOval(10,100,50,140, -tags => "other");
    my $balloon = $canvas -> Balloon(-statusbar => "sddasd");
    #$balloon -> attach($item1, -msg => "node");
    
    }

sub qq {
    print "in\n";
}