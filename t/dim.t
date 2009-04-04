#!/usr/bin/perl -w

use Test::More;
use strict;

# test dim(), html_dim() and image_info()

BEGIN
   {
   plan tests => 5;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim html_dim);

my $info = image_info("../img/test.gif");
my @dim = dim($info);

is (join(" ", @dim), "400 300", 'dim()');

is (dim($info), '400x300', 'dim($info)');

is (html_dim($info), 'width="400" height="300"', 'html_dim()');

is (html_dim(image_info('README')), '', 'no README in info');
