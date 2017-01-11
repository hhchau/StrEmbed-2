# Step.pm
# HHC - 21-07-2016 - a version passed onto AKB
package Step;
use Set::Scalar;
use warnings;
use strict;

our %assy_relation;
our %product_def;
our %product_source;
our %product_desp;
our %product;
our %assembly;
our %element;
our @only_a_parent;
our @only_a_child;
my $level;
our ($x_size, $y_size) = ($main::x_size, $main::y_size);
my %node;
my %level;
my %at_level;
my %coords;
my %item; my %link;
my %text;
my %name;
my %lookup;
my %list; my %done;

our @available_lv_0 = ();
our @available_lv_1 = ();
our @available_lv_2 = ();
our @available_lv_3 = ();
our @available_lv_4 = ();
our @available_lv_5 = ();

sub setproduct {
    $product{"#1"} = "STEP one";
    $product{"#2"} = "STEP two";
}

sub printproduct {
    print "... In PRINT Step.\n";
    while (my @list = each %product) {
        my $key = $list[0];
        my $value = $list[1];
        print "$key $value\n"
    }
    print "Out PRINT Step.\n";
}

sub clearproduct{
    %product = undef;
}

sub read_step_file {

    ### 1st pass

    # my $file = "data/step/lock_6-pin_assembly_eg.STEP";
    my $file = "data/step/puzzle_1c.STEP";
    open(my $fh, "<", $file) or die "cannot open < $file: $!";
    while (<$fh>) {
        my $line = $_;

        if ($line =~ m/^\w*(\#\d+) \= NEXT_ASSEMBLY_USAGE_OCCURRENCE \( \'(\w+)\'\, \' \'\, \' \'\, (\#\d+)\, (\#\d+)\, \$ \) \;\s*/) {
            $assy_relation{$2} = [$3, $4];
        } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT_DEFINITION \( \'UNKNOWN\'\, \'\'\, (\#\d+)\, \#\d+ \) \;\s*/) {
            $product_def{$1} = $2;
        } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT_DEFINITION_FORMATION_WITH_SPECIFIED_SOURCE \( \'ANY\'\, \'\'\, (\#\d+)\, \.NOT_KNOWN\. \) \;\s*/) {
            $product_source{$1} = $2;
        } elsif ($line =~ m/^\w*(\#\d+) \= PRODUCT \( \'[a-zA-Z0-9_\- ]+\'\, \'([a-zA-Z0-9_\- ]+)\'\, \'\'\, \( \#\d+ \) \) \;\s*/) {
            my $assy_id = $1;
            my $product_desp = $2;
            $product{$assy_id} = $product_desp;
        }  # end if
    }  # end while
    close $fh;

    ### 2nd pass

    while (my ($assy_id, $parent_child_ref_pair) = each %assy_relation) {
        my ($parent_id, $child_id) = @{$parent_child_ref_pair};
        #print "$assy_id \t$parent_id \t$child_id\n";
        my $parent = $product_source{$product_def{$parent_id}};
        my $child  = $product_source{$product_def{$child_id}};
        $assembly{$assy_id} = [$parent, $child];
        #$parents{"$parent"} = 0;  # is a parent
        #$children{"$child"} = 0;  # is a child
    }

    ### 3rd pass - initialise %element

    while (my ($id, $product_desp) = each %product) {
        $element{$id}{description} = $product_desp;
        $element{$id}{coords} = [10, 20, 30];
    }

    ### 4th pass - add parents and children to %product

    while (my ($assy_id, $parent_child_id_pair) = each %assembly) {
        my ($parent_id, $child_id) = @{$parent_child_id_pair};
        push @{$element{$parent_id}{children}}, $child_id;
        push @{$element{$child_id }{parents }}, $parent_id;
    }

    ### 5th pass - find only_a_parent and only_a_child

    while (my $id = each %element) {
        my (@m, @n);
        push @m, $_ foreach @{$element{$id}{children}};
        push @n, $_ foreach @{$element{$id}{parents}};
        my $m = @m;
        my $n = @n;
        push @only_a_child, $id if not $m;
        push @only_a_parent, $id if not $n;
    }

    # pass 5a - add infimum as a new element
    my $id = "zero";
    $element{$id}{description} = "infimum";
    $element{$id}{coords} = [0, 0, 0];
    @{$element{$id}{parents}} = @only_a_child;
    
}  # end sub read_step_file

sub change_colour_link {
    my $c = $_[0];
    my $p = $_[1];
    our $canv = $main::canvas;
    $canv -> itemconfigure($link{$c}{$p}, -width => "3", -fill => 'black');
}

sub change_colour_item {
    our $canv = $main::canvas;
    $canv -> itemconfigure($item{$_[0]}, -outline => 'black', -fill => 'black');
    $canv -> itemconfigure($text{$_[0]}, -fill => 'black',
        -text => $element{$name{$_[0]}}{description},
    );
}

sub embed_lattice {
    while (my $this = each %element) {
        $list{$this} = 0;
    }
    #print $_ . "\n" while each %list;    

    my $i = 5;
    my $inf;
    LABEL: while (my $id = each %element) {
       my $desp = $element{$id}{description};
       $inf = $id if $desp eq "infimum";
    }
    #print "... infimum is $inf - $element{$inf}{description}\n";
    my @p4 = @{$element{$inf}{parents}};
    # print "... $inf has parents: @p4\n";
    $name{"0"} = "zero";
    &change_colour_item("0");
    delete $list{"zero"};
    $done{"zero"} = 0;

    #print $_ . "\n" while each %list;
    
    $i = 4;
    my @target;
    my $targ = 0;
    while (my $id = each %{$level{$i}}) {
        push @target, $id;
    }
    # print "level $i has targets = @target\n";
    foreach (@p4) {
        my $part = $_;
        $targ = pop @target;
        #print "b/f: $part - $targ\n";
        $level{$i}{$targ} = $part;
        $lookup{$part} = $targ;
        # print "a/f: $part - $targ - $level{$i}{$targ}\n";
        $name{$targ} = $part;
        &change_colour_item($targ);
        &change_colour_link($targ, "0");
        delete $list{$part};
        $done{$part} = 0;
    }
    #print "....list: " . $_ . "\n" while each %list;
    #print "....done: " . $_ . "\n" while each %done;

    $i =3;
    while (my $one = each %list) {
        my @children = @{$element{$one}{children}};
        #print "yet to do: $one\n";
        
        my $allthere = 1;
        #print "has childen: @children\n";
        foreach (@children) {
            #print $_, " ", defined $done{$_}, "\n";
            $allthere = $allthere && defined $done{$_};
        }
        # print "all there? $allthere.\n";

        if ($allthere) {
            #print "do something with $one.\n";
            my @cc = @{$element{$one}{children}};
            &lub3($one, @cc);
            #print "... child @cc.\n";
        }
        
    }
    #print "list: " . $_ . "\n" while each %list;
    #print "done: " . $_ . "\n" while each %done;
    
    $i = 2;
    our @available_lv_0;
    our @available_lv_1;
    our @available_lv_2;
    our @available_lv_3;
    our @available_lv_4;
    while (each %{$level{2}} ) {
        push @available_lv_2, $_ if not defined $name{$_};
    }
    while (each %{$level{3}} ) {    
        push @available_lv_3, $_ if not defined $name{$_};
    }
    while (each %{$level{4}} ) {    
        push @available_lv_4, $_ if not defined $name{$_};
    }    
    #print "lv 4: @available_lv_4\n";  # should be none
    #print "lv 3: @available_lv_3\n";  # varies
    #print "lv 2: @available_lv_2\n";  # should be all 10

    while (my $one = each %list) {
        my @children = @{$element{$one}{children}};
        #print "yet to do: $one\n";
        #print "has children: @children\n";
        &lub2($one, @children);
    }

    $i = 1;
    while (each %{$level{1}} ) {    
        push @available_lv_1, $_ if not defined $name{$_};
    }    
    #print "lv 1: @available_lv_1\n";

    $i = 0;
    while (each %{$level{0}} ) {    
        push @available_lv_0, $_ if not defined $name{$_};
    }    
    #print "lv 0: @available_lv_0\n";
    
    # print "list: " . $_ . " ($list{$_})" . "\n" while each %list;
    # print "done: " . $_ . " ($done{$_})" . "\n" while each %done;
    

    while (my $parent = each %list) {
        my @children = @{$element{$parent}{children}};
        # print "these need to be sorted @children\n";
        # print "parent -- $parent\n";
        foreach (@children) {
            my $child = $_;
            # print "b/f calling lub0: parent = $parent, child = $child\n";
            &lub0($parent, $child);
        }
        delete $list{$parent};
        $done{$parent} = 0;
        $name{31} = $parent;
        &change_colour_item("31");
    }
    print "available level 3 nodes @available_lv_3\n";
    # print "list: " . $_ . " ($list{$_})" . "\n" while each %list;
    # print "done: " . $_ . " ($done{$_})" . "\n" while each %done;
}

    #&change_colour_item("0");
    #delete $list{"zero"};

sub remove_node {
    my $node = $_;
    my $level = $at_level{$node};
    # print "to remove node $node at level $level\n";
    if ($level == 1) {
        print "1: to remove node $node at level $level\n";
        my @temp = ();
        foreach my $this (@available_lv_1) {
            push @available_lv_1, $this unless $this == $node;
        }
        @available_lv_1 = @temp;
    } elsif ($level == 2) {
        print "2: to remove node $node at level $level\n";
        my @temp = ();
        foreach my $this (@available_lv_2) {
            # push @available_lv_2, $this unless $this == $node;
        }
    } elsif ($level == 3) {
        print "3: to remove node $node at level $level\n";
        my @temp = ();
        foreach my $this (@available_lv_3) {
            # push @available_lv_3, $this unless $this == $node;
        }
    }
}    

sub lub0 {
    # $one is at level 0 - pointing to all below
    my ($parent, $child) = @_;
    my $c_id = $lookup{$child};
    # print "a/f calling lub0: parent = $parent, child = $child ($c_id)\n";

    # our @available_lv_0;
    # our @available_lv_1;
    # our @available_lv_2;
    # our @available_lv_3;

    my @nodes_to_be_removed = ();
    foreach (@available_lv_0) {
        my $p_id = $_;
        # print "$p_id, $c_id\n";
        my @chain = &find_chain($p_id, $c_id);
        if ($#chain) {
            # print "($p_id) @chain ($c_id)\n\n";
            my $top = shift @chain;
            foreach (@chain) {
                my $next = $_;
                push @nodes_to_be_removed, $top;
                &change_colour_link($top, $next),
                $top = $next;
            }
        }
    }
    shift @nodes_to_be_removed;
    print "nodes to be removed @nodes_to_be_removed\n";
    foreach (@nodes_to_be_removed) {
        # &remove_node($_);
        # print "remove node $_ ($at_level{$_})\n";
    }
    
    #my $p_id = $lookup{$parent};
    #my $level_parent = $at_level{$p_id};
    #print "yet to do: $one ... $p_id at $level_parent\n";
    # print "has children: @children\n";

}

sub find_chain {
    my ($p_id, $c_id) = @_;
    my $p_level = $at_level{$p_id};
    my $c_level = $at_level{$c_id};
    print "parent node $p_id (level $p_level), child node $c_id (level $c_level)\n";

    my @children_nodes = @{$node{$p_id}{c}};
    # print "children nodes are @children_nodes\n";
    

    # our @available_lv_0;
    # our @available_lv_1;
    # our @available_lv_2;
    # our @available_lv_3;

    my @chain = ();
    CHAIN3: if ($c_level == 3) {
        my @lv_1_both_child_and_available = &set_isect(\@children_nodes, \@available_lv_1);
        foreach (@lv_1_both_child_and_available) {
            my $candidate_lv_1 = $_;
            # print "level 1 candidate node is $candidate_lv_1\n";
            
            my @level_2_children = @{$node{$candidate_lv_1}{c}};
            #print "$candidate_lv_1 -- @level_2_children\n";
            my @lv_2_both_child_and_available = &set_isect(\@level_2_children, \@available_lv_2);
            foreach (@lv_2_both_child_and_available) {
                my $candidate_lv_2 = $_;
                # print "$p_id - $candidate_lv_1 - $candidate_lv_2\n";
                
                my @level_3_children = @{$node{$candidate_lv_2}{c}};
                #print "$candidate_lv_2 -- @level_3_children\n";
                #my @lv_3_both_child_and_available = &set_isect(\@level_3_children, \@available_lv_3);
                foreach (@level_3_children) {
                    my $candidate_lv_3 = $_;
                    # print "$p_id - $candidate_lv_1 - $candidate_lv_2 - $candidate_lv_3 ($c_id)\n"
                    #    if $candidate_lv_3 == $c_id;
                    # return undef;
                    return ($p_id, $candidate_lv_1, $candidate_lv_2, $candidate_lv_3) if $candidate_lv_3 == $c_id;
                }
            }

        }
    } # end if CHAIN3

    CHAIN4: if ($c_level == 4) {
        my @lv_1_both_child_and_available = &set_isect(\@children_nodes, \@available_lv_1);
        foreach (@lv_1_both_child_and_available) {
            my $candidate_lv_1 = $_;
            # print "level 1 candidate node is $candidate_lv_1\n";
            
            my @level_2_children = @{$node{$candidate_lv_1}{c}};
            #print "$candidate_lv_1 -- @level_2_children\n";
            my @lv_2_both_child_and_available = &set_isect(\@level_2_children, \@available_lv_2);
            foreach (@lv_2_both_child_and_available) {
                my $candidate_lv_2 = $_;
                # print "$p_id - $candidate_lv_1 - $candidate_lv_2\n";
                
                my @level_3_children = @{$node{$candidate_lv_2}{c}};
                #print "$candidate_lv_2 -- @level_3_children\n";
                my @lv_3_both_child_and_available = &set_isect(\@level_3_children, \@available_lv_3);
                foreach (@lv_3_both_child_and_available) {
                    my $candidate_lv_3 = $_;

                    my @level_4_children = @{$node{$candidate_lv_3}{c}};
                    foreach (@level_4_children) {
                        my $candidate_lv_4 = $_;
                        # return undef;
                        return ($p_id, $candidate_lv_1, $candidate_lv_2, $candidate_lv_3, $candidate_lv_4) if $candidate_lv_4 == $c_id;
                        #print "$p_id - $candidate_lv_1 - $candidate_lv_2 - $candidate_lv_3 - $candidate_lv_4 ($c_id)\n"
                        #    if $candidate_lv_4 == $c_id;
                    }
                }
            }

        }
    } # end if CHAIN4
    return undef;
}

sub set_isect {
    my ($ref_set_A, $ref_set_B) = @_;
    my @set_A = @{$ref_set_A};
    my @set_B = @{$ref_set_B};
    my @union = ();
    my %union = ();
    my %isect = ();
    $union{$_} = 1 foreach @set_A;
    foreach my $e (@set_B) { $isect{$e} = 1 if $union{$e} };
    return keys %isect;
}

sub lub2 {
    # $one is at level 2 - pointing to levels 4 or 3
    my ($one, @children) = @_;
    #print "yet to do: $one\n";
    #print "has children: @children\n";
    
    # have a go only if all children are defined
    my $all_defined = 1;
    foreach (@children) {
        my $p = $_;
        my $level = $at_level{$p};
        $all_defined = $all_defined && defined $lookup{$p};
    }
    if ($all_defined) {
        #print "$one has @children that are all defined.\n";

        our @avail_2 = our @available_lv_2;
        our @avail_3 = our @available_lv_3;
        
        our %avail_2;
        our %avail_3;
        
        $avail_2{$_} = 0 foreach @available_lv_2;
        $avail_3{$_} = 0 foreach @available_lv_3;
        
        #print "lv 2: @avail_2\n";
        #print "lv 3: @avail_3\n";
        my @targets;
        foreach (@children) {
             my $part = $_;
             my $targ = $lookup{$part};
             my $lv = $at_level{$targ};
             push @targets, $targ;
             #print "$part points to $targ (level $lv)\n";
             #print "is there a chain from $one to $part?\n";
        }
        
        # still at level 2
        LABEL2: while (each %avail_2) {
            my $node2 = $_;
            #print "node2 = $node2\n";
            my $all_chain_exists = 1;
            my @chain;
            LABEL4: foreach (@targets) {
                my $node4 = $_;
                #print "find chain 2-4: $node2, $node4.\n";
                my @chain = find_chain_24($node2, $node4);
                #print ">>> this chain is @chain.\n" if @chain;
                $all_chain_exists = $all_chain_exists and scalar @chain;
            }
            
            #print "$all_chain_exists ...\n";            
            if ($all_chain_exists) {
                #print "all chain exists - $node2.\n";
                last LABEL2;
            }
        } # end LABEL2

    }
}


sub next_one_link {
    return 1;
}

sub find_chain_24 {
    my $node2 = $_[0];
    my $node4 = $_[1];
    our %avail_3 = %avail_3;

    while (my $node3 = each %avail_3) {
        if ( &is_in($node3, @{$node{$node2}{c}} ) &&
             &is_in($node3, @{$node{$node4}{p}} ) ) {
             #print "... $node2, $node3, $node4.\n";
             return ($node2, $node3, $node4);
        }
    }
    return 0;
}

sub is_in {
    my ($element, @list) = @_;
    foreach (@list) {
        return 1 if $_ == $element;
    }
    return 0;
}

sub lub3 {
    my ($one, @list) = @_;
    #print "@_\n";
    my @nn;
    my $ll = 5;
    foreach (@list) {
        my $pp = $_;
        $ll = $at_level{$lookup{$pp}} if $at_level{$lookup{$pp}} < $ll;
        #print "$lookup{$pp} $element{$pp}{description} - $at_level{$lookup{$pp}}.\n";
        push @nn, $lookup{$pp};
    }
    $ll--;
    #print "next level is $ll\n";
    #print "... @nn\n";

    # find lub for list @nn
    my @l3;
    while (my $next = each %{$level{$ll}}) {
        #print "$next\n";
        my $covers_all = 1;
        foreach (@nn) {
           my $this = $_;
           $covers_all = $covers_all && &covers($next, $this);
           #print "does $next covers $this? $logic.\n";
        }
        if ($covers_all) {
            $name{$next} = $one;
            #print "$next covers @nn\n";
            $lookup{$one} = $next;
            #print "$one is the one.\n";
            &change_colour_item($next);
            &change_colour_link($next, $_) foreach @nn;
            delete $list{$one};
            $done{$one} = 0;
        };
    }    
}

sub covers {
    my $next = $_[0];
    my $this = $_[1];
    #print "does $next covers $this?\n";
    foreach (@{$node{$next}{c}}) {
        #print "... $next covers $_\n";
        return 1 if $_ eq $this;
    }
    #print "___ $next does not cover $this";
    return 0;
}

sub print_lat {
    print "sub print_lat: do nothing\n";
    return;
    
    ($x_size, $y_size) = @_;
    my $x_width = $x_size - 10;
    my $y_height = $y_size - 10;

    my $n_child = @only_a_child;
    my $n_parent = @only_a_parent;

    my $y_step = $y_height / $n_child;
    
    my ($x, $y) = (0, 0);
    #&print_node($x, $y);

    $y += 50;    
    #&print_node($x, $y);
}

sub print_a_node {
    my ($x, $y, $id) = @_;
    our ($x_size, $y_size) = ($main::x_size, $main::y_size);
    #print "xy: $x_size, $y_size.\n";
    #print "$x, $y has $id\n";
    my $y_inc = ($y_size - 20) / 5;
    my $x_inc = ($x_size - 20) / 12;
    my $r = 6;
    my ($x_offset, $y_offset) = ($x_size/2, 10);
    my $x1 = $x * $x_inc - $r + $x_offset;
    my $x2 = $x * $x_inc + $r + $x_offset;
    my $y1 = $y * $y_inc - $r + $y_offset;
    my $y2 = $y * $y_inc + $r + $y_offset;
    
    our $canv = $main::canvas;
    $item{$id} = $canv -> createOval($x1, $y1, $x2, $y2,
        -tags => "node",
        -outline => 'gray50',
    );
    $text{$id} = $canv -> createText($x2+$r*2, $y2,
        -text => "$id",
        -tag => "text",
        -fill => 'gray50',
    );
}

sub read_hypercube {
    my $name;

    open (FH, "data/lattice/hypercube/cube5.lat") || die "Could not open file";
    LABEL: while (<FH>) {
        my $line = $_;
        chomp $line;
        if ($line =~ /^\)$/ ) {
            #print "last line: '$line'\n";
            last LABEL;
        } elsif ($line =~ /\((.*) \(\)\)/ ) {
            #print "second last '$1'\n";
            $node{$1}{p} = undef;
        } elsif ($line =~ /^\((.*) \((.*)\)\)$/ ) {
            my $p = $1;
            my @c = split / /, $2;
            #print "$p - @c\n";
            foreach (@c) {
               #print "$_ covers $p\n";
               push @{$node{$_}{c}}, $p;
               push @{$node{$p}{p}}, $_;
            }
        } elsif ($line =~ /\((.*)/ ) {
            $name = $1;
            #print "first line: '$name'\n";
        } else {
            print "ignored: $line\n";
        }
    }   
    close (FH);
}

sub print_hypercube {
    my $lv = 0;

    # find supremum
    
    while (my $id = each %node) {
        #print "$id:\n";
        unless ($node{$id}{p}) {
            my @list = @{$node{$id}{c}};
            $level{$lv}{$id} = 1;
            $at_level{$id} = $lv;
            #print "level $lv - $id has no parent\n";
            #print "has children @list\n";
        }
    }

    # level 0 and upwards
    
    while (my $id = each %{$level{$lv}}) {
        #print "level 0 - $id\n";
        &set_hyp_1($id, $lv);
    }

    for (my $i = 0; $i <= 5; $i++) {
        #print "level $i\n";
        my @list;
        while (my $id = each %{$level{$i}}) {
            #print "$id\n";
            push @list, $id;
        }
        &print_nodes($i, @list);
    }
    &print_links();
}

sub print_links {
    our ($x_size, $y_size) = ($main::x_size, $main::y_size);
    my $y_inc = ($y_size - 20) / 5;
    my $x_inc = ($x_size - 20) / 12;
    my ($x_offset, $y_offset) = ($x_size/2, 10);

    while (my $id = each %{node}) {
        foreach (@{$node{$id}{p}}) {
            my $x1 = $coords{$id}[0] * $x_inc + $x_offset;
            my $y1 = $coords{$id}[1] * $y_inc + $y_offset;
            my $x2 = $coords{$_}[0]  * $x_inc + $x_offset;
            my $y2 = $coords{$_}[1]  * $y_inc + $y_offset;

            &print_a_link($x1, $y1, $x2, $y2, $_, $id);
        }
    }
}

sub print_a_link {
    our $canv = $main::canvas;
    my $x1 = $_[0];
    my $y1 = $_[1];
    my $x2 = $_[2];
    my $y2 = $_[3];
    my $c  = $_[4];
    my $p  = $_[5];
    $link{$c}{$p} = $canv -> createLine($x1, $y1, $x2, $y2,
        -tags => "link",
        -fill => 'gray50');
}

sub print_nodes {
    my ($lv, @list) = @_;
    my $n = @list;
    #print "$lv - $n\n";
    my $x0 = - ($n - 1) / 2;
    foreach (@list) {
        $coords{$_} = [$x0, $lv];
        &print_a_node($x0, $lv, $_);
        $x0++;
    }
}

sub set_hyp_1 {
    my ($id, $lv) = @_;
    my $lu = $lv + 1;
    my @list = @{$node{$id}{c}};
    foreach (@list) {
        #print "$_ is level $lu\n";
        $level{$lu}{$_} = 0;
        $at_level{$_} = $lu;
        &set_hyp_2($_, $lu);
    }
}

sub set_hyp_2 {
    my ($id, $lv) = @_;
    my $lu = $lv + 1;
    #print "level $lv - $id\n";
    my @list = @{$node{$id}{c}};
    foreach (@list) {
        #print "$_ is level $lu\n";
        $level{$lu}{$_} = 0;
        $at_level{$_} = $lu;
        &set_hyp_3($_, $lu);
    }
}

sub set_hyp_3 {
    my ($id, $lv) = @_;
    my $lu = $lv + 1;
    #print "level $lv - $id\n";
    my @list = @{$node{$id}{c}};
    foreach (@list) {
        #print "$_ is level $lu\n";
        $level{$lu}{$_} = 0;
        $at_level{$_} = $lu;
        &set_hyp_4($_, $lu);
    }
}

sub set_hyp_4 {
    my ($id, $lv) = @_;
    my $lu = $lv + 1;
    #print "level $lv - $id\n";
    my @list = @{$node{$id}{c}};
    foreach (@list) {
        #print "$_ is level $lu\n";
        $level{$lu}{$_} = 0;
        $at_level{$_} = $lu;
        &set_hyp_5($_, $lu);
    }
}

sub set_hyp_5 {
    my ($id, $lv) = @_;
    my $lu = $lv + 1;
    #print "level $lv - $id\n";
    my @list = @{$node{$id}{c}};
    foreach (@list) {
        #print "$_ is level $lu\n";
        $level{$lu}{$_} = 0;
        $at_level{$_} = $lu;
        #&set_hyp_6($_, $lu);
    }
}

sub print_only {
    our $text = $main::text;

    $text -> insert('end', "only a parent ...\n");
    $text -> insert('end', "    $_: $element{$_}{description}\n")
        foreach @only_a_parent;

    $text -> insert('end', "only a child ...\n");
    $text -> insert('end', "    $_: $element{$_}{description}\n")
        foreach @only_a_child;
}

sub print_element {
    our $text = $main::text;
    while (my $id = each %element) {
        #my $desp = $element{$id} -> description;
        my $desp = $element{$id}{description};
        my ($x, $y, $z) = @{$element{$id}{coords}};
        #my $l = $element{$id}{level};

        my (@m, @n);
        push @m, $_ foreach @{$element{$id}{children}};
        push @n, $_ foreach @{$element{$id}{parents}};

        my $m = @m;
        my $n = @n;

        $text -> insert('end', "element $id - $desp\n");
        #$text -> insert('end', "level $l.\n");
        $text -> insert('end', "coords $x, $y, $z\n");
        $text -> insert('end', "$m children are = @m.\n");
        $text -> insert('end', "$n parents are = @n.\n\n");
    }
}  # end read_step_file and parsing

sub print_assembly {
    our $text = $main::text;
    while (my ($assy_id, $parent_child_id_pair) = each %assembly) {
        my $parent_id = @{$parent_child_id_pair}[0];
        my $child_id  = @{$parent_child_id_pair}[1];
        my $parent = $product{$parent_id};
        my $child  = $product{$child_id};
        $text -> insert('end', "$assy_id  ");
        $text -> insert('end', "$parent_id  ");
        $text -> insert('end', "$child_id\n");
        $text -> insert('end', "$assy_id  ");
        $text -> insert('end', "$parent  ");
        $text -> insert('end', "$child\n");
    }
}

sub print_product {
    our $text = $main::text;
    while (my ($product_id, $product_desp) = each %product) {
        $text -> insert('end', "$product_id  \t");
        $text -> insert('end', "$product_desp\n");
    }
}

sub return_parents {
    foreach (@only_a_parent) {
        return $_, $product{$_};
    }
}

sub draw_element {

}

1;