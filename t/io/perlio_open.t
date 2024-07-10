#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    skip_all_without_perlio();
    skip_all_without_dynamic_extension('Fcntl'); # how did you get this far?
}

use strict;
use warnings;

plan tests => 31;

use Fcntl qw(:seek);

{
    ok((open my $fh, "+>", undef), "open my \$fh, '+>', undef");
    print $fh "the right write stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right write stuff", "found the right stuff");
}

{
    ok((open my $fh, "+<", undef), "open my \$fh, '+<', undef");
    print $fh "the right read stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right read stuff", "found the right stuff");
}

SKIP:
{
    ok((open my $fh, "+>>", undef), "open my \$fh, '+>>', undef")
      or skip "can't open temp for append: $!", 3;
    print $fh "abc";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    print $fh "xyz";
    ok(seek($fh, 0, SEEK_SET), "seek to zero again");
    my $data = <$fh>;
    is($data, "abcxyz", "check the second write appended");
}

# GH 22385
{
    my $var;
    my @warned = capture_warnings sub {
        ok !open(my $fh, "+>", $var), 'open my $fh, "+>", $var';
    };
    is @warned, 1, "warned once";
    like $warned[0], qr/^Use of uninitialized value \$var in open /;
}
{
    my @var = undef;
    my @warned = capture_warnings sub {
        ok !open(my $fh, "+>", $var[0]), 'open my $fh, "+>", $var[0]';
    };
    is @warned, 1, "warned once";
    like $warned[0], qr/^Use of uninitialized value \$var\[0\] in open /;
}
{
    my %var = (a => undef);
    my @warned = capture_warnings sub {
        ok !open(my $fh, "+>", $var{a}), 'open my $fh, "+>", $var{a}';
    };
    is @warned, 1, "warned once";
    like $warned[0], qr/^Use of uninitialized value \$var\{"a"\} in open /;
}

TODO: {
    local our $TODO = 'GH 22385';
    {
        my @var;
        my @warned = capture_warnings sub {
            ok !open(my $fh, "+>", $var[0]), 'open my $fh, "+>", $var[0]';
        };
        is @warned, 1, "warned once";
        like $warned[0], qr/^Use of uninitialized value \$var\[0\] in open /;

        @warned = capture_warnings sub {
            ok !&CORE::open(my $fh, "+>", $var[0]), 'open my $fh, "+>", $var[0]';
        };
        is @warned, 1, "warned once";
        like $warned[0], qr/^Use of uninitialized value in open /;
    }
    {
        my %var;
        my @warned = capture_warnings sub {
            ok !open(my $fh, "+>", $var{a}), 'open my $fh, "+>", $var{a}';
        };
        is @warned, 1, "warned once";
        like $warned[0], qr/^Use of uninitialized value \$var\{"a"\} in open /;

        @warned = capture_warnings sub {
            ok !CORE::open(my $fh, "+>", $var{a}), 'open my $fh, "+>", $var{a}';
        };
        is @warned, 1, "warned once";
        like $warned[0], qr/^Use of uninitialized value in open /;
    }
}
