#!/usr/bin/perl -w

use Test::More;
use strict;

# test exif info extraction

BEGIN
   {
   plan tests => 5;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.jpg") || die;

#use Data::Dump; print Data::Dump::dump($i), "\n";

is ($i->{DateTimeDigitized}, "1999:12:06 16:38:40", 'DateTimeDigitized');

is ($i->{Make}, "OLYMPUS OPTICAL CO.,LTD", 'Make');

# test parsing of MakerNote (especially that there are no trailing \x00):

# this is a "UNDEFINED" value with trailing zeros \x00:
is ($i->{'Olympus-CameraID'}, 'OLYMPUS DIGITAL CAMERA', 'Olympus-CameraID');

#use Devel::Peek;
#print Dump($i->{'Olympus-CameraID'});

is (dim($i), '640x480', 'dim()');
