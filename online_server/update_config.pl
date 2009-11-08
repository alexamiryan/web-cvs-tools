# Array of the available sites.
%sites=('mysite'=>{
            'TEST_DIR'=>'/home/mysite_test/',
            'DEV_DIR'=>'/home/mysite_dev/',
            'SITE_DIR'=>'/home/mysite/'},
        'mysite2'=>{
            'TEST_DIR'=>'/home/mysite2_test/',
            'DEV_DIR'=>'/home/mysite2_dev/',
            'SITE_DIR'=>'/home/mysite2/'}
       );

# CVSROOT, have to point to dev server's CVSROOT
$ENV{'CVSROOT'} = ':ext:user@devserver.example.com:/www/cvs';
$ENV{'CVS_RSH'} = 'ssh';

# List of developers
@developers=('mike', 'john', 'karl');