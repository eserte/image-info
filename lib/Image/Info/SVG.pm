package Image::Info::SVG;
use XML::Simple;

=begin register

MAGIC: /^<\?xml/

SVG also provides (for) a plethora of attributes and metadata of an image.
See L<Image::Info::SVG> for details.

=end register

=cut

$VERSION = '1.00';

sub process_file{
    my($info, $source) = @_;
    my(@comments, @warnings, %info, $comment, $img, $imgdata, $xs);

    while(<$source>){
	if( ! exists($info{standalone}) && /standalone="(.+?)"/ ){
	    $info{standalone} = $1;
	}
	if( ! exists($info{dtd}) && /<!DOCTYPE\s+svg\s+.+?\s+"(.+?)">/ ){
	    $info{dtd} = $1;
	}
	if( /<!--/ .. /-->/ ){
	    $comment .= $_;
	}
	if( /-->/ ){
	    $comment =~ s/<!--//;
	    $comment =~ s/-->//;
	    chomp($comment);
	    push @comments, $comment;
	    $comment = '';
	}
	$imgdata .= $_;
    }

    *XML::Simple::carp = sub { push @warnings, @_; };
    $xs = new XML::Simple();
    $img = $xs->XMLin($imgdata);

    use Data::Dumper;
    print Dumper($img);

    # XXX RGB? http://www.w3.org/TR/2000/CR-SVG-20000802/refs.html#ref-SRGB
    $info->push_info(0, "color_type" => "sRGB");
    $info->push_info(0, "file_ext" => "svg");
    # XXX not official type yet, may be image/svg+xml
    $info->push_info(0, "file_media_type" => "image/svg-xml");
    $info->push_info(0, "height", $img->{height});
    $info->push_info(0, "width", $img->{width});
    $info->push_info(0, "BitsPerSample", 8);
    # XXX Compression? for ZVG/SVZ?
    #$info->push_info(0, "SamplesPerPixel", -1);

    if( local $_ = $img->{desc} ){
	chomp $_;
	$info->push_info(0, "ImageDescription", $_); }
    if( $img->{image} ){
	if( ref($img->{image}) eq 'ARRAY' ){
	    foreach my $img (@{$img->{image}}){
		$info->push_info(0, "SVG_Image", $img->{'xlink:href'});
	    }
	}
	else{
	    $info->push_info(0, "SVG_Image", $img->{image}->{'xlink:href'});
	}
    }
    $info->push_info(0, "SVG_StandAlone", $info{standalone});
    if( local $_ = $img->{title} ){
	chomp $_;
	$info->push_info(0, "SVG_Title", $_); }
#    $info->push_info(0, "SVG_Title", $img->{title}) if $img->{title};
    $info->push_info(0, "SVG_Version", $info{dtd});

    for (@comments) {
	$info->push_info(0, "Comment", $_);
    }
    
    for (@warnings) {
	$info->push_info(0, "Warn", $_);
    }
}
1;
__END__
Colors
    # iterate over polygon,rect,circle,ellipse,line,polyline,text for style->stroke: style->fill:?
    #  and iterate over each of these within <g> too?! and recurse?!
    # append <color>'s
    # perhaps even deep recursion through <svg>'s?
ColorProfile <color-profile>
RenderingIntent ?
requiredFeatures
requiredExtensions
systemLanguage

=pod

=head1 NAME

Image::Info::SVG - SVG support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.svg");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

A functional yet thus far rudimentary SVG implementation.
SVG also provides (for) a plethora of attributes and metadata of an image.

This modules supplies the standard key names except for
SamplesPerPixel and resolution. It also supplies the
additional keys:

=over

=item ImageDescription

The image description, corresponds to <desc>.

=item SVG_Image

A scalar or reference to an array of scalars contaning the URI's of images
(JPG or PNG) that are embedded in the image.

=item SVG_StandAlone

Whether or not the image is standalone.

=item SVG_Title

The image title, corresponds to <title>

=item SVG_Version

The URI of the DTD the image conforms to.

=back

=item FILES

This module requires L<XML::Simple>

=head1 SEE ALSO

L<Image::Info>, L<XML::Simple>, L<expat>

=head1 NOTES

SVG is not yet a standard,
though much software exists which is capable of creating and displaying SVG images. 
For more information about SVG see:

 http://www.w3.org/Graphics/SVG/

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
