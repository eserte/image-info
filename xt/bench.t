#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use blib "$FindBin::RealBin/..";

use Test::More 'no_plan';

use Data::Dumper;
use File::Glob qw(bsd_glob);
use Benchmark qw(timeit timestr);
use Image::ExifTool qw();
use Image::Info qw();
use Image::Magick qw();
use Image::Size qw();

my $count = 1;
my @files = @ARGV;
if (!@files) {
    diag "Note: no files provided, using supplied test files...";
    @files = bsd_glob("$FindBin::RealBin/../img/*.{gif,jpg,png,bmp,tif}");
}

{
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::Info::image_type($file);
		       }
		   });
    diag 'Image::Info::image_type: ' . timestr($t, 'all');
}

{
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::Info::image_info($file);
		       }
		   });
    diag 'Image::Info::image_info: ' . timestr($t, 'all');
}

{
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::ExifTool::ImageInfo($file);
		       }
		   });
    diag 'Image::ExifTool: ' . timestr($t, 'all');
}

{
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my($x,$y) = Image::Size::imgsize($file);
		       }
		   });
    diag 'Image::Size: ' . timestr($t, 'all');
}

{
    my $t = timeit($count, sub {
		       open my $fh, "-|", 'identify', @files or die $!;
		       while(<$fh>) { }
		       close $fh or die $!;
		   });
    diag 'identify: ' . timestr($t, 'all');
}

{
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my($w,$h,undef,$format) = Image::Magick->new->Ping($file);
		       }
		   });
    diag 'Image::Magick: ' . timestr($t, 'all');
}

pass "Benchmark tests done!";

__END__
