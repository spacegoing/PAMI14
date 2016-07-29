/*****************************************************************************
** This is a reference implementation for the synthetic experiments on lower
** linear envelope inference and learning described in
**
** [1] "Max-margin Learning for Lower Linear Envelope Potentials in Binary
**      Markov Random Fields", Stephen Gould, ICML 2011.
**
** [2] "Learning for Weighted Lower Linear Envelopes Potentials in Binary
**      Markov Random Fields", Stephen Gould, PAMI 2014.
**
** Copyright (c) 2011-2014, Stephen Gould <stephen.gould@anu.edu.au>
** All rights reserved.
**
*****************************************************************************/

// c++ standard headers
#include <cstdlib>
#include <cstdio>
#include <cmath>
#include <limits>
#include <vector>
#include <list>
#include <set>

// matlab
#include "mex.h"
#include "matrix.h"

// Vladmir Kolmogorov's maxflow-v3.03 library
#include "maxflow-v3.03.src/graph.h"

using namespace std;

// usage --------------------------------------------------------------------

void usage()
{
    mexPrintf("LINENVINF    Lower Linear Envelope Inference\n");
    mexPrintf("\n");
    mexPrintf("USAGE: [y, e] = linEnvInf(unary, pairwise, coeffs, cliques);\n");
    mexPrintf("\nWHERE\n");
    mexPrintf("  unary    : N-by-2 array of unary potentials\n");
    mexPrintf("  pairwise : M-by-3 list of edge weights (u_m, v_m, weight_m)\n");
    mexPrintf("  coeffs   : K-by-2 list of linear envelope potentials (a_k, b_k)\n");
    mexPrintf("  cliques  : N-by-C list of clique indexes\n");
    mexPrintf("\n");
}

// mexFunction --------------------------------------------------------------

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // check number of input and output arguments
    if ((nrhs != 4) || (nlhs < 1) || (nlhs > 3)) {
        usage();
        return;
    }

    // constants
    const int nVariables = mxGetM(prhs[0]);
    mxAssert((nVariables != 0) || (mxGetN(prhs[0]) == 2), "incorrect size for unary");
    const int nPairwise = mxGetM(prhs[1]);
    mxAssert((nPairwise == 0) || (mxGetN(prhs[1]) == 3), "incorrect size for pairwise");
    const int K = mxGetM(prhs[2]);
    mxAssert((K == 0) || (mxGetN(prhs[2]) == 2), "incorrect size of coeffs");
    const int nMaxCliquesPerVariable = mxGetN(prhs[3]);
    mxAssert((nMaxCliquesPerVariable == 0) || (mxGetM(prhs[3]) == nVariables),
        "mismatch between unary and cliques");

    // construct s-t graph
    typedef Graph<double, double, double> GraphType;
    GraphType *g = new GraphType(nVariables, 8 * nVariables);

    g->add_node(nVariables);

    // add unary terms
    mexPrintf("...adding %d unary terms\n", nVariables);
    const double *p = mxGetPr(prhs[0]);
    for (int i = 0; i < nVariables; i++) {
        g->add_tweights(i, p[i], p[i + nVariables]);
        // mexPrintf("Node: %d, Source: %f, Sink: %f\n", i, p[i], p[i + nVariables]);
    }

    // add pairwise terms
    mexPrintf("...adding %d pairwise terms\n", nPairwise);
    p = mxGetPr(prhs[1]);
    for (int ei = 0; ei < nPairwise; ei++) {
        int u = (int)p[ei] - 1;
        int v = (int)p[ei + nPairwise] - 1;
        mxAssert((u >= 0) && (u < nVariables) && (v >= 0) && (v < nVariables), "illegal variable pair");
        double w = p[ei + 2 * nPairwise];
        mxAssert(w >= 0.0, "illegal pairwise weight");
        if (w == 0.0) continue;

        g->add_edge(u, v, w, w);
    }

    // add higher-order term for each clique
    // sets w_i = 1/cliqueSize
    vector<int> cliqueSize;
    const double *cliques = mxGetPr(prhs[3]);
    for (int i = 0; i < nVariables; i++) {
        for (int c = 0; c < nMaxCliquesPerVariable; c++) {
            const int cliqueIndx = (int)cliques[c * nVariables + i] - 1;
            if (cliqueIndx < 0) continue;
            if (cliqueSize.size() < cliqueIndx + 1) {
                cliqueSize.resize(cliqueIndx + 1, 0);
            }
            cliqueSize[cliqueIndx] += 1;
        }
    }
    mexPrintf("...%d higher-order cliques (maximum of %d cliques per variable)\n", 
        (int)cliqueSize.size(), nMaxCliquesPerVariable);

    vector<int> z(cliqueSize.size());

    if ((K != 0) && !cliqueSize.empty()) {
        mexPrintf("...adding %d linear envelope potentials\n", (int)cliqueSize.size());
        p = mxGetPr(prhs[2]);

        // add auxiliary variables for each clique
        if (K > 1) {
            for (int cliqueIndx = 0; cliqueIndx < (int)z.size(); cliqueIndx++) {
                z[cliqueIndx] = g->add_node(K - 1);
            }
        }

        // add edges between y_i and z_k and y_i and t
        for (int i = 0; i < nVariables; i++) {
            for (int c = 0; c < nMaxCliquesPerVariable; c++) {
                const int cliqueIndx = (int)cliques[c * nVariables + i] - 1;
                if (cliqueIndx < 0) continue;

                double w_i = 1.0 / (double)cliqueSize[cliqueIndx];

                double a = p[0];
                g->add_tweights(i, 0.0, a * w_i);

                for (int k = 1; k < K; k++) {
                    const double da = p[k - 1] - p[k];
                    if (fabs(da) < 1.0e-6) continue;
                    mxAssert(da > 0.0, "invalid linear envelope coefficients");
                    g->add_edge(i, z[cliqueIndx] + k - 1, 0.0, w_i * da);
                }
            }
        }

        // add edges between s and z_k and z_k and t
        for (int cliqueIndx = 0; cliqueIndx < (int)cliqueSize.size(); cliqueIndx++) {
            if (cliqueSize[cliqueIndx] == 0) {
                mexPrintf("warning: clique %d is empty\n", cliqueIndx + 1);
                continue;
            }

            for (int k = 1; k < K; k++) {
                const double da = p[k - 1] - p[k];
                if (fabs(da) < 1.0e-6) continue;
                const double db = p[K + k] - p[K + k - 1];
                mxAssert(db > 0.0, "invalid linear envelope coefficients");
                g->add_tweights(z[cliqueIndx] + k - 1, da, db);
            }
        }
    }

    // find min-st-cut
    double e = g->maxflow();
    mexPrintf("min-cut has value %f\n", e);

    // decode solution
    plhs[0] = mxCreateDoubleMatrix(nVariables, 1, mxREAL);
    double *y = mxGetPr(plhs[0]);
    for (int i = 0; i < nVariables; i++) {
        y[i] = (g->what_segment(i) == GraphType::SOURCE) ? 1.0 : 0.0;
    }

    // output energy
    if (nlhs >= 2) {
        plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
        *mxGetPr(plhs[1]) = e;
        plhs[2] = mxCreateDoubleMatrix(z.size()*(K-1), 1, mxREAL);
        double *zz = mxGetPr(plhs[2]);
        int abc = 0;
        for (int i = 0; i < z.size(); i++) {
            for(int j = 0; j < K-1; j++){
                zz[abc] = (g->what_segment(z[i]+j) == GraphType::SOURCE) ? 1.0 : 0.0;
                abc++;
            }
        }
    }

    // free graph
    delete g;
}
