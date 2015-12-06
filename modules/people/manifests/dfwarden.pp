class people::dfwarden {

  # Variables used in this manifest
  $home		= "/Users/${::boxen_user}"
  $code		= "${home}/src"
  $boxendev = "${code}/boxen-modules-dev"
  $dotfiles	= "${code}/dotfiles"
  $ohmyzsh	= "${code}/oh-my-zsh"
  $powerline_fonts = "${code}/powerline-fonts"

  # OSX settings - https://github.com/boxen/puppet-osx
  include osx::global::enable_keyboard_control_access

  include osx::global::expand_print_dialog
  include osx::global::expand_save_dialog
  include osx::global::disable_remote_control_ir_receiver
  include osx::global::disable_autocorrect

  include osx::dock::autohide
  include osx::dock::disable_dashboard

  include osx::finder::show_all_on_desktop
  include osx::finder::unhide_library
  include osx::finder::enable_quicklook_text_selection
  include osx::finder::show_all_filename_extensions
  include osx::finder::no_file_extension_warnings

  include osx::safari::enable_developer_mode
  include osx::no_network_dsstores

  include osx::global::key_repeat_delay
  include osx::global::key_repeat_rate
  # end OSX settings


  # Update the following when a new iTerm2 comes out.
  class { 'iterm2::stable':
    version => $::iterm2_version,
  }
  include iterm2::colors::solarized_light
  include iterm2::colors::solarized_dark
  boxen::osx_defaults { 'iterm2 prefs folder define':
    domain => 'com.googlecode.iterm2',
    key    => 'PrefsCustomFolder',
    value  => "${home}/.iterm2",
  }
  boxen::osx_defaults { 'iterm2 prefs folder enable':
    domain => 'com.googlecode.iterm2',
    key    => 'LoadPrefsFromCustomFolder',
    value  => '1',
  }
  file { 'iterm2 prefs symlink':
    path   => "${home}/.iterm2",
    ensure => 'link',
    target => "${dotfiles}/iterm2",
  }

  $brewcask_pkgs = ['alfred']
  # Some of these need sudo cached to work.
  # Just run sudo ls before scripts/boxen.
  package { $brewcask_pkgs:
    provider => 'brewcask'
  }

  # Install packages from homebrew
  $brew_pkgs = ['tmux']
  package { $brew_pkgs: }

  class { 'dropbox':
    version => $::dropbox_version,
  }

  include java

  include dash
  include firefox
  include hipchat
  include onepassword
  include caffeine
  include adium

  file { [$dotfiles, $ohmyzsh, $boxendev, $powerline_fonts]:
    ensure	=> directory
  }

  repository { $dotfiles:
    source 	=> 'dfwarden/dotfiles',
    require	=> File[$dotfiles]
  }
  repository { $ohmyzsh:
    source 	=> 'dfwarden/oh-my-zsh',
    require	=> File[$ohmyzsh]
  }

  # Menumeters for 10.11 El Capitan
  file { 'menumeters config':
    path   => "${home}/Library/Preferences/com.ragingmenace.MenuMeters.plist",
    ensure => 'link',
    target => "${dotfiles}/menumeters/com.ragingmenace.MenuMeters.plist",
  }
  exec { 'deploy menumeters prefpane':
    command => "/usr/bin/unzip -o ${dotfiles}/menumeters/MenuMeters_1.9.1.zip -d ${home}/Library/PreferencePanes",
    unless  => "plutil -convert json -o - ${home}/Library/PreferencePanes/MenuMeters.prefPane/Contents/Info.plist | grep -q '\"CFBundleVersion\":\"1.9.1\"'",
    require => Repository[$dotfiles],
  }

  # Powerline, including fonts
  repository { $powerline_fonts:
    source  => 'powerline/fonts',
    require => File[$powerline_fonts],
  }
  exec { 'install Powerline fonts':
    command => "${powerline_fonts}/install.sh",
    unless  => "find ${home}/Library/Fonts -type f -iname \\*powerline\\* | grep -qi powerline",
    require => Repository[$powerline_fonts],
  }

  # Set up Oh-My-Zsh and ZSH
  file { 'zshrc':
    path   => "${home}/.zshrc",
    ensure => 'link',
    target => "${ohmyzsh}/templates/zshrc.${::boxen_user}",
  }
  osx_chsh { $::boxen_user:
    shell => '/bin/zsh',
  }


  # Git settings
  include git
  git::config::global { 'user.email':
    value	=> 'dfwarden@gmail.com'
  }
  git::config::global { 'user.name':
    value	=> 'David Warden'
  }

  # Deploy .vimrc (possibly switch to dotfiles deploy)
  file { 'dotfile vimrc':
    path    => "${home}/.vimrc",
    ensure  => 'link',
    target  => "${dotfiles}/vim/vimrc",
    require => Repository[$dotfiles]
  }
  $vimdirs = [ "${home}/.vim", "${home}/.vim/bundle"]
  file { $vimdirs:
    ensure => 'directory',
    before => Repository["${home}/.vim/bundle/Vundle.vim"]
  }
  repository { "${home}/.vim/bundle/Vundle.vim":
    source 	=> 'VundleVim/Vundle.vim',
  }


  # Keyboard remapping stuff
  include seil
  include seil::login_item
  seil::bind { 'keyboard bindings':
    mappings => {
      'capslock' => 53
    }
  }
  include karabiner
  include karabiner::login_item

}
