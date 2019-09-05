#!/bin/perl
################################################################################
## Certfication Report Perl Script
## 2019.02 created by CoreSolution (smlee@sk.com)
################################################################################

use strict;
#use warnings;

my (%program, %filename, %socket_pid, %socket_digest, %max_len);
my (%file_fullname, %file_expire, %file_issuer, %socket_expire, %socket_issuer);
################################################################################
sub MaxLength
{
	my ($key, $data)=@_;
	if (length($data)>$max_len{$key}) {
		$max_len{$key}=length($data);
	}
}
sub StringCat
{
	my ($key, $data)=@_;

	if ($max_len{$key} eq "") { $max_len{$key}=length($key); }
	my $rst="| $data";
	my $cnt_space=$max_len{$key}-length($data);
	for (my $i=0;$i<$cnt_space+1;$i++) {
		$rst .= " ";
	}
	return $rst;
}
sub StringLine
{
	my ($key)=@_;
	my $rst="+";
	if ($max_len{$key} eq "") { $max_len{$key}=length($key); }
	for (my $i=0;$i<$max_len{$key}+2;$i++) {
		$rst .= "-";
	}
	return $rst;
}
################################################################################
if (! -f "program.txt") { die "Error - program.txt not found"; }
open(FILE, "grep -v \"^ \" program.txt |awk '{print \$7,\$1}'|");
while (my $line=<FILE>) {
	#print $line;
	$line =~ s/\n//g;
	my ($pid, $name)=split(/ /, $line);
	$program{$pid}=$name;
	&MaxLength("PID", $pid);
	&MaxLength("Program", $name);
}
close(FILE);

my ($file, $md5);
if (! -f "file.txt") { die "Error - file.txt not found"; }
open(FILE, "< file.txt");
while (my $line=<FILE>) {
	$line =~ s/\n//g;
	if ($line =~ / md5sum /) {
		($file, undef, $md5)=split(/ /, $line);
		$filename{$md5}=$file;
		$file_fullname{$file}=$md5;
		&MaxLength("File", $file);
		#&MaxLength("MD5", $md5);
	} elsif ($line =~ / issuer= /) {
		my (undef, $a)=split(/\/O=/, $line);
		my ($org)=split(/\//, $a);
		$file_issuer{$md5}=$org;
		#&MaxLength("Issuer", $org);
	} elsif ($line =~ / notAfter=/) {
		my (undef, $date_expire)=split(/notAfter=/, $line);
		$file_expire{$md5}=$date_expire;
		#&MaxLength("Expire", $date_expire);
		&MaxLength("Date", $date_expire." (".$file_issuer{$md5}.")");
	}
}
close(FILE);

my ($port, $pid);
if (! -f "socket.txt") { die "Error - socket.txt not found"; }
open(FILE, "< socket.txt");
while (my $line=<FILE>) {
	$line =~ s/\n//g;
	if ($line =~ / md5sum /) {
		(undef, $port, undef, $pid, undef, $md5)=split(/ /, $line);
		$socket_pid{$pid}=$port;
		$socket_digest{$port}=$md5;
		&MaxLength("Port", $port);
		&MaxLength("PID", $pid);
		#&MaxLength("MD5", $md5);
	} elsif ($line =~ / issuer= /) {
		my (undef, $a)=split(/\/O=/, $line);
		my ($org)=split(/\//, $a);
		$socket_issuer{$md5}=$org;
	} elsif ($line =~ / notAfter=/) {
		my (undef, $date_expire)=split(/notAfter=/, $line);
		$socket_expire{$md5}=$date_expire;
		&MaxLength("Date", $date_expire." (".$socket_issuer{$md5}.")");
	}
}
close(FILE);
################################################################################

my $line;
$line = &StringLine("PID");
$line .= &StringLine("Program");
$line .= &StringLine("Port");
$line .= &StringLine("File");
$line .= &StringLine("Date");
print $line."+\n";
$line = &StringCat("PID", "PID");
$line .= &StringCat("Program", "Program");
$line .= &StringCat("Port", "Port");
$line .= &StringCat("File", "File");
$line .= &StringCat("Date", "Expire Date (Issuer)");
print $line."|\n";
$line = &StringLine("PID");
$line .= &StringLine("Program");
$line .= &StringLine("Port");
$line .= &StringLine("File");
$line .= &StringLine("Date");
print $line."+\n";

foreach my $pid (sort {$a<=>$b} keys %program) {
	my $aa = $socket_pid{$pid};
	my $bb = $socket_digest{$aa};

	$line = &StringCat("PID", $pid);
	$line .= &StringCat("Program", $program{$pid});
	$line .= &StringCat("Port", $socket_pid{$pid});
	$line .= &StringCat("File", $filename{$bb});
	if ($socket_expire{$bb} eq "") {
		$line .= &StringCat("Date", "");
	} else {
		$line .= &StringCat("Date", $socket_expire{$bb}." (".$socket_issuer{$bb}.")");
	}
	print $line."|\n"
}

$line = &StringLine("PID");
$line .= &StringLine("Program");
$line .= &StringLine("Port");
$line .= &StringLine("File");
$line .= &StringLine("Date");
print $line."+\n";

my $chk=0;
foreach my $pid (sort {$a<=>$b} keys %socket_pid) {
	my $aa = $program{$pid};
	if ($aa ne "") { next; }

	$line = &StringCat("PID", "");
	$line .= &StringCat("Program", "");
	$line .= &StringCat("Port", $socket_pid{$pid});
	$line .= &StringCat("File", "");
	$line .= &StringCat("Date", $socket_expire{$aa}." (".$socket_issuer{$aa}.")");
	print $line."|\n";
	$chk=1;
}
if ($chk==1) {
	$line = &StringLine("PID");
	$line .= &StringLine("Program");
	$line .= &StringLine("Port");
	$line .= &StringLine("File");
	$line .= &StringLine("Date");
	print $line."+\n";
}

$chk=0;
foreach my $file (keys %file_fullname) {
	my $chk2=0;
	my $md5=$file_fullname{$file};
	foreach my $pid (keys %socket_digest) {
		if ($socket_digest{$pid} eq $md5) { $chk2=1; last; }
	}
	if ($chk2==1) { next; }

	$line = &StringCat("PID", "");
	$line .= &StringCat("Program", "");
	$line .= &StringCat("Port", "");
	$line .= &StringCat("File", $file);
	$line .= &StringCat("Date", $file_expire{$md5}." (".$file_issuer{$md5}.")");
	print $line."|\n";
	$chk=1;
}
if ($chk==1) {
	$line = &StringLine("PID");
	$line .= &StringLine("Program");
	$line .= &StringLine("Port");
	$line .= &StringLine("File");
	$line .= &StringLine("Date");
	print $line."+\n";
}
