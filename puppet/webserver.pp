# Ensure Apache (apache2) is installed
package { 'apache2':
    ensure => installed,
}

# Ensure the Apache service is running and enabled
service { 'apache2':
    ensure => running,
    enable => true,
    require => Package['apache2'], # This ensures Apache is installed first
}

# A simple example to deploy a web page
file { '/var/www/html/index.html':
    ensure  => file,
    content => "<html><body><h1>Hello from Puppet!</h1></body></html>\n",
    require => Package['apache2'], # This ensures Apache is installed first
}