# == Class: jmeter
#
# This class installs the latest stable version of JMeter.
#
# === Examples
#
#   class { 'jmeter': }
#
class jmeter(
  $jmeter_version         = '2.13',
  $jmeter_plugins_install = false,
  $jmeter_plugins_version = '1.2.1',
  $jmeter_plugins_set     = ['Standard'],
  $java_version           = '7',
) {

  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  $jdk_pkg = $::osfamily ? {
    debian => "openjdk-${java_version}-jre-headless",
    redhat => "java-1.${java_version}.0-openjdk"
  }

  package { $jdk_pkg:
    ensure => present,
  }

  package { 'unzip':
    ensure => present,
  }

  package { 'wget':
    ensure => present,
  }

  exec { 'download-jmeter':
    command => "wget -P /root http://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${jmeter_version}.tgz",
    creates => "/root/apache-jmeter-${jmeter_version}.tgz"
  }

  exec { 'install-jmeter':
    command => "tar xzf /root/apache-jmeter-${jmeter_version}.tgz && mv apache-jmeter-${jmeter_version} jmeter",
    cwd     => '/usr/share',
    creates => '/usr/share/jmeter',
    require => Exec['download-jmeter'],
  }

  if $jmeter_plugins_install == true {
    jmeter::plugins_install { $jmeter_plugins_set:
      plugins_version => $jmeter_plugins_version,
      require         => [Package['wget'], Package['unzip'], Exec['install-jmeter']],
    }
  }
}

define jmeter::plugins_install (
  $plugins_set = $title,
  $plugins_version)
{
  $base_download_url = 'http://jmeter-plugins.org/downloads/file/'
  $plugins_file_base = "JMeterPlugins-${plugins_set}-${plugins_version}"

  exec { "download-jmeter-plugins-${plugins_set}":
    command => "wget -P /root ${base_download_url}/${plugins_file_base}.zip",
    creates => "/root/${plugins_file_base}.zip"
  }

  exec { "install-jmeter-plugins-${plugins_set}":
    command => "unzip -q -o -d JMeterPlugins-${plugins_set} ${plugins_file_base}.zip && cp -r JMeterPlugins-${plugins_set}/lib/* /usr/share/jmeter/lib/",
    cwd     => '/root',
    creates => "/usr/share/jmeter/lib/ext/JMeterPlugins-${plugins_set}.jar",
    require => Exec["download-jmeter-plugins-${plugins_set}"],
  }
}
