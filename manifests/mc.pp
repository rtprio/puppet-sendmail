# = Class: sendmail::mc
#
# Manage the sendmail.mc file
#
# == Parameters:
#
# [*ostype*]
#   The value for the OSTYPE macro in the sendmail.mc file.
#   Default value: operating system specific.
#
# [*sendmail_mc_domain*]
#   The name of the m4 file that holds common data for a domain. This is an
#   optional configuration item. It may be used by large sites to gather
#   shared data into one file. Some Linux distributions (e.g. Debian) use
#   this setting to provide defaults for certain features.
#   Default value: operating system specific.
#
# [*cf_version*]
#   The configuration version string for Sendmail. This string will be
#   appended to the Sendmail version in the HELO message. If unset, no
#   configuration version will be used.
#   Default value: undef.
#
# [*smart_host*]
#   Servers that are behind a firewall may not be able to deliver mail
#   directly to the outside world. In this case the host may need to forward
#   the mail to the gateway machine defined by this parameter. All nonlocal
#   mail is forwarded to this gateway.
#   Default value: undef.
#
# [*log_level*]
#   The loglevel for the sendmail process.
#   Valid options: a numeric value. Default value: undef.
#
# [*dont_probe_interfaces*]
#   Sendmail normally probes all network interfaces to get the hostnames that
#   the server may have. These hostnames are then considered local. This
#   option can be used to prevent the reverse lookup of the network addresses.
#   If this option is set to 'localhost' then all network interfaces except
#   for the loopback interface is probed.
#   Valid options: the strings 'true', 'false' or 'localhost'.
#   Default value: undef.
#
# [*enable_ipv4_daemon*]
#   Should the host accept mail on all IPv4 network adresses.
#   Valid options: 'true' or 'false'. Default value: 'true'.
#
# [*enable_ipv6_daemon*]
#   Should the host accept mail on all IPv6 network adresses.
#   Valid options: 'true' or 'false'. Default value: 'true'.
#
# [*mailers*]
#   An array of mailers to add to the configuration.
#   Default value: [ 'smtp', 'local' ]
#
# [*trust_auth_mech*]
#   The value of the TRUST_AUTH_MECH macro to set. If this is a string it
#   is used as-is. For an array the value will be concatenated into a
#   string. Default value: undef
#
# [*version_id*]
#   The version id string included in the sendmail.mc file. This has no
#   practical meaning other than having a used defined identifier in the
#   file.
#   Default value: undef.
#
# == Requires:
#
# Nothing.
#
# == Sample Usage:
#
#   class { '::sendmail::mc': }
#
#
class sendmail::mc (
  $ostype                = $::sendmail::params::ostype,
  $sendmail_mc_domain    = $::sendmail::params::sendmail_mc_domain,
  $cf_version            = undef,
  $smart_host            = undef,
  $log_level             = undef,
  $max_message_size      = undef,
  $dont_probe_interfaces = undef,
  $enable_ipv4_daemon    = true,
  $enable_ipv6_daemon    = true,
  $mailers               = $::sendmail::params::mailers,
  $trust_auth_mech       = undef,
  $version_id            = undef,
) inherits ::sendmail::params {

  include ::sendmail::makeall

  validate_bool($enable_ipv4_daemon)
  validate_bool($enable_ipv6_daemon)

  # Order of fragments
  # -------------------------
  # 00    # file header
  # 01    VERSIONID
  # 05    OSTYPE
  # 07    DOMAIN
  # 10    # define header
  # 12    define
  # 18    # LDAP header
  # 19    LDAP config
  # 20    # FEATURE header
  # 22    FEATURE
  # 28    FEATURE conncontrol, ratecontrol
  # 29    FEATURE nullclient
  # 30    # macro header
  # 31    MASQUERADE_AS
  # 38    MODIFY_MAILER_FLAGS
  # 40    DAEMON_OPTIONS
  # 45    TRUST_AUTH_MECH
  # 47    STARTTLS
  # 50    # DNSBL header
  # 51    DNSBL features
  # 55    # Milter header
  # 56    Milter
  # 60    # MAILER header
  # 61-69 MAILER
  # 80    LOCAL_CONFIG header
  # 81    LOCAL_CONFIG
  #       LOCAL_RULE_*
  #       LOCAL_RULESETS

  concat { 'sendmail.mc':
    ensure => 'present',
    path   => $::sendmail::params::sendmail_mc_file,
    owner  => 'root',
    group  => $::sendmail::params::sendmail_group,
    mode   => '0644',
  }

  concat::fragment { 'sendmail_mc-header':
    target  => 'sendmail.mc',
    order   => '00',
    content => template('sendmail/header.m4.erb'),
    notify  => Class['::sendmail::makeall'],
  }

  if ($cf_version != undef) {
    ::sendmail::mc::define { 'confCF_VERSION':
      expansion => $cf_version,
    }
  }

  if ($version_id != undef) {
    ::sendmail::mc::versionid { $version_id: }
  }

  if ($ostype != undef) {
    ::sendmail::mc::ostype { $ostype: }
  }

  if ($sendmail_mc_domain != undef) {
    ::sendmail::mc::domain { $sendmail_mc_domain: }
  }

  if ($smart_host != undef) {
    ::sendmail::mc::define { 'SMART_HOST':
      expansion => $smart_host,
    }
  }

  if ($log_level != undef) {
    validate_re($log_level, '^\d+$', 'log_level must be numeric')
    ::sendmail::mc::define { 'confLOG_LEVEL':
      expansion => $log_level,
    }
  }

  if ($max_message_size != undef) {
    validate_re($max_message_size, '^\d+$', 'max_message_size must be numeric')
    ::sendmail::mc::define { 'confMAX_MESSAGE_SIZE':
      expansion => $max_message_size,
    }
  }

  if ($dont_probe_interfaces != undef) {
    ::sendmail::mc::define { 'confDONT_PROBE_INTERFACES':
      expansion => $dont_probe_interfaces,
    }
  }

  if ($enable_ipv4_daemon) {
    ::sendmail::mc::daemon_options { 'MTA-v4':
      family => 'inet',
      port   => 'smtp',
    }
  }

  if ($enable_ipv6_daemon) {
    ::sendmail::mc::daemon_options { 'MTA-v6':
      family => 'inet6',
      port   => 'smtp',
      modify => 'O',
    }
  }

  if ($mailers and !empty($mailers)) {
    ::sendmail::mc::mailer { $mailers:
    }
  }

  if $trust_auth_mech {
    ::sendmail::mc::trust_auth_mech { 'trust_auth_mech':
      trust_auth_mech => $trust_auth_mech,
    }
  }
}
