# -*- ruby -*-

namespace :fountain do

  def prompt_variable(prompt, variable, previous)
    print prompt
    previous = previous.to_s.chomp
    print "(default #{previous}): "
    value = STDIN.gets

    if value.blank?
      value = previous
    else
      value.chomp!
    end

    value
  end

  def prompt_variable_number(prompt, variable)
    SystemVariable.setnumber(variable,
                             prompt_variable(prompt,
                                             variable,
                                             SystemVariable.number(variable)))
  end

  def prompt_variable_value(prompt, variable, default=nil)
    SystemVariable.setvalue(variable,
                            prompt_variable(prompt,
                                            variable,
                                            SystemVariable.string(variable) || default))
  end

  def set_iauthority
    port = SystemVariable.number(:portnum) || 443
    portinfo = sprintf(":%u", port)
    portinfo = "" if port == 443
    SystemVariable.setvalue(:jrc_iauthority, sprintf("%s%s",
                                                     SystemVariable.string(:hostname),
                                                     portinfo))

  end

  desc "Do initial setup of system variables, non-interactively, HOSTNAME=foo PORT=xxx"
  task :s0_set_hostname => :environment do
    unless ENV['HOSTNAME']
      puts "Must supply the HOSTNAME="
      exit
    end
    SystemVariable.setvalue(:hostname, ENV['HOSTNAME'])
    SystemVariable.setnumber(:portnum, ENV['PORT'])
    set_iauthority
    puts "Fountain URL is #{SystemVariable.string(:jrc_iauthority)}"

    if ENV['ACP_DOMAIN']
      SystemVariable.setvalue(:acp_domain, ENV['ACP_DOMAIN'])
    else
      SystemVariable.setvalue(:acp_domain, "acp")
    end

    if ENV['SWITCH_MAC']
      SystemVariable.setvalue(:switch_mac, ENV['SWITCH_MAC'])
    end
  end


  desc "Do initial setup of sytem variables"
  task :s0_setup_jrc => :environment do

    SystemVariable.dump_vars

    # initial serial number is now randomized, do not ask for it anymore.
    prompt_variable_value("Hostname for this instance",
                          :hostname)

    prompt_variable_value("ACP domain for this registrar",
                          :acp_domain)

    prompt_variable_value("Algorithm to use for Certification Authority ",
                          :domain_algo, 'ecdsa')

    prompt_variable_value("Curve/size to use for Certification Authority",
                          :domain_curve, 'secp384r1')

    prompt_variable_value("Algorithm to use for Registrar Key ",
                          :client_algo, 'ecdsa')

    prompt_variable_value("Curve/size to use for Registrar Key",
                          :client_curve, 'prime256v1')


    SystemVariable.dump_vars
  end

  desc "Set Registrar into ACP mode, with open registrar"
  task :s0_acp_mode => :environment do
    SystemVariable.setbool(:open_registrar, true)

    prompt_variable_value("ACP domain for this registrar",
                          :acp_domain)

    SystemVariable.acp_pool!
  end


end
