#include "mex.h"
#include "pthread.h"
#include "stdio.h"

 
char *filename;
unsigned short int *data;
size_t numElementsExpected;
size_t numElementsWritten;
 
/* thread compute function */ 
void *thread_run(void *p)
{
    /* Open the file for binary output */ 
    FILE *fp = fopen(filename, "wb"); 
    if (fp == NULL)
        mexPrintf("Could not open file");
 
    /* Write the data to file */
    numElementsWritten = (size_t) fwrite(data, sizeof(unsigned short int), numElementsExpected, fp);
    fclose(fp);
 
    /* Ensure that the data was correctly written */
    if (numElementsWritten != numElementsExpected)
           mexPrintf("Error writing data");

 
    /* Cleanup */
    pthread_exit(NULL);
}
 
/* The MEX gateway function */
void mexFunction(int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    pthread_t thread;
 
    /* Check for proper number of input and output arguments */
//     if (nrhs != 2)
//         mexPrintf("YMA:MexIO:invalidNumInputs", "2 input args required: filename, data");
//     if (nlhs > 0)
//         mexPrintf("YMA:MexIO:maxlhs", "Too many output arguments");
//     if (!mxIsChar(prhs[0]))
//         mexPrintf("YMA:MexIO:invalidInput", "Input filename must be of type string");
//     if (!mxIsDouble(prhs[1]))
//         mexPrintf("YMA:MexIO:invalidInput", "Input data must be of type double");
 
    /* Get the inputs: filename & data */
    filename = mxArrayToString(prhs[0]);
    data = mxGetPr(prhs[1]);  
    numElementsExpected = mxGetNumberOfElements(prhs[1]);
 
    /* Launch a new I/O thread using default attributes */
    if (pthread_create(&thread, NULL, thread_run, NULL))
        mexPrintf("Thread creation failed");
}