# == Class: consul_template
#
# Installs, configures, and manages consul-template
#
# === Parameters
#
# [*version*]
#   Specify version of consul-template binary to download.
#
# [*install_method*]
#   Defaults to `url` but can be `package` if you want to install via a system package.
#
# [*package_name*]
#   Only valid when the install_method == package. Defaults to `consul-template`.
#
# [*package_ensure*]
#   Only valid when the install_method == package. Defaults to `latest`.
#
# [*extra_options*]
#   Extra arguments to be passed to the consul-template agent
#
# [*init_style*]
#   What style of init system your system uses.
#
# [*config_mode*]
#   Set config file mode
#
# [*purge_config_dir*]
#   Purge config files no longer generated by Puppet
#
# [*vault_enabled*]
#   Do we want to configure Hashicopr Vault? Defaults to false.
#
# [*vault_address*]
#   HTTP/HTTPS URL of the vault service
#
# [*vault_token*]
#   Auth token to use for Vault
#
# [*vault_ssl*]
#   Should we use SSL? Defaults to true
#
# [*vault_ssl_verify*]
#   Should we verify the SSL certificate? Defaults to true
#
# [*vault_ssl_cert*]
#   What is the path to the cert.pem
#
# [*vault_ssl_key*]
#   What is the path to the key.pem
#
# [*vault_ssl_ca_cert*]
#   What is the path to the ca cert.pem
#
# [*data_dir*]
#   Path to a directory to create to hold some data. Defaults to ''
#
# [*user*]
#   Name of a user to use for dir and file perms. Defaults to root.
#
# [*group*]
#   Name of a group to use for dir and file perms. Defaults to root.
#
# [*manage_user*]
#   User is managed by this module. Defaults to `false`.
#
# [*manage_group*]
#   Group is managed by this module. Defaults to `false`.
#
# [*watches*]
#   A hash of watches - allows greater Hiera integration. Defaults to `{}`.

class consul_template (
  $purge_config_dir        = true,
  $config_mode             = $consul_template::params::config_mode,
  $bin_dir                 = '/usr/local/bin',
  $arch                    = $consul_template::params::arch,
  $version                 = $consul_template::params::version,
  $install_method          = $consul_template::params::install_method,
  $os                      = $consul_template::params::os,
  $download_url            = undef,
  $download_url_base       = $consul_template::params::download_url_base,
  $download_extension      = $consul_template::params::download_extension,
  $package_name            = $consul_template::params::package_name,
  $package_ensure          = $consul_template::params::package_ensure,
  $config_dir              = '/etc/consul-template',
  $extra_options           = '',
  $service_enable          = true,
  $service_ensure          = 'running',
  $consul_host             = 'localhost',
  $consul_port             = '8500',
  $consul_token            = '',
  $consul_retry            = '10s',
  $consul_wait             = undef,
  $consul_max_stale        = undef,
  $deduplicate             = false,
  $deduplicate_prefix      = undef,
  $init_style              = $consul_template::params::init_style,
  $log_level               = $consul_template::params::log_level,
  $logrotate_compress      = 'nocompress',
  $logrotate_files         = 4,
  $logrotate_on            = false,
  $logrotate_period        = 'daily',
  $vault_enabled           = false,
  $vault_address           = '',
  $vault_token             = undef,
  $vault_ssl               = true,
  $vault_ssl_verify        = true,
  $vault_ssl_cert          = '',
  $vault_ssl_key           = '',
  $vault_ssl_ca_cert       = '',
  $vault_grace             = '15s',
  $vault_retry_attempts    = '12',
  $vault_retry_backoff     = '250ms',
  $vault_retry_max_backoff = '1m',
  $data_dir                = '',
  $user                    = $consul_template::params::user,
  $group                   = $consul_template::params::group,
  $manage_user             = $consul_template::params::manage_user,
  $manage_group            = $consul_template::params::manage_group,
  $watches                 = {},
) inherits ::consul_template::params {

  validate_bool($purge_config_dir)
  validate_string($user)
  validate_string($group)
  validate_bool($manage_user)
  validate_bool($manage_group)
  validate_hash($watches)

  $real_download_url = pick($download_url, "${download_url_base}${version}/${package_name}_${version}_${os}_${arch}.${download_extension}")

  if $watches {
    create_resources(consul_template::watch, $watches)
  }

  anchor { '::consul_template::begin': } ->
  class { '::consul_template::install': } ->
  class { '::consul_template::config':
    consul_host  => $consul_host,
    consul_port  => $consul_port,
    consul_token => $consul_token,
    consul_retry => $consul_retry,
    purge        => $purge_config_dir,
  } ~>
  class { '::consul_template::service': } ->
  anchor { '::consul_template::end': }

  class { '::consul_template::logrotate':
    logrotate_compress => $logrotate_compress,
    logrotate_files    => $logrotate_files,
    logrotate_on       => $logrotate_on,
    logrotate_period   => $logrotate_period,
    require            => Anchor['::consul_template::begin'],
    before             => Anchor['::consul_template::end'],
  }
}
