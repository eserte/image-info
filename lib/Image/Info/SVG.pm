# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2009 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Image::Info::SVG;

use strict;
use vars qw($VERSION @PREFER_MODULE $USING_MODULE);
$VERSION = '2.00';

@PREFER_MODULE = qw(Image::Info::SVG::XMLLibXMLReader
		    Image::Info::SVG::XMLSimple
		  )
    if !@PREFER_MODULE;

TRY_MODULE: {
    for my $try_module (@PREFER_MODULE) {
	if (eval qq{ require $try_module; 1 }) {
	    my $sub = $try_module . '::process_file';
	    no strict 'refs';
	    *process_file = \&{$sub};
	    $USING_MODULE = $try_module;
	    last TRY_MODULE;
	}
    }
    die "Cannot require any of @PREFER_MODULE...\n";
}

1;

__END__
