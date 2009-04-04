#!/usr/bin/perl -w

use strict;
use File::Spec;

#############################################################################
#############################################################################
# Write the Info.pm file with system specific code from Info.pm.tmpl:

# This is run by the developer, and there is no need to rerun this at build
# time.

BEGIN
  {
  chdir 'dev' if -d 'dev';
  }

my $updir = File::Spec->updir();
my $tmpl = File::Spec->catfile("Info.pm.tmpl");
my $info_pm = File::Spec->catfile($updir,"lib", "Image", "Info.pm");
my $idir = File::Spec->catdir($updir,"lib", "Image", "Info");
opendir(DIR, $idir) || die "Can't opendir $idir: $!";
my (@code,@desc, $desc);
for my $file (sort readdir(DIR)) {
    next unless $file =~ /^([a-zA-Z]\w*)\.pm$/;
    my $format = $1;

    open(F, File::Spec->catfile($idir, $file)) || die "Can't open '$idir/$file': $!";
    my @magic;
    my @desc;
    while (<F>) {
	if (/^=begin\s+register\b/ ... /^=end\s+register\b/) {
	    next if /^=(begin|end)/;
	    if (/^MAGIC:\s+(.*)/) {
		push(@magic, $1);
		next;
	    }
	    push(@desc, $_);
	}
    }
    die "Missing magic for $format" unless @magic;
    for (@magic) {
	if (m:^/:) {
	    push(@code, qq(return "$format" if $_;));
	}
	else {
	    push(@code, qq(return "$format" if \$_ eq $_;));
	}
    }

    # trim
    shift(@desc) while @desc && $desc[0]  =~ /^\s*$/;
    pop(@desc)   while @desc && $desc[-1] =~ /^\s*$/;

    $desc .= "\n=item $format\n" unless @desc && $desc[0] =~ /^=item/;
    $desc .= "\n" . join("", @desc);

}
closedir(DIR);

my $code = "sub determine_file_format
{
   local(\$_) = \@_;
   " . join("\n   ", @code) . "
   return undef;
}
";

# Copy template to top level module with substitutions
open(TMPL, $tmpl) || die "Can't open $tmpl: $!";
open(INFO, ">$info_pm") || die "Can't create $info_pm: $!";

while (<TMPL>) {
    if (/^%%DETERMINE_FILE_FORMAT%%/) {
        $_ = $code;
    }
    elsif (/^%%FORMAT_DESC%%/) {
       $_ = $desc;
    }
    print INFO $_;
}
close(INFO);
close(TMPL);

