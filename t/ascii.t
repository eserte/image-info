print "1..2\n";

use Image::Info qw(image_info dim);

my $i = image_info("test.txt") || die;

use Data::Dumper; print Dumper($i), "\n";

print "not " unless $i->{color_type} eq "Indexed-Grey" &&
                    $i->{ColorTableSize} == 46;
print "ok 1\n";

print "not " unless dim($i) eq "75x36";
print "ok 2\n";
