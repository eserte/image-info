package Image::Info::ASCII;
$VERSION = '1.00';
use strict;

sub process_file{
    my($info, $source, $opts) = @_;
    my(@comments, @warnings, @hist, %chars, %info);
    local($_);
    %info = (cols=>0, rows=>0);

    while(<$source>){
	chomp();
	$info{rows}++;
	my $len = length();
	$info{cols} = $info{cols} < $len ? $len : $info{cols};
	%chars = (%chars, map { $_=>$chars{$_}+=1 } split(''));
    }

    $info->push_info(0, "color_type" => "Indexed-Grey");
    $info->push_info(0, "file_ext" => "txt");
    $info->push_info(0, "file_media_type" => "text/plain;charset=US-ASCII");
    $info->push_info(0, "height", $info{rows});
    $info->push_info(0, "resolution", "1/1");
    $info->push_info(0, "width", $info{cols});
    $info->push_info(0, "BitsPerSample" => 7);
    $info->push_info(0, "SamplesPerPixel", 1);

    $info->push_info(0, "ColorTableSize", scalar keys %chars);
    if( $opts->{ColorPalette} ){
	$info->push_info(0, "ColorPalette", [keys %chars]);
    }
    if( $opts->{L1D_Histogram} ){
	#Do Histogram
	foreach my $char ( keys %chars ){
	    $hist[ord($char)]=$chars{$char};
	}
	$info->push_info(0, "L1D_Histogram", [@hist]);
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

Image::Info::ASCII - ASCII support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.txt");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This modules supplies the standard key names
except for Compression, Gamma, Interlace, LastModificationTime, as well as:

=over

=item ColorPalette

Reference to an array of all colors used.
This key is only present if C<image_info> is invoked
as C<image_info({ColorPalette=E<gt>1})>.

=item ColorTableSize

The number of colors the image uses.

=item L1D_Histogram

Reference to an array representing a one dimensioanl luminance
histogram. This key is only present if C<image_info> is invoked
as C<image_info($file, L1D_Histogram=E<gt>1)>. The range is from 0 to 127,
however auto-vivification is used so a null field is also 0,
and the array may not actually contain 127 fields. The index in
the array corresponds to the C<ord> of the character and thusly
fields 0-8,11,12,14-31 should always be blank.

While not immediately obvious, this could be used to accquire
information about a normal text file and it's language.
Though it would likely have to be English, Hawaiian, Swahili,
or Latin (unless you can be assured that no 8th bit characters
occur in the first 32 bytes of the source).

=back

=head1 SEE ALSO

L<Image::Info>, L<ascii>, F<http://czyborra.com/charsets/iso646.html>

=head1 NOTES

For more information about ASCII art see:

 news:alt.ascii-art

=head1 BUGS

Other than being completely functional yet potentially useless?

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

=begin register

MAGIC: /^[\011\012\015\040-\176]*$/ && $_ !~ m%(^<\?xml)|(^#define\s+)|(^/\* XPM \*/)|(static\s+char\s+\*\w+\[\]\s*=\s*{\s*"\d+)%

For more information see L<Image::Info::ASCII>.

=end register

=cut
