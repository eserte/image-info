#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use blib "$FindBin::RealBin/..";

use Data::Dumper;
use File::Glob qw(bsd_glob);
use Test::More 'no_plan';

use Image::ExifTool qw();
use Image::Info qw();
use Image::Size qw();
use Imager;

$Data::Dumper::Useqq = 1; # protect from non-prinatble chars

if (!@ARGV) {
    diag "Note: no files provided, using supplied test files...";
    @ARGV = bsd_glob("$FindBin::RealBin/../img/*.{gif,jpg,png,bmp,tif}");
}
for my $file (@ARGV) {
    print "======== $file ========\n";
    print "Image::Info: " . Dumper(Image::Info::image_info($file, L1D_Histogram => 1, ColorPalette => 1)) . "\n";
    print "Image::ExifTool: " . Dumper(Image::ExifTool::ImageInfo($file)) . "\n";
    print "Image::Size: " . Dumper(Image::Size::imgsize($file)) . "\n";
    print "identify: "; system("identify", $file);
    {
	my $img = Imager->new;
	$img->open(file => $file);
	print "Imager: " . Dumper({type => $img->type,
				   tags => [$img->tags],
				  }) . "\n";
    }
}

pass 'All done';

__END__
