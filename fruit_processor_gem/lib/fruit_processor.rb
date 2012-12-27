#!/usr/bin/env ruby

require 'rubygems'
require 'rake'

class FruitProcessor
  attr_accessor :process_only
  
  def initialize
    @driver_program_name='fruit_driver_gen'
    @fruit_basket_module_name = 'fruit_basket_gen'

    @extensions = ["f90", "f95", "f03", "f08"]
    @spec_hash={}
  end

  def get_spec_hash_filename file_name
    return @spec_hash[file_name]
  end

  def get_methods_of_filename file_name
    return @spec_hash[file_name]["methods"]["name"]
  end

  def get_specs_of_filename file_name
    return @spec_hash[file_name]["methods"]["spec"]
  end

  def get_files
    return @files
  end
  
  def load_files dir="."
    return if @spec_hash.size != 0

    @files = []
    if @process_only
      @process_only.each{|f|
        @files.concat( FileList["#{dir}/#{f}"])
      }
    else
      @extensions.each{|f| 
        @files.concat(
          FileList["#{dir}/*_test." + f] - FileList["#{dir}/~*_test." + f] 
        )
      }
    end

    @files.each do |file|
      parse_method_names file
      gather_specs file
    end
  end
  
  def pre_process dir="."
    load_files dir 
    fruit_picker dir
    create_driver dir
  end
  
  def fruit_picker dir="."
    test_subroutine_names=[]
    fruit_basket_file = "#{dir}/#{@fruit_basket_module_name}.f90"
    File.open(fruit_basket_file, 'w') do |f| 
      f.write "module #{@fruit_basket_module_name}\n"
      f.write "  use fruit\n"
      f.write "contains\n"
    end
    
    File.open(fruit_basket_file, 'a') do |f| 
      @files.each do |file|
        test_module_name = test_module_name_from_file_path file
        
        subroutine_name="#{test_module_name}_all_tests"
        test_subroutine_names << subroutine_name
        f.write "  subroutine #{subroutine_name}\n"
        f.write "    use #{test_module_name}\n"
        f.write "\n"
        
        method_names = @spec_hash[file]['methods']['name']
        
        if @spec_hash[file]['setup'] != nil
          if @spec_hash[file]['setup']=='all'
            f.write "    call setup_before_all\n"
          end
        end        
        
        spec_counter = 0
        method_names.each do |method_name|
          if @spec_hash[file]['setup'] != nil
            if @spec_hash[file]['setup']=='each'
              f.write "    call setup\n"
            end
          end
          f.write "    write (*, *) \"  ..running test: #{method_name}\"\n"
          f.write "    call set_unit_name ('#{method_name}')\n"
          f.write "    call run_test_case(#{method_name}, &\n"
          f.write "                    &\"#{method_name}\")\n"
          f.write "    if (.not. is_case_passed()) then\n"
          f.write "      write(*,*) \n"
          f.write "      write(*,*) '  Un-satisfied spec:'\n"
          f.write "      write(*,*) '#{format_spec_fortran(@spec_hash[file]['methods']['spec'][spec_counter], '  -- ')}'\n"
          f.write "      write(*,*) \n"

          f.write "      call case_failed_xml(\"#{method_name}\", &\n"
          f.write "     &  \"#{test_module_name}\")\n"
          f.write "    else\n"
          f.write "      call case_passed_xml(\"#{method_name}\", &\n"
          f.write "     &  \"#{test_module_name}\")\n"
          f.write "    end if\n"
          
          if @spec_hash[file]['teardown'] != nil
            if @spec_hash[file]['teardown']=='each'
              f.write "    call teardown\n"
            end
          end
          f.write "\n"
          spec_counter += 1
        end
        
        if @spec_hash[file]['teardown'] != nil
          if @spec_hash[file]['teardown']=='all'
            f.write "    call teardown_after_all\n"
          end
        end
        
        f.write "  end subroutine #{subroutine_name}\n"
        f.write "\n"
        
      end
    end
    
    File.open(fruit_basket_file, 'a') do |f| 
      f.write "  subroutine fruit_basket\n"
      test_subroutine_names.each do |test_subroutine_name|
        f.write "    call #{test_subroutine_name}\n"
      end
      f.write "  end subroutine fruit_basket\n"
      f.write "\n"
      f.write "end module #{@fruit_basket_module_name}"
    end
  end
  
  def parse_method_names file_name
    File.open(file_name, 'r') do |source_file|
      @spec_hash[file_name]={}
      @spec_hash[file_name]['methods'] = {}
      @spec_hash[file_name]['methods']['name'] =[]
      @spec_hash[file_name]['methods']['spec'] =[]
      
      source_file.grep( /^\s*subroutine\s*(\w+)\s*$/i ) do |dummy|
        subroutine_name=$1
        if subroutine_name.downcase == "setup"
          @spec_hash[file_name]['setup']='each'
          next
        end
        if subroutine_name.downcase == "setup_before_all"
          @spec_hash[file_name]['setup']='all'
          next
        end
        if subroutine_name.downcase == "teardown"
          @spec_hash[file_name]['teardown']='each'
          next
        end
        if subroutine_name.downcase == "teardown_after_all"
          @spec_hash[file_name]['teardown']='all'
          next
        end

        #The same condition must be used for storing
        #both subroutine name and spec string.
        #Otherwise number of subroutine names and specs mismatch.
        next if subroutine_name !~ /^test_/
        @spec_hash[file_name]['methods']['name'] << subroutine_name
      end
    end
  end

  def warn_method_names file_name
    warned = []
    File.open(file_name, 'r') do |source_file|
      source_file.grep( /^\s*subroutine\s*(test\w+)\s*\(/i ) do
        subroutine_name = $1
        warned << subroutine_name
      end
    end
    if warned
      return warned 
    else
      return nil
    end
  end
  
  # look into all files lib_test_*.a in build_dir, then generate driver files
  def create_driver dir="."
    
    File.open("#{dir}/#{@driver_program_name}.f90", 'w') do |f| 
      f.write "program #{@driver_program_name}\n"
      f.write "  use fruit\n"
      f.write "  use #{@fruit_basket_module_name}\n"
      f.write "  call init_fruit\n"
      f.write "  call init_fruit_xml\n"
      f.write "  call fruit_basket\n"
      f.write "  call fruit_summary\n"
      f.write "  call fruit_summary_xml\n"
      f.write "  call fruit_finalize\n"
      f.write "end program #{@driver_program_name}\n"
    end
  end
  
  def gather_specs file
    spec=''
    File.open(file, 'r') do |infile|
      while (line = infile.gets)
        if line =~ /^\s*subroutine\s+(\w+)\s*$/i
          subroutine_name=$1

          #The same condition must be used for storing
          #both subroutine name and spec string.
          #Otherwise number of subroutine names and specs mismatch.
          next if subroutine_name !~ /^test_/
          spec_var=nil
          
          while (inside_subroutine = infile.gets)
            break if inside_subroutine =~ /end\s+subroutine/i

            if inside_subroutine =~ /^\s*\!FRUIT_SPEC\s*(.*)$/i 
              spec_var = $1.chomp
              next
            end

            next if inside_subroutine !~ /^\s*character.*::\s*spec\s*=(.*)$/i
            spec_var = $1
            spec_var =~ /\s*(["'])(.*)(\1|\&)\s*(!.*)?$/
            spec_var = $2
            last_character = $3
            
            if last_character == '&'
              while (next_line = infile.gets)
                next_line.strip!
                next_line.sub!(/^\&/, '')
                spec_var += "\n#{next_line.chop}"
                break if ! end_match(next_line, '&')
              end
            end 
          end # end of inside subroutine lines
          
          if spec_var == nil
            spec=subroutine_name.gsub('test_', '').gsub('_', ' ')
          else
            spec = spec_var
          end
          
          @spec_hash[file]['methods']['spec'] << spec
        end # end of test match
      end # end of each line in file
    end # end of file open
  end
  
  def end_match (string, match)
    return false if string == nil or string.length ==1
    return string[string.length-1, string.length-1] == match
  end
  
  def spec_report
    load_files 
    
    puts "\n"
    puts "All executable specifications from tests:"
    @spec_hash.keys.sort.each do |file|
      method_hash=@spec_hash[file]
      #@spec_hash[file]['methods']['spec']
      puts "  #{(test_module_name_from_file_path file).gsub('_test', '')}"
      puts "  --"
      
      method_hash.each_pair do |method, method_values|
        next if !method_values['spec']
        spaces = "    -- "
        
        method_values['spec'].each do |spec|
          puts format_spec(spec, spaces)
        end
      end
      puts "\n"
    end
  end
  
  def format_spec (spec, spaces, ending='')
    indent = "  " + spaces.gsub("-", " ")
    line = spec.gsub("\n", "#{ending}\n#{indent}")
    "#{spaces}#{line}"
  end

  def format_spec_fortran(spec, spaces)
    indent = "  " + spaces.gsub("-", " ")
    line = spec.gsub("\n", "&\n#{indent}&").gsub("'", "''")
    "#{spaces}#{line}"
  end
  
  def base_dir
    orig_path = Dir.pwd
    found_dir=''
    protection_counter = 0
    while true
      if File.exist? "ROOT_ANCHOR" 
        found_dir=Dir.pwd
        break
      end
      if Dir.pwd == "/" or protection_counter > 100
        FileUtils.cd(orig_path)
        FileUtils.cd("../")
        found_dir=Dir.pwd
        break
      end
      FileUtils.cd("../")
      protection_counter +=1
    end
    FileUtils.cd(orig_path)
    return found_dir
  end
  
  def build_dir
    "#{base_dir}/build"
  end
  
  def module_files(all_f90_files, build_dir)
    return [] if all_f90_files == nil or all_f90_files.size == 0
    module_with_path=[]
    # assume each source .f90 has a module.  This is a cleanup task, doesn't matter if removed non-existing file
    all_f90_files.ext('mod').each do |file| 
      module_with_path << "#{build_dir}/#{file}" 
    end
    return module_with_path
  end
  
  def lib_base_files(lib_bases, build_dir=nil)
    if build_dir != nil
      puts "build_dir on lib_base_files is obsolete" 
      build_dir = nil
    end
    return if lib_bases == nil 
    lib_base_files =[]
    lib_bases.each do |pair|
      lib_base_files << "#{pair[1]}/lib#{pair[0]}.a"
    end
    return lib_base_files
  end
  
  def lib_name_flag (lib_bases, build_dir)
    return if lib_bases == nil 
    lib_name_flag = ''
    lib_bases.each { |pair| lib_name_flag += "-l#{pair[0]} " }
    return lib_name_flag
  end
  
  def lib_dir_flag(lib_bases, build_dir)
    return if lib_bases == nil 
    lib_dir_flag = ''
    _libs=[]
    lib_bases.each do |pair|
      pair[1] = build_dir if pair[1] == nil
      _libs << pair[1]
    end
    _libs.uniq.each { |value|  lib_dir_flag += "-L#{value} " }
    return lib_dir_flag.strip
  end
  
  def inc_flag inc_dirs
    inc_dirs.collect {|item| 
      "-I#{item}" if item.size > 0
    }.join(" ")
  end
  
  def test_module_name_from_file_path file_name

#---
#    test_module_name=file_name.gsub(".f90", "")
#---
    test_module_name=""
    @extensions.each{|fxx| 
      if file_name =~ /(.+)\.#{fxx}/
        test_module_name=$1
      end
    }
#---


    test_module_name[test_module_name.rindex("/")+1 ..  -1]
  end
end
