#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode qw/encode decode/;
use MIME::Lite;
#Usage
#./mail_new.pl generalversammlung_2012 example_mail_adress "Bewahrer - Newsletter 03-2013" Einladung_GV_2012.pdf
MIME::Lite->send("sendmail", "/usr/bin/msmtp");
my $input_filename=$ARGV[0];
my $receiver_list=$ARGV[1];
my $subject_unencoded=$ARGV[2];
my $attachment_filename=$ARGV[3];

my $mailfrom_name="Bewahrer";
my $mailfrom_address="admin\@bewahrer.at";

my $mailto_name;
my $mailto_address;
#messagetext
my @message_text_array;
open (INPUTFILE, "<$input_filename") or die "Cannot open $input_filename: $!\n";
binmode( INPUTFILE, ':utf8' );
while(<INPUTFILE>){
    push(@message_text_array,$_);
}

close INPUTFILE;
my $mailtext_unencoded=join("", @message_text_array);
my $mailtext = Encode::encode("utf-8", $mailtext_unencoded);
#my $subject_unencoded="Newsletter 01.2012 \"Bewahrer imaginärer Welten\"";
my $subject = Encode::encode("MIME-B", $subject_unencoded);
### Create a message
my $msg;

open(RECEIVERLIST, "<$receiver_list") or die "Cannot open $receiver_list: $!\n";
while(<RECEIVERLIST>){
    chomp;
    unless($_ eq ""){
	print "$_\n";
	my @receivers=split(/,/,$_);
	$mailto_name=$receivers[0];
	$mailto_address=$receivers[1];
	open(LOG,">Log") || print STDERR "Could not write log: $!\n";
	print LOG "From: $mailfrom_name $mailto_address";
	unless(defined($attachment_filename)){
	    $msg = MIME::Lite->new(
		From     => "$mailfrom_name <$mailfrom_address>",
		To       => "$mailto_name <$mailto_address>",
		#Cc       => 'some@other.com, some@more.com',
		Subject  => "$subject",
		Type     => "text/plain; charset=\"UTF-8\"",
		Data     => "$mailtext"
		);
	}else{
	    ### Create the multipart "container":
	    $msg = MIME::Lite->new(
		From    =>"$mailfrom_name <$mailfrom_address>",
		To      =>"$mailto_name <$mailto_address>",
		#Cc      =>'some@other.com, some@more.com',
		Subject =>"$subject",
		Type    =>'multipart/mixed'
		);
	
	    ### Add the text message part:
	    ### (Note that "attach" has same arguments as "new"):
	$msg->attach(
	    Type     =>"text/plain; charset=\"UTF-8\"",
	    Data     =>"$mailtext"
	    );
	    
	    ### Add the file part:
	    #file path is relative to perl-script
	    $msg->attach(
		Type        =>'application/pdf',
		Path        =>"$attachment_filename",
		Filename    =>"$attachment_filename",
		Encoding => 'base64',
		Disposition => 'attachment'
		);
	}
	#format as string
	my $str = $msg->as_string;
	my $success=1;
	my $Sendmail_Prog = "msmtp -a default $mailto_address";
	open(MAIL,"|$Sendmail_Prog") || die $success=0;
	if($success){
	print LOG "To:$mailto_name $mailto_address Command: $Sendmail_Prog - mailing sucess\n";
	}else{
	    print LOG "$Sendmail_Prog - mailing failed\n";
	}
	print MAIL "$str";
	close MAIL;
    }
}
