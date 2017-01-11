# Foo.pm
# HHC - 30-03-2016
package Foo;
use warnings;
use strict;

our $bar;
our %product;

sub setbar {
    $bar = 47;
    print "In sub Foo::set \$bar is $bar.\n"
}

sub setproduct {
    $product{"#1"} = "name one";
    $product{"#2"} = "name two";
	#%product = %main::product;
    print "... In Foo.\n";
    while (my @list = each %product) {
        my $key = $list[0];
        my $value = $list[1];
        print "$key $value\n"
    }
     print "Out Foo.\n";   
}

1