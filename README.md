# enaml-native-repo


Once a package is built it can be uploaded to conda so the precompiled modules
can be used directly by apps without the headaches of figuring out how to
build it on your system. This allows developers on windows to build Android
apps (a mac is still requires for iOS).

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


##### Conda vs pip

Conda was chosen over pip because it aims to support both python packages and
system libraries.  Cross compiling for iOS and Android projects requires 
both (CPython for example is not a python package) and conda makes the process 
the same for each.  It also easily lets you generate different outputs for each 
target platform and arch.


### Installing

App dependencies can be installed with `conda` or the `enaml-native-cli`. 

1. Install `miniconda` from https://conda.io/miniconda.html
1. Install the `pip install --user enaml-native-cli`
2. Then `enaml-native install iphoneos-python`

Packages are prefixed for the target platform as follows

- `iphoneos` - iOS recipes for the IPhone (armv7 and arm64)
- `iphonesimulator` - iOS recipes for the IPhone simulator (x86_64)
- `android` - Android recipes for devices (armv7a)
- `androidsimulator` - Android recipes for the simulators (x86_64)


For example `conda install iphoneos-python==2.7.14` installs a package with
libpython2.7.14, stdlib, and headers cross compiled for the IPhone along with
it's dependencies (libffi and openssl) which are also already cross compiled 
for you.  Yes it's THAT easy.

### Building

To build recipes

1. Install miniconda
2. Clone this repo and cd to this folder
3. Run `conda-build <recipe-name>`

You can also create your own repos with recipes.


### Thanks

These recipes are based on those from kivy-ios and python-for-android.