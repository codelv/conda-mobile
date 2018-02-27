# conda-mobile

A collection of conda recipes for cross compiling libraries, python, and 
python extensions for iOS and Android.

The idea is to be able to easily create a python distribution that works on 
Android and iOS by simply using `conda install android-<package>` or 
`conda install ios-<package>` within an environment created for a specific app.

These recipes have been tested and confirmed working using a dev version of 
[enaml-native](https://github.com/codelv/enaml-native) (yet to be released).

### Targets

Currently all recipes are built for Python 2.7.14 with optional support for openssl and 
ctypes for the following targets:

- Android (arm (armeabi-v7a), arm64 (arm64-v8a), x86_64, x86 (i686))
- iPhone (armv7, aarch64)
- iPhone Simulator (x86_64, i386)

> Note: All libs and extensions are built as unstripped shared modules. Android strips
libraries automatically.

Packages are installed into the env using a prefix for the target platform as follows

- `iphoneos` - iOS recipes for the IPhone (armv7 and arm64)
- `iphonesimulator` - iOS recipes for the IPhone simulator (x86_64 and i386)
- `android/<arch>` - Android recipes for a given arch (arm (v7a), arm64, x86_64, x86)


Each target then contains it's own include, lib, and python folders as follows

```
# In <env>/<target> (ex miniconda2/envs/myapp/iphoneos)

iphoneos/include/ # All headers
iphoneos/libs/ # All shared libraries files
iphoneos/python/ # Python stdlib and site-packages 

```

Recipes can easily reference these locations using appropriate `CFLAGS` and `LDFLAGS`.

### Usage

This requires `conda`. The preferred method is to install `miniconda2` from 
[conda.io/miniconda.html](https://conda.io/miniconda.html).

1. Create an env `conda create -n myapp`
2. Activate it `source activate myapp`
3. Add this channel `conda --add-channel conda-mobile`
4. Then install your apps dependencies using the the `android` or `ios` prefix. 
For example `conda install ios-python ios-msgpack`  


Pure python packages can be installed with pip using the `--target` to tell it
where to install. `pip install tornado --target=$CONDA_PREFIX/iphoneos/python/site-packages`
or (preferred) create a conda package for it.

Once the packages are installed, the build system (gradle, xcode) can then easily grab 
these libraries from the env for the given target and use them as is. 

> Note: An import hook is required to load python extensions from "non" standard locations. 
[enaml-native](https://github.com/codelv/enaml-native) supports this. 


### Building recipes

Only developers of packages should need to build recipes. End users should
be able to simply install and use prebuilt versions. 

See the [conda docs](https://conda.io/docs/user-guide/tasks/build-packages/index.html)
to get started.

To add a new recipe or to build existing recipes:

1. Install `miniconda2`
2. Install conda-build via `conda install conda-build` (recommended outside of an env)
2. Clone this repo or create your own recipe(s)
3. Add the requirements to your recipes as needed
5. Run `conda-build <recipe-name>`

Then either add a PR or create your own repos with recipes.

> Note: If using linux with an encrypted home directory you may have to build in a different
root to avoid "path to long" errors. Add the `--croot=/tmp/conda` or some other path to 
fix this.


### Contributing 

Please donate to [enaml-native](https://www.codelv.com/projects/enaml-native/support/) or
[kivy](https://kivy.org/#home) to help continue supporting python frameworks that run on 
mobile devices.

This is released under the GPL v3. See the LICENSE included adjacent to this file.

Pull requests are always welcome.