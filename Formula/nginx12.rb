require 'formula'

class Nginx12 < Formula
  homepage 'http://nginx.org/'
  url 'http://nginx.org/download/nginx-1.2.4.tar.gz'
  sha1 'e3de0b2b82095f26e96bdb461ba36472d3e7cdda'

  env :userpaths

  depends_on 'pcre'

  option 'with-passenger', 'Compile with support for Phusion Passenger module'
  option 'with-webdav', 'Compile with support for WebDAV module'
  option 'with-debug', 'Enable debug logging'
  option 'with-chunkin', 'Enable http chunkin module'
  option 'with-ssl', 'Enable SSL module'
  option 'with-realip', 'Enable RealIP module'
  option 'with-addition', 'Enable RealIP module'
  option 'with-xslt', 'Enable '
  option 'with-image-filter', 'Enable '
  option 'with-sub', 'Enable '
  option 'with-flv', 'Enable '
  option 'with-mp4', 'Enable '
  option 'with-gzip-static', 'Enable '
  option 'with-random-index', 'Enable '
  option 'with-geoip', 'Enable '
  option 'with-secure-link', 'Enable '
  option 'with-degradation-status', 'Enable '
  option 'with-pcre', 'Enable '
  option 'with-ipv6', 'Enable '

  skip_clean 'logs'

  # Changes default port to 8080
  def patches
    DATA
  end

  def passenger_config_args
    passenger_root = `passenger-config --root`.chomp

    if File.directory?(passenger_root)
      return "--add-module=#{passenger_root}/ext/nginx"
    end

    puts "Unable to install nginx with passenger support. The passenger"
    puts "gem must be installed and passenger-config must be in your path"
    puts "in order to continue."
    exit
  end

  def install
    args = ["--prefix=#{prefix}",
            "--with-cc-opt=-I#{HOMEBREW_PREFIX}/include",
            "--with-ld-opt=-L#{HOMEBREW_PREFIX}/lib",
            "--conf-path=#{etc}/nginx/nginx.conf",
            "--pid-path=#{var}/run/nginx.pid",
            "--lock-path=#{var}/run/nginx.lock",
            "--http-client-body-temp-path=#{var}/run/nginx/client_body_temp",
            "--http-proxy-temp-path=#{var}/run/nginx/proxy_temp",
            "--http-fastcgi-temp-path=#{var}/run/nginx/fastcgi_temp",
            "--http-uwsgi-temp-path=#{var}/run/nginx/uwsgi_temp",
            "--http-scgi-temp-path=#{var}/run/nginx/scgi_temp"]

    args << passenger_config_args if build.include? 'with-passenger'
    args << "--with-http_dav_module" if build.include? 'with-webdav'

    if build.include? 'with-debug'
      args << "--with-debug"
    end

    if build.include? 'with-chunkin'
      args << "--add-module=#{fetch_http_chunkin_module}"
    end

    if build.include? 'with-ssl'
      args << "--with-http_ssl_module"
    end

    if build.include? 'with-realip'
      args << "--with-http_realip_module"
    end

    if build.include? 'with-addition'
      args << "--with-http_addition_module"
    end

    if build.include? 'with-xslt'
      args << "--with-http_xslt_module"
    end

    if build.include? 'with-image-filter'
      args << "--with-http_image_filter_module"
    end

    if build.include? 'with-sub'
      args << "--with-http_sub_module"
    end

    if build.include? 'with-flv'
      args << "--with-http_flv_module"
    end

    if build.include? 'with-mp4'
      args << "--with-http_mp4_module"
    end

    if build.include? 'with-gzip-static'
      args << "--with-http_gzip_static_module"
    end

    if build.include? 'with-random-index'
      args << "--with-http_random_index_module"
    end

    if build.include? 'with-geoip'
      args << "--with-http_geoip_module"
    end

    if build.include? 'with-secure-link'
      args << "--with-http_secure_link_module"
    end

    if build.include? 'with-degradation-status'
      args << "--with-http_degradation_module"
    end

    if build.include? 'with-pcre'
      args << "--with-pcre"
    end

    if build.include? 'with-ipv6'
      args << "--with-ipv6"
    end

    system "./configure", *args
    system "make"
    system "make install"
    man8.install "objs/nginx.8"
    (var/'run/nginx').mkpath
  end

  def fetch_http_chunkin_module
    puts "Downloading http chunkin module ..."
    `curl -s -L https://github.com/agentzh/chunkin-nginx-module/tarball/v0.23rc2 -o agentzh-chunkin-nginx-module-v0.23rc2.tar.gz`
    `tar xzf agentzh-chunkin-nginx-module-v0.23rc2.tar.gz`
    path = Dir.pwd + "/agentzh-chunkin-nginx-module-ddc0dd5"
  end

  def caveats; <<-EOS.undent
    In the interest of allowing you to run `nginx` without `sudo`, the default
    port is set to localhost:8080.

    If you want to host pages on your local machine to the public, you should
    change that to localhost:80, and run `sudo nginx`. You'll need to turn off
    any other web servers running port 80, of course.

    You can start nginx automatically on login running as your user with:
      mkdir -p ~/Library/LaunchAgents
      cp #{plist_path} ~/Library/LaunchAgents/
      launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    Though note that if running as your user, the launch agent will fail if you
    try to use a port below 1024 (such as http's default of 80.)
    EOS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>#{plist_name}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
    <key>ProgramArguments</key>
    <array>
        <string>#{HOMEBREW_PREFIX}/sbin/nginx</string>
    </array>
    <key>WorkingDirectory</key>
    <string>#{HOMEBREW_PREFIX}</string>
  </dict>
</plist>
    EOPLIST
  end
end

__END__
--- a/conf/nginx.conf
+++ b/conf/nginx.conf
@@ -33,7 +33,7 @@
     #gzip  on;

     server {
-        listen       80;
+        listen       8080;
         server_name  localhost;

         #charset koi8-r;
