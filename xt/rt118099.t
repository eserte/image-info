#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use IPC::Run 'run';
use List::Util 'sum';
use Test::More;

plan skip_all => "Works only on linux (using strace)" if $^O ne 'linux';
plan skip_all => "Needs strace" if !is_in_path('strace');

my %impl2opts =
    (
     'Image::Info::SVG::XMLSimple' =>
     [
      {XML_SAX_Parser => 'XML::Parser'},
      {XML_SAX_Parser => 'XML::SAX::Expat'},
      {XML_SAX_Parser => 'XML::SAX::ExpatXS'},
      {XML_SAX_Parser => 'XML::SAX::PurePerl'},
      {XML_SAX_Parser => 'XML::LibXML::SAX::Parser'},
      {XML_SAX_Parser => 'XML::LibXML::SAX'},
     ],
     'Image::Info::SVG::XMLLibXMLReader' => [{}],
    );

plan tests => 2 * sum map { scalar @$_ } values(%impl2opts);

for my $impl (keys %impl2opts) {
    my $testname = $impl;
    my @opts = @{ $impl2opts{$impl} };
    for my $opt (@opts) {
	my $testname = $testname . (%$opt ? ", " . join(", ", map { "$_ => $opt->{$_}" } keys %$opt) : '');
	my @cmd =
	    (
	     $^X, "-I$FindBin::RealBin/../lib", '-MImage::Info=image_info', '-e',
	     ($opt->{XML_SAX_Parser} ? 'require XML::Simple; $XML::Simple::PREFERRED_PARSER = shift; ' : '') .
	     '@Image::Info::SVG::PREFER_MODULE=shift; my $info = image_info(shift); die $info->{error} if $info->{error};',
	     ($opt->{XML_SAX_Parser} ? $opt->{XML_SAX_Parser} : ()),
	     $impl, "$FindBin::RealBin/../img/xxe.svg",
	    );
	{
	    my $stderr;
	    ok run(\@cmd, '2>', \$stderr), "Run @cmd"
		or diag $stderr;
	}
	{
	    my $success = run(["strace", "-eopen,stat", @cmd], '2>', \my $strace);
	    if (!$success) {
		if (($opt->{XML_SAX_Parser}||'') eq 'XML::SAX::ExpatXS') {
		    # ignore error
		} else {
		    die "Error running @cmd with strace";
		}
	    }
	    my @matching_lines = $strace =~ m{.*/etc/passwd.*}g;
	    is scalar(@matching_lines), 0, "No XXE with $testname"
		or diag explain \@matching_lines;
	}
    }
}

done_testing;

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/src/srezic-repository 
# REPO MD5 4be1e368fea0fa9af4e89256a9878820
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
