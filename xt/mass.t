#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

# (locate .jpg | grep '.jpg$'; locate .jpeg | grep '.jpeg$'; locate .gif | grep '.gif$'; locate .png | grep '.png$'; locate .xpm|grep '.xpm$') > /tmp/filelist
# prove --exec './xt/mass.t -testokdb /tmp/testok.db' mass.t

# locate .ico | grep '.ico$' | perl -pe 's/\n/\0/g' | xargs -0 ./xt/mass.t

# (locate .jpg | grep '.jpg$'; locate .jpeg | grep '.jpeg$'; locate .gif | grep '.gif$'; locate .png | grep '.png$'; locate .xpm|grep '.xpm$') | perl -pe 's/\n/\0/g' | xargs -0 ./xt/mass.t -testokdb /tmp/testok.db

use strict;
use FindBin;
use blib "$FindBin::RealBin/..";

use Test::More;

use Data::Dumper;
use File::Glob qw(bsd_glob);
use Getopt::Long;
use Image::Info qw(image_info);

BEGIN {
    if (!eval q{ use DB_File; 1 }) {
	plan skip_all => 'DB_File not available';
    }
    if (!eval q{ use Image::Magick; 1 }) {
	plan skip_all => 'Image::Magick not available';
    }
}
plan 'no_plan';

sub usage {
    die "usage: $0 [-testokdb dbfile] [-filelist | file ...]";
}

my $test_ok_db;
my $filelist;
GetOptions(
	   "testokdb=s" => \$test_ok_db,
	   "filelist=s" => \$filelist,
	  )
    or usage;
my @files;
if ($filelist) {
    open my $fh, $filelist
	or die "Can't open $filelist: $!";
    while(<$fh>) {
	chomp;
	push @files, $_;
    }
} else {
    @files = @ARGV;
    if (!@files) {
	diag "Note: no files provided, using supplied test files...";
	@files = bsd_glob("$FindBin::RealBin/../img/*.{gif,jpg,png,bmp,tif}");
    }
}

my %tested_ok;
if ($test_ok_db) {
    tie %tested_ok, 'DB_File', $test_ok_db, O_RDWR|O_CREAT, 0644
	or die "Can't tie $test_ok_db: $!";
    $SIG{INT} = sub {
	# So db file can flush everything
	CORE::exit(1);
    };
}

for my $file (@files) {
    next if exists $tested_ok{$file};
    next if !-r $file;
    next if !-s $file;
    if ($file =~ m{\.wbmp$}) {
	diag "Image::Info cannot handle wbmp files, skipping $file...";
	next;
    }
    next if $file =~ m{/\.xvpics/[^/]+$}; # ignore xv thumbnail files
    my @info_pm = image_info($file);
    normalize_info(\@info_pm);
    my @info_im = image_magick_to_image_info($file);

    local $TODO;
    $TODO = "Minor floating point differences with SVG files" if $file =~ m{\.svg$};
    $TODO = "Buffer for magic checks is known to be too small" if $file =~ m{\.xbm$};
    $TODO = "Photoshop files not handled by Image::Info" if $info_im[0] && $info_im[0]->{file_ext} && $info_im[0]->{file_ext} eq 'psd';
    my $success = is_deeply(\@info_pm, \@info_im, "Check for $file");
    if ($success) {
	$tested_ok{$file} = 1;
    } else {
	diag(Dumper(\@info_pm, \@info_im));
    }
}

sub normalize_info {
    my($info_ref) = @_;
    for my $info (@$info_ref) {
	if ($info->{error}) {
	    $info->{__seen_error__} = 1;
	    delete $info->{error};
	}
	for my $key (keys %$info) {
	    delete $info->{$key} unless $key =~ m{^(width|height|file_ext|__seen_error__)$};
	}
    }

    no warnings 'uninitialized'; # file_ext may be undef

    # It seems that embedded thumbnails are not reported by Image::Magick
    if ($info_ref->[0]->{file_ext} eq 'jpg' && @$info_ref > 1) {
	@$info_ref = ($info_ref->[0]);
    }	
    if ($info_ref->[0] && $info_ref->[0]->{file_ext} =~ m{^p[gbp]m$}) {
	$info_ref->[0]->{file_ext} = 'pnm';
    }
    if ($info_ref->[0] && $info_ref->[0]->{file_ext} =~ m{^rle$}) {
	$info_ref->[0]->{file_ext} = 'bmp';
    }
}

sub image_magick_to_image_info {
    my $file = shift;
    my @info;

    no warnings 'uninitialized'; # $format may be undef

    my $im = Image::Magick->new;
    my(undef, undef, undef, $format) = $im->Ping($file);
    $format = lc $format;
    if ($format eq 'jpeg') {
	$format = 'jpg';
    } elsif ($format eq 'tiff') {
	$format = 'tif';
    } elsif ($format eq 'bmp3') {
	$format = 'bmp';
    }
    
    $im->Read($file);
    for (my $x = 0; $im->[$x]; $x++) {
	my %info;
	@info{qw(width height)} = $im->[$x]->Get(qw(width height));
	if (@info == 0) {
	    $info{file_ext} = $format;
	}
	push @info, \%info;
    }
    if (!@info) {
	@info = { '__seen_error__' => 1 };
    }
    @info;
}

pass 'All done.';

__END__
