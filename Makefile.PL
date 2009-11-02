#!/usr/bin/env perl
# -*- cperl -*-
#############################################################################

require 5.006;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

my $is_author_env = defined $ENV{USER} && $ENV{USER} =~ m{^(eserte|slavenr)}; # fill in the developer's user names here
if ($is_author_env) {
    require File::Compare;
    require File::Temp;
    my($tmpfh,$tmpfile) = File::Temp::tempfile(SUFFIX => '.pm', UNLINK => 1);
    system("./dev/build.pl", "-o", $tmpfile);
    if (File::Compare::compare($tmpfile, 'lib/Image/Info.pm') != 0) {
        warn <<EOF;
**********************************************************************
*** WARNING
***
*** Changes in dev/Info.pm.tmpl detected, please run dev/build.pl!
***
**********************************************************************

EOF
    }
}

perl_version	'5.006';

requires	'IO::String'		=> '1.03' if $] < 5.008;

recommends	'Compress::Zlib'	=> 0,
		'Image::Xpm'		=> 1.0,
		'Image::Xbm'		=> 1.0,
		'XML::LibXML::Reader'	=> 0,
		'XML::Simple'		=> 0;

test_requires	'Test::More'		=> '0.62';

license		'perl';

author		'Slaven Rezic <srezic@cpan.org>',
		'Gisle Aas',
		'Tels'; 

# Get most of the details from the primary module
all_from	'lib/Image/Info.pm';

# Do not index these
no_index        directory       => 'img', 'dev';

# Auto-install all dependencies from CPAN
auto_install;

repository	'git://github.com/eserte/image-info.git';

if ($is_author_env) {
    Makefile->postamble(<<EOF);
predist:
	./dev/build.pl
	rm -rf inc
	\$(PERL) Makefile.PL
	\$(MAKE) distcheck
	\$(MAKE) disttest
	\$(MAKE) distclean
	\$(PERL) Makefile.PL
	\$(MAKE) signature
	git status
	\$(NOECHO) \$(ECHO) "*** Consider also calling cpan_check_versions and"
	\$(NOECHO) \$(ECHO) "*** cpan_check_unauthorized (on an older version)"

postdist:
	\$(NOECHO) \$(ECHO) "*** Run the following commands:"
	\$(NOECHO) \$(ECHO) cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	\$(NOECHO) \$(ECHO) git tag \$(VERSION)
	\$(NOECHO) \$(ECHO) git push
	\$(NOECHO) \$(ECHO) git push --tags

EOF
}

# Generate the Makefile
WriteAll;
