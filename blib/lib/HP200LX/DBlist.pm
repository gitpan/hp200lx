#!/usr/local/bin/perl
# FILE %gg/perl/HP200LX/DBlist.pm
#
# list view component of the HP-200LX/DB GUI
#
# written:       1998-03-08
# latest update: 1998-03-23 16:58:27
#

package HP200LX::DBlist;
use Exporter;
@ISA= qw(Exporter);

use Tk;
use strict;

# ----------------------------------------------------------------------------
sub new
{
  my $class= shift;
  my $DBgui= shift;
  my $view= shift;      # NUMBER!!! (not the name) of the view
  my $title= shift;
  my %pars= @_;

  print ">>> list pars=", join (':', %pars), "\n";
  my $height= 15;       # || shift?

  my $db= $DBgui->{db};
  my $vptd= $db->find_viewptdef ($view)
            || $db->find_viewptdef ($view= 0)
            || return;
  my $vptt= $db->find_viewpttable ($view);

  my $fd= $db->{fielddef};      # description abuot data types
  my ($i, $j, $col, %fields, $top);

  # &HP200LX::DB::show_viewptdef ($vptd, *STDOUT);
  my $cols= $vptd->{cols};

  unless (defined ($top= $pars{top}))
  {
    $top= MainWindow->new ();
    $top->title ("$title [$view]");
  }

  my $sbf= $top->Frame ();
  $sbf->Label()->pack (side => 'top'); # place holder
  my $sb= $sbf->Scrollbar (orient => 'vertical', width => 10)
          ->pack (side => 'bottom', fill => 'y', expand => 1);

  # 1. produce the main widget as a horizontal composition of
  #    frames consisting of
  #    + a Label used as heading and
  #    + a Listbox used to show the data
  # 2. map column names and Listbox items where data can be filled in later
  my @name= (); # column number to name mapping
  my @lb= ();   # column number to list box mapping
  my ($name, $lb);
  foreach $col (@$cols)
  {
    my $num= $col->{num};
    my $vc= $top->Frame ();
    my $fe= $fd->[$num];
    $name= $fe->{name};

    $vc->Label (text => $name, relief => 'ridge')
         ->pack (side => 'top', fill => 'x');
    $lb= $vc->Listbox (width => $col->{width}, height => $height,
                       yscrollcommand => ['set', $sb])
              ->pack (side => 'bottom', fill => 'both', expand => 1);

    $vc->pack (side => 'left', fill => 'both', expand => 1);

    push (@name, $name);
    push (@lb, $lb);
  }

  # fill data items into each cell
  if ($vptt == undef || $#$vptt < 0)
  { # hack up a faked view point table; T2D: refresh the real table
    print <<EOX;
WARNING: view point $view needs to be refreshed
T2D: NOT YET IMPLEMENTED
using all items in DB order
EOX

    $vptt= [];
    my $cnt= $db->get_last_index ();    # total number of records
    for ($i= 0; $i <= $cnt; $i++) { push (@$vptt, $i); }
  }

  # use view point table to produce the right sorting of the items
  foreach $i (@$vptt)
  {
    my $rec= $db->FETCH ($i) || next;  # or bail out ???
    for ($j= 0; $j <= $#name; $j++)
    {
      my $s= $rec->{$name[$j]};
      $s=~ tr/\r\n /   /s;
      $lb[$j]->insert ('end', $s);
    }
  }

  $sbf->pack (side => 'left', fill => 'y');

  my $List_View=
  {
    DBgui => $DBgui,
    db => $db,

    top => $top,
    view => $view,
    vptd => $vptd,
    vptt => $vptt,
    lists => \@lb,
    scroll => $sb,
  };
  bless $List_View, $class;

  foreach $lb (@lb)
  {
    $lb->bind ('<Double-1>' => sub { $List_View->select_item ($lb); } );
  }

  $sb->configure (command => ['yview', $List_View]);
  $List_View;
}

# ----------------------------------------------------------------------------
# vertical scroll method for a composite list view widget:
# calls yview method for each list
sub yview
{
  my $w= shift;
  foreach (@{$w->{lists}}) { $_->yview (@_); }
}

# ----------------------------------------------------------------------------
sub select_item
{
  my $DBlist= shift;
  my $listbox= shift;

  my $lb_idx= $listbox->index ('active');
  my $db_idx= $DBlist->{vptt}->[$lb_idx];

  print ">>> show_card lb_idx=$lb_idx db_idx=$db_idx\n";
  $DBlist->{DBgui}->show_card ($db_idx+1);
}
