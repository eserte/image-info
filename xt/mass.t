#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

# locate .ico | grep '.ico$' | perl -pe 's/\n/\0/g' | xargs -0 ./xt/mass.t

use strict;
use FindBin;
use blib "$FindBin::RealBin/..";

use Test::More 'no_plan';

use Data::Dumper;
use DB_File;
use Getopt::Long;
use Image::Info qw(image_info);

sub usage {
    die "usage: $0 [-testokdb dbfile] file ...";
}

my $test_ok_db;
GetOptions("testokdb=s" => \$test_ok_db)
    or usage;
my @files = @ARGV
    or usage;

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
    if ($file =~ m{\.wbmp$}) {
	diag "Image::Info cannot handle wbmp files, skipping $file...";
	next;
    }
    my @info_pm = image_info($file);
    normalize_info(\@info_pm);
    my @info_im = identify_to_image_info($file);

    local $TODO;
    $TODO = "Minor floating point differences with SVG files" if $file =~ m{\.svg$};
    $TODO = "Buffer for magic checks is known to be too small" if $file =~ m{\.xbm$};
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
	for my $key (keys %$info) {
	    delete $info->{$key} unless $key =~ m{^(width|height|file_ext|error)$};
	}
    }
}

sub identify_to_image_info {
    my $file = shift;
    my @info;
    open my $fh, "-|", "identify", $file
	or die $!;
    while(<$fh>) {
	chomp;
	my($filename_with_index, $file_type, $width, $height) = $_ =~ m{^(.*) # filename, maybe with image index
									\s+(\S+) # file type
									\s+(\d+)x(\d+) # dim
									\s+\S+ # geometry
									\s+\S+ # bits
									\s+\S+ # visual
									\s+\S+ # filesize
									\s*$
								   }x;
	if (defined $filename_with_index) {
	    my $info = {};
	    if (!@info) { # only for first array element
		$info->{file_ext} = lc $file_type;
		$info->{file_ext} = 'jpg' if $info->{file_ext} eq 'jpeg';
	    }
	    $info->{width} = $width;
	    $info->{height} = $height;
	    push @info, $info;
	} else {
	    push @info, { 'error' => 'Unrecognized file format' };
	}
    }
    if (!@info) {
	@info = { 'error' => 'Unrecognized file format' };
    }
    @info;
}

__END__
