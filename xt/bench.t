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

my $count = 1;
my @files = @ARGV;
if (!@files) {
    diag "Note: no files provided, using supplied test files...";
    @files = bsd_glob("$FindBin::RealBin/../img/*.{gif,jpg,png,bmp,tif}");
}

SKIP: {
    skip "No Image::Info available", 0 if !eval { require Image::Info; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::Info::image_type($file);
		       }
		   });
    diag "Image::Info ($Image::Info::VERSION) image_type: " . timestr($t, 'all');
}

SKIP: {
    skip "No Image::Info available", 0 if !eval { require Image::Info; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::Info::image_info($file);
		       }
		   });
    diag "Image::Info ($Image::Info::VERSION) image_info: " . timestr($t, 'all');
}

SKIP: {
    skip "No Image::ExifTool available", 0 if !eval { require Image::ExifTool; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $info = Image::ExifTool::ImageInfo($file);
		       }
		   });
    diag "Image::ExifTool ($Image::ExifTool::VERSION): " . timestr($t, 'all');
}

SKIP: {
    skip "No Image::Size available", 0 if !eval { require Image::Size; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my($x,$y) = Image::Size::imgsize($file);
		       }
		   });
    diag "Image::Size ($Image::Size::VERSION): " . timestr($t, 'all');
}

SKIP: {
    skip "No identify program available", 0 if !is_in_path('identify');
    my $t = timeit($count, sub {
		       open my $fh, "-|", 'identify', @files or die $!;
		       while(<$fh>) { }
		       close $fh or warn "While working at 'identify @files[0..5] ...': $!";
		   });
    diag 'identify: ' . timestr($t, 'all');
}

SKIP: {
    skip "No Image::Magick available", 0 if !eval { require Image::Magick; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my($w,$h,undef,$format) = Image::Magick->new->Ping($file);
		       }
		   });
    diag "Image::Magick ($Image::Magick::VERSION): " . timestr($t, 'all');
}

SKIP: {
    skip "No GD available", 0 if !eval { require GD; 1 };
    my $t = timeit($count, sub {
		       for my $file (@files) {
			   my $img = GD::Image->new($file);
			   if ($img) {
			       my($w,$h) = $img->getBounds;
			   }
		       }
		   });
    diag "GD ($GD::VERSION): " . timestr($t, 'all');
}

pass "Benchmark tests done!";

# REPO BEGIN
# REPO NAME is_in_path /home/slavenr/work2/srezic-repository 
# REPO MD5 e18e6687a056e4a3cbcea4496aaaa1db
sub is_in_path {
    my($prog) = @_;
    require File::Spec;
    if (File::Spec->file_name_is_absolute($prog)) {
	if ($^O eq 'MSWin32') {
	    return $prog       if (-f $prog && -x $prog);
	    return "$prog.bat" if (-f "$prog.bat" && -x "$prog.bat");
	    return "$prog.com" if (-f "$prog.com" && -x "$prog.com");
	    return "$prog.exe" if (-f "$prog.exe" && -x "$prog.exe");
	    return "$prog.cmd" if (-f "$prog.cmd" && -x "$prog.cmd");
	} else {
	    return $prog if -f $prog and -x $prog;
	}
    }
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"     if (-f "$_\\$prog" && -x "$_\\$prog");
	    return "$_\\$prog.bat" if (-f "$_\\$prog.bat" && -x "$_\\$prog.bat");
	    return "$_\\$prog.com" if (-f "$_\\$prog.com" && -x "$_\\$prog.com");
	    return "$_\\$prog.exe" if (-f "$_\\$prog.exe" && -x "$_\\$prog.exe");
	    return "$_\\$prog.cmd" if (-f "$_\\$prog.cmd" && -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

__END__
