
#############################################################################

require 5.006002;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

if (defined $ENV{USER} && $ENV{USER} eq 'eserte') { # fill in the developer's user names here
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

# Get most of the details from the primary module
all_from	'lib/Image/Info.pm';

requires	'IO::String'		=> '1.03' if $] < 5.008;

recommends	'Image::Xpm'		=> 1.0,
		'Image::Xbm'		=> 1.0,
		'XML::LibXML::Reader'	=> 0;

test_requires  'Test::More'		=> '0.62';

license		'perl';

author		'Tels <nospam-abuse@bloodgate.com>',
		'Gisle Aas',
		'Slaven Rezic'; 

# Do not index these
no_index        directory       => 'img', 'dev';
    
# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
