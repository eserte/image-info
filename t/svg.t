#!/usr/bin/perl -w

use Test::More;
use strict;

# test SVG images

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../lib';

  if (!eval { require XML::LibXML::Reader; require XML::Simple; 1 } &&
      !eval { require XML::Simple; 1 }
     )
    {
      plan skip_all => "Need XML::Simple or XML::LibXML::Reader for this test";
    }

  plan tests => 12;
  }

use Image::Info qw(image_info dim);

my $i = image_info("../img/test.svg") ||
  die ("Couldn't read test.svg: $!");

{
  no warnings 'once';
  diag "Using SVG module $Image::Info::SVG::USING_MODULE";
  diag "XML::Simple $XML::Simple::VERSION" if defined $XML::Simple::VERSION;
  diag "XML::LibXML::Reader $XML::LibXML::Reader::VERSION" if defined $XML::LibXML::Reader::VERSION;
}

#use Data::Dumper; print Dumper($i), "\n";

is ($i->{color_type}, 'sRGB', 'color_type');
is ($i->{file_media_type}, 'image/svg+xml', 'file_media_type');

is ($i->{SVG_StandAlone}, 'yes', 'SVG_StandAlone');
is ($i->{file_ext}, 'svg', 'file_ext');
is ($i->{SVG_Version}, 'unknown', 'SVG_Version unknown');

is (dim($i), '4inx3in', 'dim()');

#############################################################################
# second test file
$i = image_info("../img/graph.svg") ||
  die ("Couldn't read graph.svg: $!");

#use Data::Dumper; print Dumper($i), "\n";

is ($i->{SVG_StandAlone}, 'yes', 'SVG_StandAlone');
is ($i->{file_ext}, 'svg', 'file_ext');
is ($i->{file_media_type}, 'image/svg+xml', 'file_media_type');
is ($i->{SVG_Title}, 'Untitled graph', 'title');
is ($i->{SVG_Version}, '1.1', 'SVG_Version 1.1');

is (dim($i), '209x51', 'dim()');

