package Image::Info;

# Copyright 1999-2000, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Symbol ();

use vars qw($VERSION @EXPORT_OK);

$VERSION = '1.01';  # $Date: 2000/08/24 08:57:20 $

require Exporter;
*import = \&Exporter::import;

@EXPORT_OK = qw(image_info dim html_dim);

my @magic = (
   "\xFF\xD8" => "JPEG",
   "II*\0"    => "TIFF",
   "MM\0*"    => "TIFF",
   "\x89PNG\x0d\x0a\x1a\x0a" => "PNG",
   "GIF87a" => "GIF",
   "GIF89a" => "GIF",
   "P1"     => "PPM",
   "P2"     => "PPM",
   "P3"     => "PPM",
   "P4"     => "PPM",
   "P5"     => "PPM",
   "P6"     => "PPM",
);

sub image_info
{
    my $source = shift;

    if (@_) {
	return { error => "Extra arguments reserved for future extensions" };
    }

    if (!ref $source) {
        require Symbol;
        my $fh = Symbol::gensym();
        open($fh, $source) || return _os_err("Can't open $source");
        binmode($fh);
        $source = $fh;
    }
    elsif (ref($source) eq "SCALAR") {
	require IO::String;
	$source = IO::String->new($$source);
    }
    else {
	seek($source, 0, 0) or return _os_err("Can't rewind");
    }

    my $head;
    read($source, $head, 32) == 32 or return _os_err("Can't read head");
    if (ref($source) eq "IO::String") {
	# XXX workaround until we can trap seek() with a tied file handle
	$source->setpos(0);
    }
    else {
	seek($source, 0, 0) or _os_err("Can't rewind");
    }

    if (my $format = determine_file_format($head)) {
	no strict 'refs';
	my $mod = "Image::Info::$format";
	my $sub = "$mod\::process_file";
	my $info = bless [], "Image::Info::Result";
	eval {
	    unless (defined &$sub) {
		eval "require $mod";
		die $@ if $@;
		die "$mod did not define &$sub" unless defined &$sub;
	    }

	    &$sub($info, $source, @_);
	    $info->clean_up;
	};
	return { error => $@ } if $@;
	return wantarray ? @$info : $info->[0];
    }
    return { error => "Unrecognized file format" };
}

sub _os_err
{
    return { error => "$_[0]: $!",
	     Errno => $!+0,
	   };
}

sub determine_file_format
{
    my $head = shift;
    for (my $i = 0; $i < @magic; $i += 2) {
	my $m = $magic[$i];
	return $magic[$i+1] if substr($head, 0, length($m)) eq $m;
    }
    return;
}

sub dim
{
    my $img = shift || return;
    my $x = $img->{width} || return;
    my $y = $img->{height} || return;
    wantarray ? ($x, $y) : "${x}x$y";
}

sub html_dim
{
    my($x, $y) = dim($_);
    return unless $x;
    "WIDTH=$x HEIGHT=$y";
}

package Image::Info::Result;

sub push_info
{
    my($self, $n, $key) = splice(@_, 0, 3);
    push(@{$self->[$n]{$key}}, @_);
}

sub clean_up
{
    my $self = shift;
    for (@$self) {
	for my $k (keys %$_) {
	    my $a = $_->{$k};
	    $_->{$k} = $a->[0] if @$a <= 1;
	}
    }
}

sub get_info {
    my($self, $n, $key, $delete) = @_;
    my $v = $delete ? delete $self->[$n]{$key} : $self->[$n]{$key};
    $v ||= [];
    @$v;
}

1;

__END__

=head1 NAME

Image::Info - Extract meta information from image files

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.jpg");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This module provide functions to extract various kind of meta
information from image files.  The following functions are provided by
the C<Image::Info> module:

=over

=item image_info( $file )

=item image_info( \$imgdata )

This function takes the name of a file or a file handle as argument
and will return one or more hashes (actually hash references)
describing the images inside the file.  If there is only one image in
the file only one hash is returned.  In scalar context, only the hash
for the first image is returned.

In case of error, and hash containing the "error" key will be
returned.  The corresponding value will be an appropriate error
message.

If a reference to a scalar is passed as argument to this function,
then it is assumed that this scalar contains the raw image data
directly.

=item dim( $info_hash )

Takes an hash as returned from image_info() and returns the dimensions
($width, $height) of the image.  In scalar context returns the
dimensions as a string.

=item html_dim( $info_hash )

Returns the dimensions as a string suitable for embedding directly
into HTML <img>-tags. E.g.:

   print "<img src="..." @{[html_dim($info)]}>\n";

=back

=head1 Image descriptions

The image_info() function returns meta information about each image in
the form of a reference to a hash.  The hash keys used are in most
cases based on the TIFF element names.  All lower case keys are
mandatory for all file formats and will always be there unless an
error occured (in which case the "error" key will be present.)  Mixed
case keys will only be present when the corresponding information
element is available in the image.

The following key names are common for any image format:

=over

=item file_media_type

This is the MIME type that is appropriate for the given file format.
The corresponding value is a string like: "image/png" or "image/jpeg".

=item file_ext

The is the suggested file name extention for a file of the given file
format.  The value is a 3 letter, lowercase string like "png", "jpg".

=item width

This is the number of pixels horizontally in the image.

=item height

This is the number of pixels vertically in the image.  (TIFF use the
name ImageLength for this field.)

=item color_type

The value is a short string describing what kind of values the pixels
encode.  The value can be one of the following:

  Gray
  GrayA
  RGB
  RGBA
  CMYK
  YCbCr
  CIELab

These names can also be prefixed by "Indexed-" if the image is
composed of indexes into a palette.  Of these, only "Indexed-RGB" is
likely to occur.

(It is similar to the TIFF field PhotometricInterpretation, but this
name was found to be too long, so we used the PNG inpired term
instead.)

=item resolution

The value of this field normally gives the physical size of the image
on screen or paper. When the unit specifier is missing then this field
denotes the squareness of pixels in the image.

The syntax of this field is:

   <res> <unit>
   <xres> "/" <yres> <unit>
   <xres> "/" <yres>

The <res>, <xres> and <yres> fields are numbers.  The <unit> is a
string like C<dpi>, C<dpm> or C<dpcm> (denoting "dots per
inch/cm/meter).

=item SamplesPerPixel

This says how many channels there are in the image.  For some image
formats this number might be higher than the number implied from the
C<color_type>.

=item BitsPerSample

This says how many bits are used to encode each of samples.  The value
is a reference to an array containing numbers. The number of elements
in the array should be the same as C<SamplesPerPixel>.

=item Comment

Textual comments found in the file.  The value is a reference to an
array if there are multiple comments found.

=item Interlace

If the image is interlaced, then this tell which interlace method is
used.

=item Compression

This tell which compression algorithm is used.

=item Gamma

A number.

=item LastModificationTime

A ISO date string

=back

=head1 Supported Image Formats

The following image file formats are currently supported:

=over

=item JPEG

For JPEG files we extract information both from C<JFIF> and C<Exif>
application chunks.

C<Exif> is the file format written by most digital cameras.  This
encode things like timestamp, camera model, focal length, exposure
time, aperture, flash usage, GPS position, etc.  The following web
page contain description of the fields that can be present:

 http://www.butaman.ne.jp/~tsuruzoh/Computer/Digicams/exif-e.html


=item PNG

Information from IHDR, PLTE, gAMA, pHYs, tEXt, tIME chunks are
extracted.  The sequence of chunks are also given by the C<PNG_Chunks>
key.

=item GIF

Both GIF87a and GIF89a are supported and the version number is found
as C<GIF_Version> for the first image.  GIF files can contain multiple
images, and information for all images will be returned if
image_info() is called in list context.  The Netscape-2.0 extention to
loop animation sequences is represented by the C<GIF_Loop> key for the
first image.  The value is either "forever" or a number indicating
loop count.

=back

=head1 SEE ALSO

L<Image::Size>

=head1 AUTHOR

Copyright 1999-2000 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
