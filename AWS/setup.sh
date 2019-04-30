#!/bin/bash

#
# Setup script to install QMCPACK, Quantum Espresso (QE/PWSCF), PySCF, Quantum Package (QP),
# and workshop files for QMCPACK 2019 workshop https://qmc2019.ornl.gov/
#
# Assumes a vanilla Ubuntu 18.04 LTS or similar and x86 architecture
# Script is safely rerunnable
# 
echo -- START `date`
sudo apt-get -y update
sudo apt-get -y install cmake g++ gfortran libboost-dev libhdf5-dev libxml2-dev 
sudo apt-get -y install python-numpy python-matplotlib #This will also install python27
sudo apt-get -y install python-h5py

# Requirements for full NEXUS demo:
sudo apt-get -y install python-numpy python-scipy python-h5py python-matplotlib python-pydot python-pip
pip install --user spglib
pip install --user seekpath

echo --- Intel files setup `date`
# Setup Intel MKL and MPI
# Instructions from https://software.intel.com/en-us/articles/installing-intel-free-libs-and-python-apt-repo
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
rm -f GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
#Full Intel MKL+Python products 
sudo wget https://apt.repos.intel.com/setup/intelproducts.list -O /etc/apt/sources.list.d/intelproducts.list 
#MKL:  
#sudo sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list'  
#Intel MPI
#sudo sh -c 'echo deb https://apt.repos.intel.com/mpi all main > /etc/apt/sources.list.d/intel-mpi.list'
sudo apt-get -y update
sudo apt-get -y install intel-mkl-2019.3-062 #Be patient
sudo apt-get -y install intel-mpi-2019.3-062 #Be patient

echo --- Tools `date`
# Nice to have tools
sudo apt-get -y install emacs-nox
sudo apt-get -y install gnuplot

# Setup Intel MKL variables, path
source /opt/intel/mkl/bin/mklvars.sh intel64
# Setup Intel MPI variables, path
source /opt/intel/impi/2019.3.199/intel64/bin/mpivars.sh

if [ ! -e $HOME/apps ]; then
    mkdir $HOME/apps
fi
cd $HOME/apps

# HDF5 installation
if [ ! -e hdf5-hdf5-1_10_5-gcc-impi/lib/libhdf5.a ]; then   
echo --- Installing HDF5 `date`
    wget https://github.com/live-clones/hdf5/archive/hdf5-1_10_5.tar.gz
    tar xvf hdf5-1_10_5.tar.gz
    #XXX rm -f hdf5-1_10_5.tar.gz
    mkdir hdf5-hdf5-1_10_5-gcc-impi
    cd hdf5-hdf5-1_10_5-gcc-impi/
    INSTALLDIR=`pwd`
    echo INSTALLDIR=$INSTALLDIR
    CC=mpigcc FC=mpif90 ../hdf5-hdf5-1_10_5/configure --enable-parallel --enable-fortran  --prefix=$INSTALLDIR >&configure.out
    make >&make.out
    make install 
    cd ..
fi

# QMCPACK
# XXX consider using our HDF5 install
cd $HOME/apps
if [ ! -e qmcpack ]; then
    mkdir qmcpack
fi
cd qmcpack
if [ ! -e qmcpack ]; then
    git clone https://github.com/QMCPACK/qmcpack.git
else
    cd qmcpack
    git pull
    cd ..
fi

if [ ! -e build/bin/qmcpack ]; then
echo --- Building QMCPACK `date`
rm -r -f build
mkdir build
cd build
cmake -DCMAKE_CXX_COMPILER=mpigxx -DCMAKE_C_COMPILER=mpigcc -DQMC_MPI=1  -DENABLE_MKL=1 -DMKL_ROOT=$MKLROOT -DCMAKE_C_FLAGS=-march=broadwell -DCMAKE_CXX_FLAGS=-march=broadwell ../qmcpack/ >&cmake.out
make -j 16 >&make.out
ctest -R deterministic >& ctest.out
cat ctest.out
cd ..
fi
# XXX build_complex needed

# QE
if [ ! -e $HOME/apps/qe-6.4/bin/pw.x ]; then
echo --- Building QE `date`
    cd $HOME/apps/qmcpack/qmcpack/external_codes/quantum_espresso/
    ./download_and_patch_qe6.4.sh
    cd qe-6.4
    ./configure  CC=mpigcc MPIF90=mpif90 F77=mpif77 --with-scalapack=intel --with-hdf5=/home/ubuntu/apps/hdf5-hdf5-1_10_5-gcc-impi  >&configure.out
    make pw >&make_pw.out
    make pwall >&make_pwall.out
    rm -r -f $HOME/apps/qe-6.4
    mv qe-6.4 $HOME/apps
    cd $HOME/apps
fi

cd $HOME
echo --- Shell setup `date`
# Shell setup
#XXX
# MKL, MPI, OMP threads, path to executables 
#XXX

echo --- Workshop files `date`
# Workshop files
cd $HOME
if [ ! -e qmcpack_workshop_2019 ]; then
    git clone https://github.com/QMCPACK/qmcpack_workshop_2019.git
else
    cd qmcpack_workshop_2019
    git pull
    cd ..
fi
echo -- END `date`

