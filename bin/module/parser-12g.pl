#!/usr/bin/perl -w
# HHC - 16-03-2016
# Version 12g Release 1
#use strict;
use CGI;
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use Cwd;
use warnings;

### input filename from CGI call

$CGI::POST_MAX = 1024 * 20000;
my $query = new CGI;
my $input_file = $query->param("input_file");
($name, $path, $suffix) = fileparse($input_file, qr/\.[^.]*/);

### EM1 Problem when empty or wrong extension

if (not $suffix =~ m/^\.STE{0,1}P$/i) {
    print $query->header();
    em_html("em-problem.dat", $input_file);
    exit 0;
}

### Replace spaces and remove illegal characters in input file

my $safe_chars = "a-zA-Z0-9_.-";
$name =~ tr/ /_/;
$name =~ s/[^$safe_chars]//g;

### filenames with locations

$path_cwd = getcwd();
$step_file = $path_cwd . "/../embedding/upload/" . $name . $suffix;
$lattice_file = $path_cwd . "/../embedding/upload/" . $name . ".lat";
$web_file = "/embedding/upload/" . $name . ".lat";

### read input file

my $fh_upload = $query->upload("input_file");
open ( UPLOADFILE, ">$step_file" ) or die "$!";
print UPLOADFILE while <$fh_upload>;
close UPLOADFILE;

# expects $input_file
#         $step_file
#         $lattice_file
#         $web_file
#         $name

###
### 1st pass
###

# STEP AP214 file and parsing it
# ISO 10303-214:2010 was superseded by ISO 10303-242:2014
# ISO/NP 10303-242 is under development at Stage 10.99 (2014-09-12)
# store four type of entities and ignore the rest
#         NEXT_ASSEMBLY_USAGE_OCCURRENCE
# PRDDFN  PRODUCT_DEFINITION
# PDFWSS  PRODUCT_DEFINITION_FORMATION_WITH_SPECIFIED_SOURCE
# PRDCT   PRODUCT
# reference: ISO 10303-41:1994(E) Table A.1 p.149
# reference: Ungerer and Rosche (2002) PDM Schema Usage Guide, release 4.3, p.57-88.  PDM Implementor Forum.

my $fh_read;
open($fh_read, "<", $step_file) or die "cannot open < $step_file: $!";

while (<$fh_read>) {
    my $line = $_;

    if ($line =~ m/^\w*(\#\d+) \= NEXT_ASSEMBLY_USAGE_OCCURRENCE \( \'(\w+)\'\, \' \'\, \' \'\, (\#\d+)\, (\#\d+)\, \$ \) \;\s*/) {
        $assy_relation{"$2"} = [$3, $4];
    } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT_DEFINITION \( \'UNKNOWN\'\, \'\'\, (\#\d+)\, \#\d+ \) \;\s*/) {
        $product_def{"$1"} = $2;
    } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT_DEFINITION_FORMATION_WITH_SPECIFIED_SOURCE \( \'ANY\'\, \'\'\, (\#\d+)\, \.NOT_KNOWN\. \) \;\s*/) {
        $product_source{"$1"} = $2;
    } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT \( \'[a-zA-Z0-9_\- ]+\'\, \'([a-zA-Z0-9_\- ]+)\'\, \'\'\, \( \#\d+ \) \) \;\s*/) {
        my $assy_id = $1;
        my $product_desp = $2;
        $product_desp =~ tr/ /_/;
        $product_desp =~ s/[^$safe_chars]//g;
        $first_char = substr $product_desp, 0, 1;
#        if ($first_char =~ s/[0-9]//) {
#            $product_desp = "P_" . $product_desp;
#        }
        $product_desp = "P_" . $product_desp if $first_char =~ s/[0-9]//;
        $product{"$assy_id"} = $product_desp;
    }  # end if
}  # end while 
close $fh_read;

###
### 2nd pass
###

# organise data structure, from four AP214 entity type to a custom one
# a hush %assembly of an list ($parent, $child) of two elements
# $assembly{"$assy_id"} = [$parent, $child];

# main variables: hush %assembly, pointer a list ($parent, $child)
# hush %parents, hush %children

# temporary variables, reuse many times
my ($assy_id, $parent_child_id_pair);

# keep all parents and children in hashes, then reduce one by one
my (%parents, %children);

while (($assy_id, $parent_child_id_pair) = each %assy_relation) {
    ($parent_id, $child_id) = @{$parent_child_id_pair};
    $parent = $product{$product_source{$product_def{$parent_id}}};
    $child  = $product{$product_source{$product_def{$child_id}}};
    $assembly{"$assy_id"} = [$parent, $child];
    $parents{"$parent"} = 0;  # is a parent
    $children{"$child"} = 0;  # is a child
}

###
### 3rd pass
###

# append assy_id to duplicate part names

my %seen;
while (my ($assy_id, $parent_child_pair) = each %assembly) {
    my ($parent, $child) = @{$parent_child_pair};

    if (not $seen{"$child"}) {
        $seen{"$child"} = 1;
    }
    else {
        my $new_name =  $child . "_" . $assy_id;
        $assembly{"$assy_id"}[1] = $new_name;
        $children{"$new_name"} = 0;
    }
}

###
### 4th pass
###

my (@only_a_parent, @only_a_child);
while (my $parent = each %parents) {
    push @only_a_parent, $parent if not defined $children{"$parent"};
}

while (my $child = each %children) {
    push @only_a_child, $child if not defined $parents{"$child"};
}


###
### 5th pass
###

# $level{"$part"} stores level in an assembly

# a parent but never a child, set $level{"$part"} = 0
# otherwise fill with a false value

my %level;
while (my $parent = each %parents) {
    $level{"$parent"} = 0;
    while (my $child = each %children) {
        $level{"$parent"} = -1 if $child eq $parent;
    }
}

#tree_zero();
lattice_zero();

### EM1 Success

print $query->header();
em_html("em-success.dat", $web_file, $name);

exit 0;

###
### end main program; subrotines follow
###

### output assembly tree

# print top level 0 main assembly

sub tree_zero {
    my $level = 0;
    foreach my $parent (@only_a_parent) {
        $level{"$parent"} = $level;
        print "$parent (level $level) [no parent]\n";
        tree($parent, $level);
    }
}

# print level 1 parts and onwards recursively

sub tree {
    my $new_parent = $_[0];
    my $level = $_[1] + 1;
    my @ids_of_children;
    while (my ($assy_id, $parent_child_pair) = each %assembly) {
        my ($parent, $child) = @{$parent_child_pair};
        if ($parent eq $new_parent) {
            $level{$child} = $level;
            push @ids_of_children, $assy_id;
        }
    }

    foreach my $assy_id (@ids_of_children) {
        my $parent = $assembly{"$assy_id"}[0];
        my $child  = $assembly{"$assy_id"}[1];
        my $string1 = "    " x $level . "+ $child";
        my $string2 = "(level $level)";
        my $string3 = "[$assy_id]";
format TREE_FORMAT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<< @<<<<<<<<<
$string1,                                              $string2,    $string3
.
$~ = "TREE_FORMAT";
write;
        tree($child, $level);
    }
}

### output lattice file for Lattice Drawing

# print top level 0 main lattice element(s)

sub lattice_zero {
    open($fh2, ">", $lattice_file) or die "cannot open > $lattice_file: $!";
    print $fh2 "($name\n";
    my $level = 0;
    foreach my $parent (@only_a_parent) {
        $level{"$parent"} = $level;
        print $fh2 "    ($parent ())\n";
        lattice($parent, $level);
    }
    my $string = join(" ", @only_a_child);
    print $fh2 "    (0 ($string))\n";
    print $fh2 ")\n";
    close $fh2;
}

# print level 1 parts and onwards recursively

sub lattice {
    my $new_parent = $_[0];
    my $level = $_[1] + 1;
    my @ids_of_children;
    while (my ($assy_id, $parent_child_pair) = each %assembly) {
        my ($parent, $child) = @{$parent_child_pair};
        if ($parent eq $new_parent) {
            $level{$child} = $level;
            push @ids_of_children, $assy_id;
        }
    }

    foreach my $assy_id (@ids_of_children) {
        my $parent = $assembly{"$assy_id"}[0];
        my $child  = $assembly{"$assy_id"}[1];
        print $fh2 "    " x ($level + 1);
        print $fh2 "($child ($parent))\n";
        lattice($child, $level);
    }
}

### subroutines ###

sub em_html {
    my $em_error_html = $_[0];
    my $em_filename = $_[1];
    my $em_name = $_[2];
    my $em_tree = $tree_out;
    open (EM_HTML, "<../embedding/$em_error_html");
    while (<EM_HTML>){
        s/(\$\w+)/$1/gee;
        print;
    }
    close EM_HTML;
}

#em_html("em-index.html");
#em_html("em-success.dat");
#em_html("em-problem.dat");
#em_html("em-error.dat");
