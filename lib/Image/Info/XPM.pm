package Image::Info::XPM;

=begin register

MAGIC: /^\/\* XPM \*\//

See L<Image::Info::XPM> for details.

=end register

=cut

use Image::Xpm;

$VERSION = '1.02';

sub process_file{
    my($info, $source) = @_;
    my(@comments, @warnings, $i);

    *Image::Xpm::carp = sub { push @warnings, @_; };
    if( $Image::Xpm::Version cmp '1.08' < 1){
	push @warnings, "This version of Image::Xpm does not support filehandles or scalar references";
	$source = $info->get_info(0, "FileName");
    }

    $i = Image::Xpm->new(-file, $source);
    $info->push_info(0, "color_type" => "Indexed-RGB");
    $info->push_info(0, "file_ext" => "xpm");
    $info->push_info(0, "file_media_type" => "image/x-xpixmap");
    $info->push_info(0, "height", $i->get(-height));
    $info->push_info(0, "width", $i->get(-width));
    $info->push_info(0, "BitsPerSample" => 8);
#    $info->push_info(0, "SamplesPerPixel", 1);

    $info->push_info(0, "CharactersPerPixel" => $i->get(-cpp) );
    # XXX is this always?
    $info->push_info(0, "ColorResolution", 8);
    $info->push_info(0, "ColorTableSize" => $i->get(-ncolours) );
    $info->push_info(0, "RGB_Palette" => [keys %{$i->get(-cindex)}] );
    $info->push_info(0, "HotSpotX" => $i->get(-hotx) );
    $info->push_info(0, "HotSpotY" => $i->get(-hoty) );
    $info->push_info(0, ucfirst($i->get(-extname)) => $i->get(-extlines)) if
	$i->get(-extname);
    push @comments, @{$i->get(-comments)};

    for (@comments) {
	$info->push_info(0, "Comment", $_);
    }
    
    for (@warnings) {
	$info->push_info(0, "Warn", $_);
    }
}
1;
__END__
=pod

=head1 NAME

Image::Info::XPM - XPM support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.xpm");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This modules supplies the standard key names except for
SamplesPerPixel and resolution. It also supplies the
additional keys:

=over

=item CharactersPerPixel

This is typically 1 or 2.

=item ColorResolution

Always 8

=item ColorTableSize

The number of colors the image uses.

=item RGB_Palette

Reference to an array of all colors used.

=item HotSpotX

The x-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=item HotSpotY

The y-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=back

=item FILES

This module requires L<Image::Xpm>

=head1 SEE ALSO

L<Image::Info>, L<Image::Xpm>

=head1 NOTES

For more information about XPM see:

 ftp://ftp.x.org/contrib/libraries/xpm-README.html

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
