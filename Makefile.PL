require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Image::Info',
    VERSION_FROM => 'lib/Image/Info.pm',
    PREREQ_PM    => {
                      'IO::String' => 1,
                    },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
