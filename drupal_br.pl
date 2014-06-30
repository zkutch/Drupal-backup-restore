#!/usr/bin/perl
#

use warnings; 
use strict;
use File::Copy::Recursive qw(dircopy );
use Cwd;
use POSIX qw(strftime);
$|=1;
# to-do: for check copy status File::Copy::Vigilant 


	my $working_dir = cwd();
	my $dir_origin = "";
	my $dir_destination = ""; 
	my $pg_data_base = "";
	my $working_file = "";
	my $ref_dir_origin = \$dir_origin;
	my $ref_dir_destination= \$dir_destination;
	my $ref_pg_data_base= \$pg_data_base;
	my $ref_working_dir = \$working_dir;
	my $ref_working_file = \$working_file;

if ($>) 
	{
		print "you need run this script as root.\n";
		print "Exiting...\n";
		exit;
	}
	
if ($#ARGV == -1)
	{
		print "\nYou need specify at least one switch..\nType -h for more info.\n\n";
		exit;
	}
if ($#ARGV gt 0)
	{
		print "\nAt begining you shoud specify only one option switch: -b(-bc), -r(-rc), -s or -h.\nType -h for more info.\n\n";
		exit;	
	}
if ($ARGV[0] eq "-b" || $ARGV[0] eq "-bc") 
	{
		backupi();		
	}
if ($ARGV[0] eq "-r" || $ARGV[0] eq "-rc") 
	{
		restorei();		
	}		
if ($ARGV[0] =~ /^-h$/) 
	{
		print "\nNAME\n";
		print "\n\tdrupal_br - make backup and restore (br) of drupal site including database postgres\n";
		print "\nSYNOPSIS\n";
		print "\n\tdrupal_br -h | -b | -bc | -r | -rc | -s\n";
		print "\nDESCRIPTION\n";
		print "\n\tdrupal_br make dump and restore of postgres database and copying drupal files from source to backup directory.\n";
		print "\nOPTIONS\n";
		print "\n\tAt begining you shoud specify only one option switch.\n";
		print "\t-h\tprint this message.\n";
		print "\t-b\tstarts interactively drupal+postgres backup process. In working directory will be created corresponding config file drupal_br.cf";
		print "\n\t-bc\tstarts drupal+postgres backup process using config file";
		print " drupal_br.cfg from working directory.\n";
		print "\t-r\tstarts interactively drupal+postgres restore process. In working directory will be created corresponding config file drupal_br.\n";
		print "\t-rc\tstarts drupal+postgres restore process using config file";
		print " drupal_br.cfg from working directory.\n";
		print "\t-s\tshow postgres ID and existing postgres databases.\n\n";
		print "\nDETAILED DESCRIPTION\n\n";
		print "\n\t\tScript copies all directory structure from ".'$dir_origin'." to ".'$dir_destination'." and change links with original files. For postgres ";
		print "database ".'$pg_data_base'." it creates file ".'$working_file'."  for dump or restore aims.\n\n";
		print "\nFILES\n\n";
		print "\t\tConfig file: it is drupal_br.cfg in script working directory.  -b and -r options create this file interactively, but you can make it by hand also. It have";
		print " delimiter ".'" = "'." and three columns. First two columns are obligatory and need to have in first column";
		print " one of four variables: ".'$dir_origin, $dir_destination, $pg_data_base and $working_file.'." Each variable";
		print " need to have before it letter ".'"b"'." or ".'"r"'." to be used correspondingly in backup or restore operations. ";
		print "In second column you will have variable value and third column is optional. Script write in it date and ";
		print "time. Example of line:\n\n\tb".'$dir_origin'." = /home/mura/drupal1 = 2013-07-26 00:24:22\n\n";
		print "\nAUTHOR\n\n";
		print "\tzkutch\@yahoo.com\n\n";
		exit;		
	}			
if ($ARGV[0] eq "-s")
	{
		print "\n";
		$> = check_user("postgres")  or die "cannot change ".'$EFFECTIVE_USER_ID  or $EUID'.", because error is ".$!;
		system("psql -l");
		print "\n";
		exit;
	}
print "\nAt begining you shoud specify only one option switch: -b(-bc), -r(-rc), -s or -h.\nType -h for more info.\n\n";
exit;	


sub backupi
{	
	print "\n";
		
	if($ARGV[0] eq "-bc")
		{ #reading from configuration
		
			cvladebi_configuraciidan($ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, "b", $ref_working_file);
			
		} #finish reading from configuration
	else 
		{ #start interactive step
		
			cvladebi_interaqtividan($ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, "b", $ref_working_file);
			
		} #finish interactive step
	
	
	# all variables done, start working
	
	direqtoriebis_kopireba($dir_origin, $dir_destination);
	
	my $postgres_id = check_user("postgres");
	
	dumpi_database($pg_data_base, $working_file, $postgres_id);
	print "\n";
	exit;

}


sub restorei
{
	print "\n";
		
	if($ARGV[0] eq "-rc")
		{ #reading from configuration
		
			cvladebi_configuraciidan($ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, "r", $ref_working_file);
			
		} #finish reading from configuration
	else 
		{ #start interactive step
		
			cvladebi_interaqtividan($ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, "r", $ref_working_file);
			
		} #finish interactive step
	
	
	# all variables done, start working
	
	direqtoriebis_kopireba($dir_origin, $dir_destination);
	
	my $postgres_id = check_user("postgres");
	
	restore_database($pg_data_base, $working_file, $postgres_id);
	print "\n";
	exit;
	
}




sub cvladebi_interaqtividan
	{ #working variables $ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, , $ref_working_file
	   #references
		my $answer="";
		my $cfg_exist = 0;
		my $fh;
		if(-e "${$_[0]}/drupal_br.cfg")
			{
				$cfg_exist = 1;
				if (-z "${$_[0]}/drupal_br.cfg")
					{
						open( $fh, ">", "${$_[0]}/drupal_br.cfg") or print "cannot create ${$_[0]}/drupal_br.cfg error is: $!";
						print "\nFile ${$_[0]}/drupal_br.cfg exist and have zero size.\n";
						print "I start writing new configuration to file ${$_[0]}/drupal_br.cfg..\n";
						
					}
				else
					{
						print "\nFile ${$_[0]}/drupal_br.cfg exist and have non-zero size.\nWould you like to overwrite it";
						print "? Press ".'"y"'.", if agree, any other key mean no.\n";
						$answer = <STDIN>;
						chomp($answer);
						if ($answer eq "y")
							{
								open( $fh, ">", "${$_[0]}/drupal_br.cfg") or print "cannot create ${$_[0]}/drupal_br.cfg error is: $!";
								print "I'll write new configuration to file ${$_[0]}/drupal_br.cfg .\n";
							}
						else
							{
								open( $fh, ">>", "${$_[0]}/drupal_br.cfg") or print "cannot create ${$_[0]}/drupal_br.cfg error is: $!";
								print "I'll append new lines to configuration file ${$_[0]}/drupal_br.cfg .\n";
							}
					}
				
				
			}
		else
			{
				print "\nFile ${$_[0]}/drupal_br.cfg not exist.\nWould you like I create new one";
				print "? Press ".'"y"'.", if agree, any other key mean no.\n";
				$answer = <STDIN>;
				chomp($answer);
				if ($answer eq "y")
					{
						open( $fh, ">", "${$_[0]}/drupal_br.cfg") or print "cannot create ${$_[0]}/drupal_br.cfg error is: $!";
						print "I'll write new configuration to file ${$_[0]}/drupal_br.cfg .\n";
						$cfg_exist = 1;
					}
				else
					{
						print "I'll not create configuration file.\n";
						$cfg_exist = 0;
					}
			}
		
			
			print "Please type full path of directory being backup.\n";
			${$_[1]}= <STDIN>;
			chomp(${$_[1]});
			unless(-d ${$_[1]})
				{
					print "\n${$_[1]} directory not exist.\nExiting..\n\n";
					close $fh;
					exit;
				}
			if($cfg_exist)
				{
					print $fh "$_[4]".'$dir_origin'." = ${$_[1]} = ";
					print $fh strftime ("%F %T", localtime $^T), "\n";
					
				}
			print "\nPlease type full path of directory to which write backup.\n";
			${$_[2]}= <STDIN>;
			chomp(${$_[2]});
			if(!(-d ${$_[2]}) and #(-e ${$_[2]}) and 
			(-l ${$_[2]} or -f ${$_[2]} or -p ${$_[2]} or -S ${$_[2]} 
			or -b ${$_[2]} or -c ${$_[2]} or -t ${$_[2]} or -T ${$_[2]} or -B ${$_[2]}))
				{
					print "\n${$_[2]} already exist as some type file.\n";
					print "You need to use diffferent name for directory.\nExiting..\n\n";
					close $fh;
					exit;
				}
			unless( -d ${$_[2]} )
				{
					print "\n${$_[2]} directory not exist.\nShould I create it? Press ".'"y"'.", if agree, any other key mean no.\n";
					$answer = <STDIN>;
					chomp($answer);
					if ($answer eq "y")
						{
							mkdir ${$_[2]} or die "cannot create directory ${$_[2]}, error is: $!";
						}
					else
						{
							print "\nYou need second directory for work.\nExiting..\n";
							close $fh;
							exit;
						}
				}
			else
				{
					print "\n${$_[2]} directory already exist.";
					print "Should I continue? Press ".'"y"'." if agree, any other key mean no.\n";
					$answer = <STDIN>;
					chomp($answer);
					if ($answer  ne "y")
						{
							close $fh;
							exit;
						}
				}
			if($cfg_exist)
				{
					print $fh "$_[4]".'$dir_destination'." = ${$_[2]} = ";
					print $fh strftime ("%F %T", localtime $^T), "\n";
				}
			if(${$_[2]} eq ${$_[1]})
				{
					print "Source directory ${$_[1]} is same as destination directory ${$_[2]}.\nExiting..\n\n ";
					close $fh;
					exit;
				}	
			print "Please enter postgres database name. \n";
				${$_[3]}= <STDIN>;
				chomp(${$_[3]});
				if($cfg_exist)
					{
						print $fh "$_[4]".'$pg_data_base'." = ${$_[3]} = ";
						print $fh strftime ("%F %T", localtime $^T), "\n";
					}
			print "Please type full path for file, which we use for backup. \n";
			${$_[5]}= <STDIN>;
			chomp(${$_[5]});
			unless(-e ${$_[5]})
				{
					print "\n${$_[5]} file does not exist. Would you like I create it? Press ".'"y"'." if agree, any other key mean no.\n";
					$answer = <STDIN>;
					chomp($answer);
					if ($answer  eq "y")
						{
							open( my $file_handle, ">", "${$_[5]}") or print "cannot create ${$_[5]} error is: $!";
							print $file_handle "\n";
							close $file_handle;
						}
					else
						{
							print "Without working file for backup I cannot work.\nExiting..\n\n";
							close $fh;
							exit;
						}
				}
			else
				{
					if(!(-d ${$_[5]}) and  
						(-l ${$_[5]}  or -p ${$_[5]} or -S ${$_[5]} 
						or -b ${$_[5]} or -c ${$_[5]} or -t ${$_[5]}  or -B ${$_[5]}))
						{
							print "\n${$_[5]} already exist as some diffferent type file then you need for backup and may be is useful for something.\n";
							print "You need to use diffferent name for file, which we use for backup.\nExiting..\n\n";
							close $fh;
							exit;
						}
				}
			
			if($cfg_exist)
					{
						print $fh "$_[4]".'$working_file'." = ${$_[5]} = ";
						print $fh strftime ("%F %T", localtime $^T), "\n";
					}	
			close $fh;
		
	}




sub cvladebi_configuraciidan
	{ #working 5 variables references $ref_working_dir, $ref_dir_origin, $ref_dir_destination, $ref_pg_data_base, , $ref_working_file
	   # first letter b is for backup and  r for restory
		unless (-e "${$_[0]}/drupal_br.cfg" || -r "${$_[0]}/drupal_br.cfg" )
			{
				print "configuration file  ${$_[0]}/drupal_br.cfg does not exist or is not readable. Without file for backup I cannot work.\nExit..\n";
				exit;
			}
		open(my $fh, "<", "${$_[0]}/drupal_br.cfg") or die "cannot open ${$_[0]}/drupal_br.cfg error is: $!";
			print "start configuration analysing..\n";
			if (-z "${$_[0]}/drupal_br.cfg")
				{
					print "${$_[0]}/drupal_br.cfg has zero size.\nExiting..\n\n";
					close $fh;
					exit;
				}
			my $i;	
			while  ($i = <$fh>)
				{
					my @a = split(" = ", $i);
					if($a[0] =~ /$_[4]\$dir_origin/)
						{
							${$_[1]} = $a[1];
						}
					
					if($a[0] =~ /$_[4]\$dir_destination/)
						{
							${$_[2]} = $a[1];
						}
					if($a[0] =~ /$_[4]\$pg_data_base/)
						{
							${$_[3]} = $a[1];
						}
					if($a[0] =~ /$_[4]\$working_file/)
						{
							${$_[5]} = $a[1];
						}					
				}
				
			chomp(${$_[1]});
			unless(-d  ${$_[1]})
				{
					print "${$_[1]} is not a directory.\nExiting..\n\n";
					exit;
				}
			if ( ${$_[1]} eq "")
				{
					print "${$_[1]} is not in ${$_[0]}/drupal_br.cfg .\nExiting..\n\n";
					exit;
				}
								
			chomp(${$_[2]});
			if(!(-d ${$_[2]}) and #(-e $dir_destination) and 
			(-l ${$_[2]} or -f ${$_[2]} or -p ${$_[2]} or -S ${$_[2]} 
			or -b ${$_[2]} or -c ${$_[2]} or -t ${$_[2]} or -T ${$_[2]} or -B ${$_[2]}))
				{
					print "\n${$_[2]} already exist as some type file  and may be is useful for something.\n";
					print "You need to use diffferent name for directory.\nExiting..\n\n";
					exit;
				}

			unless(-d ${$_[2]})
				{
					print "${$_[2]} is not a directory.\nExiting..\n\n";
					exit;
				}
								
			chomp(${$_[3]});
			chomp(${$_[5]});
			
			close $fh;
			print "source directory I take: ${$_[1]}\n";
			print "destination directroy I take: ${$_[2]}\n";
			print "postgres database name I take: ${$_[3]}\n";
			print "Working file name I take: ${$_[5]}\n";	
			print "finish configuration analysing.\nDo you like continue with above variables? Press ".'"y"'.", if agree, any other key mean no.\n";
			my $answer = <STDIN>;
			chomp($answer);
			unless ($answer eq "y")
				{
					print "Exit accordingly to user choise..\n\n";
					exit;
				}
		
	}

sub direqtoriebis_kopireba
	{   #variables are 2 directories:  $_[0] source and $_[1] destination, when copy links changes to files(preserve)
		print "\n";
		print "Start copying directory $_[0] to $_[1]\n";
		my $copy_link_old_value = $File::Copy::Recursive::CopyLink;
		if($File::Copy::Recursive::CopyLink) 
			{
				print "Symlinks was set to be preserved,  but now ";
				print "Symlinks is set to be not preserved.\n";
				$File::Copy::Recursive::CopyLink = 0 ;
				print $File::Copy::Recursive::CopyLink == 0," is Symlinks value \n";
				$File::Copy::Recursive::CopyLink == 0 or die "cannot set it to 0, reason: ".$!;
			} 
		else 
			{
			    print "Symlinks will not be preserved because your system does not support it\n";
			}
		
		my($num_of_files_and_dirs, $num_of_dirs, $depth_traversed) = dircopy($_[0], $_[1]) or die "dircopy error is: $!";
		print "num_of_files_and_dirs = $num_of_files_and_dirs\n";
		print "num_of_dirs = $num_of_dirs\n";
		print "depth_traversed = $depth_traversed\n";
		print "Finish copying directory $_[0] to $_[1]\n";
		print "\n";
		$File::Copy::Recursive::CopyLink = $copy_link_old_value ;
	}


sub check_user
	{ #variable $_[0] user name, check if exist in /etc/passwd
		
	my $etc_passwd = '/etc/passwd';
	open(FILE, $etc_passwd) or die "Could not read from $etc_passwd, program halting.";
	my @login; my $s = "";
	while(<FILE>)
		{
			 @login  = split(':', $_);
			 if($login[0] =~ m/^$_[0]$/)
				{
					$s = $login[0] ;
					last;		
				}
		}
	close FILE;
	if ($s eq "")
		{			
			print "Not found $_[0] user. Stopped. \n";
			exit;
		}
	print "on this comp $_[0] id is ".$login[2]."\n";
	return $login[2];
	}




sub dumpi_database
	{ # variables $pg_data_base, $working_file, $postgres_id  in $_[0], $_[1], $_[2]-ში
		my $answer;
		unless(-e $_[1])
			{
				print "\n$_[1] file does not exist. Would you like I create it? Press ".'"y"'." if agree, any other key mean no.\n";
				$answer = <STDIN>;
				chomp($answer);
				 if ($answer  eq "y")
				         {        
				         	open( my $file_handle, ">", "$_[1]") or print "cannot create $_[1] error is: $!";
				                close $file_handle;
				          }      
				  else       
					{        
						print "Without working file for backup I cannot work.\nExiting..\n\n";
					        exit;
					 }
			}
		
		
		chmod 0666, $_[1];
		$> =  $_[2] or die "cannot change ".'$EFFECTIVE_USER_ID  or $EUID'.", because error is ".$!;
		system("psql -l > /dev/null");
		my $s1 =`psql -l `; #|  awk -F "|"  '{ print $s2 }' `;
		if ($?)
			{
				print "\nWhile execute psql as user $_[2] error code is: $?.\nExiting..\n";
				$> = 0;
				exit;
			}
		my @name; my $s2;
		my @login  =  split("\n", $s1);
		for (1..3) {shift(@login);}
		pop(@login);
		for (0..$#login)
			{
				@name = split(" | ", $login[$_]);
				if($name[1] =~ m/^$_[0]$/)
					{
						$s2 = $name[1] ;
						last;		
					}
			}
		if (!$s2)
			{
				print "There is not $_[0] database in postgres. Exiting.. \n"; 
				$> = 0;
				chmod 0644, $_[1];
				exit;
			}
		print "There is database $s2 in postgres.\n";
		chmod 0777, $_[1];
		open( my $file_handle, ">", "$_[1]") or print "cannot create $_[1] error is: $!";
		system("pg_dump  $_[0] > $_[1]");
		close $file_handle; 
		  if ($?)
			{
				print "\nWhile execute pg_dump as user $_[2] error code is: $?.\nExiting..\n";
				$> = 0;
				exit;
			}
		$> = 0;
		chmod 0644, $_[1];
		if (-e $_[1])
			{
				print "Finish dump database $_[0].\n"; 
			}
		else
			{
				print "Something is wrong with dump database $_[0].\n"; 
			}
		print "\n";
	}



sub restore_database
	{ # variables $pg_data_base, $working_file, $postgres_id in $_[0], $_[1], $_[2]
		my $answer; 
		$> =  $_[2] or die "cannot change ".'$EFFECTIVE_USER_ID  or $EUID'.", because error is ".$!;
		my $s1 =`psql -l `; #|  awk -F "|"  '{ print $s2 }' `;
		my @name; my $s2;
		my @login  =  split("\n", $s1);
		for (1..3) {shift(@login);}
		pop(@login);
		for (0..$#login)
			{
				@name = split(" | ", $login[$_]);
				if($name[1] =~ m/^$_[0]$/)
					{
						$s2 = $name[1] ;
						last;		
					}
			}
		if (!$s2)
			{
				print "\n$_[0] database not exist.\nShould I create it? Press ".'"y"'.", if agree, any other key mean no.\n";
				$answer = <STDIN>;
				chomp($answer);
				if ($answer eq "y")
					{
							system("createdb $_[0]"); #or die "cannot create $_[0] database, error is: $!";
							if ($?)
								{
									print "\nCannot create $_[0] database, error code is: $?.\nExiting..\n";
									$> = 0;
									exit;
								}
					}
				else
					{
							print "\nYou choose not to create database.\nExiting..\n";
							$> = 0;
							exit;
					}
								
			}
		else
			{
				print "There is database $s2 in postgres.\n";
				print "Would you like to restore directly in it? Press ".'"y"'.", if agree, any other key mean no.\n";
				$answer = <STDIN>;
				chomp($answer);
				unless($answer eq "y")
					{
						print "Would you like to drop  $_[0] database and create again it first? Press ".'"y"'.", if agree, any other key mean no.\n";
						$answer = <STDIN>;
						chomp($answer);
						if($answer eq "y")
							{
								system("dropdb -w $_[0] ");
								if ($?)
									{
										print "\nCannot  drop $_[0] database, error code is: $?.\nExiting..\n";
										$> = 0;
										exit;
									}
								system("createdb -w $_[0] ");
								if ($?)
									{
										print "\nCannot  create $_[0] database, error code is: $?.\nExiting..\n";
										$> = 0;
										exit;
									}
							}
						else
							{
								print "\nYou do not want to drop $_[0] database and you do not want to work with existing one.\n";
								print "Please, decide firstly what you want and then start this script again.\nExiting..\n\n";
								$> = 0;
								exit;
							}
					}
			}
		
		unless (-e "$_[1]")
			{
				print "There is not  file $_[1]  for restore. Exiting.. \n"; 
				$> = 0;
				exit;
			}
		print "There is file $_[1]  for restore.\nStart restoring.. .\n"; 
		system("psql $_[0] < $_[1]"); #or die "cannot restore $_[0] database, error is: $!";
		if ($?)
			{
				print "\nCannot  restore $_[0] database, error code is: $?.\nExiting..\n";
				$> = 0;
				exit;
			}
		$> = 0;
		print "Finish restore database $_[0].\n"; 
		print "\n";
		
	}

