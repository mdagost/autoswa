#!/usr/bin/perl -w
use strict;
$|++;

my $email = "";

my $mailString ="To: ".$email."\n".
    "From: \@\n" .
    "Cc: @\n" .
    "MIME-Version: 1.0\n" .
    "Content-Type: text/html; charset=us-ascii\n" .
    "From: \@\n" .
    "Subject:Automatic Southwest Airlines Checkin Cron Still Running\n\n" .
    "I'm alive!!!!!!!!!!!!!";

my $mailProg = "/usr/sbin/sendmail";
open (MAIL,"|$mailProg -t") or print "Can't find email program $mailProg";
print MAIL $mailString;
close MAIL;


