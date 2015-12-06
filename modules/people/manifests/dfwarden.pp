class people::dfwarden {

  # OSX settings - https://github.com/boxen/puppet-osx
  include osx::global::expand_print_dialog
  include osx::global::expand_save_dialog
  include osx::global::disable_remote_control_ir_receiver
  include osx::global::disable_autocorrect

  # Update the following when a new iTerm2 comes out.
  include iterm2::stable
  include iterm2::colors::solarized_light
  include iterm2::colors::solarized_dark

  $brewcask_pkgs = ['alfred']
  # Some of these need sudo cached to work.
  # Just run sudo ls before scripts/boxen.
  package { $brewcask_pkgs:
    provider => 'brewcask'
  }

  include dropbox
  include java

  include dash
  include firefox
  include hipchat
  include onepassword
  include caffeine
  include adium
  include menumeters

  # Local "dev" boxen puppet modules

  $home		= "/Users/${::boxen_user}"
  $code		= "${home}/src"
  $boxendev = "${code}/boxen-modules-dev"
  $dotfiles	= "${code}/dotfiles"
  $ohmyzsh	= "${code}/oh-my-zsh"

  file { [$dotfiles, $ohmyzsh, $boxendev]:
    ensure	=> directory
  }

  repository { $dotfiles:
    source 	=> 'dfwarden/dotfiles',
    require 	=> File[$dotfiles]
  }
  repository { $ohmyzsh:
    source 	=> 'dfwarden/oh-my-zsh',
    require 	=> File[$ohmyzsh]
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
  file { "${home}/.vimrc":
    target 	=> "${dotfiles}/.vimrc",
    require	=> Repository[$dotfiles]
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
