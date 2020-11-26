"""
Daemonize a process.

Based on: http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
Taken from: https://github.com/WIPACrepo/iceprod/blob/master/iceprod/server/daemon.py
"""
import sys
import os
import time
import atexit
import signal
from builtins import str

class Daemon(object):
    """
    A generic daemon class.
    
    Usage:
      d=Daemon(pidfile - filename for pidfile (required)
               runner - function to execute in daemon (required)
               stdin - input filename (default is /dev/null)
               stdout - output filename (default is /dev/null)
               stderr - error filename (default is /dev/null)
               chdir - working directory (default is /)
               umask - umask of new files (default is 0)
              )
      d.start()
      d.stop()
      d.kill()
    """
    def __init__(self, pidfile, runner,
                 stdin='/dev/null',
                 stdout='/dev/null',
                 stderr='/dev/null',
                 chdir='/',
                 umask=0):
        if not isinstance(pidfile, str):
            raise Exception('pidfile is not a string')
        if not callable(runner):
            raise Exception('runner is not callable')
        self.pidfile = pidfile
        self.runner = runner
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.chdir = chdir
        self.umask = umask

    def _daemonize(self):
        """
        do the UNIX double-fork magic, see Stevens' "Advanced 
        Programming in the UNIX Environment" for details (ISBN 0201563177)
        http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
        """
        try: 
            pid = os.fork() 
            if pid > 0:
                # exit first parent
                sys.exit(0) 
        except OSError as e: 
            sys.stderr.write("fork #1 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1)
    
        # decouple from parent environment
        os.chdir(self.chdir) 
        os.setsid() 
        os.umask(self.umask) 
    
        # do second fork
        try: 
            pid = os.fork() 
            if pid > 0:
                # exit from second parent
                sys.exit(0) 
        except OSError as e: 
            sys.stderr.write("fork #2 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1) 
    
        # redirect standard file descriptors
        sys.stdout.flush()
        sys.stderr.flush()
        si = open(self.stdin, 'rb')
        so = open(self.stdout, 'ab+')
        se = open(self.stderr, 'ab+', 0)
        os.dup2(si.fileno(), sys.stdin.fileno())
        os.dup2(so.fileno(), sys.stdout.fileno())
        os.dup2(se.fileno(), sys.stderr.fileno())
    
        # write pidfile
        atexit.register(self.delpid)
        pid = str(os.getpid())
        pgrp = str(os.getpgrp())
        open(self.pidfile,'w+').write("%s %s\n" % (pid,pgrp))

    def _sendsignal(self,pid,sig,waitfordeath=True):
        """Send the specified signal to the process"""
        try:
            os.kill(pid, sig)
            if waitfordeath:
                for _ in range(10):
                    time.sleep(1)
                    os.kill(pid, sig)
                return False
        except OSError as err:
            err = str(err)
            if 'No such process' in err:
                self.delpid()
            else:
                sys.stdout.write("OSError: %s\n" % err)
                sys.exit(1)
        return True

    def _sendsignalgrp(self,pid,sig,waitfordeath=True):
        """Send the specified signal to the process group"""
        try:
            os.killpg(pid, sig)
            if waitfordeath:
                for _ in range(10):
                    time.sleep(1)
                    os.killpg(pid, sig)
                return False
        except OSError as err:
            err = str(err)
            if 'No such process' in err:
                self.delpid()
            else:
                sys.stdout.write("OSError: %s\n" % err)
                sys.exit(1)
        return True

    def delpid(self):
        if os.path.exists(self.pidfile):
            sys.stdout.write("Deleting pidfile\n")
            os.remove(self.pidfile)

    def getpid(self):
        """Get the pid from the pidfile"""
        try:
            pf = open(self.pidfile,'r')
            pid,pgrp = [int(x.strip()) for x in pf.read().split()]
            pf.close()
        except IOError:
            pid = None
            pgrp = None
        return (pid,pgrp)

    def start(self):
        """Start the daemon"""
        pid,pgrp = self.getpid()
        if pid:
            message = "pidfile %s already exist. Daemon already running?"
            raise Exception(message % self.pidfile)
        
        # Start the daemon
        self._daemonize()
        self.runner()

    def stop(self):
        """Stop the daemon"""
        pid,pgrp = self.getpid()
        if not pid:
            message = "pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return
        if not self._sendsignal(pid,signal.SIGINT):
            sys.stdout.write('SIGINT failed, try SIGQUIT\n')
            if not self._sendsignalgrp(pgrp,signal.SIGQUIT):
                sys.stdout.write('SIGQUIT failed, try SIGKILL\n')
                self._sendsignalgrp(pgrp,signal.SIGKILL)

    def kill(self):
        """Kill the daemon"""
        pid,pgrp = self.getpid()
        if not pid:
            message = "pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return
        if not self._sendsignal(pid,signal.SIGQUIT):
            self._sendsignalgrp(pgrp,signal.SIGTERM)

    def hardkill(self):
        """Kill the daemon"""
        pid,pgrp = self.getpid()
        if not pid:
            message = "pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return
        self._sendsignalgrp(pgrp,signal.SIGKILL)

    def restart(self):
        """Restart the daemon"""
        self.stop()
        self.start()

