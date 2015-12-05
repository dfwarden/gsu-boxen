class people::dfwarden {
  include dropbox
  include alfred
  include java
  #include osx - need to do osx::something{'setting'}
  include iterm2::stable
  include iterm2::colors::solarized_light
  include iterm2::colors::solarized_dark

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
