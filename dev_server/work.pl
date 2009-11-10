#!/usr/bin/perl
#
# work.pl - Main script for developers
# Copyright (C) 2008,2009 Alex Amiryan
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

require ("../work_config_global.pl");

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
<title>$user - CVS Admin</title>
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
opendir(DIR, $dir) or die  "Can't open $dir: $!";
@files=grep { -f "$dir/$_" } readdir(DIR);
closedir DIR;

@out = `cd $dir && cvs status -v $files[0]`;
$trigger=0;
@tags=();
for(@out){
	if($trigger==1){
		if(/\s*(\S+)\s*/){
			push(@tags,$1);
		}
	}
	if(/Sticky Tag:\s*(\S+)/){
		$cur_tag=$1;
		print "Sticky Tag: <h3>$1</h3><br>";
	}
	if(/Existing Tags:/){
		$trigger=1;
	}
}
if(url_param('action')){
	if(url_param('action') eq 'start_new' and url_param('new_name')){
		print "<br>Creating branch...<br><br>";
		my $name=url_param('new_name');
		@out = `cd $dir && cvs -q rtag -B -b -F -r $proj-stable-current $proj-$user-$name $proj 2>&1`;
		for(@out){ print "$_<br>"; }
		
		print "<br>Moving to branch...<br><br>";
		@out = `cd $dir && cvs -q update -d -r $proj-$user-$name 2>&1`;
		for(@out){ print "$_<br>"; }
	}
	elsif(url_param('action') eq 'move_to' and url_param('move_tag')){
		print "<br>Moving to tag...<br><br>";
		my $tag=url_param('move_tag');
		@out = `cd $dir && cvs -q update -d -C -r $tag 2>&1`;
		for(@out){ print "$_<br>"; }
	}
	elsif(url_param('action') eq 'delete' and url_param('move_tag')){
		my $tag=url_param('move_tag');
		if($tag eq $cur_tag){
			print "<br>Updating project...<br><br>";
			@out = `cd $dir && cvs -q update -d -A 2>&1`;
			for(@out){ print "$_<br>"; }
		}
		print "<br>Deleting branch tag...<br><br>";
		@out = `cd $dir && cvs -q tag -B -d $tag`;
		for(@out){ print "$_<br>"; }
	}
	elsif(url_param('action') eq 'update_current'){
		print "<br>Updating...<br><br>";
		my $name=url_param('new_name');
		@out = `cd $dir && cvs -q update -d -j $proj-stable-current 2>&1`;
		$confl=0;
		for(@out){
			print "$_<br>";
			if(/nonmergeable file needs merge/){
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
		}
		
		print "<br>Commiting...<br><br>";
		@out = `cd $dir && cvs -q commit -m "Updated with latest stable" 2>&1`;
		for(@out){
			print "$_<br>";
			if(/commit aborted/){
				print "<br><br>Commit aborted!!!";
				exit;
			}
		}
	}
	print '<br><h2>Done</h2><br><hr><a href="?">&lt;--Back</a>';
}
else{
	print <<EOF;
<br>
<form action="?" method="GET">
	<input type="text" name="new_name">
	<input type="submit" name="action" value="start_new"><br><br>
	<input type="submit" name="action" value="update_current"><br><br>
	<select name="move_tag">
		<option value="">------</option>
EOF
	for(@tags){
		if(/^$proj-$user-/ and !/\-merged$/){
			print '<option value="'.$_.'">'.$_.'</option>';
		}
	}
	print <<EOF;
	</select>
	<input type="submit" name="action" value="move_to">
	<input type="submit" name="action" value="delete"><br><br>
</form>
</body>
</html>
EOF
}