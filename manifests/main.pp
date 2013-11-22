exec { 'apt-get update':
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"]
}

package { 'nginx-extras':
  ensure => installed,
  require => Exec['apt-get update'],
}


exec { 'wget --no-check-certificate https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.7.deb':
  cwd => '/root',
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  creates => '/root/elasticsearch-0.90.7.deb'

}

package { 'default-jre':
  ensure => installed,
}

package { 'elasticsearch':
  ensure => installed,
  source => '/root/elasticsearch-0.90.7.deb',
  require => [Exec['wget --no-check-certificate https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.7.deb'], Package['default-jre']],
  provider => dpkg
}

file { '/etc/nginx/sites-enabled/es':
  content => template('/vagrant/manifests/nginx/es.conf.erb'),
  require => Package['nginx-extras'],
}

exec { 'wget --no-check-certificate https://github.com/baloo/kibana/archive/improvements/use-elasticjs.tar.gz':
  cwd => '/root',
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  creates => '/root/use-elasticjs.tar.gz'
}

file { '/var/www':
  ensure => 'directory'
}

file { '/etc/kibana':
  ensure => 'directory'
}

file { '/etc/kibana/users':
  ensure => 'file',
  content => 'foo:$apr1$4c6pc6bh$9xwCglW4.iP34oroFBk.l.' # foo / bar
}

exec { 'tar xzf /root/use-elasticjs.tar.gz':
  cwd => '/var/www',
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  creates => '/var/www/kibana-improvements-use-elasticjs',
  require => [ Exec['wget --no-check-certificate https://github.com/baloo/kibana/archive/improvements/use-elasticjs.tar.gz'], File['/var/www']],
}

file { '/etc/nginx/sites-enabled/kibana':
  content => template('/vagrant/manifests/nginx/kibana.conf.erb'),
  require => [ Package['nginx-extras'], File['/etc/kibana/users'] ],
}

file { '/etc/nginx/sites-enabled/default':
  ensure => absent,
  content => template('/vagrant/manifests/nginx/kibana.conf.erb'),
  require => [ Package['nginx-extras'], File['/etc/kibana/users'] ],
}

file { '/etc/kibana/config.js':
  content => template('/vagrant/manifests/kibana/config.js.erb'),
  require => File['/etc/kibana'],
}



file { '/etc/kibana/nginx-set-cookies.lua':
  content => template('/vagrant/manifests/kibana/set-cookies.lua.erb'),
  require => File['/etc/kibana'],
}

file { '/etc/kibana/nginx-verify-cookies.lua':
  content => template('/vagrant/manifests/kibana/verify-cookies.lua.erb'),
  require => File['/etc/kibana'],
}


# Restart everything
exec { 'service elasticsearch restart':
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  require => [
    Package["elasticsearch"]
  ]
}

exec { 'service nginx restart':
  path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin"],
  require => [
    File['/etc/nginx/sites-enabled/default'],
    File['/etc/nginx/sites-enabled/kibana'],
    File['/etc/nginx/sites-enabled/es']
  ]
}

