BEGIN {
    require '../../t/test.pl';
    require '../../t/loc_tools.pl'; # to find locales
}

use XS::APItest;
use Config;

skip_all("locales not available") unless locales_enabled('LC_NUMERIC');

my @locales = eval { find_locales( &LC_NUMERIC ) };
skip_all("no LC_NUMERIC locales available") unless @locales;

my $non_dot_locale;
for (@locales) {
    use locale;
    setlocale(LC_NUMERIC, $_) or next;
    my $in = 4.2; # avoid any constant folding bugs
    if (sprintf("%g", $in) ne "4.2") {
        $non_dot_locale = $_;
        last;
    }
}


SKIP: {
      if ($Config{usequadmath}) {
            skip "no gconvert with usequadmath", 2;
      }
      is(test_Gconvert(4.179, 2), "4.2", "Gconvert doesn't recognize underlying locale outside 'use locale'");
      use locale;
      is(test_Gconvert(4.179, 2), "4.2", "Gconvert doesn't recognize underlying locale inside 'use locale'");
}

my %correct_C_responses = (
        # Commented out entries are ones which there is room for variation
                            ABDAY_1 => 'Sun',
                            ABDAY_2 => 'Mon',
                            ABDAY_3 => 'Tue',
                            ABDAY_4 => 'Wed',
                            ABDAY_5 => 'Thu',
                            ABDAY_6 => 'Fri',
                            ABDAY_7 => 'Sat',
                            ABMON_1 => 'Jan',
                            ABMON_10 => 'Oct',
                            ABMON_11 => 'Nov',
                            ABMON_12 => 'Dec',
                            ABMON_2 => 'Feb',
                            ABMON_3 => 'Mar',
                            ABMON_4 => 'Apr',
                            ABMON_5 => 'May',
                            ABMON_6 => 'Jun',
                            ABMON_7 => 'Jul',
                            ABMON_8 => 'Aug',
                            ABMON_9 => 'Sep',
                            ALT_DIGITS => '',
                            AM_STR => 'AM',
                            #CODESET => 'ANSI_X3.4-1968',
                            #CRNCYSTR => '-',
                            DAY_1 => 'Sunday',
                            DAY_2 => 'Monday',
                            DAY_3 => 'Tuesday',
                            DAY_4 => 'Wednesday',
                            DAY_5 => 'Thursday',
                            DAY_6 => 'Friday',
                            DAY_7 => 'Saturday',
                            #D_FMT => '%m/%d/%y',
                            #D_T_FMT => '%a %b %e %H:%M:%S %Y',
                            ERA => '',
                            #ERA_D_FMT => '',
                            #ERA_D_T_FMT => '',
                            #ERA_T_FMT => '',
                            MON_1 => 'January',
                            MON_10 => 'October',
                            MON_11 => 'November',
                            MON_12 => 'December',
                            MON_2 => 'February',
                            MON_3 => 'March',
                            MON_4 => 'April',
                            MON_5 => 'May',
                            MON_6 => 'June',
                            MON_7 => 'July',
                            MON_8 => 'August',
                            MON_9 => 'September',
                            #NOEXPR => '^[nN]',
                            PM_STR => 'PM',
                            RADIXCHAR => '.',
                            THOUSEP => '',
                            #T_FMT => '%H:%M:%S',
                            #T_FMT_AMPM => '%I:%M:%S %p',
                            #YESEXPR => '^[yY]',
                        );

my $hdr = "../../perl_langinfo.h";
open my $fh, "<", $hdr;
$|=1;

SKIP: {
    skip "No LC_ALL", 1 unless find_locales( &LC_ALL );

    use POSIX;
    setlocale(LC_ALL, "C");
    eval "use I18N::Langinfo qw(langinfo RADIXCHAR); langinfo(RADIXCHAR)";
    my $has_nl_langinfo = $@ eq "";

    skip "Can't open $hdr for reading: $!", 1 unless $fh;

    my %items;

    # Find all the current items from the header, and their values.
    # For non-nl_langinfo systems, those values are arbitrary negative numbers
    # set in the header.  Otherwise they are the nl_langinfo approved values,
    # which for the moment is the item name.
    while (<$fh>) {
        chomp;
        next unless / - \d+ $ /x;
        s/ ^ .* PERL_//x;
        m/ (.*) \  (.*) /x;
        $items{$1} = ($has_nl_langinfo)
                     ? $1
                     : $2;
    }

    # Get the translation from item name to numeric value.
    I18N::Langinfo->import(keys %items) if $has_nl_langinfo;

    foreach my $formal_item (sort keys %items) {
        if (exists $correct_C_responses{$formal_item}) {
            my $item = eval $items{$formal_item};
            next if $@;
            is (test_Perl_langinfo($item),
                $correct_C_responses{$formal_item},
                "Returns expected value for $formal_item");
        }
    }
}

done_testing();
