#!/usr/bin/perl -w

use Test::More;
use strict;

# test SVG images

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../lib';

  if (!eval { require XML::LibXML::Reader; require XML::Simple; 1 } &&
      !eval { require XML::Simple; require XML::SAX::PurePerl; 1 } # XML::Simple requires XML::SAX (which XML::SAX::PurePerl) but theoretically works just with XML::Parser, which is not sufficient here (RT #143685)
     )
    {
      plan skip_all => "Need XML::Simple+XML::SAX::PurePerl or XML::LibXML::Reader+XML::Simple for this test";
    }

  plan tests => 14;
  }

use Image::Info qw(image_info dim);

my $test_svg = "../img/test.svg";
my $i = image_info($test_svg) ||
  die ("Couldn't read $test_svg: $!");
is $i->{error}, undef, "no error while reading $test_svg";

{
  no warnings 'once';
  diag "Using SVG module $Image::Info::SVG::USING_MODULE";
  diag "XML::Simple $XML::Simple::VERSION" if defined $XML::Simple::VERSION;
  if (defined $XML::SAX::ParserPackage) {
      no strict 'refs';
      my $ver = ${ $XML::SAX::ParserPackage . "::VERSION" };
      diag "XML::SAX::ParserPackage $XML::SAX::ParserPackage $ver";
  }
  diag "XML::LibXML::Reader $XML::LibXML::Reader::VERSION" if defined $XML::LibXML::Reader::VERSION;
  diag "Compiled against libxml2 version: " . XML::LibXML::LIBXML_VERSION() if defined &XML::LibXML::LIBXML_VERSION;
  diag "Running libxml2 version:          " . XML::LibXML::LIBXML_RUNTIME_VERSION() if defined &XML::LibXML::LIBXML_VERSION;
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

#############################################################################
# first file without xml preamble
{
    my $buf;
    {
	open my $fh, "../img/test.svg" or die $!;
	local $/ = \4096;
	while (<$fh>) {
	    $buf .= $_;
	}
    }
    $buf =~ s{^<\?xml.*?>}{}; # strip XML preamble
    $i = image_info(\$buf);
    is ($i->{file_media_type}, 'image/svg+xml', 'file_media_type (svg without xml preamble)');
}
