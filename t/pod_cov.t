#!/usr/bin/perl -w

use Test::More;
use strict;
my $tests;

BEGIN
   {
   $tests = 7;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip("Test::Pod::Coverage 1.00 required for testing POD coverage", $tests)
    unless do {
    eval "use Test::Pod::Coverage;";
    $@ ? 0 : 1;
    };
  for my $m (qw[
    Info
    Info::BMP
    Info::PPM
    Info::SVG
    Info::XBM
    Info::XPM
    Info::TIFF
    ])
    {
    pod_coverage_ok( 'Image::' . $m, "$m is covered" );
    }
  # XXX TODO:
#    TIFF
#    Info::GIF
#    Info::PNG
#    Info::JPEG

  }

