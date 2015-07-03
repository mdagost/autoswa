#!/usr/bin/perl -w

use lib '/home/mdagost/perl/share/perl5/WWW/';
use lib '/home/mdagost/perl/share/perl5/';

use strict;
$|++;

use File::Basename;
use WWW::Mechanize;


my $confnumber = $ARGV[0];
my $firstname  = $ARGV[1];
my $lastname   = $ARGV[2];
my $email      = $ARGV[3];

my $now = `date +"%H%M%S%Y"`;
chomp($now);

my $mech = WWW::Mechanize->new(  );

#go to the Southwest Airlines homepage
#$mech->get( "http://www.southwest.com" );
$mech->get( "http://www.southwest.com/flight/retrieveCheckinDoc.html" );
$mech->success or die $mech->response->status_line;

#select the form, fill the fields we need, and submit...
#$mech->form_number( 2 );
$mech->form_number( 2 );
#$mech->field( recordLocator => $confnumber );
$mech->field( confirmationNumber => $confnumber );
$mech->field( firstName => $firstname );
$mech->field( lastName => $lastname );
$mech->submit(  );

$mech->success or die "post failed: ",
    $mech->response->status_line;


#the stuff below was for the old version of the SWA website
#we need to look at the response and parse out the value of the 
#first radio button
#my $matchingRegex1 = "\<input type=\"radio\" name=\"passenger\" value=\".*\"";
#my $matchingRegex1 = "\<input type=\"hidden\" name=\".*\" value=\".*\"";
#$mech->content =~ m/$matchingRegex1/;
#my $radioButtonString = $&;

#now clean out only the value
#my $matchingRegex2 = "value=\".*\"";
#my $matchingRegex3 = "value=";
#my $matchingRegex4 = '"';

#$radioButtonString =~ m/$matchingRegex2/;
#my $value = $&;
#$value =~ s/$matchingRegex3//g;
#$value =~ s/$matchingRegex4//g;

$mech->form_number( 2 );
$mech->current_form()->param("checkinPassengers[0].selected", "true");
#uncomment below for multiple passengers
$mech->current_form()->param("checkinPassengers[1].selected", "true");
#$mech->current_form()->param("checkinPassengers[1].selected", "true");
$mech->click("printDocuments");

#open a file to save the returned html to
my $tmp_dir = "/home/mdagost/public_html/southwest/tmp_files/";

#open a temporary output file to write our old cron file to
my $outfile_basename=$tmp_dir."reply_".$now.".html";
my $outfile_name    =">".$outfile_basename;

open OUT_FILE, $outfile_name or die;

#print the page that we get back
print OUT_FILE $mech->content;

#close the outfile
close OUT_FILE;

#parse out the boarding number
my $groupGrepExp  = "egrep -o ".'"/images/checkin/boarding_pass/boarding[A-Z]" '.$outfile_basename." | egrep -o ".'"boarding[A-Z]"'." | egrep -o ".'"[A-Z]"';
my $numberGrepExp = "egrep -o ".'"/images/checkin/boarding_pass/boarding[0-9]+" '.$outfile_basename." | egrep -o ".'"boarding[0-9]+"'." | egrep -o ".'"[0-9]+"';

#print $groupGrepExp;
#print $numberGrepExp;

my @boardingGroup       = qx($groupGrepExp);
my @boardingNumbers     = qx($numberGrepExp);


#now send an email with the response
#my $mailString = "|mail -s ".'"'."Your Automatic Southwest Airlines Checkin".'" '.$email;

#open MAIL, $mailString;
#print MAIL $mech->content;
#close MAIL;

my $mailString ="To: ".$email."\n".
    "From: \@\n" .
    "Cc: \@\n" .
    "MIME-Version: 1.0\n" .
    "Content-Type: text/html; charset=us-ascii\n" .
    "From: \@\n" .
    "Subject:Your Automatic Southwest Airlines Checkin\n\n" .
    "Your Automatic Southwest Airlines Checkin was successful!!  You have been assigned the boarding number ".$boardingGroup[0];

foreach(@boardingNumbers){ $mailString = $mailString.$_; }

$mailString = $mailString."\n\n" .
    "Unfortunately, we've only reserved your spot for you.  You still have to log back into Southwest to print your boarding pass.  Have a safe trip!!\n\n\n\n".
    $mech->content;

my $mailProg = "/usr/sbin/sendmail";
open (MAIL,"|$mailProg -t") or print "Can't find email program $mailProg";
print MAIL $mailString;
close MAIL;


