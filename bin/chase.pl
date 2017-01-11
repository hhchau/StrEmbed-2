#!/usr/bin/perl
# chase.pl
# HHC - 2016-09-01
use strict;
use warnings;

my $id = $ARGV[0];
my $field = $ARGV[1];
my $n = 0;
my $nauo_n = 0;
my %line;
my @shape_def_rep = ();
my %shape_def_rep;
my @shape_rep_relationship = ();
my @context_dependent_shape_rep = ();
my %context_dependent_shape_rep;
my %to_be_deleted_shape_def_rep;
my $preamble;
my %part;

&read_step_file;
&find_product;
&extract_shape_def_rep;
&extract_context_dependent_shape_rep;
&find_sdr_cdsr;
&sub_to_be_deleted_shape_def_rep;
&find_old_pds;
&delete_four_plus_things;
&main_loop;
&output_step_file;

sub main_loop {
    #&create_new_shape_def_rep(qw/ABCDE A B C D E/);

    #&create_new_shape_def_rep(qw/ABC A B C/);
    #&create_new_shape_def_rep(qw/DE D E/);
    #&create_new_shape_def_rep(qw/ABCDE ABC DE/);

    #&create_new_shape_def_rep(qw/AB A B/);
    #&create_new_shape_def_rep(qw/CD C D/);
    #&create_new_shape_def_rep(qw/ABCDE AB CD E/);

    &create_new_shape_def_rep(qw/AB A B/);
    &create_new_shape_def_rep(qw/ABC AB C/);
    &create_new_shape_def_rep(qw/DE D E/);
    &create_new_shape_def_rep(qw/ABCDE ABC DE/);
}

sub find_old_pds {
    while ( my ($id, $content) = each %line) {
        if ($content =~ m/^PRODUCT_DEFINITION_SHAPE\s*\(/) {
            my $id2 = &get_argument($id, 2);
            my $content2 = $line{$id2};
            if ($content2 =~ m/^PRODUCT_DEFINITION\s*\(/) {
                my $pdfwss = &get_argument($id2, 2);
                my $prod = &get_argument($pdfwss, 2);
                my $name = &get_argument($prod, 0);
                $name =~ s/^\'//;
                $name =~ s/\'$//;
                $part{$name}[2] = $id;  # $id = $pds
                # print "$name    $id > $content\n";
            } elsif ($content2 =~ m/^NEXT_ASSEMBLY_USAGE_OCCURRENCE\s*\(/) {
                #print "delete $id = $line{$id}\n";
                delete $line{$id};
            }
        }
    }
}

sub delete_four_plus_things {
    foreach my $sdr ( &hash_sort( keys %to_be_deleted_shape_def_rep ) ) {
        delete $line{$sdr};
        foreach my $ref( @{$to_be_deleted_shape_def_rep{$sdr}} ) {
            delete $line{$ref};
        }
    }

    while ( my ($id, $content) = each %line) {
        if ( $content =~ m/^NEXT_ASSEMBLY_USAGE_OCCURRENCE/ or
             $content =~ m/^ITEM_DEFINED_TRANSFORMATION/ or
             $content =~ m/^PRODUCT_RELATED_PRODUCT_CATEGORY/ or
             $content =~ m/^\(\s*REPRESENTATION_RELATIONSHIP/ or
             $content =~ m/^\(\s*PRODUCT_DEFINITION_SHAPE/ or
             $content =~ m/^CONTEXT_DEPENDENT_SHAPE_REPRESENTATION/ ) {
            delete $line{$id};
        }            
    }
}

sub XXX_print_product {
    foreach my $label ( sort keys %part ) {
        my $sr  = $part{$label}[0];
        my $pd  = $part{$label}[1];
        print "$label -> SR=$sr PD=$pd\n";
    }
}

sub find_product {
    foreach my $id ( &hash_sort( keys %line ) ) {
        my $content = $line{$id};
        my $entity = 0;
        $entity = $1 if $content =~ m/^(\w+)\s*(.*)/;
        if ($entity eq 'SHAPE_DEFINITION_REPRESENTATION') {
            #print "$id = $line{$id} ;\n";
            my $pds = &get_argument($id, 0);
            my $pd = &get_argument($pds, 2);
            my $pdfwss = &get_argument($pd, 2);
            my $p = &get_argument($pdfwss, 2);
            my $label = &get_argument($p, 0);
            my $description = &get_argument($p, 1);
            $label =~ s/^'//;
            $label =~ s/'$//;
            $description =~ s/^'//;
            $description =~ s/'$//;
            #print "$label $description\n";
            $part{$label}[1] = $pd;
        } elsif ($entity eq 'SHAPE_REPRESENTATION') {
            #print "$id = $line{$id} ;\n";
            my $label = &get_argument($id, 0);
            $label =~ s/^'//;
            $label =~ s/'$//;
            #print "$label\n";
            $part{$label}[0] = $id;
        }
    }
}

sub create_new_shape_def_rep {
    my $parent = shift;
    my @children = @_;
    my %template;
    foreach my $id ('#sdr', '#pds', '#pd', '#pdfwss', '#p', '#pc', '#app', '#pdc', '#apc',
                    '#sr', '#axis', '#origin', '#dirz', '#dirx', '#geo',
                    '#uncertainy', '#mm', '#radian', '#steradian',
                    '#prpc', '#apdp', '#apdc') {
        $template{$id} = ++$n;
    }
    
    my $data_start = tell DATA;
    while (<DATA>) {
        my $line = $_;
        chomp $line;
        $line =~ s/\s*;\s*$//;
        while (my ($old, $new) = each %template) {
            $line =~ s/\Q$old\E([,\)\s])/#\Q$new\E$1/g;
        }

        if ( $line =~ m/^\s*(\#\d+)\s*=\s*(.*)$/ ) {
            my $id = $1;
            my $content = $2;
            $line{$id} = $content;
            if ($content =~ m/^PRODUCT\s*\(/) {
                $content =~ s/\#name\#/$parent/g;
                $line{$id} = $content;
            } elsif ($content =~ m/^SHAPE_REPRESENTATION\s*\(/) {
                $part{$parent}[0] = $id;
                $content =~ s/\#name\#/$parent/;
                $line{$id} = $content;
            } elsif ($content =~ m/^PRODUCT_DEFINITION\s*\(/) {
                $part{$parent}[1] = $id;
            } elsif ($content =~ m/^PRODUCT_DEFINITION_SHAPE\s*\(/) {
                $part{$parent}[2] = $id;
            }
        }
    }
    seek DATA, $data_start, 0;
    
    foreach my $child (@children) {
        &create_new_assy_relation($parent, $child);
    }
}

sub create_new_assy_relation {
    my ($parent, $child) = @_;
    my $sr_p = $part{$parent}[0];
    my $pd_p = $part{$parent}[1];
    my $sr_c = $part{$child}[0];
    my $pd_c = $part{$child}[1];
    my $pds_c = $part{$child}[2];
    #print "$parent -> $child = SR=$sr_p PD=$pd_p\n";
    #print "$parent <- $child = SR=$sr_c PD=$pd_c\n";
    my $nauo = "#" . ++$n; $nauo_n++;
    $line{$nauo} = "NEXT_ASSEMBLY_USAGE_OCCURRENCE ( 'NAUO$nauo_n', ' ', ' ', $pd_p, $pd_c, \$ )";  ###
    my $pds = "#" . ++$n;
    $line{$pds} = "PRODUCT_DEFINITION_SHAPE ( 'NONE', 'NONE',  $nauo )";
    my $idt = "#" . ++$n;
    my $axis = "#" . ++$n;
    my $origin = "#" . ++$n;
    my $dirz = "#" . ++$n;
    my $dirx = "#" . ++$n;
    $line{$idt} = "ITEM_DEFINED_TRANSFORMATION ( 'NONE', 'NONE', $axis, $axis )";
    $line{$axis} = "AXIS2_PLACEMENT_3D ( 'NONE', $origin, $dirz, $dirx )";
    $line{$origin} = "CARTESIAN_POINT ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) )";
    $line{$dirz} = "DIRECTION ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 1.000000000000000000 ) )";
    $line{$dirx} = "DIRECTION ( 'NONE',  ( 1.000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) )";
    my $rep = "#" . ++$n;
    $line{$rep} = "( REPRESENTATION_RELATIONSHIP ('NONE','NONE', $sr_p, $sr_c ) REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION ( $idt )SHAPE_REPRESENTATION_RELATIONSHIP( ) )";   ###
    my $cdsr = "#" . ++$n;
    $line{$cdsr} = "CONTEXT_DEPENDENT_SHAPE_REPRESENTATION ( $rep, $pds )";
}

sub output_step_file {
    my $filename = "pp.STEP";
    open( my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $preamble;
    print $fh "$_ = $line{$_} ;\n" foreach &hash_sort( keys %line );
    print $fh "ENDSEC;\n";
    print $fh "END-ISO-10303-21;\n";
    close $fh;
}

sub hash_sort {
    my @input = @_;
    my @output = ();
    my %hash;
    foreach my $hash_digits (@input) {
        $hash_digits =~ m/#(\d+)/;
        my $digits = $1;
        $hash{$digits} = $hash_digits;
    }

    for my $key ( sort {$a<=>$b} keys %hash) {
           push @output, $hash{$key};
    }

    return @output;
}

sub to_be_deleted_entities {
    my $sdr = shift;
    my $ref = shift;
    #print "lines 195 - $sdr, $ref\n";
    #print "$sdr = $line{$sdr}\n";
    #print "$ref = $line{$ref}\n";
    my $content = $line{$ref};
    #print ">>>$to_be_deleted_shape_def_rep{$sdr}<<<\n";
    #my @list;
    #push @list, $ref;
    #print "===@list===\n";
    push @{ $to_be_deleted_shape_def_rep{$sdr} }, $ref;  ##### ???????
    &delete_next_level_down($sdr, $ref);
}

sub delete_next_level_down {
    my $sdr = shift;
    my $next = shift;
    my $content = $line{$next};
    my @references = ();
    @references = $content =~ m/\#\d+/g;
    push @{ $to_be_deleted_shape_def_rep{$sdr} }, $next;
    foreach my $id (@references) {
        &delete_next_level_down($sdr, $id);   
    }
}

sub sub_to_be_deleted_shape_def_rep {
    foreach my $sdr (keys %to_be_deleted_shape_def_rep) {
        my @references = $line{$sdr} =~ m/\#\d+/g;
        foreach my $ref (@references) {
            &to_be_deleted_entities($sdr, $ref);
        }
    }
}

sub to_be_copied_n_deleted {
    my ($template, @children) = @_;
    print "$template = @children\n";
    foreach my $child (@children) {
        print "$template .. $child\n";
        my $product_definition_shape                           = &get_argument($id, 0);
        my $product_definition                                 = &get_argument($product_definition_shape, 2);
        my $product_definition_formation_with_specified_source = &get_argument($product_definition, 2);
        my $product                                            = &get_argument($product_definition_formation_with_specified_source, 2);
        print "$id = $line{$id}\n";
        print "$product_definition_shape = $line{$product_definition_shape}\n";
        print "$product_definition = $line{$product_definition}\n";
        print "$product_definition_formation_with_specified_source = $line{$product_definition_formation_with_specified_source}\n";
        print "$product = $line{$product}\n";

        $n++;
        my $new_id = "#$n";
        $line{$new_id} = $line{$id};
        print "$new_id > $line{$new_id}\n";

        my $shape_representation                               = &get_argument($id, 1);
        print "$shape_representation = $line{$shape_representation}\n";
        #&copy_chain($shape_representation);
    }
}

sub print_them {
    print "shape_def_rep = @shape_def_rep\n";
    print "context_dependent_shape_rep = @context_dependent_shape_rep\n";
    print "shape_rep_relationship = @shape_rep_relationship\n";
}

sub trace_all_entities {
    while ( my ($id, $content) = each %line) {
        &trace_entity($id) unless $content =~ m/^\(/;
    }
}

sub trace_entity {
    my $id = $_[0];
    my $content = $line{$id};
    my $entity;
    if ($content =~ m/^(\w+)\s*(.*)/) {
        $entity = $1;
    }

    if ($entity eq 'SHAPE_DEFINITION_REPRESENTATION') {
        my $product_definition_shape                           = &get_argument($id, 0);
        my $product_definition                                 = &get_argument($product_definition_shape, 2);
        my $product_definition_formation_with_specified_source = &get_argument($product_definition, 2);
        my $product                                            = &get_argument($product_definition_formation_with_specified_source, 2);
        my $part_p_id                                          = &get_argument($product, 0);
        my $part_p_name                                        = &get_argument($product, 1);

        my $shape_representation                               = &get_argument($id, 1);
        my $part_sr_name                                       = &get_argument($shape_representation, 0);
        #print ">>>$id = SHAPE_DEFINITION_REPRESENTATION\n";
        #print ">>>$part_p_id=$part_p_name-$part_sr_name\n";
        push @shape_def_rep, $id;
    }

    if ($entity eq 'CONTEXT_DEPENDENT_SHAPE_REPRESENTATION') {
        my $three_things                                       = &get_argument($id, 0);
        my $content = $line{$three_things};
        $content =~ s/^\(\s*//;
        $content =~ s/\s*\)$//;
        # print ">>>$three_things=$content<<<\n";
        my @things = $content =~ m/(\w+\s* \()/g;
        my $thing_one = $things[1];
        my $thing_two;
        my $thing_three;
        # print "thing one is $thing_one\n";

        my $product_definition_shape                                  = &get_argument($id, 1);
        my $next_assembly_usage_occurrence                            = &get_argument($product_definition_shape, 2);
        my $assy_id                                                   = &get_argument($next_assembly_usage_occurrence, 0);
        my $product_definition_parent                                 = &get_argument($next_assembly_usage_occurrence, 3);
        my $product_definition_child                                  = &get_argument($next_assembly_usage_occurrence, 4);
        my $product_definition_formation_with_specified_source_parent = &get_argument($product_definition_parent, 2);
        my $product_definition_formation_with_specified_source_child  = &get_argument($product_definition_child, 2);
        my $product_parent                                            = &get_argument($product_definition_formation_with_specified_source_parent, 2);
        my $product_child                                             = &get_argument($product_definition_formation_with_specified_source_child, 2);
        my $part_p_id_parent                                          = &get_argument($product_parent, 0);
        my $part_p_id_child                                           = &get_argument($product_child, 0);
        my $part_p_name_parent                                        = &get_argument($product_parent, 1);
        my $part_p_name_child                                         = &get_argument($product_child, 1);

        #print "###$id = CONTEXT_DEPENDENT_SHAPE_REPRESENTATION\n";
        #print "###$assy_id-$part_p_id_parent=$part_p_name_parent-$part_p_id_child=$part_p_name_child\n";
        push @context_dependent_shape_rep, $id;
    }

    if ($entity eq 'SHAPE_REPRESENTATION_RELATIONSHIP') {
        my $shape_representation               = &get_argument($id, 2);
        my $part_sr_name                       = &get_argument($shape_representation, 0);

        my $advanced_brep_shape_representation = &get_argument($id, 3);
        my $field_1                            = &get_argument($advanced_brep_shape_representation, 1);
        $field_1 =~ m/(#\d+)\s*,\s*(#\d+)/;
        my $field_10 = $1;
        my $field_11 = $2;
        my $part_msb_name                      = &get_argument($field_10, 0);
        #print "...$id = SHAPE_REPRESENTATION_RELATIONSHIP\n";
        #print "...$part_msb_name-$part_sr_name\n";
        push @shape_rep_relationship, $id;
    }    
}

sub get_argument {
    my $id = $_[0];
    my $item = $_[1];
    my $content = $line{$id};
    #print "$id > $content\n";
    my @list;
    if ($content =~ m/^(\w+)\s*(.*)/) {
        my $entity = $1;
        my $arguments = $2;
        $arguments =~ s/^\(\s*//;
        $arguments =~ s/\s*\)$//;
        @list = split m/,(?![^()]*\))/, $arguments;
        $_ =~  s/^\s*// foreach @list;
    }
    return $list[$item];
}

sub find_cdsr {
    foreach my $id (&hash_sort( keys %context_dependent_shape_rep ) ) {
        my $n1 = my $three_rep_relationships = $context_dependent_shape_rep{$id}[0][0];
        my $n2 = my $rep_relationship_parent = $context_dependent_shape_rep{$id}[0][1][0];
        my $n3 = my $rep_relationship_child  = $context_dependent_shape_rep{$id}[0][1][1];
        my $n4 = my $product_def_shape       = $context_dependent_shape_rep{$id}[1][0];
        my $n5 = my $nauo                    = $context_dependent_shape_rep{$id}[1][1];
        my $n6 = my $nauo_parent             = $context_dependent_shape_rep{$id}[1][2][0];
        my $n7 = my $nauo_child              = $context_dependent_shape_rep{$id}[1][2][1];
        print "- $id = $line{$id} ;\n";
        print "- $n1 = $line{$n1} ;\n";
        print "o $n2 = $line{$n2} ;\n";
        print "- $n3 = $line{$n3} ;\n";
        print "- $n4 = $line{$n4} ;\n";
        print "- $n5 = $line{$n5} ;\n";
        print "o $n6 = $line{$n6} ;\n";
        print "o $n7 = $line{$n7} ;\n";
        print "\n";
    }
}

sub find_sdr_cdsr {
    my $id;

    #print "context_dependent_shape_rep\n";    
    foreach $id (sort keys %context_dependent_shape_rep) {
         my $parent = $context_dependent_shape_rep{$id}[1][2][0];
    #    print "$id:", $context_dependent_shape_rep{$id}[1][0], ":",
    #                  $context_dependent_shape_rep{$id}[1][1], ":(",
    #                  $context_dependent_shape_rep{$id}[1][2][0], " ",
    #                  $context_dependent_shape_rep{$id}[1][2][1], ")\n";

        foreach my $id2 (sort keys %shape_def_rep) {
            my $match = $shape_def_rep{$id2}[0][1];
            @{ $to_be_deleted_shape_def_rep{$id2} } = () if $parent eq $match;
        }
    }

    #print "context_dependent_shape_rep\n";    
    foreach $id (sort keys %context_dependent_shape_rep) {
        my $parent = $context_dependent_shape_rep{$id}[0][1][0];
        #print "$parent\n";
        #print "$id:", $context_dependent_shape_rep{$id}[0][0], ":(",
        #              $context_dependent_shape_rep{$id}[0][1][0], " ",
        #              $context_dependent_shape_rep{$id}[0][1][1], ")\n";

        foreach my $id2 (sort keys %shape_def_rep) {
            my $match = $shape_def_rep{$id2}[1];
            @ {$to_be_deleted_shape_def_rep{$id2} } = () if $parent eq $match;
        }
    }
}

sub extract_context_dependent_shape_rep {
    my $entity = 'CONTEXT_DEPENDENT_SHAPE_REPRESENTATION';
    foreach my $id (sort keys %line) {
        if ($line{$id} =~ m/^\Q$entity\E\s*\(/) {
            my $three_rep_relationships = &get_argument($id, 0);

            my $content = $line{$three_rep_relationships};
            $content =~ s/^\(\s*//;
            $content =~ s/\s*\)$//;
            my @rep_relationships = $content =~ m/#\d+/g;
            my $rep_relationship_parent  = $rep_relationships[0];
            my $rep_relationship_child   = $rep_relationships[1];
            my $rep_relationship_w_trans = $rep_relationships[2];
            #print "$id:$three_rep_relationships:($rep_relationship_parent $rep_relationship_child)\n";

            my $product_def_shape = &get_argument($id, 1);
            my $nauo              = &get_argument($product_def_shape, 2);
            my $nauo_parent       = &get_argument($nauo, 3);
            my $nauo_child        = &get_argument($nauo, 4);
            # print "$id:$product_def_shape:$nauo:($nauo_parent $nauo_child)\n";
            $context_dependent_shape_rep{$id} = [
                [$three_rep_relationships, [$rep_relationship_parent, $rep_relationship_child] ] ,
                [$product_def_shape, $nauo, [$nauo_parent, $nauo_child] ]
            ];
        }
    }
}

sub extract_shape_def_rep {
    my $entity = 'SHAPE_DEFINITION_REPRESENTATION';
    #print "shape_def_rep\n";
    foreach my $id (sort keys %line) {
        if ($line{$id} =~ m/^\Q$entity\E\s*\(/) {
            my $product_def_shape = &get_argument($id, 0);
            my $product_def       = &get_argument($product_def_shape, 2) ;           
            my $shape_rep         = &get_argument($id, 1);

            $shape_def_rep{$id} = [ [$product_def_shape, $product_def], $shape_rep];
        }
    }
}

sub extract {
    my $entity = shift;
    foreach my $id (sort keys %line) {
        my $content = $line{$id};
        print "$id = $content ;\n" if $content =~ m/^\Q$entity\E\s*\(/;
    }
}

sub copy_chain {
    my $root = shift;
    my $content = $line{$root};
    print "$root = $line{$root}\n";
    &next_level_down_all($root);
}

sub next_level_down_all {
    my $root = shift;
    my $content = $line{$root};
    my @references = $content =~ m/\#\d+/g;
    $content =~ m/(\w+)\s*\(/;
    my $entity = $1;
    unless (0) {
        foreach (@references) {
            my $id = $_;
            my $content = $line{$id};
            $n++;
            my $new_id = "#$n";
            
            print "$id = $content\n";  #old
            my @list = $content =~ m/\#\d+/g;
            for (my $i=0; $i<$#list+1; $i++) {
                my $template_ref = $list[$i];
                $n++;
                $content =~ s/\Q$template_ref\E([,\)\s])/#\Q$n\E$1/;
            }
            print "$new_id > $content\n";  #new
            &next_level_down($id);
        } 
    }
}

sub print_entities {
    my $root = shift;
    my $content = $line{$root};
    print "$root = $line{$root}\n";
    &next_level_down($root);
}

sub next_level_down {
    my $root = shift;
    my $content = $line{$root};
    my @references = $content =~ m/\#\d+/g;
    $content =~ m/(\w+)\s*\(/;
    my $entity = $1;
    unless ($entity eq 'SHAPE_REPRESENTATION' or
            # $entity eq 'ITEM_DEFINED_TRANSFORMATION' or
            $entity =~ m/^product$/i or
            $entity eq 'MANIFOLD_SOLID_BREP' or
            $entity eq 'AXIS2_PLACEMENT_3D') {
        foreach (@references) {
            print "$_ = $line{$_}\n";
            &next_level_down($_);
        } 
    }
}

sub read_step_file {
    # my $file = "data/step/puzzle_1b.STEP";
    # my $file = "data/step/puzzle_1c.STEP";
    # my $file = "data/step/puzzle_1d.STEP";
    my $file = "data/step/mess with STEP files/puzzle_1c.STEP";
    open(my $fh, "<", $file) or die "cannot open < $file: $!";
    LABEL: while (<$fh>) {
        # print "$_";
        $preamble .= $_;
        last if $_ =~ m/^DATA;/;
    }
    while (<$fh>) {
        chomp;
        s/\s*;\s*$//;
        if ( $_ =~ m/^\s*(\#\d+)\s*=\s*(.*)$/ ) {
            my $id = $1;
            my $content = $2;
            $line{$id} = $content;
            my @i = $id =~ m/\#(\d+)/;
            $n = $i[0] if $n < $i[0];
            
            if ( $content =~ m/NEXT_ASSEMBLY_USAGE_OCCURRENCE\s*\(\s*\'NAUO(\d+)\'/ ) {
                $nauo_n = $1 if $nauo_n < $1;
            }
        }
    }
    close $fh;
}

#prpc = PRODUCT_RELATED_PRODUCT_CATEGORY ( 'part', '', ( #p ) ) ;

__DATA__
#sdr = SHAPE_DEFINITION_REPRESENTATION ( #pds, #sr ) ;
#pds = PRODUCT_DEFINITION_SHAPE ( 'NONE', 'NONE',  #pd ) ;
#pd = PRODUCT_DEFINITION ( 'UNKNOWN', '', #pdfwss, #pdc ) ;
#pdfwss = PRODUCT_DEFINITION_FORMATION_WITH_SPECIFIED_SOURCE ( 'ANY', '', #p, .NOT_KNOWN. ) ;
#p = PRODUCT ( '#name#', '#name#', '', ( #pc ) ) ;
#pc = PRODUCT_CONTEXT ( 'NONE', #app, 'mechanical' ) ;
#app = APPLICATION_CONTEXT ( 'automotive_design' ) ;
#pdc = PRODUCT_DEFINITION_CONTEXT ( 'detailed design', #apc, 'design' ) ;
#apc = APPLICATION_CONTEXT ( 'automotive_design' ) ;
#sr = SHAPE_REPRESENTATION ( '#name#', ( #axis ), #geo ) ;
#axis = AXIS2_PLACEMENT_3D ( 'NONE', #origin, #dirz, #dirx ) ;
#origin = CARTESIAN_POINT ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) ) ;
#dirz = DIRECTION ( 'NONE',  ( 0.0000000000000000000, 0.0000000000000000000, 1.000000000000000000 ) ) ;
#dirx = DIRECTION ( 'NONE',  ( 1.000000000000000000, 0.0000000000000000000, 0.0000000000000000000 ) ) ;
#geo = ( GEOMETRIC_REPRESENTATION_CONTEXT ( 3 ) GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT ( ( #uncertainy ) ) GLOBAL_UNIT_ASSIGNED_CONTEXT ( ( #mm, #radian, #steradian ) ) REPRESENTATION_CONTEXT ( 'NONE', 'WORKASPACE' ) ) ;
#uncertainy = UNCERTAINTY_MEASURE_WITH_UNIT (LENGTH_MEASURE( 1.000000000000000100E-005 ), #mm, 'distance_accuracy_value', 'NONE') ;
#mm = ( LENGTH_UNIT ( ) NAMED_UNIT ( * ) SI_UNIT ( .MILLI., .METRE. ) ) ;
#radian = ( NAMED_UNIT ( * ) PLANE_ANGLE_UNIT ( ) SI_UNIT ( $, .RADIAN. ) ) ;
#steradian = ( NAMED_UNIT ( * ) SI_UNIT ( $, .STERADIAN. ) SOLID_ANGLE_UNIT ( ) ) ;
#apdp = APPLICATION_PROTOCOL_DEFINITION ( 'draft international standard', 'automotive_design', 1998, #app ) ;
#apdc = APPLICATION_PROTOCOL_DEFINITION ( 'draft international standard', 'automotive_design', 1998, #apc ) ;
