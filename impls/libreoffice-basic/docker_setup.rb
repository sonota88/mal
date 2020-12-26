require "fileutils"
require "rexml/document"
require "rexml/formatters/pretty"

require_relative "libo"

SCRIPT_XLB_TEMPLATE = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE library:library PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "library.dtd">
<library:library
  xmlns:library="http://openoffice.org/2000/library"
  library:name="{{lib_name}}"
  library:readonly="false" library:passwordprotected="false"
>
</library:library>
XML

MOD_TEMPLATE = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE script:module PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "module.dtd">
<script:module xmlns:script="http://openoffice.org/2000/script"
  script:name="{{module_name}}"
  script:language="StarBasic"
>
{{src}}
</script:module>
XML

def xpath_match(el, xpath)
  return REXML::XPath.match(el, xpath)
end

def create_el(name, attrs)
  el = REXML::Element.new(name)
  attrs.each { |k, v| el.add_attribute(k, v) }
  el
end

def modify_xml(path)
  xml = File.read(path)
  doc = REXML::Document.new(xml)

  yield doc

  File.open(path, "wb") do |f|
    pretty_formatter = REXML::Formatters::Pretty.new
    pretty_formatter.write(doc, f)
    f.print "\n"
  end
end

def user_bas_dir
  File.join(ENV['HOME'], ".config/libreoffice/4/user/basic")
end

def add_library(lib_name)
  path = File.join(user_bas_dir, "script.xlc")

  modify_xml(path) do |doc|
    existing_lib_names = doc.root.elements.map{ |el| el["library:name"] }
    return if existing_lib_names.include?(lib_name)

    doc.root.add_element(
      create_el(
        "library:library",
        {
          "library:name" => lib_name,
          "library:link" => "false",
          "xlink:href"   => "$(USER)/basic/#{lib_name}/script.xlb/",
          "xlink:type"   => "simple"
        }
      )
    )
  end

  lib_dir = File.join(user_bas_dir, lib_name)
  FileUtils.mkdir_p lib_dir

  script_xlb_path = File.join(lib_dir, "script.xlb")
  File.open(script_xlb_path, "wb") do |f|
    f.print ::SCRIPT_XLB_TEMPLATE.sub("{{lib_name}}", lib_name)
  end
end

def add_module_src(lib_name, mod_name, src)
  xml = MOD_TEMPLATE
          .sub("{{module_name}}", mod_name)
          .sub("{{src}}", escape(src))

  file_path = File.join(user_bas_dir, lib_name, mod_name + ".xba")

  File.open(file_path, "wb") { |f| f.print xml }
end

def add_module(lib_name, module_name, src)
  path = File.join(user_bas_dir, lib_name, "script.xlb")

  modify_xml(path) do |doc|
    existing_module_names = doc.root.elements.map{ |el| el["library:name"] }

    unless existing_module_names.include?(module_name)
      el_mod = REXML::Element.new("library:element")
      el_mod.add_attribute("library:name", module_name)
      doc.root.add_element(el_mod)
    end
  end

  add_module_src(lib_name, module_name, src)
end

lib_name = "Mal"
mod_name = "Main"

add_library(lib_name)

[
  ["Main"             , "stepA_mal.libo.bas"         ],
  ["Calc"             , "mod_calc.libo.bas"          ],
  ["Core"             , "mod_core.libo.bas"          ],
  ["MalList"          , "mod_list.libo.bas"          ],
  ["MalVector"        , "mod_vector.libo.bas"        ],
  ["MalMap"           , "mod_map.libo.bas"           ],
  ["MalEnv"           , "mod_env.libo.bas"           ],
  ["MalSymbol"        , "mod_symbol.libo.bas"        ],
  ["MalFunction"      , "mod_function.libo.bas"      ],
  ["MalNamedFunction" , "mod_named_function.libo.bas"],
  ["MalAtom"          , "mod_atom.libo.bas"          ],
  ["Printer"          , "mod_printer.libo.bas"       ],
  ["Reader"           , "mod_reader.libo.bas"        ],
  ["Utils"            , "mod_utils.libo.bas"         ],
].each do |mod_name, file|
  src = file_read(file)
  src = preprocess(src)
  add_module(lib_name, mod_name, src)
end
