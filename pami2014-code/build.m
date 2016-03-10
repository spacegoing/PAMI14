% BUILD
%
% Copyright (c) 2011-2014, Stephen Gould <stephen.gould@anu.edu.au>
% All rights reserved.
%

% download Vladimir Kolmogorov's maxflow library
URL = 'http://pub.ist.ac.at/~vnk/software/';
SRC = 'maxflow-v3.03.src';
if (~exist(SRC, 'file')),
    disp('installing maxflow library...');
    status = system(['wget ', URL, SRC, '.zip']);
    if (status ~= 0),
        error('ERROR: could not download maxflow library');
    end;
    system(['unzip ', SRC, '.zip']);
end;

disp('building mex files...');
mex -g -output linEnvInf linEnvInf.cpp ...
    maxflow-v3.03.src/graph.cpp maxflow-v3.03.src/maxflow.cpp
