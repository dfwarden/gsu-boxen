# Dave's personal configs.

class people::dfwarden {

  # TODO: Get and configure Microsoft Remote Deskto
  # Connections are stored in /Users/$USER/Library/Containers/com.microsoft.rdc.mac/Data/Library/Preferences/com.microsoft.rdc.mac.plist
  # and can be read with defaults read com.microsoft.rdc.mac
  # but they are in a god-awful format.

  # Default to my user when reading/writing OSX defaults
  Boxen::Osx_defaults {
    user => $::boxen_user,
  }

  # Variables used in this manifest
  $home            = "/Users/${::boxen_user}"
  $library         = "${home}/Library"
  $code            = "${home}/src"
  $boxendev        = "${code}/boxen-modules-dev"
  $dotfiles        = "${code}/dotfiles"
  $ohmyzsh         = "${code}/oh-my-zsh"
  $powerline_fonts = "${code}/powerline-fonts"

  $brew_pkgs = ['tmux', 'zsh-completions', 'findutils', 'ack', 'gnu-tar', 'nmap', 'jq', 'httpie', 'vim', 'ssh-copy-id']
  $brewcask_pkgs = ['adium', 'alfred', 'bettertouchtool', 'caffeine', 'dash', 'dropbox', 'firefox', 'flux', 'google-chrome', 'karabiner', 'seil', 'yujitach-menumeters']

  # Some of these need sudo cached to work.
  # Just run sudo ls before scripts/boxen.
  package { $brewcask_pkgs:
    provider => 'brewcask'
  }
  package { $brew_pkgs: }


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
    domain      => 'com.googlecode.iterm2',
    key         => 'PrefsCustomFolder',
    value       => "${home}/.iterm2",
  }
  boxen::osx_defaults { 'iterm2 prefs folder enable':
    domain      => 'com.googlecode.iterm2',
    key         => 'LoadPrefsFromCustomFolder',
    value       => true,
  }
  file { 'iterm2 prefs symlink':
    ensure => 'link',
    path   => "${home}/.iterm2",
    target => "${dotfiles}/iterm2",
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
    ensure => 'link',
    path   => "${library}/Preferences/com.ragingmenace.MenuMeters.plist",
    target => "${dotfiles}/menumeters/com.ragingmenace.MenuMeters.plist",
  }


  # Set up Oh-My-Zsh and ZSH
  file { 'zshrc':
    ensure => 'link',
    path   => "${home}/.zshrc",
    target => "${dotfiles}/zsh/zshrc",
  }
  osx_chsh { $::boxen_user:
    shell => '/bin/zsh',
  }
  file { 'oh-my-zsh custom themes link':
    ensure => 'link',
    path   => "${ohmyzsh}/custom/themes",
    target => "${dotfiles}/zsh/themes",
  }


  # Vim settings and plugins
  $vimrc_dotfile = "${dotfiles}/vim/vimrc"
  file { $vimrc_dotfile:
      audit => 'content',
  }
  file { 'dotfile vimrc':
    ensure  => 'link',
    path    => "${home}/.vimrc",
    target  => $vimrc_dotfile,
    require => Repository[$dotfiles],
  }
  exec { 'install vim plugins':
    command     => '/usr/bin/vim +PluginInstall +qall',
    refreshonly => true,
    require     => Repository["${home}/.vim/bundle/Vundle.vim"],
    subscribe   => File[$vimrc_dotfile],
  }
  $vimdirs = [ "${home}/.vim", "${home}/.vim/bundle"]
  file { $vimdirs:
    ensure => 'directory',
    before => Repository["${home}/.vim/bundle/Vundle.vim"]
  }
  repository { "${home}/.vim/bundle/Vundle.vim":
    source => 'VundleVim/Vundle.vim',
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
  # From http://willi.am/blog/2015/02/27/dynamically-configure-your-git-email/,
  # dynamically set email address when cloning a new repo.
  file { 'git-scripts link':
    ensure => 'link',
    path   => "${home}/.git-scripts",
    target => "${dotfiles}/git/scripts",
  }
  file { 'git post-checkout default hook':
    ensure => 'link',
    path   => '/usr/local/share/git-core/templates/hooks/post-checkout',
    target => "${dotfiles}/git/hooks/post-checkout",
  }

  # Karabiner settings
  # TODO: refactor https://github.com/boxen/puppet-karabiner to work with
  # brew cask Karabiner but retain the XML and CLI functionality...
  $karabiner_private_dotfile = "${dotfiles}/karabiner/private.xml"
  file { $karabiner_private_dotfile:
      audit => 'content',
  }
  file { 'karabiner private.xml':
    ensure => 'link',
    path   => "${library}/Application Support/Karabiner/private.xml",
    target => $karabiner_private_dotfile,
  }
  exec { 'karabiner settings refresh':
    path        => "${dotfiles}/karabiner/set_options.sh",
    refreshonly => true,
    subscribe   => File[$karabiner_private_dotfile],
  }

  # BetterTouchTool settings
  # TODO: Refactor https://github.com/boxen/puppet-boxen/blob/master/manifests/osx_defaults.pp to support complex types.
  $btt_profile = "${::boxen_user}_profile"
  $btt_presets = "<array><dict><key>fileName</key><string>bttdata2</string><key>presetName</key><string>Default</string></dict><dict><key>fileName</key><string>${btt_profile}</string><key>presetName</key><string>${btt_profile}</string></dict></array>"
  $btt_dotfile = "${dotfiles}/bettertouchtool/profile"
  file { $btt_dotfile:
      audit => 'content',
  }
  file { 'btt support dir':
    ensure => 'directory',
    path    => "${library}/Application Support/BetterTouchTool",
  }
  file { 'btt custom preset':
    ensure  => 'link',
    path    => "${library}/Application Support/BetterTouchTool/${btt_profile}",
    target  => $btt_dotfile,
    require => File['btt support dir'],
  }
  boxen::osx_defaults { 'btt presets append settings':
    domain      => 'com.hegenberg.BetterTouchTool',
    key         => 'presets',
    value       => $btt_presets,
    refreshonly => true,
    subscribe   => File[$btt_dotfile],
  }
  boxen::osx_defaults { 'btt select custom preset':
    domain      => 'com.hegenberg.BetterTouchTool',
    key         => 'currentStore',
    value       => $btt_profile,
    refreshonly => true,
    subscribe   => File[$btt_dotfile],
  }
  boxen::osx_defaults { 'btt enable window snapping':
    domain      => 'com.hegenberg.BetterTouchTool',
    key         => 'windowSnappingEnabled',
    value       => true,
  }

  # Firefox Vimperator Plugin
  file { 'vimperator local config':
    ensure => 'link',
    path   => "${home}/.vimperatorrc.local",
    target => "${dotfiles}/vimperator/vimperatorrc.local",
  }

}
