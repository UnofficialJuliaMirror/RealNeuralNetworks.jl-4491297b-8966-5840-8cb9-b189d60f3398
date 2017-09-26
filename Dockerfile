FROM julia:0.5.2
LABEL   maintainer="Jingpeng Wu <jingpeng@princeton.edu>" \
        project="skeletonization"

RUN apt-get update
RUN apt-get install -qq --no-install-recommends build-essential unzip wget \
                libjemalloc-dev libhdf5-dev libxml2
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so 

RUN julia -e 'Pkg.update()'
RUN julia -e 'Pkg.add("LightGraphs")'
RUN julia -e 'Pkg.add("ArgParse")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/EMIRT.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/GSDicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'

WORKDIR /root/.julia/v0.5/
RUN mkdir TEASAR 
ADD . TEASAR/ 

RUN julia -e 'using TEASAR'
WORKDIR /root/.julia/v0.5/TEASAR/scripts
ENTRYPOINT ["julia", "skeletonize.jl", "-h"]