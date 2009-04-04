#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../blib/';
  use lib '../lib/';
  plan tests => 12;
  }

use Image::Info qw(image_info dim);

## This TIFF file has 3 images, in 24-bit colour, 1-bit mono and 8-bit grey.
my @i = image_info("../img/test.tif");
ok ( @i, 'image_info ran ok');
is ( @i, 3, 'Right number of images found' );

## First image
is ( scalar @{$i[0]->{BitsPerSample}}, 3 , 'Three lots of BitsPerSample for full-colour image' );
is ( $i[0]->{SamplesPerPixel}, 3, 'SamplesPerPixel is 3 for full-colour image' );
is ( $i[0]->{width}, 60, 'width is right for full-colour image');
is ( $i[0]->{height}, 50, 'height is right for full-colour image');

## Second image
is ( $i[1]->{BitsPerSample}, 1, 'BitsPerSample right for 1-bit image' );
is ( $i[1]->{SamplesPerPixel},  1, 'BitsPerSample right for 1-bit image' );
is ( $i[1]->{Compression}, 'CCITT T6', 'Compression right for 1-bit image' );

## Third image
is ( $i[2]->{BitsPerSample}, 8,  'Bit depth right for greyscale image' );
is ( $i[2]->{SamplesPerPixel}, 1, 'Bit depth right for greyscale image' );
is ( dim($i[2]), '60x50' , 'dim() function is right for greyscale image' );

1;

