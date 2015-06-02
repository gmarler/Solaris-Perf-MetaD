use strict;
use warnings;

use Test::Most;

use_ok( 'Solaris::Perf::MetaD' );

my $metad = Solaris::Perf::MetaD->new();

isa_ok( $metad, 'Solaris::Perf::MetaD' );

done_testing();

