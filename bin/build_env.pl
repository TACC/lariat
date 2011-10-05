#!/usr/bin/perl 
#---------------------------------------------------------
# Derive the user environment and strip out a 
# couple of key elements (to pass along to MVAPICH later).
#
# ks 5/3/06
#
# Now includes string size for calling routine.
# Size is returned as first keypair with TACC_ENVLEN key.
# See loop to remove environment variables with NULL.
#
# km 5/4/06
#
# Removed module, include, and manpath information.
# Included method to remove variables of any specific prefix.
# e.g. Compiler variables, ICC_, IFC_ and IDB_.
#
# km 8/31/06
#
#---------------------------------------------------------

$varenv = '';
@env_exclude_list = qw(PWD PS1 HOME SSH_CLIENT SSH_CONNECTION HOST TERM SSH_AUTH_SOCK SSH_TTY SHLVL LSB_MCPU_HOSTS LSB_HOSTS LSF_PM_HOSTIDS LSB_EEXEC_REAL_GID LSB_JOBRES_PID INFOPATH _LMFILES_ LOADEDMODULES LOCAL_MODULES_DIR MODULEPATH _MODULESBEGINENV_ MODULESHOME  MODULE_VERSION MODULE_VERSION_STACK INCLUDE MANPATH  LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me LESS_TERMCAP_se LESS_TERMCAP_so LESS_TERMCAP_ue LESS_TERMCAP_us ARCHIVER REMOTEHOST XTERM_VERSION);
#$env_begin_with = '(^TACC_|^ICC_|^IFC_|^IDDB_|^CVS)';
 $env_begin_with =       '( ^ICC_|^IFC_|^IDDB_)';

# TACC change: propogate entire user environment. (1/9/04)

my %exclude;
foreach (@env_exclude_list) { $exclude{$_} = 1; }

foreach (keys %ENV) {
    unless ($exclude{$_} || $_ =~  /$env_begin_with/ || $ENV{$_} =~ m/[ \n\t;*]/) { $varenv .= " $_=\"$ENV{$_}\" ";}
}

# Report length of environment string, in the reported environment 
# with the TACC_ENVLEN variable.

$base_size = length($varenv);
$num_size  = length($base_size);
$add_size  = $base_size + 12 + $num_size;
$varenv  = "TACC_ENVLEN=$add_size" . $varenv;

print "$varenv";
