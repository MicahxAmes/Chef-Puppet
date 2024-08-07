# Install Apache package
package 'apache2' do
    action :install
end

# Start and enable the Apache service
service 'apache2' do
    action [:start, :enable]
end

# Deploy a simple web page
file '/var/www/html/index.html' do
    content '<html><body><h1>Hello from Chef!</h1></body></html>'
    action :create
end