# ♜ Warden

Quickly, **Warden** check periodically your files, run a specific command, and run a git command if you want and the command succeed. 

![Warden](http://i.imgur.com/KFJj0K9.png)

Based on [Guardian](https://github.com/f/guardian), but better. :P

## Installation

For **Linux**, just run `sudo ./install/linux.sh`

It install this program into `/usr/bin/warden`, the config file into `/usr/share/warden/config.yml`, and an unstalling  script into `/usr/share/warden/uninstall.sh`.
  

## Uninstallation (but you don't need it)

* You can run the following command `sudo warden --uninstall`
* You can run `sudo /usr/share/warden/uninstall.sh`
* You can also run `sudo rm -r /usr/share/warden/ /usr/bin/warden`


*N.B.:* all commands are equivalent, but build in option command is recommanded

## Usage

## Run Warden

Simply run `warden` command, easy no?

### Options

* `$ warden -i`              : Init project file automatically
* `$ warden --init`          : Init project file automatically

* `$ warden -d 1500`         : change the delay (in ms) between two files watch (min = 250)
* `$ warden --delay=1500`    : change the delay (in ms) between two files watch (min = 250)

* `$ warden -t 10000`        : Change the time (in ms) before which a command is killed (min = 250)
* `$ warden --timeout=10000` : Change the time (in ms) before which a command is killed (min = 250)

* `$ warden -v`              : output the current version of Warden
* `$ warden --version`       : output the current version of Warden

* `$ warden -h`              : output help
* `$ warden -help`           : output help

* `$ warden --uninstall`     : uninstall this programm (you need to validate it). But ... you don't need this ;)

## Create a project file

`warden --init` or `warden --i` to create automatically a `.warden.yml` files, used by Wardan for.
The project file is **simply a YAML file**

Because I'm lazy, `.warden.yml` is automatically reload when it changed 🐨

## Write your `.warden.yml`

For your `.warden.yml` file, you have some simple parameters:
```yaml

delay: 1000 # change the delay (in ms) between to files watch (min = 250) [Facultative]
timeout: 2000 # Change the time (in ms) before which a command is killed (min = 250) [Facultative]

watch:

  - files: ./src/**/*.cr # all files in src and subdirectories
    run: shards build    # command to run when a file is changed
    git: add             # git command to play when a file is changed
    timeout: 10000       # it's timeout just for these files (useful for compilation)
  
  - files: ./*.cr                               # all .cr in this folder
    run: "crystal build #{file} -o #{basename}" # run for exemple 'crystal build main.cr main'
    git: none                                   # no git command 
    
  - files: ./*.md # run no command for every ".md" in this folder, simply notify you when it changed
```

### `files` parameter
This option is the glob pattern of files.

### `git` option
This option is facultative, you have some values:
  - **none** -> no git command
  - **add** -> run `git add <your file>`
  - **push** -> run `git push`
  - **pull** -> run `git pull`
  - **commit** -> **_Comming Soon_**
  
### `run` option
This option is the following command to run when a file is changed.

You have some specifics variables subsitution in this command to do make it easy to use, with the delimiter `#{}`.

Exemple for the file `./src/warden/version.cr` in `warden` folder:
  - `#{file}` -> print raw path of the file: `./src/warden/version`
  - `#{path}` -> print path without filename: `./src/warden/`
  - `#{basename}` -> print the filename without path and extension: `version`
  - `#{extname}` -> print the extension of the file: `.cr`
  - `#{dirname}` -> print the current folder name: `warden`
  - `#{pwd}` -> print the current directory, it's simply bash `pwd` command
  - `#{cwd}` -> like `pwd` but for those who prefer `C/C++` style ;)

**_P.S.:_** You can propose new substitutions :)


## Your own configuration `config.yml`

You have similary configuration with `.warden.yml` like:
  - `delay` in ms
  - `timeout` in ms

`target` is the target of the project file, by default it's `.warden.yml`

The last parameter is the `precommand` parameter, it's exactly like `watch` parameter in project file, but it used in `$ warden --init` for auto configuration, please, don't fucked up your parameter ;)

```yaml
precommand:
  # crystal - sources
  - files: ./src/**/*.cr
    run: shards build
    git: add
  # etc, ...
```

## Contributing

1. Fork it ( https://github.com/diggersheep/warden/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[github.com/diggersheep]](https://github.com/diggersheep) diggersheep - creator, maintainer
