#!/usr/bin/perl

# HHC - 2016-03-23
# usage: hypercube.pl n
#        where n as in 2^n hypercube

die "Require a number" unless defined $ARGV[0];
$max = $ARGV[0];
die "Require n >= 0" if not $max >= 0;

# n=0
$n = 0; @list = qw/0/;
if ($max == 0) {
    my $name = name($n);
    print "($name\n";
    print "    (0 ())\n";
    print ")\n";
    exit 0;
}

# n=1
$n++;     @list = qw/0 1/;
$hypercube{"0"} = 0;
$hypercube{"1"} = 1;

# generate hypercube recursively
while ($n < $max) {
    next_hypercube();
    $n++;
}

#print_hypercube();  # for testing only
#print_by_name(@list);  # for testing only

group_by_level();
#print_by_level();  # for testing only
lattice_by_level();

exit 0;

###
### subroutines
###

sub next_hypercube {
    # turn %hypercube to @list, increase degree, turn @list to %hypercube
    undef @list;
    while (my ($binary, $decimal) = each %hypercube) {
        push @list, "0" . $binary;
        push @list, "1" . $binary;
    }
    undef %hypercube;
    $hypercube{$_} = bin2dec($_) foreach @list;
}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
    # 32 binary digits maximum or 2,147,483,647 demcial
}

sub print_by_name {
    $name = name($n);
    print "$name\n";
    print "@_" . "\n";
    exit 0 if $n >= $max;
}

sub print_hypercube {
    while (my ($binary, $decimal) = each %hypercube) {
        my $sum = digits_sum($binary);
        print "$sum: $binary - $decimal\n";
    }
}

sub group_by_level {
    undef %level;
    while (my ($binary, $decimal) = each %hypercube) {
        my $sum = digits_sum($binary);
        #print "$sum: $binary - $decimal\n";
        push @{$level{"L$sum"}}, $binary;
    }
}

sub print_by_level{
    for (my $i=$max; $i >= 0; $i--) {
        my @list = @{$level{"L$i"}};
        print "L$i: " . "@list" . "\n";
    }
}

sub lattice_by_level{
    my $name = name($n);
    print "($name\n";
    for (my $i=0; $i <= $n; $i++) {
        my $j = $i + 1;
        my @this = @{$level{"L$i"}};
        my @next = @{$level{"L$j"}};
        foreach (@this) {
            my $child = $_;
            print "($hypercube{$child} (";
            @list = compare($child, @next);
            print "@list";
            print "))\n";
        }
    }
    print ")\n";
}

sub compare {
   my ($child, @parents) = @_;
   my @list;
   foreach (@parents) {
       my $parent = $_;
       my @char_c = split //, $child;
       my @char_p = split //, $parent;
       my ($diff, $odd);
       my $count = @char_c;
       for (my $i=0; $i < $count; $i++) {
           $odd++ if not $char_p[$i] == $char_c[$i];
           $diff += $char_p[$i] - $char_c[$i];
       }
       push @list, $hypercube{"$parent"} if $odd == 1 and $diff == 1;
   }
   return @list;
}

sub name {
    if    ($_[0] == 0) {return "point_" . $n;}
    elsif ($_[0] == 1) {return "line_" . $n;}
    elsif ($_[0] == 2) {return "square_" . $n;}
    elsif ($_[0] == 3) {return "cube_" . $n;}
    elsif ($_[0] == 4) {return "tessaract_" . $n;}
    else               {return "hypercube_" . $n;}
}

sub digits_sum {
    my $sum;
    $sum += $_ foreach (split //, $_[0]);
    return $sum;
}
