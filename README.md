# Setup

Generally, you want to

```
git submodule add --name shlib https://github.build.ge.com/Lynny/shlib.git bin/.shlib
(cd bin && ln -s .shlib/lib .
```

To initializa at the path "submodules/shlib":

```
git submodule add --name shlib https://github.build.ge.com/Lynny/shlib.git submodules/shlib
(cd bin && ln -s ../submodules/shlib/lib .)
```
