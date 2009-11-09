#!/usr/bin/perl
#
# merge.pl - Merge tool
# Copyright (C) 2008 Alex Amiryan
#
# This file is part of Web-CVS-Tools
#
# Web-CVS-Tools is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Web-CVS-Tools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#

use CGI qw/:standard/;
use CGI::Cookie;
use POSIX qw(tmpnam);

require ("../work_config_global.pl");
require ("config.pl");

$ch_proj=url_param('ch_proj');
if(grep (/^$ch_proj$/,@projects)){
	$cookie1 = new CGI::Cookie(-name=>'proj',-value=>url_param('ch_proj'));
	print header(-cookie=>[$cookie1]);
}
else{
	print header;
}
%cookies = fetch CGI::Cookie;

$proj='';
$cur_tag='';

print <<EOF;
<html>
<head>
<meta http-equiv="Content-Language" content="en" />
<meta name="GENERATOR" content="Zend Studio" />
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>CVS Merge</title>
</head>
<body bgcolor="#FFFFFF" text="#000000" link="#FF9966" vlink="#FF9966" alink="#FFCC99">
<form action="?" method="GET">
	<select name="ch_proj">
		<option value="">------</option>
EOF
	for(@projects){
		if((grep (/^$ch_proj$/,@projects) and url_param('ch_proj') eq $_) or
		   (!grep (/^$ch_proj$/,@projects) and $cookies{'proj'} and $cookies{'proj'}->value eq $_)){
			print '<option value="'.$_.'" selected>'.$_.'</option>';
			$proj=$_;
		}
		else{
			print '<option value="'.$_.'">'.$_.'</option>';
		}
	}
	print <<EOF;
	</select>
	<input type="submit" value="Change">
</form>
<center><h1>$proj</h1></center>
EOF

$dir=$WORK_DIR . $proj . '/';
if(url_param('action')){
	if(url_param('action') eq 'merge' and url_param('number') and url_param('dev')){
		my $number=url_param('number');
		my $dev=url_param('dev');
		
		print "<br>Updating project...<br><br>";
		@out = `cd $dir && cvs -q update -d -A`;
		for(@out){ print "$_<br>"; }
		
		if(url_param('update')){
			my $tmp_dir = POSIX::tmpnam();
			mkdir($tmp_dir,0777);
			
			print "Tmp dir is $tmp_dir<br>";
			$tag_ex=1;
			print "<br>Exporting tmp project...<br><br>";
			@out = `cd $tmp_dir && cvs -q checkout -r $proj-$dev-$number $proj 2>&1 1>/dev/null`;
			for(@out){
				print "$_<br>";
				if(/no such tag/){
					print "<br>No such TAG!!!<br>";
					exit;
				}
			}
			print "<br>Merging differences...<br><br>";
			$conflict=0;
			@out = `cd $tmp_dir/$proj && cvs -q update -d -j $proj-stable-current 2>&1`;
			$confl=0;
			for(@out){
				print "$_<br>";
				if(/nonmergeable file needs merge/){
					$confl=1;
				}
				elsif(/^C\s*\S+/ or /conflicts during merge/){
					if($confl==1){
						$confl=0;
					}
					else{
						print "<br><br>There is a conflict!!!";
						exit;
					}
				}
			}
			print "<br>Commiting...<br><br>";
			@out = `cd $tmp_dir/$proj && cvs -q commit -m "Updated with latest stable" 2>&1`;
			for(@out){
				print "$_<br>";
				if(/commit aborted/){
					print "<br><br>Commit aborted!!!";
					exit 0;
				}
			}
		}
		print "<br>Joining branch to HEAD...<br><br>";
		@out = `cd $dir && cvs -q update -d -j $proj-$dev-$number 2>&1`;
		$confl=0;
		for(@out){
			if(/no such tag/){
				print "<br>No such TAG!!!<br>";
				exit;
			}
			elsif(/nonmergeable file needs merge/){
				$confl=1;
			}
			elsif(/^C\s*\S+/){
				if($confl==1){
					$confl=0;
				}
				else{
					print "<br><br>There is a conflict!!!";
					exit;
				}
			}
			print "$_<br>";
		}
		print "<br>Commiting...<br><br>";
		@out = `cd $dir && cvs -q commit -m "joined $proj-$dev-$number" 2>&1`;
		for(@out){
			print "$_<br>";
			if(/commit aborted/){
				print "<br><br>Commit aborted";
				exit 0;
			}
		}
		
		print "<br>Tagging as merged...<br><br>";
		@out = `cd $dir && cvs -q rtag -F -r $proj-$dev-$number $proj-$dev-$number-merged $proj 2>&1`;
		for(@out){ print "$_<br>"; }
		
		print "<br>Tagging stable version history...<br><br>";
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
		$dt=$year.'-'.$mon.'-'.$mday.'_'.$hour.'-'.$min.'-'.$sec;
		@out = `cd $dir && cvs -q rtag -r HEAD $proj-stable-$dt $proj 2>&1`;
		for(@out){ print "$_<br>"; }
		
		print "<br>Tagging stable-current...<br><br>";
		@out = `cd $dir && cvs -q rtag -F -r HEAD $proj-stable-current $proj 2>&1`;
		for(@out){ print "$_<br>"; }
		
		if(url_param('update')){
			print "<br>Removing tmp dir...<br><br>";
			@out = `/bin/rm -Rf $tmp_dir 2>&1`;
			for(@out){ print "$_<br>"; }
		}
	}
	elsif(url_param('action') eq 'commit'){
		print "<br>Commiting...<br>";
		@out = `cd $dir && cvs commit -m "manualy commited"`;
		for(@out){ print "$_<br>"; }
		
		print "<br>Tagging stable version history...<br>";
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
		$dt=$year.'-'.$mon.'-'.$mday.'_'.$hour.'-'.$min.'-'.$sec;
		@out = `cd $dir && cvs rtag -r HEAD $proj-stable-$dt $proj`;
		for(@out){ print "$_<br>"; }
		
		print "<br>Tagging stable-current...<br>";
		@out = `cd $dir && cvs rtag -F -r HEAD $proj-stable-current $proj`;
		for(@out){ print "$_<br>"; }
	}
	print '<br><h2>Done</h2><br><hr><a href="?">&lt;--Back</a>';
}
else{
	print <<EOF;
<br>
<form action="?" method="GET">
	<select name="dev">
EOF
	for(@developers){
		print '<option value="'.$_.'">'.$_.'</option>';
	}
	print <<EOF;
	</select>
	<input type="text" name="number"><br>
	Update before merge <input type="checkbox" name="update" checked>
	<input type="submit" name="action" value="merge"><br><br>
	<input type="submit" name="action" value="commit">
</form>
</body>
</html>
EOF
}