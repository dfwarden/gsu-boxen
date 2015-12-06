class people::dfwarden {

  # Variables used in this manifest
  $home            = "/Users/${::boxen_user}"
  $library         = "${home}/Library"
  $code            = "${home}/src"
  $boxendev        = "${code}/boxen-modules-dev"
  $dotfiles        = "${code}/dotfiles"
  $ohmyzsh         = "${code}/oh-my-zsh"
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

  include osx::no_network_dsstores

  include osx::global::key_repeat_delay
  class { 'osx::global::key_repeat_rate':
    rate => '2'
  }


  include osx::safari::enable_developer_mode
  # Safari settings that are not yet in osx::safari
  $safari_keys = [ 'AlwaysShowTabBar', 'ShowOverlayStatusBar', 'NewTabBehavior', 'NewWindowBehavior', 'ShowFullURLInSmartSearchField' ]
  # The following does not work yet
  #osx_default_enable('com.apple.safari', $safari_keys)
  boxen::osx_defaults { 'safari home page':
    domain => 'com.apple.safari',
    key    => 'HomePage',
    value  => 'https://google.com',
  }
  # end OSX settings


  # iTerm 2
  # Getting iTerm via brew cask is preferred, but I would have to implement
  # getting solarized color scheme...
  class { 'iterm2::stable':
    version => hiera('iterm2_version'),
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

  $brewcask_pkgs = ['adium', 'alfred', 'caffeine', 'dash', 'dropbox', 'firefox', 'flux', 'google-chrome', 'karabiner', 'seil', 'yujitach-menumeters']
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

  file { [$dotfiles, $ohmyzsh, $boxendev, $powerline_fonts]:
    ensure    => directory
  }

  repository { $dotfiles:
    source     => 'dfwarden/dotfiles',
    require    => File[$dotfiles]
  }

  repository { $ohmyzsh:
    source     => 'dfwarden/oh-my-zsh',
    require    => File[$ohmyzsh]
  }

  # Powerline, including fonts
  repository { $powerline_fonts:
    source  => 'powerline/fonts',
    require => File[$powerline_fonts],
  }
  exec { 'install Powerline fonts':
    command => "${powerline_fonts}/install.sh",
    unless  => "find ${library}/Fonts -type f -iname \\*powerline\\* | grep -qi powerline",
    require => Repository[$powerline_fonts],
  }


  file { 'menumeters config':
    path   => "${library}/Preferences/com.ragingmenace.MenuMeters.plist",
    ensure => 'link',
    target => "${dotfiles}/menumeters/com.ragingmenace.MenuMeters.plist",
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


  # Deploy .vimrc as file so we can refresh plugins
  file { 'dotfile vimrc':
    path    => "${home}/.vimrc",
    ensure  => 'file',
    source  => "${dotfiles}/vim/vimrc",
    require => Repository[$dotfiles],
    notify  => Exec['install vim plugins'],
  }
  exec { 'install vim plugins':
    command     => "/usr/bin/vim +PluginInstall +qall",
    refreshonly => true,
    require      => Repository["${home}/.vim/bundle/Vundle.vim"],
  }
  $vimdirs = [ "${home}/.vim", "${home}/.vim/bundle"]
  file { $vimdirs:
    ensure => 'directory',
    before => Repository["${home}/.vim/bundle/Vundle.vim"]
  }
  repository { "${home}/.vim/bundle/Vundle.vim":
    source     => 'VundleVim/Vundle.vim',
  }


  # Mac OS Python 2.7.x doesn't come with virtualenv
  exec { 'install pip':
    command => '/usr/bin/easy_install pip',
    creates => '/usr/local/bin/pip',
    user    => 'root',
  }
  $pip_packages = ['virtualenv']
  package { $pip_packages:
    ensure   => 'installed',
    provider => 'pip',
    require  => Exec['install pip'],
  }


  # Git settings
  include git
  git::config::global { 'user.email':
    value    => 'dfwarden@gmail.com'
  }
  git::config::global { 'user.name':
    value    => 'David Warden'
  }


}
