#!/usr/bin/perl -w

use Test::More;
use strict;
my $tests;

BEGIN
   {
   $tests = 6;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip("Test::Pod::Coverage 1.00 required for testing POD coverage", $tests)
    unless do {
    eval ("use Test::Pod::Coverage 1.00");
    $@ ? 0 : 1;
    };
  for my $m (qw[
    Image::Info.pm
    Image::Info::BMP.pm
    Image::Info::PPM.pm
    Image::Info::SVG.pm
    Image::Info::XBM.pm
    Image::Info::XPM.pm
    ])
    {
    pod_coverage_ok( $m, "$m is covered" );
    }
  # XXX TODO:
#    TIFF.pm
#    Info::TIFF.pm
#    Info::GIF.pm
#    Info::PNG.pm
#    Info::JPEG.pm

  }

