#!/usr/bin/perl -w

# test 'fallback' for overload cos/sin/atan2

use Test;
use strict;

BEGIN
  {
  $| = 1;
  # to locate the testing files
  my $location = $0; $location =~ s/fallback.t//i;
  if ($ENV{PERL_CORE})
    {
    # testing with the core distribution
    @INC = qw(../t/lib);
    }
  unshift @INC, qw(../lib);     # to locate the modules
  if (-d 't')
    {
    chdir 't';
    require File::Spec;
    unshift @INC, File::Spec->catdir(File::Spec->updir, $location);
    }
  else
    {
    unshift @INC, $location;
    }
  print "# INC = @INC\n";

  plan tests => 7;
  }

# The tests below test that cos(BigInt) = cos(Scalar) which is DWIM, but not
# exactly right, ideally cos(BigInt) should truncate to int() and cos(BigFloat)
# should calculate the result to X digits accuracy. For now, this is better
# than die()ing...

use Math::BigInt;
use Math::BigFloat;

my $bi = Math::BigInt->new(1);

ok (cos($bi), int(cos(1)));
ok (sin($bi), int(sin(1)));
ok (atan2($bi,$bi), atan2(1,1));

my $bf = Math::BigInt->new(0);

ok (cos($bf), int(cos(0)));
ok (sin($bf), int(sin(0)));
ok (atan2($bi,$bf), atan2(1,0));
ok (atan2($bf,$bi), atan2(0,1));

