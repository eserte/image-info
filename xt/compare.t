#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use blib "$FindBin::RealBin/..";

use Data::Dumper;
use Test::More 'no_plan';

use Image::ExifTool qw();
use Image::Info qw();
use Image::Size qw();
use Imager;

my $file = shift
    or die "Please specify file";

print "Image::Info: " . Dumper(Image::Info::image_info($file)) . "\n";
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

pass 'All done';

__END__
