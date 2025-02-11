from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension("your_module_name", ["your_module_name.pyx"]),
]

setup(
    name="your_package_name",
    ext_modules=cythonize(extensions),
)
