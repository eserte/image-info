#!/usr/bin/perl -w

use Test::More;
use strict;

# test RLE encoded bitmaps

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use lib '../blib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.rle")
 || die ("Couldn't read test.rle: $!");

#use Data::Dumper; print Dumper($i), "\n";

is ($i->{Compression}, 'RLE8', 'Compression');
is ($i->{BitsPerSample}, '8', 'BitsPerSample');
is ($i->{SamplesPerPixel}, 1, 'SamplesPerPixel');

is ($i->{file_media_type}, 'image/bmp', 'image/bmp');
is ($i->{BMP_ColorsImportant}, 255, '255 colors');
is ($i->{ColorTableSize}, 255, '255 colors');
is ($i->{BMP_Origin}, 1, 'BMP_Origin');
is ($i->{color_type}, 'Indexed-RGB', 'color_type');

is (dim($i), '64x64', 'dim()');
