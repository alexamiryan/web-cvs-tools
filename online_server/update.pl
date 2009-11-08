#!/usr/bin/perl
use CGI qw/:standard/;
use CGI::Cookie;

require ("update_config.pl");

$ch_proj=url_param('ch_proj');
if(grep (/^$ch_proj$/,keys(%sites))){
	$cookie1 = new CGI::Cookie(-name=>'proj',-value=>url_param('ch_proj'));
	print header(-cookie=>[$cookie1]);
}
else{
	print header;
}
%cookies = fetch CGI::Cookie;
if(grep (/^$ch_proj$/,keys(%sites))){
	$c_proj=$ch_proj;
}
elsif($cookies{'proj'}){
	$c_proj=$cookies{'proj'}->value;
}

print <<EOF;
<html>
<head>
<meta http-equiv="Content-Language" content="en" />
<meta name="GENERATOR" content="Zend Studio" />
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>$c_proj - CVS Update</title>
</head>
<body bgcolor="#FFFFFF" text="#000000" link="#FF9966" vlink="#FF9966" alink="#FFCC99">
<form action="?" method="GET">
	<select name="ch_proj">
		<option value="">------</option>
EOF
	for(keys(%sites)){
		if((grep (/^$ch_proj$/,keys(%sites)) and url_param('ch_proj') eq $_) or
		   (!grep (/^$ch_proj$/,keys(%sites)) and $cookies{'proj'} and $cookies{'proj'}->value eq $_)){
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


$DEV_DIR = $sites{$proj}{'DEV_DIR'};
$TEST_DIR = $sites{$proj}{'TEST_DIR'};
$SITE_DIR = $sites{$proj}{'SITE_DIR'};

if(url_param('action')){
	if(url_param('action') eq 'update_to_dev'){
		print "Updating...<br>";
		$dev=url_param('dev');
		$bname=url_param('branch_name');
		@out=`cd $DEV_DIR && cvs -q update -d -r $proj-$dev-$bname 2>&1`;
		for(@out){ print "$_<br>"; }
		print "<br><br>Done";
	}
	elsif(url_param('action') eq 'update_to_test'){
		print "Updating...<br>";
		@out=`cd $TEST_DIR && cvs -q update -d -r $proj-stable-current 2>&1`;
		for(@out){ print "$_<br>"; }
		print "<br><br>Done";
	}
	elsif(url_param('action') eq 'copy_to_site'){
		print "Copying...<br>";
		@out=`/bin/cp -aT $TEST_DIR $SITE_DIR 2>&1`;
		`find $SITE_DIR -name CVS -prune -exec rm -rf {} \\; 2>&1`;
		`find $SITE_DIR -name .cvsignore -prune -exec rm -rf {} \\; 2>&1`;
		for(@out){ print "$_<br>"; }
		print "<br><br>Done";
	}
	print '<hr><a href="?">&lt;--Back</a>';
}
elsif($proj){	
	opendir(DIR, $DEV_DIR) or die  "Can't open $dir: $!";
	@files=grep { -f "$DEV_DIR/$_" } readdir(DIR);
	closedir DIR;
	
	@out = `cd $DEV_DIR && cvs status $files[0]`;
	for(@out){
		if(/Sticky Tag:\s*(\S+)/){
			$cur_tag=$1;
			print "Sticky Tag on DEV: <h3>$1</h3><br>";
		}
	}

	print <<EOF;
<br>
<form action="update.pl" method="GET">
	<select name="dev">
EOF
	for(@developers){
		print '<option value="'.$_.'">'.$_.'</option>';
	}
	print <<EOF;
	</select>
	<input type="text" name="branch_name">
	<input type="submit" name="action" value="update_to_dev"><br><br>
	<input type="submit" name="action" value="update_to_test"><br><br>
	<input type="submit" name="action" value="copy_to_site">
</form>
</body>
</html>
EOF
}