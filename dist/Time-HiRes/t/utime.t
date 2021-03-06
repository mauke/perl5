use strict;

sub has_subsecond_file_times {
  require File::Temp;
  require Time::HiRes;
  my ($fh, $filename) = File::Temp::tempfile( "Time-HiRes-utime-XXXXXXXXX" );
  use File::Basename qw[dirname];
  my $dirname =  dirname($filename);
  require Cwd;
  $dirname = &Cwd::getcwd if $dirname eq '.';
  print("\n# Testing for subsecond file timestamps (mtime) in $dirname\n");
  close $fh;
  my @mtimes;
  for (1..2) {
    open $fh, '>', $filename;
    print $fh "foo";
    close $fh;
    push @mtimes, (Time::HiRes::stat($filename))[9];
    Time::HiRes::sleep(.1) if $_ == 1;
  }
  my $delta = $mtimes[1] - $mtimes[0];
  # print STDERR "mtimes = @mtimes, delta = $delta\n";
  unlink $filename;
  my $ok = $delta > 0 && $delta < 1;
  printf("# Subsecond file timestamps in $dirname: %s\n",
         $ok ? "OK" : "NO");
  return $ok;
}

BEGIN {
    require Time::HiRes;
    require Test::More;
    require File::Temp;
    unless(&Time::HiRes::d_hires_utime) {
	Test::More::plan(skip_all => "no hires_utime");
    }
    unless(&Time::HiRes::d_hires_stat) {
        # Being able to read subsecond timestamps is a reasonable
	# prerequisite for being able to write them.
	Test::More::plan(skip_all => "no hires_stat");
    }
    unless (&Time::HiRes::d_futimens) {
	Test::More::plan(skip_all => "no futimens()");
    }
    unless (&Time::HiRes::d_utimensat) {
	Test::More::plan(skip_all => "no utimensat()");
    }
    unless (has_subsecond_file_times()) {
	Test::More::plan(skip_all => "No subsecond file timestamps");
    }
}

use Test::More tests => 18;
BEGIN { push @INC, '.' }
use t::Watchdog;
use File::Temp qw( tempfile );

use Config;

# Hope initially for nanosecond accuracy.
my $atime = 1.111111111;
my $mtime = 2.222222222;

if ($^O eq 'cygwin') {
   # Cygwin timestamps have less precision.
   $atime = 1.1111111;
   $mtime = 2.2222222;
}
print "# \$^O = $^O, atime = $atime, mtime = $mtime\n";

print "# utime \$fh\n";
{
	my ($fh, $filename) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $fh), 1, "One file changed";
	my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename) )[8, 9];
	is $got_atime, $atime, "atime set correctly";
	is $got_mtime, $mtime, "mtime set correctly";
};

print "#utime \$filename\n";
{
	my ($fh, $filename) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $filename), 1, "One file changed";
	my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh) )[8, 9];
	is $got_atime, $atime, "atime set correctly";
	is $got_mtime, $mtime, "mtime set correctly";
};

print "utime \$filename and \$fh\n";
{
	my ($fh1, $filename1) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	my ($fh2, $filename2) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $filename1, $fh2), 2, "Two files changed";
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh1) )[8, 9];
		is $got_atime, $atime, "File 1 atime set correctly";
		is $got_mtime, $mtime, "File 1 mtime set correctly";
	}
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename2) )[8, 9];
		is $got_atime, $atime, "File 2 atime set correctly";
		is $got_mtime, $mtime, "File 2 mtime set correctly";
	}
};

print "# utime undef sets time to now\n";
{
	my ($fh1, $filename1) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	my ($fh2, $filename2) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );

	my $now = Time::HiRes::time;
        sleep(1);
	is Time::HiRes::utime(undef, undef, $filename1, $fh2), 2, "Two files changed";

	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh1) )[8, 9];
		cmp_ok $got_atime, '>=', $now, "File 1 atime set correctly";
		cmp_ok $got_mtime, '>=', $now, "File 1 mtime set correctly";
	}
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename2) )[8, 9];
		cmp_ok $got_atime, '>=', $now, "File 2 atime set correctly";
		cmp_ok $got_mtime, '>=', $now, "File 2 mtime set correctly";
	}
};

print "# negative atime dies\n";
{
	eval { Time::HiRes::utime(-4, $mtime) };
	like $@, qr/::utime\(-4, 2\.22222\): negative time not invented yet/,
		"negative time error";
};

print "# negative mtime dies;\n";
{
	eval { Time::HiRes::utime($atime, -4) };
	like $@, qr/::utime\(1.11111, -4\): negative time not invented yet/,
		"negative time error";
};

done_testing;

1;
