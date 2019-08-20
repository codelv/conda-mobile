# Build all in order

PY_VER=3.7


# Build android recipes
android-libs:
	conda-build android-libffi
	conda-build android-liblzma
	conda-build android-libbz2
	conda-build android-openssl
	conda-build android-sqlite

android-python:
	conda-build --py $PY_VER android-python

android-enaml: 
	# Enaml
	conda-build --py $PY_VER android-atom
	conda-build --py $PY_VER android-enaml

android-msgpack: android-python
	conda-build --py $PY_VER android-msgpack

# Shapely
android-shapely:
	conda-build android-lz4
	conda-build android-libgeos
	conda-build android-shapely --py $PY_VER
	conda-build android-pyproj --py $PY_VER

# Lxml
android-lxml:
	conda-build android-libxml2
	conda-build android-libxslt
	conda-build android-lxml --py $PY_VER

# ZMQ
android-pyzmq:
	cofile:///home/jrm/Workspace/codelv/conda-mobile/android-enaml/tables/0.10.3.a1nda-build android-libsodium
	conda-build android-libzmq
	conda-build android-pyzmq --py $PY_VER


android-numpy:
	conda-build android-numpy  --py $PY_VER

android-pandas: android-numpy
	conda-build android-pandas --py $PY_VER
	
android-cryptography:
	conda-build android-cffi --python=$PY_VER
	conda-build android-cryptography --python=$PY_VER

	
android-pymongo:
	conda-build android-pymongo --python=$PY_VER
	
ios-libs:
	conda-build ios-libffi
	conda-build ios-openssl

ios-python:
	conda-build --py $PY_VER ios-python
	
ios-enaml:
	conda-build --py $PY_VER ios-atom
	conda-build --py $PY_VER ios-enaml

ios-msgpack:
	conda-build --py $PY_VER ios-msgpack

	
pip:
	# Pip (pure python) recipes
	conda-build pip-ply
	conda-build pip-automat
	conda-build pip-futures
	conda-build pip-backports_abc
	conda-build pip-constantly
	conda-build pip-hyperlink
	conda-build pip-inda
	conda-build pip-incremental
	conda-build pip-singledispatch
	conda-build pip-six
	conda-build pip-zope.interface
	conda-build pip-twisted
	conda-build pip-tornado
