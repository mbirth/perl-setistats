#!/usr/bin/perl
# SETI@home stats 1.0 - shows current status of a running SETI-client in your browser
# Copyright (C)1999 by Markus Birth <mbirth@webwriters.de> - GPL v2
# http://www.webwriters.de/mbirth/

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use CGI::Carp qw(fatalsToBrowser);

$VERSION = "1.0";
$IMGDIR  = "/cgi-data/setistats";
$SETIDIR = "/opt/SETI";
$ST = "$SETIDIR/state.txt";
$UI = "$SETIDIR/user_info.txt";
$WU = "$SETIDIR/work_unit.txt";
$VI = "$SETIDIR/version.txt";

$T_BOR = "black";      # Table border
$T_DBG = "#ffff80";    # Table descr. background
$T_VBG = "#ffffc0";    # Table value background

$QS = $ENV{"QUERY_STRING"};

print "Content-type: text/html\n";
# print "Expires: Thu Jan 01 00:00:00 1970 GMT\n\n";

# client version: version.txt
# work unit info: work_unit.txt
# user info: user_info.txt
# current working state: state.txt
# current results: result_header.txt
# all suspicious things: outtext.txt

&WriteHead;
print "<P>&nbsp;<P>\n";
&Graph(&Read($ST, "prog"), "Progress status", 500);
print "<P>\n";
&UserInfo;
print "<P>&nbsp;<P>\n";
&WorkUnitInfo;
print "<P>&nbsp;<P>\n";
&StateInfo;
print "<P>&nbsp;<P>\n";
&OutBest;
print "<P>&nbsp;<P>\n";
&WriteFoot;

exit 0;

sub Graph {
  my $val = shift;
  my $capt = shift;
  my $width = shift;
  print "<P>\n<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0>\n<TR>\n<TD><FONT SIZE=+2>&nbsp;<B>$capt</B><BR>&nbsp;";
  print &MakeGraph($val, $width);
  print " <B>" . ($val)*100 . "%</B></FONT></TD></TR></TABLE>\n";
  print "<P>&nbsp;<P>\n";
}

sub UserInfo {
  &TableStart("User info");
  &TableItem("Client version", &Read($VI, "major") . "." . &Read($VI, "minor"));
  &TableItem("Directory", "$SETIDIR");
    if ( &Read($UI, "show_name") eq "yes" ) { $nameshown = ""; } else { $nameshown = "not "; }
  &TableItem("Username", "<B>" . &Read($UI, "name") . "</B> (ID: " . &Read($UI, "id") . ") ($nameshown" . "shown on server)");
    if ( &Read($UI, "show_email") eq "yes" ) { $mailshown = ""; } else { $mailshown = "not "; }
  &TableItem("eMail","<B><A HREF=\"mailto:" . &Read($UI, "email_addr") . "\"></B>" . &Read($UI, "email_addr") . "</A> ($mailshown" . "shown on server)");
  my $URL = &Read($UI, "url");
  if ($URL ne "\#invalid_entry\#") {
    &TableItem("URL","<A HREF=\"$URL\" TARGET=\"_new\">$URL</A>");
  }
  &TableItem("Postal code", &Read($UI, "postal_code"));
  &TableItem("Country", &Read($UI, "country"));
  &TableItem("Register time (GMT)", &JD2HMS(&Read($UI, "register_time")));
  &TableItem("Register time (JD)", &ExtrJD(&Read($UI, "register_time")));
  &TableItem("Work Units", &Read($UI, "nwus") . " received, " . &Read($UI, "nresults") . " sent");
  &TableItem("Total CPU time", &time2HMS(&Read($UI, "total_cpu")));
  &TableStop;
}

sub WorkUnitInfo {
  &TableStart("Work Unit Info");
  &TableItem("Work Unit name", &Read($WU, "name"));
  &TableItem("Record time (GMT)", &JD2HMS(&Read($WU, "time_recorded")));
  &TableItem("Record time (JD)", &ExtrJD(&Read($WU, "time_recorded")));
  &TableItem("Receiver", "Arecibo Radio Observatory (" . &Read($WU, "receiver") . ")");
  &TableItem("Tape version", &Read($WU, "tape_version"));
  &TableItem("Area", &Read($WU, "start_ra") . " R.A., " . &Read($WU, "start_dec") . " DEC - " . &Read($WU, "end_ra") . " R.A. " . &Read($WU, "end_dec") . " Dec");
  &TableItem("Angle range", &Read($WU, "angle_range"));
  &TableItem("Subband number", &Read($WU, "subband_number"));
  &TableItem("Subband sample rate", &Read($WU, "subband_sample_rate"));
  &TableItem("Subband base freq", &Read($WU, "subband_base")/1000000000 . " GHz");
  &TableItem("Subband center freq", &Read($WU, "subband_center")/1000000000 . " GHz");
  &TableItem("FFT length", &Read($WU, "fft_len"));
  &TableItem("iFFT length", &Read($WU, "ifft_len"));
  &TableItem("nsamples", &Read($WU, "nsamples"));
  if ($QS eq "coords") {
    my $pos = &Read($WU, "num_positions");
    &TableItem("num_positions", $pos);
    for (my $i=0;$i<$pos;$i++) {
      my $item = &Read($WU, "coord" . $i);
      my ($trash, $rt, $ra, $trash, $dec) = split (/ /,$item);
      &TableItem("coord" . $i, &JD2HMS($rt) . " | $ra R.A., $dec Dec");
    }
    &TableItem("Collapse", "<A HREF=\"" . $ENV{"SCRIPT_NAME"} . "\">[ Hide coordinate info ]</A>");
  } else {
    &TableItem("Expand", "<A HREF=\"" . $ENV{"SCRIPT_NAME"} . "?coords\">[ Additional coordinate info ]</A>");
  }
  &TableStop;
}

sub StateInfo {
  &TableStart("Current State");
  &TableItem("Progress status", &Read($ST, "prog")*100 . "%");
  &TableItem("Unit CPU time", &time2HMS(&Read($ST, "cpu")));
  &TableItem("Doppler shift rate", &Read($ST, "cr"));
  &TableItem("No. of shifts", &Read($ST, "ncfft"));
  &TableItem("FFT length", &Read($ST, "fl"));
  &TableStop;
}

sub OutBest {
  print <<"E_O_I";
<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 WIDTH=550><TR><TD WIDTH=50% ALIGN=left VALIGN=top>
  <TABLE BORDER=0 CELLPADDING=2 CELLSPACING=0 WIDTH=90%>
    <CAPTION><B>Best Spike</B></CAPTION>
    <TR><TD BGCOLOR=$T_BOR>
      <TABLE BORDER=0 CELLSPACING=1 CELLPADDING=2 WIDTH=100% HEIGHT=100%>
E_O_I
&BTableItem("POWER", &Read($ST, "bs_power"));
&BTableItem("SCORE", &Read($ST, "bs_score"));
&BTableItem("BIN", &Read($ST, "bs_bin"));
&BTableItem("FFT index", &Read($ST, "bs_fft_ind"));
&BTableItem("chirp rate", &Read($ST, "bs_chirp_rate"));
&BTableItem("FFT length", &Read($ST, "bs_fft_len"));
print <<"E_O_I";
    </TABLE>
  </TD></TR></TABLE>
</TD><TD WIDTH=50% ALIGN=right VALIGN=top>
  <TABLE BORDER=0 CELLPADDING=2 CELLSPACING=0 WIDTH=90%>
    <CAPTION><B>Best Gaussian</B></CAPTION>
    <TR><TD BGCOLOR=$T_BOR>
      <TABLE BORDER=0 CELLSPACING=1 CELLPADDING=2 WIDTH=100% HEIGHT=100%>
E_O_I
&BTableItem("POWER", &Read($ST, "bg_power"));
&BTableItem("SCORE", &Read($ST, "bg_score"));
&BTableItem("BIN", &Read($ST, "bg_bin"));
&BTableItem("FFT index", &Read($ST, "bg_fft_ind"));
&BTableItem("chirp rate", &Read($ST, "bg_chirp_rate"));
&BTableItem("FFT length", &Read($ST, "bg_fft_len"));
&BTableItem("CHISQ", &Read($ST, "bg_chisq"));
print <<"E_O_I";
    </TABLE>
  </TD></TR></TABLE>
</TD></TR></TABLE>
E_O_I
}

sub TableStart {
  my $capt = shift;
  print <<"E_O_I";
<TABLE BORDER=0 CELLPADDING=2 CELLSPACING=0 WIDTH=550><CAPTION><B>$capt</B></CAPTION><TR><TD BGCOLOR=$T_BOR>
  <TABLE BORDER=0 CELLSPACING=1 CELLPADDING=2 WIDTH=100% HEIGHT=100%>
E_O_I
}

sub TableStop {
  print <<"E_O_I";
  </TABLE>
</TD></TR></TABLE>
E_O_I
}

sub TableItem {
  my $desc = shift;
  my $valu = shift;
  print "    <TR><TD BGCOLOR=$T_DBG ALIGN=right VALIGN=top WIDTH=25%><B>$desc:</B></TD><TD VALIGN=top BGCOLOR=$T_VBG>$valu</TD></TR>\n";
}

sub BTableItem {
  my $desc = shift;
  my $valu = shift;
  print "    <TR><TD BGCOLOR=$T_DBG ALIGN=right VALIGN=top WIDTH=35%><B>$desc:</B></TD><TD VALIGN=top BGCOLOR=$T_VBG>$valu</TD></TR>\n";
}

sub Read {
  my $file = shift;
  my $what = shift;

  open (FH, "$file") || return "#cannot_open_file#";

  until ((index $tmp, $what) == 0 || eof FH) {
    $tmp = <FH>;
  }

  close FH;
  chomp $tmp;
  if ( (index $tmp, $what) != -1 ) {
    (my $trash, $info) = split(/=/,$tmp);
    if ( (length $info) < 1 ) {
      $info = "\#invalid_entry\#";
    }
  } else {
    $info = "\#entry_not_found\#";
  }
  return $info;

}

sub WriteHead {
  print <<"E_O_I";
<HTML>
<HEAD>
  <TITLE>SETI\@home statistics</TITLE>
  <STYLE TYPE="text/css">
    TD { font-family: "Arial"; font-size: 9pt; }
    CAPTION { font-family: "Arial"; font-size: 14pt; text-align: left; }
  </STYLE>
</HEAD>
<BODY BGCOLOR=white TEXT=black>
<CENTER>
<FONT COLOR=blue FACE="Haettenschweiler"><FONT SIZE=+4 COLOR=navy>SETI\@home stats</FONT> $VERSION</FONT><BR>
<FONT SIZE=-2>(C)1999 by Markus Birth &lt;<A HREF="mailto:mbirth\@webwriters.de">mbirth\@webwriters.de</A>&gt;</FONT>
<P>
E_O_I
}

sub WriteFoot {
  print <<"E_O_I";
</CENTER>
</BODY>
</HTML>
E_O_I
}

sub time2HMS {
  my $seti = shift;
  my $d = int ($seti / 86400);
  my $h = int (($seti - $d * 86400) / 3600);
  my $m = int (($seti - $d * 86400 - $h * 3600) / 60);
  my $s = int (($seti - $d * 86400 - $h * 3600 - $m * 60) * 1000) / 1000;
  return "$d"."d $h"."h $m"."m $s"."s";
}

sub JD2HMS {
  my $jd = shift;
  my ($jod, $trash) = split (/ \(/, $jd);
  $jd = $jod;  
  $jd -= 2440587.5; # 00.01.1970 12:00:00 (because "gmtime" need seconds since 1970)
  $jd *= 86400;     # days -> seconds
  
  my @tim = gmtime $jd;
  my @weekdays = ("Mon","Tue","Wed","Thu","Fri","Sat","Sun");
  my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
  
  my $sec = $tim[0];
  if ($sec<10) { $sec = "0" . "$sec"; }
  my $min = $tim[1];
  if ($min<10) { $min = "0" . "$min"; }
  my $hour = $tim[2];
  if ($hour<10) { $hour = "0" . "$hour"; }
  my $mday = $tim[3];
  # my $month = $tim[4] + 1;
  # if ($month<10) { $month = "0" . "$month"; }
  my $month = $months[$tim[4]];
  my $year = $tim[5];
  my $wday = $weekdays[$tim[6]];
  my $yday = $tim[7];
  
  return "$month $mday 19$year / $hour:$min:$sec";
}

sub ExtrJD {
  my $jd = shift;
  my ($jod, $trash) = split (/ \(/, $jd);
  return $jod;  
}

sub MakeGraph {
  my $val = shift;
  my $len = shift;
  my $imgp = "ALIGN=absmiddle";
  if ($val < 1 && $val > 0) {
    if (($len - $val * $len) > 3) {
      $len = $len - 18 - 4 - 3 - 3 - 1 - 19;
    } elsif (($len * $val) > 4) {
      $len = $len - 18 - 3 - 1 - 19;
    } else {
      $len = $len - 18 - 4 - 3 - 1 - 19;
    }
  } elsif ($val == 1) {
    $len = $len - 18 - 4 - 3 - 19;
  } elsif ($val == 0) {
    $len = $len - 18 - 1 - 19;
  }
  my $full = int ($len * $val);
  my $left = $len - $full;
  my $out = "";
  
  $out = $out . "<IMG SRC=\"$IMGDIR/bar_left.gif\" $imgp HEIGHT=48 WIDTH=18>";
  if ($full > 4) {
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_beg.gif\" $imgp HEIGHT=48 WIDTH=4>";
  }
  if ($full > 0) {
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_mid.gif\" $imgp HEIGHT=48 WIDTH=$full>";
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_end.gif\" $imgp HEIGHT=48 WIDTH=3>";
  }
  if ($full != 0 && $left > 3) {
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_shad.gif\" $imgp HEIGHT=48 WIDTH=3>";
  }
  if ($left > 0) {
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_clr.gif\" $imgp HEIGHT=48 WIDTH=$left>";
    $out = $out . "<IMG SRC=\"$IMGDIR/bar_cright.gif\" $imgp HEIGHT=48 WIDTH=1>";
  }
  $out = $out . "<IMG SRC=\"$IMGDIR/bar_right.gif\" $imgp HEIGHT=48 WIDTH=19>";
  return $out;
}
