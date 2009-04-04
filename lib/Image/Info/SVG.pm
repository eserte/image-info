package Image::Info::SVG;

$VERSION = '1.04';

use strict;
no strict 'refs';
use XML::Simple;

sub process_file {
    my($info, $source) = @_;
    my(@comments, @warnings, %info, $comment, $img, $imgdata, $xs);
    local($_);

    while(<$source>){
	if( ! exists($info{standalone}) && /standalone="(.+?)"/ ){
	    $info{standalone} = $1;
	}
	if( /<!--/ .. /-->/ ){
	    $comment .= $_;
	}
	if( /-->/ ){
	    $comment =~ s/<!--\s*//;
	    $comment =~ s/\s*-->//;
	    chomp($comment);
	    push @comments, $comment;
	    $comment = '';
	}
	$imgdata .= $_;
    }

    if( $imgdata !~ /<svg/ ){
	return $info->push_info(0, "error", "Not a valid SVG image");
    }

    local $SIG{__WARN__} = sub {
	push(@warnings, @_);
    };

    $xs = XML::Simple->new;
    $img = $xs->XMLin($imgdata);

#    use Data::Dumper; print Dumper($img);

    $info->push_info(0, "color_type" => "sRGB");
    $info->push_info(0, "file_ext" => "svg");
    # "image/svg+xml" is the official MIME type
    $info->push_info(0, "file_media_type" => "image/svg+xml");

    $info->push_info(0, "height", $img->{height});
    $info->push_info(0, "width", $img->{width});
    $info->push_info(0, "SVG_StandAlone", $info{standalone});
    $info->push_info(0, "SVG_Version", $img->{version} || 'unknown');

    # XXX Description, title etc. could be tucked away in a <g> :-(
    $info->push_info(0, "ImageDescription", $img->{desc}) if $img->{desc};
    $info->push_info(0, "SVG_Title", $img->{title}) if $img->{title};

#    $info->push_info(0, "SamplesPerPixel", -1);
#    $info->push_info(0, "resolution", "1/1");
#    $info->push_info(0, "BitsPerSample", 8);

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

Image::Info::SVG - SVG support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.svg");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $title = $info->{SVG_Title};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This modules supplies the standard key names except for
BitsPerSample, Compression, Gamma, Interlace, LastModificationTime, as well as:

=over

=item ImageDescription

The image description, corresponds to <desc>.

=item SVG_Image

A scalar or reference to an array of scalars containing the URI's of
embedded images (JPG or PNG) that are embedded in the image.

=item SVG_StandAlone

Whether or not the image is standalone.

=item SVG_Title

The image title, corresponds to <title>

=item SVG_Version

The URI of the DTD the image conforms to.

=back

=head1 METHODS

=head2 process_file()
    
	$info->process_file($source, $options);

Processes one file and sets the found info fields in the C<$info> object.

=head1 FILES

This module requires L<XML::Simple>.

=head1 SEE ALSO

L<Image::Info>, L<XML::Simple>, L<expat>

=head1 NOTES

For more information about SVG see:

 http://www.w3.org/Graphics/SVG/

Random notes:

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

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=begin register

MAGIC: /^<\?xml/

Provides a plethora of attributes and metadata of an SVG vector grafic.

=end register

=cut
