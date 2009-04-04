#!/usr/bin/perl -w

use Test::More;
use strict;

# test dim(), html_dim() and image_info()

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.rle")
 || die ("Couldn't read test.rle: $!");

#use Data::Dumper; print Dumper($i), "\n";

is ($i->{Compression}, 'RLE8', 'Compression');
is ($i->{BitsPerSample}, '8', 'BitsPerSample');

is (dim($i), '256x256', 'dim()');
