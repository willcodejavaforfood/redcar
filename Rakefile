REDCAR_VERSION = "0.6.1dev" # also change in lib/redcar.rb!
require 'rubygems'
require 'fileutils'
require 'spec/rake/spectask'
require 'cucumber/rake/task'
require "rake/gempackagetask"
require "rake/rdoctask"

if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    # not available for jruby yet
    require 'win32console'
  rescue LoadError
    ARGV << "--nocolour"
  end
end

### DOCUMENTATION

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files   = [
        'lib/*.rb',
        'lib/*/*.rb',
        'plugins/*/lib/*.rb',
        'plugins/*/lib/**/*.rb'
      ]
    t.options = ['--markup', 'markdown']
  end  
rescue LoadError
end

desc "upload the docs to redcareditor.com"
task :release_docs do
  port     = YAML.load(File.read(".server.yaml"))["port"]
  docs_dir = YAML.load(File.read(".server.yaml"))["dir"]
  sh "rsync -e 'ssh -p #{port}' -avz doc/ danlucraft.com:#{docs_dir}/#{REDCAR_VERSION}/"
  sh "rsync -e 'ssh -p #{port}' -avz doc/ danlucraft.com:#{docs_dir}/latest/"
end

### CI
task :ci => [:specs_ci, :cucumber_ci]

def find_ci_reporter(filename)
  jruby_gem_path = %x[jruby -rubygems -e "p Gem.path.first"].gsub("\n", "").gsub('"', "")
  result = Dir.glob("#{jruby_gem_path}/gems/ci_reporter-*/lib/ci/reporter/rake/#{filename}.rb").reverse.first
  result || raise("Could not find ci_reporter gem in #{jruby_gem_path}")
end

task :specs_ci do
  rspec_loader = find_ci_reporter "rspec_loader"  
  files = Dir['plugins/*/spec/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*/*_spec.rb']
  opts = "-J-XstartOnFirstThread" if Config::CONFIG["host_os"] =~ /darwin/
  opts = "#{opts} -S spec --require #{rspec_loader} --format CI::Reporter::RSpec -c #{files.join(" ")}"
  sh("jruby #{opts} && echo 'done'")
end

task :cucumber_ci do  
  opts = "-J-XstartOnFirstThread" if Config::CONFIG["host_os"] =~ /darwin/
  opts = "#{opts} bin/cucumber -f progress -f junit --out features/reports/ plugins/*/features"
  sh("jruby #{opts} && echo 'done'")
end

### TESTS

desc "Run all specs and features"
task :default => ["specs", "cucumber"]

task :specs do
  files = Dir['plugins/*/spec/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*/*_spec.rb']
  case Config::CONFIG["host_os"]
  when "darwin"
    sh("jruby -J-XstartOnFirstThread -S spec -c #{files.join(" ")} && echo 'done'")
  else
    sh("jruby -S spec -c #{files.join(" ")} && echo 'done'")
  end
end

desc "Run features"
task :cucumber do
  case Config::CONFIG["host_os"]
  when "darwin"
    sh("jruby -J-XstartOnFirstThread bin/cucumber -cf progress plugins/*/features && echo 'done'")
  else
    sh("jruby bin/cucumber -cf progress plugins/*/features && echo 'done'")
  end
end

### BUILD AND RELEASE

desc "Build"
task :build do
  sh "ant jar -f vendor/java-mateview/build.xml"
  cp "vendor/java-mateview/lib/java-mateview.rb", "plugins/edit_view_swt/vendor/"
  cp "vendor/java-mateview/release/java-mateview.jar", "plugins/edit_view_swt/vendor/"
  cd "plugins/application_swt" do
    sh "ant"
  end
end

def remove_gitignored_files(filelist)
  ignores = File.readlines(".gitignore")
  ignores = ignores.select {|ignore| ignore.chomp.strip != ""}
  ignores = ignores.map {|ignore| Regexp.new(ignore.chomp.gsub(".", "\\.").gsub("*", ".*"))}
  r = filelist.select {|fn| not ignores.any? {|ignore| fn =~ ignore }}
  r.select {|fn| fn !~ /\.git/ }
end

def remove_matching_files(list, string)
  list.reject {|entry| entry.include?(string)}
end

spec = Gem::Specification.new do |s|
  s.name              = "redcar"
  s.version           = REDCAR_VERSION
  s.summary           = "A JRuby text editor."
  s.author            = "Daniel Lucraft"
  s.email             = "dan@fluentradical.com"
  s.homepage          = "http://redcareditor.com"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)

  
  
  s.files             = %w(CHANGES LICENSE Rakefile README.md) + 
                          Dir.glob("bin/redcar") + 
                          Dir.glob("config/**/*") + 
                          Dir.glob("share/**/*") + 
                          remove_gitignored_files(Dir.glob("lib/**/*")) + 
                          remove_matching_files(remove_gitignored_files(Dir.glob("plugins/**/*")), "redcar-bundles") + 
                          Dir.glob("plugins/textmate/vendor/redcar-bundles/Bundles/*.tmbundle/Syntaxes/**/*") + 
                          Dir.glob("plugins/textmate/vendor/redcar-bundles/Bundles/*.tmbundle/Preferences/**/*") + 
                          Dir.glob("plugins/textmate/vendor/redcar-bundles/Bundles/*.tmbundle/Snippets/**/*") + 
                          Dir.glob("plugins/textmate/vendor/redcar-bundles/Bundles/*.tmbundle/info.plist") + 
                          Dir.glob("plugins/textmate/vendor/redcar-bundles/Themes/*.tmTheme")
  s.executables       = FileList["bin/redcar"].map { |f| File.basename(f) }
   
  s.require_paths     = ["lib"]

  s.add_dependency("rubyzip")
  
  s.add_development_dependency("cucumber")
  s.add_development_dependency("rspec")
  s.add_development_dependency("watchr")
  
  s.post_install_message = <<TEXT

------------------------------------------------------------------------------------

Please now run:

  $ redcar install

to complete the installation. (NB do NOT use sudo. In previous versions, sudo was 
required for this step, but now it should be run as the user.)

NB. This will download jars that Redcar needs to run from the internet. It will put
them into ~/.redcar/assets.

------------------------------------------------------------------------------------

TEXT
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build a MacOS X App bundle"
task :app_bundle => :build do
  require 'erb'

  redcar_icon = "redcar_icon_beta.png"

  bundle_contents = File.join("pkg", "Redcar.app", "Contents")
  FileUtils.rm_rf bundle_contents if File.exist? bundle_contents
  macos_dir = File.join(bundle_contents, "MacOS")
  resources_dir = File.join(bundle_contents, "Resources")
  FileUtils.mkdir_p macos_dir
  FileUtils.mkdir_p resources_dir

  info_plist_template = ERB.new <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>redcar</string>
	<key>CFBundleIconFile</key>
	<string><%= redcar_icon %></string>
	<key>CFBundleIdentifier</key>
	<string>com.redcareditor.Redcar</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string><%= spec.version %></string>
	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>
</dict>
</plist>
  PLIST
  File.open(File.join(bundle_contents, "Info.plist"), "w") do |f|
    f << info_plist_template.result(binding)
  end

  File.open(File.join(macos_dir, "redcar"), "w") do |f|
    f << '#!/bin/sh
          DIR=$(cd "$(dirname "$0")"; pwd)
          REDCAR=$(cd "$(dirname "${DIR}/../Resources/bin/redcar")"; pwd)
          $REDCAR/redcar install
          $REDCAR/redcar --ignore-stdin $@'
  end
  File.chmod 0777, File.join(macos_dir, "redcar")

  spec.files.each do |f|
    FileUtils.mkdir_p File.join(resources_dir, File.dirname(f))
    FileUtils.cp_r f, File.join(resources_dir, f), :remove_destination => true
  end

  FileUtils.cp_r File.join(resources_dir, "plugins", "application", "icons", redcar_icon), 
      resources_dir, :remove_destination => true
end

desc 'Run a watchr continuous integration daemon for the specs'
task :run_ci do
  require 'watchr'
  script = Watchr::Script.new
  script.watch(/.*\/([^\/]+).rb$/) { |filename|
    if filename[0] =~ /_spec\.rb/ # a spec file
      a = "jruby -S spec #{filename} --backtrace"
      puts a
      system a
    end  
  
    spec_filename = "#{filename[1]}_spec.rb"
    spec = Dir["**/#{spec_filename}"]
    if spec.length > 0
     a = "jruby -S spec #{spec[0]}"
     puts a
     system a
    end
  }
  contrl = Watchr::Controller.new(script, Watchr.handler.new)
  contrl.run
end

desc "Release gem"
task :release => :gem do
  require 'aws/s3'
  credentials = YAML.load(File.read("/Users/danlucraft/.s3-creds.yaml"))
  AWS::S3::Base.establish_connection!(
    :access_key_id     => credentials['access_key_id'],
    :secret_access_key => credentials["secret_access_key"]
  )
  
  redcar_bucket = AWS::S3::Bucket.find('redcar')
  s3_uploads = {
    "vendor/java-mateview/release/java-mateview.jar" => "java-mateview-#{REDCAR_VERSION}.jar",
    "plugins/application_swt/lib/dist/application_swt.jar"   => "application_swt-#{REDCAR_VERSION}.jar",
    "pkg/redcar-#{REDCAR_VERSION}.gem"                       => "redcar-#{REDCAR_VERSION}.gem"
  }
  
  s3_uploads.each do |source, target|
    AWS::S3::S3Object.store(target, open(source), 'redcar', :access => :public_read)
  end
end

namespace :redcar do
  def hash_with_hash_default
    Hash.new {|h,k| h[k] = hash_with_hash_default }
  end

  require 'json'
  
  desc "Redcar Integration: output runnable info"
  task :runnables do
    mkdir_p(".redcar/runnables")
    puts "Creating runnables"
    File.open(".redcar/runnables/sync_stdout.rb", "w") do |fout|
      fout.puts <<-RUBY
        $stdout.sync = true
        $stderr.sync = true
      RUBY
    end
    
    tasks = Rake::Task.tasks
    runnables = []
    ruby_bin = Config::CONFIG["bindir"] + "/ruby -r#{File.dirname(__FILE__)}/.redcar/runnables/sync_stdout.rb " 
    tasks.each do |task|
      name = task.name.gsub(":", "/")
      command = ruby_bin + $0 + " " + task.name
      runnables << {
        "name"        => name,
        "command"     => command, 
        "description" => task.comment,
        "type"        => "task/ruby/rake"
      }
    end
    File.open(".redcar/runnables/rake.json", "w") do |f|
      data = {"commands" => runnables}
      f.puts(JSON.pretty_generate(data))
    end
    File.open(".redcar/runnables/ruby.json", "w") do |f|
      data = {"file_runners" => 
        [
          {
            "regex" =>    ".*.rb$",
            "name" =>     "Run as ruby",
            "command" =>  ruby_bin + "__PATH__",
            "type" =>     "script/ruby"
          }
        ]
      }
      f.puts(JSON.pretty_generate(data))
    end
  end
  
  task :sample do
    5.times do |i|
      puts "out#{i}"
      sleep 1
      $stderr.puts "err#{i}"
      sleep 1
    end
    FileUtils.touch("finished_process")
  end
end








