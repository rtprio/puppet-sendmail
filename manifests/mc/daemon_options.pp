# = define: sendmail::mc::daemon_options
#
# Add the DAEMON_OPTIONS macro to the sendmail.mc file.
#
# == Parameters:
#
# [*family*]
#   The network family type. Valid options: 'inet', 'inet6' or 'iso'
#
# [*addr*]
#   The network address to listen on for remote connections. This can be
#   a hostname or network address.
#
# [*port*]
#   The port used by the daemon. This can be either a numeric port number
#   or a service name like 'smtp' for port 25.
#
# [*children*]
#   The maximum number of processes to fork for this daemon.
#
# [*delivery_mode*]
#   The mode of delivery for this daemon. Valid options: 'background',
#   'deferred', 'interactive' or 'queueonly'.
#
# [*input_filter*]
#   A list of milters to use.
#
# [*listen*]
#   The length of the listen queue used by the operating system.
#
# [*modify*]
#   Single letter flags to modify the daemon behaviour. See the Sendmail
#   documention for details.
#
# [*delay_la*]
#   The local load average at which connections are delayed before they
#   are accepted.
#
# [*queue_la*]
#   The local load average at which received mail is queued and not
#   delivered immediately.
#
# [*refuse_la*]
#   The local load average at which mail is no longer accepted.
#
# [*send_buf_size*]
#   The size of the network send buffer used by the operating system.
#   The value is a size in bytes.
#
# [*receive_buf_size*]
#   The size of the network receive buffer used by the operating system.
#   The value is a size in bytes.
#
# == Requires:
#
# Nothing.
#
# == Sample Usage:
#
#   sendmail::mc::daemon_options { 'MTA-v4':
#     family => 'inet',
#     port   => '25',
#   }
#
#
define sendmail::mc::daemon_options (
  $family           = undef,
  $addr             = undef,
  $port             = undef,
  $children         = undef,
  $delivery_mode    = undef,
  $input_filter     = undef,
  $listen           = undef,
  $modify           = undef,
  $delay_la         = undef,
  $queue_la         = undef,
  $refuse_la        = undef,
  $send_buf_size    = undef,
  $receive_buf_size = undef,
) {

  include ::sendmail::makeall

  if !empty($family) {
    validate_re($family, [ '^inet$', '^inet6$', '^iso$'])
  }

  if !empty($delivery_mode) {
    validate_re($delivery_mode,
      [
        '^b$', '^background$',
        '^d$', '^deferred$',
        '^i$', '^interactive$',
        '^q$', '^queueonly$',
    ])
  }

  $delivery = $delivery_mode ? {
    undef   => undef,
    ''      => undef,
    default => regsubst($delivery_mode, '^(.).*$', '\1')
  }

  $sparse_opts = {
    'Name'           => $title,
    'Family'         => $family,
    'Addr'           => $addr,
    'Port'           => $port,
    'children'       => $children,
    'DeliveryMode'   => $delivery,
    'InputFilter'    => $input_filter,
    'Listen'         => $listen,
    'M'              => $modify,
    'delayLA'        => $delay_la,
    'queueLA'        => $queue_la,
    'refuseLA'       => $refuse_la,
    'SendBufSize'    => $send_buf_size,
    'ReceiveBufSize' => $receive_buf_size,
  }

  $hash_opts = delete_undef_values($sparse_opts)

  $opts = join(join_keys_to_values($hash_opts, '='), ', ')

  concat::fragment { "sendmail_mc-daemon_options-${title}":
    target  => 'sendmail.mc',
    order   => '40',
    content => inline_template("DAEMON_OPTIONS(`${opts}')dnl\n"),
    notify  => Class['::sendmail::makeall'],
  }

  # Also add the section header
  include ::sendmail::mc::macro_section
}
