#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

$VERSION = "1.0";
$IMGDIR  = "/cgi-data/setistats";
$SETIDIR = "/opt/SETI";
$ST = "$SETIDIR/state.txt";
$UI = "$SETIDIR/user_info.txt";
$WU = "$SETIDIR/work_unit.txt";

$T_BOR = "black";      # Table border
$T_DBG = "#ffffc0";    # Table descr. background
$T_VBG = "#ffffc0";    # Table value background

print "Content-type: text/html\n";
print "Expires: Thu Jan 01 00:00:00 1970 GMT\n\n";

# client version: version.txt
# work unit info: work_unit.txt
# user info: user_info.txt
# current working state: state.txt
# current results: result_header.txt
# all suspicious things: outtext.txt

&WriteHead;
$clientver = &ReadVersion;
print "Client version is $clientver\n<P>\n";
&TableStart;
&TableItem("Client version", "$clientver");
&TableItem("Username", "$ui[4]");
&TableItem("eMail","<A HREF=\"mailto:$ui[3]\">$ui[3]</A>");
&TableItem("URL","<A HREF=\"$ui[5]\" TARGET=\"_new\">$ui[5]</A>");
&TableStop;

&WriteFoot;

exit 0;

sub TableStart {
  print <<"E_O_I";
<TABLE BORDER=0 CELLPADDING=2 CELLSPACING=0><TR><TD BGCOLOR=$T_BOR>
  <TABLE BORDER=0 CELLSPACING=1>
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
  print "    <TR><TD BGCOLOR=$T_DBG ALIGN=right VALIGN=top><B>$desc:</B></TD><TD BGCOLOR=$T_VBG VALIGN=top>$valu</TD></TR>\n";
}

sub ReadVersion {
  open (FH, "$SETIDIR/version.txt") || die "Could not open $SETIDIR/version.txt !";
  
  my $major = <FH>;
  chomp($major);
  my $minor = <FH>;
  chomp($minor);
  
  close FH;
  
  my ($bla,$major) = split(/=/, $major);
  my ($bla,$minor) = split(/=/, $minor);
  
  return $major . "." . $minor;
}

sub LoadWorkUnitInfo {
  open (FH, "$SETIDIR/work_unit.txt") || die "Could not open $SETIDIR/work_unit.txt!";
  
  until ((index $what,"end_seti") != -1) {
    $what = <FH>;
    push @wu, $what;
  }
  
  close FH;
  chomp @wu;

  for (my $i=0;$i<@wu;$i++) {
    my ($bla, $info) = split(/=/, $wu[$i]);
    $wu[$i] = $info;
  }
}

sub LoadUserInfo {
  open (FH, "$SETIDIR/user_info.txt") || die "Could not open $SETIDIR/user_info.txt!";
  
  @ui = <FH>;  

  close FH;
  chomp @ui;

  for (my $i=0;$i<@ui;$i++) {
    my ($bla, $info) = split(/=/, $ui[$i]);
    $ui[$i] = $info;
  }
}

sub LoadState {
  open (FH, "$SETIDIR/state.txt") || die "Could not open $SETIDIR/state.txt!";
  
  @st = <FH>;  

  close FH;
  chomp @st;

  for (my $i=0;$i<@st;$i++) {
    my ($bla, $info) = split(/=/, $st[$i]);
    $st[$i] = $info;
  }
}

sub WriteHead {
  print <<"E_O_I";
<HTML>
<HEAD>
  <TITLE>SETI\@home statistics</TITLE>
</HEAD>
<BODY BGCOLOR=white TEXT=black>
<CENTER>
<FONT COLOR=blue FACE="Haettenschweiler"><FONT SIZE=+4 COLOR=navy>SETI\@home stats</FONT> $VERSION</FONT>
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
