#!/usr/bin/perl

# 
#    SMTP mail send tool
# 

use Socket;
use strict;

# ./smtp_send.pl mta-ipaddr rcpt-addr from-addr message-filename

my(
	$port, $struct, $respons, $command, $send_data,
	$server, $rcpt_to, $mail_from, $file_name, $line, $i
);

if($#ARGV < 3){
	print "./smtp_send.pl mta-ipaddr rcpt-addr from-addr message-filename\n";
	exit;
}

$server 	= $ARGV[0];
$rcpt_to 	= $ARGV[1];
$mail_from 	= $ARGV[2];
$file_name 	= $ARGV[3];

$send_data	= "";

open ( INFILE , $file_name);

while ( $line = <INFILE> ){
	$send_data .= $line;
}

close(INFILE);

# ------------------------------------------------------- #
#  SOCKET
# ------------------------------------------------------- #

$port 	= getservbyname('smtp','tcp');
$struct = sockaddr_in($port,inet_aton($server)); 
socket(SH, PF_INET, SOCK_STREAM, 0) || die("sock faild $!") ; 
setsockopt(SH, SOL_TCP, TCP_NODELAY,1);

connect(SH, $struct ) || die("connect faild $!") ; 

select(SH); $| = 1; select(STDOUT);

$respons = <SH>  ;

unless($respons =~ /^220/) {
    close(SH); die("connect faild. no responce $!") ; 
}


# EHLO
# ------------------------------------------------------- #

$command = "EHLO $server\n";
print $command;
print SH $command  ;

$respons  =  <SH>  ;
&decode(\$respons) ;
print ">$respons";

unless($respons =~ /^250/){

	$command = "HELO $server\n";
	print $command;
	print SH $command;

	$respons  =  <SH>  ;
	&decode(\$respons) ;
	print ">$respons";

	unless($respons =~ /^250/){
	    close(SH); die("HELO faild. $!") ; 
	}
}

# MAIL FROM
# ------------------------------------------------------- #

$command = "MAIL FROM:$mail_from\n";
print $command;
print SH  $command ; 

$respons  =  <SH>  ;
&decode(\$respons) ;
print ">$respons";

unless($respons =~ /^250/){
    print SH "RSET\n"; close(SH);
    die("MAIL faild. $!") ; 
}

# RCPT TO
# ------------------------------------------------------- #

$command = "RCPT TO: $rcpt_to\n";
print 		$command;
print SH  	$command  ;

$respons  = <SH>;
&decode(\$respons);
print ">$respons";

unless($respons =~ /^25[0|1]/){
    print SH "RSET\n"; close(SH);
    die("RCPT faild. $!") ; 
}

# DATA
# ------------------------------------------------------- #

$command = "DATA\n";
print $command;
print SH  $command  ;

$respons  =  <SH>  ;
&decode(\$respons) ;
print ">$respons";

unless($respons =~ /^354/){
    print SH "RSET\n"; close(SH);
    die("DATA faild. $!") ; 
}

# ------------------------------------------------------- #

#&jcode'convert(*send_data,'jis');

$command = "$send_data";
print $command;
print SH  $command  ;

$command = ".\r\n";
print $command;
print SH  $command  ;

$respons  =  <SH>  ;
&decode(\$respons) ;
print ">$respons";

unless($respons =~ /^250/){
    print SH "RSET\n"; close(SH);
    die("message faild. $!") ; 
}

# QUIT
# ------------------------------------------------------- #

$command = "QUIT\n";
print $command;
print SH  $command  ;

$respons  =  <SH>  ;
&decode(\$respons) ;
print ">$respons";

unless($respons =~ /^221/){
    print SH "RSET\n"; close(SH);
    die("QUIT faild. $!") ; 
}

# ------------------------------------------------------- #
close(SH); select(STDOUT);

print "mail send ok.\n";

exit(0);

# ------------------------------------------------------- #
sub decode
{
    my $inf = $_[0];
    $$inf =~ s/\x0D\x0A|\x0D|\x0A/\n/g;

}

