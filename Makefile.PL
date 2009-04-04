#!/usr/bin/perl -w

use strict;
use File::Spec;

#############################################################################

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Image-Info';

# Get most of the details from the primary module
all_from	'lib/Image/Info.pm';

requires	'IO::String'	=> 1.03 if $] < 5.008;

recommends	'Image::Xpm'	=> 1.0,
		'Image::Xbm'	=> 1.0,
		'XML::Simple'	=> 0;

build_requires  'Test::More'	=> 0.42;

license		'perl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index        directory       => 'img',
		directory	=> 'dev';
    
# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;

