#!/usr/bin/perl -w
use strict;
$|++;

use File::Basename;
use WWW::Mechanize;
use Net::AWS::SES;
use WWW::PushBullet;
use YAML::XS 'LoadFile';

# needed for AWS::SES
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

# get our commandline arguments
my $confnumber       = $ARGV[0];
my $firstname        = $ARGV[1];
my $lastname         = $ARGV[2];
my $multiple_checkin = $ARGV[3];
my $from_email       = $ARGV[4];
my $to_email         = $ARGV[5];

# load any secrets that we need access to
my $secrets = LoadFile('/app/secrets.yaml');

my $aws_access_key = $secrets->{aws_access_key};
my $aws_secret_key = $secrets->{aws_secret_key};
my $pb_api_key = $secrets->{pb_api_key};

my $now = `date +"%H%M%S%Y"`;
chomp($now);

my $mech = WWW::Mechanize->new();

# go to the SWA checking page
$mech->get( "http://www.southwest.com/flight/retrieveCheckinDoc.html" );
$mech->success or die $mech->response->status_line;

# select the form, fill in the fields we need, and submit...
$mech->form_number(2);
$mech->field(confirmationNumber => $confnumber);
$mech->field(firstName => $firstname);
$mech->field(lastName => $lastname);
$mech->submit();

$mech->success or die "Form post failed: ", $mech->response->status_line;

# now parse the response
$mech->form_number(2);
$mech->current_form()->param("checkinPassengers[0].selected", "true");
if($multiple_checkin==1){
    $mech->current_form()->param("checkinPassengers[1].selected", "true");
}
$mech->click("printDocuments");

# open a file to save the returned html to so that we can parse out the boarding info
my $outfile_basename="/tmp/reply_".$now.".html";
my $outfile_name    =">".$outfile_basename;
open OUT_FILE, $outfile_name or die;
# print the page that we get back
print OUT_FILE $mech->content;
# close the outfile
close OUT_FILE;

# parse out the boarding number for our email
my $groupGrepExp  = "egrep -o ".'"boarding_group.*" '.$outfile_basename." | egrep -o ".'">[A-Z]<"'." | egrep -o ".'"[A-Z]"';
my $numberGrepExp = "egrep -o ".'"boarding_position.*" '.$outfile_basename." | egrep -o ".'">[0-9]+"'." | egrep -o ".'"[0-9]+"';

my @boardingGroup       = qx($groupGrepExp);
my @boardingNumbers     = qx($numberGrepExp);

# now send our email and push notifications
my $ses = Net::AWS::SES->new(access_key => $aws_access_key,
			     secret_key => $aws_secret_access_key);

my $subject = 'Your Automatic Southwest Airlines Checkin';
my $body = "Your Automatic Southwest Airlines Checkin was successful!!  You have been assigned the boarding number ".$boardingGroup[0];
foreach(@boardingNumbers){ $body = $body.$_; }
$body = $body."\n\n" .
    "Unfortunately, we've only reserved your spot for you.  You still have to log back into Southwest to print your boarding pass.  Have a safe trip!!\n\n\n\n".$mech->content;

my $response = $ses->send(From    => $from_email,
			  To      => $to_email,
			  Subject => $subject,
			  Body    => $body);

unless ( $r->is_success ) {
    printf("Could not deliver the message: " . $r->error_message);
}

printf("SES email sent successfully. MessageID: %s\n", $r->message_id);

# send the same thing via a pushbullet notification
my $pb = WWW::PushBullet->new({apikey => $pb_api_key});
$pb->push_note({ title => $subject,
                 body => $body });
