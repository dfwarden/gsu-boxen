# GSU Boxen

This is a tool to help bootstrap your working environment on your Mac.

It is not intended to replace Deployment/Munki but rather augment it with
artifacts common to our organization. It also allows each user to define their own
personal preferences.

This expects you have a Github account. I'd like to figure out a way to use
our AD accounts instead.

## Getting Started

To give you a brief overview, we're going to:

* Install dependencies (basically Xcode Command Line tools)
* Run Boxen

There are a few potential conflicts to keep in mind.
Boxen does its best not to get in the way of a dirty system,
but you should check into the following before attempting to install your
boxen on any machine (we do some checks before every Boxen run to try
and detect most of these and tell you anyway):

* Boxen __requires__ at least the Xcode Command Line Tools installed.
* Boxen __will not__ work with an existing rvm install.
* Boxen __may not__ play nice with a Github username that includes dash(-)
* Boxen __may not__ play nice with an existing rbenv install.
* Boxen __may not__ play nice with an existing chruby install.
* Boxen __may not__ play nice with an existing homebrew install.
* Boxen __may not__ play nice with an existing nvm install.
* Boxen __recommends__ installing the full Xcode.

### Dependencies

**Install the Xcode Command Line Tools and/or full Xcode.**
This will grant you the most predictable behavior in building apps like
MacVim.

How do you do it?

#### OS X 10.10+ (Yosemite, El Capitan)

1. Open terminal and run `git`
2. Follow the prompts to install Command Line Tools

#### OS X 10.9 (Mavericks)

If you are using [`b26abd0` of boxen-web](https://github.com/boxen/boxen-web/commit/b26abd0d681129eba0b5f46ed43110d873d8fdc2)
or newer, it will be automatically installed as part of Boxen.
Otherwise, follow instructions below.

#### OS X < 10.9

1. Install Xcode from the Mac App Store.
1. Open Xcode.
1. Open the Preferences window (`Cmd-,`).
1. Go to the Downloads tab.
1. Install the Command Line Tools.

### Run Boxen

Putting this repo in /opt/boxen/repo is not explicitly necessary,
but creating /opt/boxen writable by you is.

```
sudo mkdir -p /opt/boxen
sudo chown ${USER}:staff /opt/boxen
git clone <location of my this git repository> /opt/boxen/repo
cd /opt/boxen/repo
sudo echo 'sudo make me a sandwich!'; ./script/boxen
```

Why run sudo just before? Some apps need elevated privs to be installed,
and running sudo before boxen means there will be a cached sudo session
boxen can use.

Boxen nags you if you do not have FileVault enabled.
If that bothers you, you can run boxen with `--no-fde`.

### Tell User Environment About Boxen

For users without a bash or zsh config or a `~/.profile` file,
Boxen will create a shim for you that will work correctly.
If you do have a `~/.bashrc` or `~/.zshrc`, your shell will not use
`~/.profile` so you'll need to add a line like so at _the end of your config_:

``` sh
[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh
```

Once your shell is ready, open a new tab/window in your Terminal
and you should be able to successfully run `boxen --env`.
If that runs cleanly, you're in good shape.

## What You Get

This template project provides the following by default:

* Homebrew
* Homebrew-Cask
* Git
* Hub
* 1Password
* Hipchat
* Java (currently 8.latest)

Traditional Mac apps are install to your user's Applications dir (/Users/$username/Applications).

## Customizing

Boxen uses Puppet internally, which can be confusing (especially to newcomers).
If you are new, check out `./manifests/site.pp` and other users' .pp files
in `./modules/people/manifests/` for examples of how to do things like install apps.

Some good Puppet resources for beginners:
  * [Puppet Basics](https://docs.puppetlabs.com/puppet/latest/reference/lang_summary.html)
  * [Puppet Visual Index](https://docs.puppetlabs.com/puppet/latest/reference/lang_visual_index.html)
  * [Puppet Standard Types](https://docs.puppetlabs.com/references/latest/type.html)

### User-specific Configs

Boxen looks in `./modules/people/manifests/` for a file called `$username.pp` where $username is
your username in Mac OS. If found, Boxen will execute that Puppet manifest. This is where your
user-specific configuration should go.

### Including boxen modules from github (boxen/puppet-<name>)

Using Boxen Puppet modules to install software is deprecated in favor of
homebrew's "cask" system. Please see `./manifests/site.pp` for examples.

You can always check out the number of existing modules from the
[boxen organization](https://github.com/boxen). These modules are all
tested to be compatible with Boxen. Use the `Puppetfile` to pull them
in dependencies automatically whenever `boxen` is run.

You must add the github information for your added Puppet module into your Puppetfile at the root of your
boxen repo (ex. /path/to/your-boxen/Puppetfile):

    # Core modules for a basic development environment. You can replace
    # some/most of these if you want, but it's not recommended.

    github "repository", "2.0.2"
    github "dnsmasq",    "1.0.0"
    github "gcc",        "1.0.0"
    github "git",        "1.2.2"
    github "homebrew",   "1.1.2"
    github "hub",        "1.0.0"
    github "inifile",    "0.9.0", :repo => "cprice404/puppetlabs-inifile"
    github "nginx",      "1.4.0"
    github "nodejs",     "2.2.0"
    github "ruby",       "4.1.0"
    github "stdlib",     "4.0.2", :repo => "puppetlabs/puppetlabs-stdlib"
    github "sudo",       "1.0.0"

    # Optional/custom modules. There are tons available at
    # https://github.com/boxen.

    github "java",     "1.6.0"

In the above snippet of a customized Puppetfile, the bottom line
includes the Java module from Github using the tag "1.6.0" from the github repository
"[boxen/puppet-java/releases](https://github.com/boxen/puppet-java/releases)".  The function "github" is defined at the top of the Puppetfile
and takes the name of the module, the version, and optional repo location:

    def github(name, version, options = nil)
      options ||= {}
      options[:repo] ||= "boxen/puppet-#{name}"
      mod name, version, :github_tarball => options[:repo]
    end

Now Puppet knows where to download the module from when you include it in your site.pp or mypersonal.pp file:

    # include the java module referenced in my Puppetfile with the line
    # github "java",     "1.6.0"


### Hiera

Hiera is preferred mechanism to make changes to module defaults (e.g. default
global ruby version, service ports, etc). This repository supplies a
starting point for your Hiera configuration at `config/hiera.yml`, and an
example data file at `hiera/common.yaml`. See those files for more details.

The default `config/hiera.yml` is configured with a hierarchy that allows
individuals to have their own hiera data file in
`hiera/users/{github_login}.yaml` which augments and overrides
site-wide values in `hiera/common.yaml`. This default is, as with most of the
configuration in the example repo, a great starting point for many
organisations, but is totally up to you. You might want to, for
example, have a set of values that can't be overridden by adding a file to
the top of the hierarchy, or to have values set on specific OS
versions:

```yaml
# ...
:hierarchy:
  - "global-overrides.yaml"
  - "users/%{::github_login}"
  - "osx-%{::macosx_productversion_major}"
  - common
```

### Node definitions

Puppet has the concept of a
['node'](http://docs.puppetlabs.com/references/glossary.html#agent),
which is essentially the machine on which Puppet is running. Puppet looks for
[node definitions](http://docs.puppetlabs.com/learning/agent_master_basic.html#node-definitions)
in the `manifests/site.pp` file in the Boxen repo. You'll see a default node
declaration that looks like the following:

``` puppet
node default {
  # core modules, needed for most things
  include dnsmasq

  # more...
}
```

### How Boxen interacts with Puppet

Boxen runs everything declared in `manifests/site.pp` by default.
But just like any other source code, throwing all your work into one massive
file is going to be difficult to work with. Instead, we recommend you
use modules in the `Puppetfile` when you can and make new modules
in the `modules/` directory when you can't. Then add `include $modulename`
for each new module in `manifests/site.pp` to include them.
One pattern that's very common is to create a module for your organization
(e.g., `modules/github`) and put an environment class in that module
to include all of the modules your organization wants to install for
everyone by default. An example of this might look like so:

``` puppet
# modules/github/manifests/environment.pp

 class github::environment {
   include github::apps::mac

   include ruby::1-8-7

   include projects::super-top-secret-project
 }
```

 If you'd like to read more about how Puppet works, we recommend
 checking out [the official documentation](http://docs.puppetlabs.com/)
 for:

 * [Modules](http://docs.puppetlabs.com/learning/modules1.html#modules)
 * [Classes](http://docs.puppetlabs.com/learning/modules1.html#classes)
 * [Defined Types](http://docs.puppetlabs.com/learning/definedtypes.html)
 * [Facts](http://docs.puppetlabs.com/guides/custom_facts.html)

### Creating a personal module

See [the documentation in the
`modules/people`](modules/people/README.md)
directory for creating per-user modules that don't need to be applied
globally to everyone.

### Creating a project module

See [the documentation in the
`modules/projects`](modules/projects/README.md)
directory for creating organization projects (i.e., repositories that people
will be working in).

## Binary packages

We support binary packaging for everything in Homebrew, rbenv, and nvm.
See `config/boxen.rb` for the environment variables to define.

## Sharing Boxen Modules

If you've got a Boxen module you'd like to be grouped under the Boxen org,
(so it can easily be found by others), please file an issue on this
repository with a link to your module.
We'll review the code briefly, and if things look pretty all right,
we'll fork it under the Boxen org and give you read+write access to our
fork.
You'll still be the maintainer, you'll still own the issues and PRs.
It'll just be listed under the boxen org so folks can find it more easily.

##upgrading boxen
See [FAQ-Upgrading](https://github.com/boxen/our-boxen/blob/master/docs/faq.md#q-how-do-you-upgrade-your-boxen-from-the-public-our-boxen).

## Integrating with Github Enterprise

If you're using a Github Enterprise instance rather than github.com,
you will need to set the `BOXEN_GITHUB_ENTERPRISE_URL` and
`BOXEN_REPO_URL_TEMPLATE` variables in your
[Boxen config](config/boxen.rb).

## Halp!

See [FAQ](https://github.com/boxen/our-boxen/blob/master/docs/faq.md).

Use Issues or #boxen on irc.freenode.net.
