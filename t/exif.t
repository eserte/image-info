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

my $i = image_info("../img/test.jpg") || die;

#use Data::Dump; print Data::Dump::dump($i), "\n";

is ($i->{DateTimeDigitized}, "1999:12:06 16:38:40", 'DateTimeDigitized');

is ($i->{Make}, "OLYMPUS OPTICAL CO.,LTD", 'Make');

is (dim($i), '640x480', 'dim()');
