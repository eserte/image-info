
#############################################################################

require 5.006002;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Get most of the details from the primary module
all_from	'lib/Image/Info.pm';

requires	'IO::String'	=> '1.03' if $] < 5.008;

recommends	'Image::Xpm'	=> 1.0,
		'Image::Xbm'	=> 1.0,
		'XML::Simple'	=> 0;

test_requires  'Test::More'	=> '0.62';

license		'perl';

author		'Tels <nospam-abuse@bloodgate.com>',
		'Gisle Aas'; 

# Do not index these
no_index        directory       => 'img', 'dev';
    
# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
