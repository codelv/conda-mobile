# conda-mobile

A collection of conda recipes for cross compiling libraries, python, and
python extensions for iOS and Android.

[![status](https://github.com/codelv/conda-mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/codelv/conda-mobile/actions)

The idea is to be able to easily create a python distribution that works on
Android and iOS by simply using `conda install android-<package>` or
`conda install ios-<package>` within an environment created for a specific app.

These recipes have been tested and confirmed working using
[enaml-native](https://github.com/codelv/enaml-native).

Visit [anaconda.org/codelv/repo](https://anaconda.org/codelv/repo) to see which
packages are available.


### Targets

Currently all recipes are built 3.10.2 with optional support for
openssl, sqlite, and ctypes for the following targets:

- Android (arm (armeabi-v7a), arm64 (arm64-v8a), x86_64, x86 (i686))

At one time iPhone builds worked but they are no longer being maintained.

- iPhone (armv7, aarch64)
- iPhone Simulator (x86_64, i386)

> Note: All libs and extensions are built as unstripped shared modules.
>Android strips libraries automatically.

Packages are installed into the env using a prefix for the target platform as follows

- `android/<arch>` - Android recipes for a given arch (arm (v7a), arm64, x86_64, x86)
- `iphoneos` - iOS recipes for the IPhone (armv7 and arm64)
- `iphonesimulator` - iOS recipes for the IPhone simulator (x86_64 and i386)



Each target then contains it's own include, lib, and python folders as follows

```
# In <env>/<target> (ex miniconda3/envs/myapp/iphoneos)

<target>/include/ # All headers
<target>/libs/ # All shared libraries files
<target>/python/ # Python stdlib and site-packages

```

Recipes can easily reference these locations using appropriate `CFLAGS` and `LDFLAGS`.

### Building packages

Only developers of packages should need to build recipes. End users should
be able to simply install and use prebuilt versions.

See the [conda docs](https://conda.io/docs/user-guide/tasks/build-packages/index.html)
to get started.

There are three general recipe types that are generally relevant for conda-mobile:

 1. Pure python packages, no extensions
 2. Python package with, with extensions
 3. Non python dependent libs


Pure python packages are prefixed with `pip-<package>` to distinguish them between regular
conda packages that may exist with the same name. You can create these package (almost)
automatically using the [enaml-native-cli](https://github.com/codelv/enaml-native-cli)'s
`enaml-native make-pip-recipe <package>` command.

Libraries with compiled extensions / cython components are split  into separate packages with
the prefix `ios-<package>` and `android-package`. Otherwise all packages would need to be
built from mac osx.

To add a new recipe or to build existing recipes:

1. Install `miniconda3`
2. Install conda-build via `conda install conda-build` (recommended outside of an env)
3. Clone this repo or create your own recipe(s)
4. Install the android ndk using `sdkmanager "ndk:23.1.7779620"` (or update the android-ndk recipe)
5. Add the requirements to your recipes as needed
6. If building an extension or c/c++ library install `build-essential`,  `rename`, `autopoint`, and `texinfo` with apt
7. Run `conda-build <recipe-name>` (python extensions must be built separately for
    `2.7` and `3.10` by specifying it as an argument ex `conda-build --py 3.10 <recipe-name>`)
8. Then either add a PR or create your own repos with recipes.

> Note: If using linux with an encrypted home directory you may have to build in a different
root to avoid "path to long" errors. Add the `--croot=/opt/conda` or some other path to
fix this.

#### Recipe requirements

Now that both python 2.7 and 3.10 are supported all recipes that build python extensions MUST
include `py27` or `py310` in the build string so conda knows which version to install.
conda will do this automatically if you simply include `python` in the run
requirements of your recipe (even though the ios / android version is actually used on the
app). Alternatively you can manually set `string: py{{CONDA_PY}}` under the `build` section.

In addition to specifying a build string, any requirements that have python extensions must
filter by the build string since conda does not do this automatically at the moment.

> Note: This only applies to python extensions. Pure c/c++ libraries do not need to do this!

For example:

```yaml

requirements:
  build:
    - python
    - cython
    - android-ndk
    - android-python * py{{CONDA_PY}}*
    - android-libc++
  run:
    - python # Adding python here make conda append the py27 or py37 build string
    - android-python  * py{{CONDA_PY}}* # Required so it installs the correct pkg for the py version
    - android-libc++ # Pure c/c++ libraries do not need a "build" filter

```

Failure to include python as a run requirement may cause conda to install the incorrect
packages (ie a 2.7 package may be selected for a 3.10 python build!).

In order to make your package "installable" from other operating systems (ie windows) the
recipe must use `noarch:generic` in the `build` parameters as follows.

```yaml

build:
    binary_relocation: False
    noarch: generic

```

The `binary_relocation: False` prevents conda from doing it's relocation logic on the
libraries created which can cause issues.


### Installing packages

This requires `conda`. The preferred method is to install `miniconda3` from
[conda.io/miniconda.html](https://conda.io/miniconda.html).

1. Create an env `conda create -n myapp`
2. Activate it `source activate myapp`
3. Add this channel `conda config --add channels codelv`
4. Then install your apps dependencies using the the `android` or `ios` prefix.
For example `conda install ios-python ios-msgpack`


Pure python packages can be installed with pip using the `--target` to tell it
where to install. `pip install tornado --target=$CONDA_PREFIX/iphoneos/python/site-packages`
or (preferred) create a conda package for it using `enaml-native make-pip-recipe <package>`.

Once the packages are installed, the build system (gradle, xcode) can then easily grab
these libraries from the env for the given target and use them as is.

> Note: An import hook is required to load python extensions from "non" standard locations.
[enaml-native](https://github.com/codelv/enaml-native) supports this.


### Contributing

This is released under the GPL v3. See the LICENSE included adjacent to this file.

Pull requests are always welcome.
