# A dockerfile must always start by importing the base image.
# We use the keyword 'FROM' to do that.
# In our example, we want import the python image.
# So we write 'python' for the image name and 'latest' for the version.
#FROM pymesh/pymesh
#FROM debian:bullseye

# NOTE ---> MUST BUILD WITH --format docker
# Example: podman build . -t masif_seed --format docker

# need an older version which will install gcc 9
FROM continuumio/anaconda3:2023.09-0

# In order to launch our python code, we must import it into our image.
# We use the keyword 'COPY' to do that.
# The first parameter 'main.py' is the name of the file on the host.
# The second parameter '/' is the path where to put the file on the image.
# Here we put the file at the image root folder.



ENV DEBIAN_FRONTEND "noninteractive"
ENV CC /usr/bin/gcc-9
ENV CXX /usr/bin/g++-9

# install necessary dependencies
RUN apt-get update
RUN apt-get install -y gcc-9
RUN apt-get install -y g++-9
RUN apt-get install -y apt-utils
RUN apt-get install -y build-essential
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y unzip
RUN apt-get install -y cmake
RUN apt-get install -y vim
RUN apt-get install -y libgl1-mesa-glx
RUN apt-get install -y libcifpp1
RUN apt-get install -y dssp
RUN apt-get install -y curl

# Create python environments:
RUN conda create -n venv3 python=3.6 numpy ipython matplotlib scikit-learn-intelex \
    Biopython scikit-learn tensorflow==1.12 networkx dask==1.2.2 packaging
# We only need this to compile one package
RUN conda create -n venv2 python=2.7 numpy
# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "venv3", "/bin/bash", "-c"]
# make sure this container starts in python 3.6
RUN echo "source activate venv3" > ~/.bashrc

# DOWNLOAD/INSTALL APBS
RUN mkdir /install
WORKDIR /install
RUN git clone https://github.com/Electrostatics/apbs-pdb2pqr
WORKDIR /install/apbs-pdb2pqr
RUN ls
RUN git checkout b3bfeec
RUN git submodule init
RUN git submodule update
RUN ls
RUN cmake -DGET_MSMS=ON apbs
RUN make
RUN make install
RUN cp -r /install/apbs-pdb2pqr/apbs/externals/mesh_routines/msms/msms_i86_64Linux2_2.6.1 /root/msms/

# INSTALL PDB2PQR
WORKDIR /install/apbs-pdb2pqr/pdb2pqr
RUN git checkout b3bfeec
# RUN using python 2.7
SHELL ["conda", "run", "-n", "venv2", "/bin/bash", "-c"]
RUN which g++
RUN python scons/scons.py install
# Switch back to python 3.6
SHELL ["conda", "run", "-n", "venv3", "/bin/bash", "-c"]

# Setup environment variables 
ENV MSMS_BIN /usr/local/bin/msms
ENV APBS_BIN /usr/local/bin/apbs
ENV MULTIVALUE_BIN /usr/local/share/apbs/tools/bin/multivalue
ENV PDB2PQR_BIN /root/pdb2pqr/pdb2pqr.py

# DOWNLOAD reduce (for protonation)
WORKDIR /install
RUN git clone https://github.com/rlabduke/reduce.git
WORKDIR /install/reduce
RUN make install
RUN mkdir -p /install/reduce/build/reduce
WORKDIR /install/reduce/build/reduce
RUN cmake /install/reduce/reduce_src
WORKDIR /install/reduce/reduce_src
RUN make
RUN make install

# Install python libraries using pip
#RUN pip3 install matplotlib 
#RUN pip3 install ipython Biopython scikit-learn tensorflow==1.12 networkx open3d==0.8.0.0 dask==1.2.2 packaging
#RUN pip install StrBioInfo
RUN pip3 install open3d==0.8.0.0

# Install PyMesh
# https://pymesh.readthedocs.io/en/latest/installation.html
# THIS IS NOT THE SAME AS THE PIP PYMESH PACKAGE
RUN apt-get install -y \
    libeigen3-dev \
    libgmp-dev \
    libgmpxx4ldbl \
    libmpfr-dev \
    libboost-dev \
    libboost-thread-dev \
    libtbb-dev \
    python3-dev
    
WORKDIR /root/
RUN git clone https://github.com/PyMesh/PyMesh.git
WORKDIR /root/PyMesh
RUN git submodule update --init
ENV PYMESH_PATH /root/PyMesh
RUN pip3 install -r $PYMESH_PATH/python/requirements.txt
RUN ./setup.py build
RUN ./setup.py install
RUN python -c "import pymesh; pymesh.test()"

# Clone masif
WORKDIR /
RUN git clone --single-branch https://github.com/LPDI-EPFL/masif

# We need to define the command to launch when we are going to run the image.
# We use the keyword 'CMD' to do that.
CMD [ "bash" ]
