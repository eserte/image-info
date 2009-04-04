package Image::Info::TIFF;

use strict;
use Config;
use Carp qw(confess);
use Image::TIFF;

my @types = (
  [ "ERROR INVALID TYPE",     "?", 0],
  [ "BYTE",      "C", 1],
  [ "ASCII",     "A", 1],
  [ "SHORT",     "S", 2],
  [ "LONG",      "L", 4],
  [ "RATIONAL",  "N2", 8],
  [ "SBYTE",     "c", 1],
  [ "UNDEFINED", "a", 1],
  [ "SSHORT",    "s", 2],
  [ "SLONG",     "l", 4],
  [ "SRATIONAL", "N2", 8],
  [ "FLOAT",     "f", 4],  
  [ "DOUBLE",    "d", 8],  
);


sub _read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}
sub _readbytes
{
    my ($fh,$offset,$len) = @_;
    my $curoffset = tell($fh);
    my $buf;
    seek($fh,$offset,0);
    my $n = read($fh,$buf,$len);
    confess("short read($n/$len)") unless $n == $len;
    # back to before.
    seek($fh,$curoffset,0);
    return $buf;
}

sub _readrational
{
    my ($fh,$offset,$byteorder,$count,$ar,$signed) = @_;
    my $curoffset = tell($fh);
    my $buf;
    seek($fh,$offset,0);
    while ($count > 0) {
	my $num;
	my $denom;
	if ($signed) {
	    $num = unpack("l",_read_order($fh,4,$byteorder));
	    $denom = unpack("l",_read_order($fh,4,$byteorder));
	} else {
	    $num = unpack("L",_read_order($fh,4,$byteorder));
	    $denom = unpack("L",_read_order($fh,4,$byteorder));
	}
	push(@{$ar},new Image::TIFF::Rational($num,$denom));
	$count--;
    }
    # back to before.
    seek($fh,$curoffset,0);
}

sub _read_order
{
    my($source, $len,$byteorder) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    # maybe reverse
    if ($byteorder ne $Config{byteorder}) {
	my @bytes = unpack("C$len",$buf);
	my @newbytes;
	# swap bytes
	for (my $i = $len-1; $i >= 0; $i--) {
	    push(@newbytes,$bytes[$i]);
	}
	$buf = pack("C$len",@newbytes);
    }
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}

my %order = (
	     "MM\x00\x2a" => '4321',
	     "II\x2a\x00" => '1234',
	     );

sub process_file
{
    my($info, $fh) = @_;

    my $soi = _read($fh, 4);
    die "SOI missing" unless (defined($order{$soi}));
    # XXX: should put this info in all pages?
    $info->push_info(0, "file_media_type" => "image/tiff");
    $info->push_info(0, "file_ext" => "tif");

    my $byteorder = $order{$soi};
    # print "TIFF byte order $byteorder, our byte order: $Config{byteorder}\n";
    my $ifdoff = unpack("L",_read_order($fh,4,$byteorder));
    my $page = 0;
    do {
      # print "TIFF Directory at $ifdoff\n";
      $ifdoff = _process_ifds($info,$fh,$page,0,$byteorder,$ifdoff);
      $page++;
    } while ($ifdoff);
}

sub _process_ifds {
    my($info, $fh, $page, $tagsseen, $byteorder, $ifdoffset) = @_;
    my $curpos = tell($fh);
    seek($fh,$ifdoffset,0);

    my $n = unpack("S",_read_order($fh, 2, $byteorder)); ## Number of entries
    my $i = 1;
    while ($n > 0) {
	# process one IFD entry
	my $tag = unpack("S",_read_order($fh,2,$byteorder));
	my $fieldtype = unpack("S",_read_order($fh,2,$byteorder));
	unless ($types[$fieldtype]) {
	  warn "Unrecognised fieldtype $fieldtype, skipping\n";
	  next;
	}
        my ($typename, $typepack, $typelen) = @{$types[$fieldtype]};
	my $count = unpack("L",_read_order($fh,4,$byteorder));
        my $value_offset_orig = _read_order($fh,4,$byteorder);
	my $value_offset = unpack("L", $value_offset_orig);
	my $val;
        ## The 4 bytes of $value_offset may actually contains the value itself,
        ## if it fits into 4 bytes.
        if ($typelen * $count <= 4) {
          @$val = unpack($typepack x $count, $value_offset_orig);
	} elsif ($fieldtype == 5 || $fieldtype == 10) { 
	  ## Rationals
	  my $num;
	  my $denom;
	  $val = [];
	  if ($fieldtype == 5) {
            ## Unsigned
	    _readrational($fh,$value_offset,$byteorder,$count,$val,0);
	  } else {
	    ## Signed 
	    _readrational($fh,$value_offset,$byteorder,$count,$val,1);
	  }
        } else {
          ## Just read $count thingies from the offset
	  @$val = unpack($typepack x $count, _readbytes($fh, $value_offset, $typelen * $count));
	}
	#look up tag
	my $tn =  Image::TIFF->exif_tagname($tag);
        foreach my $v (@$val) {
	  if (ref($tn)) {
	    $v = $$tn{$v};
	    $tn = $$tn{__TAG__};
	  }
        }
	if ($tn eq "NewSubfileType") {
	    # start new page if necessary
	    if ($tagsseen) {
		$page++;
		$tagsseen = 0;
	    }
	} else {
	    $tagsseen = 1;
	}
        my $vval;
        ## If only one value, use direct
        if (@$val <= 1) {
          $val = $val->[0] || '';
          $vval = $val;
        } else {
          $vval = '(' . join(',',@$val) . ')';
        }
	# print "$page/$i:$value_offset:$tag ($tn), fieldtype: $fieldtype, count: $count = $vval\n";
	if ($tn eq "ExifOffset") {
	    # parse ExifSubIFD
            # print "ExifSubIFD at $value_offset\n";
	    process_ifds($info,$fh,$page,$tagsseen,$byteorder,$value_offset);
	}
	$info->push_info($page, $tn => $val);
	$n--;
	$i++;
    }
    my $ifdoff = unpack("L",_read_order($fh,4,$byteorder));
    #print "next dir at $ifdoff\n";
    seek($fh,$curpos,0);
    return $ifdoff if $ifdoff;
    0;
}
1;

__END__

=pod

=head1 NAME

Image::Info::TIFF - TIFF support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.tif");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 print $info->{BitPerSample};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This module adds TIFF support for Image::Info.


=head1 METHODS

=head2 process_file()

        $info->process_file($source, $options);

Processes one file and sets the found info fields in the C<$info> object.

=head1 SEE ALSO

L<Image::Info>

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

Patches and fixes by Ben Wheeler.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=begin register

MAGIC: /^MM\x00\x2a/
MAGIC: /^II\x2a\x00/

The C<TIFF> spec can be found at (requires a login):
L<http://partners.adobe.com/asn/developer/PDFS/TN/TIFF6.pdf>

The EXIF spec can be found at:
L<http://www.exif.org/>

=end register

=cut
