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

my $i = image_info("../img/test.png") ||
  die ("Couldn't read test.png: $!");

#use Data::Dump; print Data::Dump::dump($i), "\n";

is ($i->{color_type}, 'Indexed-RGB', 'color_type');
is ($i->{LastModificationTime}, "1999-12-25 22:29:06", 'LastModificationTime');

is (dim($i), '400x300', 'dim()');
