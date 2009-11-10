#
# update_config.pl - online update config file
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