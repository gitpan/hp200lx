#!/usr/local/bin/perl
# FILE %usr/unixonly/hp200lx/catgdb.pl
#
# print data records of a HP 200LX DB 
#
# written:       1998-01-11
# latest update: 1998-06-18 16:49:13
#

use HP200LX::DB;

# initializiation
$FS= ';';
$RS= "\n";
$show_fields= 1;

ARGUMENT: while (defined ($arg= shift (ARGV)))
{
  if ($arg =~ /^-/)
  {
    if ($arg eq '-')            { push (JOBS, $arg);    }
    elsif ($arg =~ /^-noh/)     { $show_fields= 0;      }
    else
    {
      &usage;
      exit (0);
    }
    next;
  }

  push (JOBS, $arg);
}

foreach $job (@JOBS)
{
  &print_gdb ($job);
}

# cleanup

exit (0);

# ----------------------------------------------------------------------------
sub usage
{
  print <<END_OF_USAGE
usage: $0 [-options] [filenanme]

Options:
-help           ... print help
END_OF_USAGE
}

# ----------------------------------------------------------------------------
sub print_gdb
{
  my $view= '';  # retrieve a view description
  my $fnm= shift;

  my (@data, $i);

  my $db= HP200LX::DB::openDB ($fnm);
  my $db_cnt= $db->get_last_index ();

  tie (@data, HP200LX::DB, $db);

  for ($i= 0; $i <= $db_cnt; $i++)
  {
    my $rec= $data[$i];
    my $fld;

    if ($show_fields && $i == 0)
    {
      foreach $fld (sort keys %$rec)
      {
        print $fld, $FS;
        $show_fields= 0;
      }
      print $RS;
    }

    foreach $fld (sort keys %$rec)
    {
      print $rec->{$fld}, $FS;
    }
    print $RS;
  }

}
