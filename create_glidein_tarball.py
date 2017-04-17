"""
Create a glidein tarball by downloading the source, building it, then
copying what is needed into the tarball.
"""

import sys
import os
import stat
import shutil
import subprocess
import tarfile
import tempfile

if sys.version_info[0] < 3 and sys.version_info[1] < 7:
    raise Exception('requires python 2.7+')

def libuuid_download(version='1.0.3'):
    url = 'http://downloads.sourceforge.net/project/libuuid/libuuid-'+version+'.tar.gz'
    subprocess.check_call(['wget', url])
    subprocess.check_call(['tar', '-zxf', 'libuuid-'+version+'.tar.gz'])
    return 'libuuid-'+version

def libuuid_build():
    """Build uuid statically"""
    dirname = libuuid_download()
    initial_dir = os.getcwd()
    os.chdir(dirname)
    try:
        if os.path.exists('release_dir'):
            shutil.rmtree('release_dir')
        os.mkdir('release_dir')
        options = ['--enable-static',
                   '--disable-shared',
                   '--prefix',os.path.join(initial_dir,dirname,'release_dir'),
                  ]
        subprocess.check_call(['./configure']+options)
        subprocess.check_call(['make'])
        subprocess.check_call(['make','install'])
        return os.path.join(initial_dir,dirname,'release_dir')
    finally:
        os.chdir(initial_dir)

def cvmfs_download():
    url = 'https://github.com/cvmfs/cvmfs/archive/cvmfs-2.3.5.tar.gz'
    #url = 'https://github.com/cvmfs/cvmfs/archive/libcvmfs-stable.tar.gz'
    subprocess.check_call(['wget', url])
    subprocess.check_call(['tar', '-zxf', 'cvmfs-2.3.5.tar.gz'])
    return 'cvmfs-cvmfs-2.3.5'

def cvmfs_build():
    libuuid = libuuid_build()
    dirname = cvmfs_download()
    initial_dir = os.getcwd()
    os.chdir(dirname)
    try:
        if os.path.exists('release_dir'):
            shutil.rmtree('release_dir')
        os.mkdir('release_dir')
        options = ['-Wno-dev',
                   '-DINSTALL_MOUNT_SCRIPTS=OFF',
                   '-DBUILD_SERVER=OFF',
                   '-DBUILD_CVMFS=OFF',
                   '-DBUILD_LIBCVMFS=ON',
                   '-DINSTALL_BASH_COMPLETION=OFF',
                   '-DUUID_LIBRARY:FILE='+os.path.join(libuuid,'lib','libuuid.a'),
                   '-DUUID_INCLUDE_DIR:PATH='+os.path.join(libuuid,'include'),
                   '-DCMAKE_INSTALL_PREFIX='+os.path.join(os.getcwd(),'release_dir'),
                  ]
        subprocess.check_call(['cmake']+options)
        subprocess.check_call(['make','libpacparser'])
        os.chdir('cvmfs')
        subprocess.check_call(['make'])
        subprocess.check_call(['make','install'])
        return os.path.join(initial_dir,dirname,'release_dir')
    finally:
        os.chdir(initial_dir)

def parrot_download(version):
    url = 'http://ccl.cse.nd.edu/software/files/cctools-'+version+'-source.tar.gz'
    subprocess.check_call(['wget', url])
    subprocess.check_call(['tar', '-zxf', 'cctools-'+version+'-source.tar.gz'])
    return 'cctools-'+version+'-source'

def parrot_build(version='6.0.14'):
    cvmfs = cvmfs_build()
    dirname = parrot_download(version)
    initial_dir = os.getcwd()
    os.chdir(dirname)
    try:
        if os.path.exists('release_dir'):
            shutil.rmtree('release_dir')
        os.mkdir('release_dir')
        options = ['--without-system-sand',
                   '--without-system-allpairs',
                   '--without-system-wavefront',
                   '--without-system-makeflow',
                   #'--without-system-ftp-lite',
                   #'--without-system-chirp',
                   '--without-system-umbrella',
                   '--without-system-resource_monitor',
                   '--without-system-doc',
                   '--with-cvmfs-path',cvmfs,
                   '--prefix',os.path.join(os.getcwd(),'release_dir'),
                  ]
        subprocess.check_call(['./configure']+options)
        subprocess.check_call(['make'])
        subprocess.check_call(['make','install'])
        return os.path.join(initial_dir,dirname,'release_dir')
    finally:
        os.chdir(initial_dir)

def condor_download(version):
    version = version.replace('.','_')
    url = 'https://github.com/htcondor/htcondor/archive/V'+version+'.tar.gz'
    subprocess.check_call(['wget', url])
    subprocess.check_call(['tar', '-zxf', 'V'+version+'.tar.gz'])
    return 'htcondor-'+version

def condor_build(version='8.6.1'):
    dirname = condor_download(version)
    initial_dir = os.getcwd()
    os.chdir(dirname)
    try:
        if os.path.exists('release_dir'):
            shutil.rmtree('release_dir')
        os.mkdir('release_dir')
        # skip boost forcefully
        boost_cmakelists = 'externals/bundles/boost/1.49.0/CMakeLists.txt'
        lines = open(boost_cmakelists).read()
        with open(boost_cmakelists,'w') as f:
            for line in lines.split('\n'):
                if line.startswith('if (NOT PROPER)'):
                    f.write('if (FALSE)\n')
                else:
                    f.write(line+'\n')
        options = [
            '-DPROPER=OFF',
            '-DCMAKE_SKIP_RPATH=ON',
            '-DDLOPEN_SECURITY_LIBS=FALSE',
            '-DHAVE_SHARED_PORT=OFF',
            '-DHAVE_BACKFILL=OFF',
            '-DHAVE_BOINC=OFF',
            '-DHAVE_HIBERNATION=OFF',
            '-DHAVE_KBDD=OFF',
            '-DWANT_GLEXEC=OFF',
            '-DWANT_FULL_DEPLOYMENT=OFF',
            '-DWITH_BOINC=OFF',
            '-DWITH_BOSCO=OFF',
            '-DWITH_CAMPUSFACTORY=OFF',
            '-DWITH_BLAHP=OFF',
            '-DWITH_CURL=OFF',
            '-DWITH_COREDUMPER=OFF',
            '-DWITH_CREAM=OFF',
            '-DWITH_GANGLIA=OFF',
            '-DWITH_GLOBUS=ON',
            '-DWITH_GSOAP=OFF',
            '-DWITH_VOMS=OFF',
            '-DWITH_HADOOP=OFF',
            '-DWITH_LIBCGROUP=OFF',
            '-DWITH_POSTGRESQL=OFF',
            '-DWITH_LIBDELTACLOUD=OFF',
            '-DWITH_LIBVIRT=OFF',
            '-DWITH_PYTHON_BINDINGS=OFF',
            '-DWITH_UNICOREGAHP=OFF',
            '-DWITH_QPID=OFF',
            '-DWITH_WSO2=OFF',
        ]
        if version > '8.5.2':
            options.append('-DWITH_KRB5=OFF')
        subprocess.check_call(['cmake','-DCMAKE_INSTALL_PREFIX:PATH='+os.getcwd()+'/release_dir']
                              +options+['.'])
        subprocess.check_call(['make'])
        subprocess.check_call(['make','install'])
        return os.path.join(initial_dir,dirname,'release_dir')
    finally:
        os.chdir(initial_dir)

def main():
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option('--template-dir',dest='template',default='glidein_template',
                      help='Location of template directory')
    parser.add_option('--htcondor-version',dest='condor',default=None,
                      help='HTCondor version to use')
    parser.add_option('--parrot-version',dest='parrot',default=None,
                      help='Parrot (cctools) version to use')
    parser.add_option('-o','--output',dest='output',default='glidein.tar.gz',
                      help='output tarball name')
    (options, args) = parser.parse_args()
    if not options.template:
        raise Exception('need a template directory')
    options.template = os.path.abspath(options.template)

    curdir = os.getcwd()
    d = tempfile.mkdtemp(dir=os.getcwd())
    tarfile_name = os.path.abspath(os.path.expandvars(os.path.expanduser(options.output)))
    try:
        os.chdir(d)
        parrot_opts = {}
        if options.parrot:
            parrot_opts['version'] = options.parrot
        parrot_path = parrot_build(**parrot_opts)
        condor_opts = {}
        if options.condor:
            condor_opts['version'] = options.condor
        condor_path = condor_build(**condor_opts)
        with tarfile.open(tarfile_name,'w:gz') as tar:
            for f in os.listdir(options.template):
                path = os.path.join(options.template,f)
                if not os.path.isdir(path):
                    os.chmod(path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
                tar.add(path,arcname=f)
            tar.add('.',arcname='glideinExec',recursive=False)
            for f in os.listdir(condor_path):
                tar.add(os.path.join(condor_path,f),arcname=os.path.join('glideinExec',f))
            tar.add(os.path.join(parrot_path,'bin','parrot_run'),arcname=os.path.join('GLIDEIN_PARROT','parrot_run'))
            tar.add(os.path.join(parrot_path,'lib','libparrot_helper.so'),arcname=os.path.join('GLIDEIN_PARROT','libparrot_helper.so'))
    finally:
        os.chdir(curdir)
        shutil.rmtree(d)

if __name__ == '__main__':
    main()
