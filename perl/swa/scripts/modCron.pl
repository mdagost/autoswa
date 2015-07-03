#!/usr/bin/perl -w

use bytes;

#$tmp_dir = "/home/mdagost/public_html/southwest/tmp_files/";
$tmp_dir = "/tmp/";

#open a temporary output file to write our old cron file to
$outfile_name=">".$tmp_dir."newCron.txt";
open OUT_FILE, $outfile_name or die;

#get the current contents of the cron file and write them to the file
$current_cron = `crontab -l`;
chomp($current_cron);
print OUT_FILE $current_cron."\n";

#fill an array with any input files with new tasks we want to schedule
@schedFiles = </home/mdagost/public_html/southwest/tmp_files/toSchedule_*.txt>;

#this variable tells us if we have a new task to schedule or not
my $haveNewTask = 0;
#loop over the files and do what we need to do
foreach $file (@schedFiles) {

    #if we got here, we're scheduling a new task
    $haveNewTask = 1;
    
    #open the file for reading
    $infile_name = "<".$file;
    open IN_FILE, $infile_name or die;

    #now append the tasks we want to schedule
    while(<IN_FILE>)
    {
	my $line = $_;
	print OUT_FILE $line;

    }

    close IN_FILE;

}

close OUT_FILE;

#set our new crontab file
$setCron = "crontab ".$tmp_dir."newCron.txt";
system($setCron);

#now send an email to me telling me we've scheduled a new task
if($haveNewTask){

    my $newCron = `cat /tmp/newCron.txt`;
    
    my $mailString ="To: \@\n".
	"From: \@\n" .
	"MIME-Version: 1.0\n" .
	"Content-Type: text/html; charset=us-ascii\n" .
	"From: \@\n" .
	"Subject:New Automatic Southwest Airlines Checkin Task Scheduled\n\n" .
	$newCron;
    
    my $mailProg = "/usr/sbin/sendmail";
    open (MAIL,"|$mailProg -t") or print "Can't find email program $mailProg";
    print MAIL $mailString;
    close MAIL;
}

#clean up by deleting our new cron file and then the files we've scheduled
$cleanUp = "rm -f ".$tmp_dir."newCron.txt";
system($cleanUp);

foreach $file (@schedFiles) {
 
    $cleanUp = "rm -f ".$file;
    system($cleanUp);

}
