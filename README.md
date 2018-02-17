# enaml-native-repo

This is an experimental repo for a new build system for cross compiling python 
libraries and extensions for iOS and Android using a common platform. 

The goal is to replace python-for-android and kivy-ios build systems with a 
repository of conda recipes to create precompiled packages that can simply be 
installed and used directly by gradle (Android) or xcode (iOS).


### Why?

Why do something else when kivy-ios and python-for-android are both 
well established projects?

- Versioning - Both existing build systems do not support versioning well. 
You cannot easily add or remove a specific version of a package which makes
it hard to create reproducible builds.

- Decentralized - Both p4a and kivy-ios have all the recipes in one repo and
it is often difficult for new recipes to make it into the main repo. Conda
supports installing from separate channels enabling anyone to build and share
their own recipes. Users can easily pick and choose which to use.

- Environments - Conda lets you install dependencies (including system level)
in their own environment so they don't interfere with other apps or system
packages. It also makes it easy to share the whole environment with others.

- Simplify - Kivy-ios and p4a are both very similar and complex build systems. 
Much of what they do (dependency management, downloading, building) can now be
done with pip or conda so there's no point in supporting another toolchain for 
this. 

- Clarity - Using separate and explicit build scripts makes it more clear 
which flags are being set when trying to debug a build issue.  Fixes for one
recipe won't break others.


##### Why Conda?

Conda was chosen over pip+virtualenv (or pipenv) because it aims to support both 
python packages and system libraries.  Cross compiling for iOS and Android projects 
requires both (CPython for example is not a python package) and conda makes the 
process the same for each.  It also easily lets you generate different outputs 
for each target platform and arch in a very clean manner. One conda recipe can
create outputs for both ios and android devices.

> See https://conda.io/docs/commands.html#conda-vs-pip-vs-virtualenv-commands


### Usage

App dependencies can be installed with `conda` or the `enaml-native-cli` (soon). 

1. Install `miniconda` from https://conda.io/miniconda.html
2. Create an env `conda create -n myapp`
3. Activate it `source activate myapp`
2. Then install `conda install iphoneos-python2.7`

Packages are prefixed for the target platform as follows

- `iphoneos` - iOS recipes for the IPhone (armv7 and arm64)
- `iphonesimulator` - iOS recipes for the IPhone simulator (x86_64)
- `android-<arch>` - Android recipes for a given arch (armv7a or x86)


The packages are installed into the env using the structure

```
# In <env>/<target> (ex miniconda2/envs/myapp/iphoneos)
include/ # All headers
libs/ # All .dylib or .so files
python/ # Python stdlib and site-packages 

```

The build system (gradle, xcode) can then easily grab these libraries from the
env for the given target and use them as is.


### Building

Only developers of packages should need to build recipes. End users should
be able to simply install and use prebuilt verisons. To build recipes

1. Install miniconda
2. Clone this repo or a recipe from somewhere and cd to this folder
3. Run `conda-build <recipe-name>`

You can also create your own repos with recipes.


### Thanks

These recipes are based on those from kivy-ios and python-for-android.