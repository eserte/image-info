package Image::Info::XBM;

=begin register

MAGIC: /^#define\s+/

See L<Image::Info::XBM> for details.

=end register

=cut

use Image::Xbm;
$VERSION = '1.02';

sub process_file{
    my($info, $source) = @_;
    my(@comments, @warnings, $i);

    *Image::Xbm::carp = sub { push @warnings, @_; };
    if( $Image::Xbm::Version cmp '1.07' < 1){
	push @warnings, "This version of Image::Xbm does not support filehandles or scalar references";
	$source = $info->get_info(0, "FileName");
    }

    $i = Image::Xbm->new(-file, $source);
    $info->push_info(0, "color_type" => "Grey");
    $info->push_info(0, "file_ext" => "xbm");
    $info->push_info(0, "file_media_type" => "image/x-xbitmap");
    $info->push_info(0, "height", $i->get(-height));
    $info->push_info(0, "width", $i->get(-width));
    $info->push_info(0, "BitsPerSample" => 1);
#    $info->push_info(0, "SamplesPerPixel", 1);

#    $info->push_info(0, "ColorResolution", 1);
#    $info->push_info(0, "ColorTableSize" => 2 );
    $info->push_info(0, "HotSpotX" => $i->get(-hotx) );
    $info->push_info(0, "HotSpotY" => $i->get(-hoty) );

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

Image::Info::XBM - XBM support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.xbm");
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

=item HotSpotX

The x-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=item HotSpotY

The y-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=back

=item FILES

This module requires L<Image::Xbm>

=head1 SEE ALSO

L<Image::Info>, L<Image::Xbm>

=head1 NOTES

For more information about XBM see:

 http://www.dcs.ed.ac.uk/home/mxr/gfx/2d/XBM.txt

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
